#!/usr/bin/env node

import { existsSync } from "node:fs";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, join } from "node:path";
import { spawn } from "node:child_process";

const port = Number(process.env.BROWSER_DEBUG_PORT || 9222);
const endpoint = `http://127.0.0.1:${port}`;
const ownerFile = join(tmpdir(), `browser-debug-${port}.json`);
const browsers = [
  "/Applications/Arc.app/Contents/MacOS/Arc",
  "/Applications/Helium.app/Contents/MacOS/Helium",
];

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function fetchCdpJson(path) {
  const response = await fetch(`${endpoint}${path}`);
  if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
  return response.json();
}

async function endpointReady(timeoutMs = 8000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      await fetchCdpJson("/json/version");
      return true;
    } catch {
      await delay(200);
    }
  }
  return false;
}

async function ownedVersion() {
  const version = await fetchCdpJson("/json/version");
  let owner;
  try {
    owner = JSON.parse(await readFile(ownerFile, "utf8"));
  } catch {
    throw new Error(`CDP endpoint on port ${port} is not owned by browser-debug`);
  }
  if (owner.webSocketDebuggerUrl !== version.webSocketDebuggerUrl) {
    throw new Error(`CDP endpoint on port ${port} is not owned by browser-debug`);
  }
  return version;
}

async function launch(url = "about:blank") {
  if (await endpointReady(200)) {
    const version = await ownedVersion();
    if (url !== "about:blank") await navigate(url);
    return version;
  }

  for (const binary of browsers.filter(existsSync)) {
    const profile = await mkdtemp(join(tmpdir(), "browser-debug-"));
    const child = spawn(
      binary,
      [
        `--remote-debugging-port=${port}`,
        `--remote-allow-origins=${endpoint}`,
        `--user-data-dir=${profile}`,
        "--no-first-run",
        url,
      ],
      { detached: true, stdio: "ignore" },
    );

    if (await endpointReady()) {
      const version = await fetchCdpJson("/json/version");
      await writeFile(
        ownerFile,
        JSON.stringify({
          browser: basename(binary),
          profile,
          webSocketDebuggerUrl: version.webSocketDebuggerUrl,
        }),
        { mode: 0o600 },
      );
      child.unref();
      return { browser: basename(binary), profile, ...version };
    }

    child.kill("SIGTERM");
  }

  throw new Error("Arc and Helium failed to expose a CDP endpoint");
}

async function pages() {
  await ownedVersion();
  const targets = await fetchCdpJson("/json/list");
  return targets.filter((target) => target.type === "page");
}

async function connect() {
  // ponytail: first page only; add target selection when multi-tab debugging is needed.
  const target = (await pages())[0];
  if (!target) throw new Error("No inspectable page. Run launch first.");

  const socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    socket.addEventListener("open", resolve, { once: true });
    socket.addEventListener("error", () => reject(new Error("CDP WebSocket failed")), {
      once: true,
    });
  });

  let nextId = 0;
  const pending = new Map();
  const listeners = new Set();

  socket.addEventListener("message", ({ data }) => {
    const message = JSON.parse(data);
    if (message.id) {
      const waiter = pending.get(message.id);
      if (!waiter) return;
      pending.delete(message.id);
      if (message.error) waiter.reject(new Error(message.error.message));
      else waiter.resolve(message.result);
      return;
    }
    for (const listener of listeners) listener(message);
  });

  return {
    on(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    send(method, params = {}) {
      const id = ++nextId;
      socket.send(JSON.stringify({ id, method, params }));
      return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
    },
    close() {
      socket.close();
    },
  };
}

async function navigate(url) {
  const cdp = await connect();
  try {
    await cdp.send("Page.enable");
    await cdp.send("Page.navigate", { url });
  } finally {
    cdp.close();
  }
}

async function evaluate(expression) {
  await launch();
  const cdp = await connect();
  try {
    await cdp.send("Runtime.enable");
    const result = await cdp.send("Runtime.evaluate", {
      expression,
      awaitPromise: true,
      returnByValue: true,
    });
    if (result.exceptionDetails) throw new Error(result.exceptionDetails.text);
    return result.result.value;
  } finally {
    cdp.close();
  }
}

async function observe(url, seconds = 3) {
  await launch();
  const cdp = await connect();
  const evidence = {
    url,
    console: [],
    exceptions: [],
    responses: [],
    failedRequests: [],
  };

  cdp.on(({ method, params }) => {
    if (method === "Runtime.consoleAPICalled") {
      evidence.console.push({
        type: params.type,
        values: params.args.map((arg) => arg.value ?? arg.description),
      });
    } else if (method === "Runtime.exceptionThrown") {
      evidence.exceptions.push(params.exceptionDetails);
    } else if (method === "Network.responseReceived") {
      const { response, type } = params;
      evidence.responses.push({
        url: response.url,
        status: response.status,
        statusText: response.statusText,
        mimeType: response.mimeType,
        type,
        fromDiskCache: response.fromDiskCache,
        fromServiceWorker: response.fromServiceWorker,
      });
    } else if (method === "Network.loadingFailed") {
      evidence.failedRequests.push({
        requestId: params.requestId,
        errorText: params.errorText,
        canceled: params.canceled,
        blockedReason: params.blockedReason,
      });
    }
  });

  try {
    await Promise.all([
      cdp.send("Page.enable"),
      cdp.send("Runtime.enable"),
      cdp.send("Network.enable"),
    ]);
    await cdp.send("Page.navigate", { url });
    await delay(Number(seconds) * 1000);
    return evidence;
  } finally {
    cdp.close();
  }
}

async function metrics() {
  await launch();
  const cdp = await connect();
  try {
    await cdp.send("Performance.enable");
    const { metrics: values } = await cdp.send("Performance.getMetrics");
    const navigation = await cdp.send("Runtime.evaluate", {
      expression: "performance.getEntriesByType('navigation')[0]?.toJSON() ?? null",
      returnByValue: true,
    });
    return {
      metrics: Object.fromEntries(values.map(({ name, value }) => [name, value])),
      navigation: navigation.result.value,
    };
  } finally {
    cdp.close();
  }
}

function usage() {
  console.error(`Usage:
  browser-cdp.mjs launch [url]
  browser-cdp.mjs status
  browser-cdp.mjs pages
  browser-cdp.mjs observe <url> [seconds]
  browser-cdp.mjs dom [selector]
  browser-cdp.mjs eval <expression>
  browser-cdp.mjs metrics`);
  process.exitCode = 2;
}

const [command, ...args] = process.argv.slice(2);

try {
  let result;
  if (command === "launch") result = await launch(args[0]);
  else if (command === "status") result = await ownedVersion();
  else if (command === "pages") {
    result = (await pages()).map(({ id, title, url }) => ({ id, title, url }));
  } else if (command === "observe" && args[0]) {
    result = await observe(args[0], args[1]);
  } else if (command === "dom") {
    const expression = args[0]
      ? `document.querySelector(${JSON.stringify(args[0])})?.outerHTML ?? null`
      : "document.documentElement.outerHTML";
    result = await evaluate(expression);
  } else if (command === "eval" && args.length) result = await evaluate(args.join(" "));
  else if (command === "metrics") result = await metrics();
  else {
    usage();
    result = undefined;
  }

  if (result !== undefined) console.log(JSON.stringify(result, null, 2));
} catch (error) {
  console.error(`browser-cdp: ${error.message}`);
  process.exitCode = 1;
}
