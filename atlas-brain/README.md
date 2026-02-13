# Atlas Brain (local)

A **local-only** “second brain” built with Next.js.

It auto-ingests:
- Clawdbot workspace notes: `living.md`, `memory/*.md`, `docs/*.md` (and `MEMORY.md` if present)
- Clawdbot conversation logs: `~/.clawdbot/agents/main/sessions/*.jsonl`
- Cron run logs: `~/.clawdbot/cron/runs/*.jsonl`

It explicitly **does not** ingest: `/home/ubuntu/clawd/MyJournal/**`.

## Run

```bash
cd /home/ubuntu/clawd/atlas-brain
npm run dev
```

- Web UI: http://localhost:3000
- The dev command also runs an **ingest watcher** that re-indexes on changes.

## Manual re-index

```bash
npm run ingest:once
```

## Storage

- SQLite db: `dev.db` (controlled by `DATABASE_URL` in `.env`)
- Prisma schema: `prisma/schema.prisma`
