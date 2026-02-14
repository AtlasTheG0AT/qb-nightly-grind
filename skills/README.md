# Workspace skills

This folder contains **workspace-local skills** installed for this Clawdbot instance.

## Installed

### summarize
- What it does: Summarizes URLs and local files (and optionally YouTube via external helpers) using the external `summarize` CLI.
- When to use it: Fast “read this and give me the gist / action items” for docs, articles, PDFs, logs.
- Notes: Requires the `summarize` CLI + a provider API key (OpenAI/Anthropic/xAI/Google, etc.).

### answeroverflow
- What it does: Searches indexed Discord discussions via Answer Overflow.
- When to use it: Finding fixes/workarounds that only exist in Discord threads (library issues, community Q&A).

## Management

- Prefer installing/updating via **ClawdHub CLI** when it’s available:
  - `clawdhub search "<query>"`
  - `clawdhub install <slug>`
  - `clawdhub update --all`

If the CLI is rate-limited, a fallback is to download the skill zip from ClawHub and unzip it into this folder.
