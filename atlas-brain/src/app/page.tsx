import Link from "next/link";
import { prisma } from "@/lib/db";

function fmt(d: Date) {
  return new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  }).format(d);
}

export default async function TimelinePage() {
  const docs = await prisma.document.findMany({
    orderBy: { createdAt: "desc" },
    take: 75,
    select: {
      id: true,
      kind: true,
      source: true,
      title: true,
      content: true,
      createdAt: true,
      path: true,
    },
  });

  return (
    <div className="space-y-6">
      <div className="flex items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Timeline</h1>
          <p className="text-sm text-zinc-600 dark:text-zinc-300">
            Auto-ingested notes + conversations (excluding MyJournal).
          </p>
        </div>
        <Link
          className="text-sm text-blue-600 hover:underline dark:text-blue-400"
          href="/search"
        >
          Search →
        </Link>
      </div>

      <ul className="divide-y divide-zinc-200 rounded-lg border border-zinc-200 bg-white dark:divide-zinc-800 dark:border-zinc-800 dark:bg-black">
        {docs.map((d) => (
          <li key={d.id} className="px-4 py-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div className="min-w-0">
                <Link
                  href={`/doc/${d.id}`}
                  className="block truncate font-medium hover:underline"
                >
                  {d.title ?? d.path ?? d.id}
                </Link>
                <div className="mt-1 flex flex-wrap items-center gap-2 text-xs text-zinc-500 dark:text-zinc-400">
                  <span className="rounded bg-zinc-100 px-2 py-0.5 dark:bg-zinc-900">
                    {d.kind}
                  </span>
                  <span className="rounded bg-zinc-100 px-2 py-0.5 dark:bg-zinc-900">
                    {d.source}
                  </span>
                  <span>{fmt(d.createdAt)}</span>
                </div>
              </div>
            </div>
            <p className="mt-2 line-clamp-3 text-sm text-zinc-700 dark:text-zinc-200">
              {d.content.slice(0, 400)}
            </p>
          </li>
        ))}
      </ul>
    </div>
  );
}
