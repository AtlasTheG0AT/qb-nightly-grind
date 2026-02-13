import Link from "next/link";
import { notFound } from "next/navigation";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
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

export default async function DocPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const doc = await prisma.document.findUnique({ where: { id } });
  if (!doc) return notFound();

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <div className="text-sm">
          <Link className="text-blue-600 hover:underline dark:text-blue-400" href="/">
            ← Timeline
          </Link>
        </div>
        <h1 className="text-xl font-semibold tracking-tight">{doc.title ?? doc.path ?? doc.id}</h1>
        <div className="flex flex-wrap gap-2 text-xs text-zinc-500 dark:text-zinc-400">
          <span className="rounded bg-zinc-100 px-2 py-0.5 dark:bg-zinc-900">{doc.kind}</span>
          <span className="rounded bg-zinc-100 px-2 py-0.5 dark:bg-zinc-900">{doc.source}</span>
          <span>{fmt(doc.createdAt)}</span>
          {doc.path && <span className="font-mono">{doc.path}</span>}
        </div>
      </div>

      <article className="prose prose-zinc max-w-none dark:prose-invert">
        <ReactMarkdown remarkPlugins={[remarkGfm]}>{doc.content}</ReactMarkdown>
      </article>
    </div>
  );
}
