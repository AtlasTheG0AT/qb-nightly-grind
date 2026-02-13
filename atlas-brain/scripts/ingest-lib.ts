import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";

export function sha256(text: string) {
  return crypto.createHash("sha256").update(text).digest("hex");
}

export async function fileExists(p: string) {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

export async function listFilesRecursive(root: string, opts?: { exts?: string[]; ignore?: RegExp[] }) {
  const exts = opts?.exts ?? [];
  const ignore = opts?.ignore ?? [];

  const out: string[] = [];

  async function walk(dir: string) {
    if (ignore.some((re) => re.test(dir))) return;
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const ent of entries) {
      const full = path.join(dir, ent.name);
      if (ignore.some((re) => re.test(full))) continue;
      if (ent.isDirectory()) await walk(full);
      else {
        if (exts.length === 0 || exts.includes(path.extname(ent.name))) out.push(full);
      }
    }
  }

  await walk(root);
  return out;
}

export function extractTextFromMessageContent(content: any): string {
  // content is typically an array of blocks
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";

  const parts: string[] = [];
  for (const block of content) {
    if (!block || typeof block !== "object") continue;
    if (block.type === "text" && typeof block.text === "string") parts.push(block.text);
    if (block.type === "summary_text" && typeof block.text === "string") parts.push(block.text);
  }
  return parts.join("\n").trim();
}

export function safeBasename(p: string) {
  return path.basename(p);
}
