-- Extra autostart processes.

-- Scratchpad web apps. hyprland.lua sends both to special:scratchpad by class.
-- They go through omarchy-launch-webapp rather than naming a browser, so the
-- Helium choice lives in one place. The launcher execs its own `setsid
-- uwsm-app`, hence exec_on_start rather than launch_on_start, which would wrap
-- it a second time. The Messages URL matches Omarchy's SUPER+SHIFT+CTRL+G bind
-- so the two agree on one window.
--
-- Chromium chooses its notification backend once, at process start: if
-- org.freedesktop.Notifications has no owner yet, it falls back to its own
-- message center for the life of the process, and web app notifications arrive
-- as ordinary windows -- here, inside the scratchpad. omarchy-shell owns that
-- name and starts at the same moment these do, so wait for it first.
local function after_notifications(command)
	return "gdbus wait --session --timeout 30 org.freedesktop.Notifications && " .. command
end

o.exec_on_start(after_notifications(o.launch_webapp("https://ticktick.com/webapp")))
o.exec_on_start(after_notifications(o.launch_webapp("https://messages.google.com/web/conversations")))

-- Draw on the screen
o.launch_on_start("wayscriber --daemon")

-- Night light. hyprsunset.conf carries a full evening ramp, but the profiles
-- only run once hyprsunset itself is running, and nothing starts it at login:
-- omarchy.nightlight starts it lazily on the first toggle. Starting it here is
-- what Omarchy's own hyprsunset.conf recommends for a scheduled setup.
o.launch_on_start("hyprsunset")

-- Touchscreen gestures. hyprgrass is a Hyprland plugin, installed through hyprpm
-- rather than pacman, and nothing loads it at startup on its own. A one-shot CLI
-- call, so exec rather than launch. Loading the plugin triggers a config reload,
-- which is what makes the guarded block in hypr/touch.lua register.
o.exec_on_start("hyprpm reload -n")

-- On-screen keyboard for tablet mode. Starts hidden and costs nothing until
-- revealed; SIGUSR2 (pkill -34) toggles it, which hypr/touch.lua binds to a
-- swipe up from the bottom edge.
o.launch_on_start("wvkbd-mobintl -L 256 --hidden --alpha 204")
