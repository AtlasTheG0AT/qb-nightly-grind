import fs from "node:fs/promises";
import path from "node:path";
import { PrismaBetterSqlite3 } from "@prisma/adapter-better-sqlite3";
import { PrismaClient } from "../src/generated/prisma/client";
import {
  extractTextFromMessageContent,
  fileExists,
  listFilesRecursive,
  safeBasename,
  sha256,
} from "./ingest-lib";

function sqliteUrlFromEnv() {
  return process.env.DATABASE_URL ?? "file:./dev.db";
}

const prisma = new PrismaClient({
  adapter: new PrismaBetterSqlite3({ url: sqliteUrlFromEnv() }),
});

const ROOT_CLAWD = "/home/ubuntu/clawd";
const ROOT_CLAWDBOT = "/home/ubuntu/.clawdbot";

function rel(p: string) {
  if (p.startsWith(ROOT_CLAWD)) return `clawd:${p.slice(ROOT_CLAWD.length)}`;
  if (p.startsWith(ROOT_CLAWDBOT)) return `clawdbot:${p.slice(ROOT_CLAWDBOT.length)}`;
  return p;
}

async function upsertDoc(args: {
  source: string;
  externalId: string;
  kind: string;
  title?: string;
  path?: string;
  content: string;
  createdAt?: Date;
  metadata?: any;
}) {
  const contentHash = sha256(args.content);
  const createdAt = args.createdAt ?? new Date();

  await prisma.document.upsert({
    where: { source_externalId: { source: args.source, externalId: args.externalId } },
    create: {
      source: args.source,
      externalId: args.externalId,
      kind: args.kind,
      title: args.title,
      path: args.path,
      content: args.content,
      contentHash,
      metadata: args.metadata,
      createdAt,
    },
    update: {
      kind: args.kind,
      title: args.title,
      path: args.path,
      content: args.content,
      contentHash,
      metadata: args.metadata,
      // createdAt left intact on update
    },
  });
}

async function ingestMarkdownFile(absPath: string) {
  const content = await fs.readFile(absPath, "utf8");
  const stat = await fs.stat(absPath);

  await upsertDoc({
    source: "clawd-file",
    externalId: rel(absPath),
    kind: "note",
    title: safeBasename(absPath),
    path: absPath,
    content,
    createdAt: stat.mtime,
    metadata: { ext: ".md" },
  });
}

async function ingestSessionJsonl(absPath: string, source: "clawdbot-session" | "clawdbot-cron") {
  const raw = await fs.readFile(absPath, "utf8");
  const lines = raw.split(/\r?\n/).filter(Boolean);
  const fileId = rel(absPath);

  for (let i = 0; i < lines.length; i++) {
    let obj: any;
    try {
      obj = JSON.parse(lines[i]!);
    } catch {
      continue;
    }

    // Only index human+assistant messages (skip tool calls/results and session metadata)
    if (obj?.type !== "message") continue;
    const role = obj?.message?.role;
    if (role !== "user" && role !== "assistant") continue;

    const text = extractTextFromMessageContent(obj?.message?.content);
    if (!text) continue;

    const ts = obj?.timestamp ? new Date(obj.timestamp) : undefined;
    const externalId = `${fileId}#${obj?.id ?? i}`;

    await upsertDoc({
      source,
      externalId,
      kind: "message",
      title: `${role}: ${safeBasename(absPath)}`,
      path: absPath,
      content: text,
      createdAt: ts,
      metadata: {
        role,
        sessionFile: absPath,
        rawId: obj?.id,
        timestamp: obj?.timestamp,
      },
    });
  }
}

async function main() {
  // Notes (exclude MyJournal)
  const noteTargets: string[] = [];
  const memoryMd = path.join(ROOT_CLAWD, "MEMORY.md");
  const living = path.join(ROOT_CLAWD, "living.md");

  if (await fileExists(memoryMd)) noteTargets.push(memoryMd);
  if (await fileExists(living)) noteTargets.push(living);

  const mdDirs = [
    path.join(ROOT_CLAWD, "memory"),
    path.join(ROOT_CLAWD, "docs"),
  ];
  for (const d of mdDirs) {
    if (await fileExists(d)) {
      noteTargets.push(
        ...(await listFilesRecursive(d, {
          exts: [".md"],
          ignore: [/\/MyJournal\//, /\/node_modules\//],
        }))
      );
    }
  }

  // Dedup
  const uniqueNotes = Array.from(new Set(noteTargets));
  for (const p of uniqueNotes) await ingestMarkdownFile(p);

  // Sessions
  const sessionDir = path.join(ROOT_CLAWDBOT, "agents", "main", "sessions");
  if (await fileExists(sessionDir)) {
    const sessionFiles = (await listFilesRecursive(sessionDir, { exts: [".jsonl"] })).filter(
      (p) => !p.endsWith(".lock")
    );
    for (const p of sessionFiles) await ingestSessionJsonl(p, "clawdbot-session");
  }

  // Cron runs
  const cronRuns = path.join(ROOT_CLAWDBOT, "cron", "runs");
  if (await fileExists(cronRuns)) {
    const cronFiles = await listFilesRecursive(cronRuns, { exts: [".jsonl"] });
    for (const p of cronFiles) await ingestSessionJsonl(p, "clawdbot-cron");
  }

  const count = await prisma.document.count();
  console.log(`[ingest] done. documents indexed: ${count}`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
