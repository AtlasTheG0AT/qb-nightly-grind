import Link from "next/link";

export function Nav() {
  return (
    <header className="border-b border-zinc-200 bg-white/80 backdrop-blur dark:border-zinc-800 dark:bg-black/60">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-3">
        <Link href="/" className="font-semibold tracking-tight">
          Atlas Brain
        </Link>
        <nav className="flex items-center gap-4 text-sm text-zinc-600 dark:text-zinc-300">
          <Link className="hover:text-zinc-950 dark:hover:text-white" href="/">
            Timeline
          </Link>
          <Link className="hover:text-zinc-950 dark:hover:text-white" href="/search">
            Search
          </Link>
        </nav>
      </div>
    </header>
  );
}
