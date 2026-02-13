import chokidar from "chokidar";
import { execa } from "execa";

// Keep the watcher process dumb: it just re-runs ingest-once on changes.
// This avoids long-lived Prisma client issues during dev.

const WATCH_PATHS = [
  "/home/ubuntu/clawd/memory",
  "/home/ubuntu/clawd/docs",
  "/home/ubuntu/clawd/living.md",
  "/home/ubuntu/clawd/MEMORY.md",
  "/home/ubuntu/.clawdbot/agents/main/sessions",
  "/home/ubuntu/.clawdbot/cron/runs",
];

const IGNORED = [
  /\/MyJournal\//,
  /\/node_modules\//,
  /\.lock$/,
  /\.db$/,
  /prisma\/migrations\//,
];

let running = false;
let queued = false;

async function runIngest() {
  if (running) {
    queued = true;
    return;
  }
  running = true;
  try {
    await execa("npm", ["run", "ingest:once"], { stdio: "inherit" });
  } finally {
    running = false;
    if (queued) {
      queued = false;
      void runIngest();
    }
  }
}

console.log("[ingest] watch mode starting...");
void runIngest();

const watcher = chokidar.watch(WATCH_PATHS, {
  ignoreInitial: true,
  ignored: IGNORED,
  awaitWriteFinish: { stabilityThreshold: 300, pollInterval: 100 },
});

watcher.on("all", (_event, p) => {
  console.log(`[ingest] change detected: ${p}`);
  void runIngest();
});
