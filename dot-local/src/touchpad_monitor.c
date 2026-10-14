// The i2c_designware bus behind the ELAN1206 touchpad storms IRQ 28 while
// idma64.1 is bound, until the kernel disables the IRQ outright. Unbinding
// idma64.1 stops the storm but also stops pointer data, so it must be rebound
// the moment the touchpad reports activity.
// See https://github.com/CachyOS/linux-cachyos/issues/858

#include <fcntl.h>
#include <glob.h>
#include <limits.h>
#include <poll.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define TOUCHPAD_NAME "ELAN1206"
#define IDLE_TIMEOUT_MS 1000
#define DRIVER_DIR "/sys/bus/platform/drivers/idma64"

static int open_touchpad(void) {
  glob_t names;
  if (glob("/sys/class/input/event*/device/name", 0, NULL, &names) != 0)
    return -1;

  int fd = -1;
  for (size_t i = 0; i < names.gl_pathc && fd < 0; i++) {
    FILE *f = fopen(names.gl_pathv[i], "r");
    if (!f)
      continue;

    char name[256] = {0};
    if (fgets(name, sizeof(name), f) && strstr(name, TOUCHPAD_NAME) &&
        strstr(name, "Touchpad")) {
      char event_dir[PATH_MAX];
      snprintf(event_dir, sizeof(event_dir), "%s", names.gl_pathv[i]);
      *strstr(event_dir, "/device/name") = '\0';

      char device[PATH_MAX];
      snprintf(device, sizeof(device), "/dev/input/%s",
               strrchr(event_dir, '/') + 1);
      fd = open(device, O_RDONLY);
    }
    fclose(f);
  }

  globfree(&names);
  return fd;
}

static void set_dma_bound(int bound) {
  char path[PATH_MAX];
  snprintf(path, sizeof(path), DRIVER_DIR "/%s", bound ? "bind" : "unbind");

  int fd = open(path, O_WRONLY);
  if (fd < 0 || write(fd, "idma64.1", 8) < 0)
    perror(path);
  if (fd >= 0)
    close(fd);
}

int main(void) {
  int fd = open_touchpad();
  if (fd < 0) {
    fprintf(stderr, "no " TOUCHPAD_NAME " touchpad found\n");
    return 1;
  }

  struct pollfd pfd = {.fd = fd, .events = POLLIN};
  char discard[4096];
  int sleeping = 0;

  for (;;) {
    int ready = poll(&pfd, 1, IDLE_TIMEOUT_MS);
    if (ready < 0)
      return 1;

    if (ready == 0) {
      if (!sleeping) {
        set_dma_bound(0);
        sleeping = 1;
      }
      continue;
    }

    if (read(fd, discard, sizeof(discard)) < 0)
      return 1;

    if (sleeping) {
      set_dma_bound(1);
      sleeping = 0;
    }
  }
}
