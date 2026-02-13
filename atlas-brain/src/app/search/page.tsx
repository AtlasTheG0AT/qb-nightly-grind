import Link from "next/link";
import { prisma } from "@/lib/db";

export default async function SearchPage(props: {
  searchParams?: Promise<{ q?: string }>;
}) {
  const sp = (await props.searchParams) ?? {};
  const q = (sp.q ?? "").trim();

  const results =
    q.length === 0
      ? []
      : await prisma.document.findMany({
          where: {
            OR: [{ content: { contains: q } }, { title: { contains: q } }],
          },
          orderBy: { createdAt: "desc" },
          take: 100,
          select: { id: true, title: true, path: true, kind: true, source: true, createdAt: true },
        });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Search</h1>
        <p className="text-sm text-zinc-600 dark:text-zinc-300">
          Keyword search across ingested notes + conversations.
        </p>
      </div>

      <form className="flex gap-2" action="/search" method="get">
        <input
          name="q"
          defaultValue={q}
          placeholder="search…"
          className="w-full rounded-md border border-zinc-300 bg-white px-3 py-2 text-sm outline-none focus:border-zinc-500 dark:border-zinc-700 dark:bg-black"
        />
        <button className="rounded-md bg-zinc-900 px-3 py-2 text-sm font-medium text-white dark:bg-zinc-100 dark:text-black">
          Search
        </button>
      </form>

      {q.length > 0 && (
        <div className="text-sm text-zinc-600 dark:text-zinc-300">
          {results.length} result(s) for <span className="font-mono">{q}</span>
        </div>
      )}

      <ul className="space-y-2">
        {results.map((r) => (
          <li
            key={r.id}
            className="rounded-lg border border-zinc-200 bg-white px-4 py-3 dark:border-zinc-800 dark:bg-black"
          >
            <Link href={`/doc/${r.id}`} className="font-medium hover:underline">
              {r.title ?? r.path ?? r.id}
            </Link>
            <div className="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
              {r.kind} · {r.source}
            </div>
          </li>
        ))}
      </ul>

      <div className="text-sm">
        <Link className="text-blue-600 hover:underline dark:text-blue-400" href="/">
          ← Back to timeline
        </Link>
      </div>
    </div>
  );
}
