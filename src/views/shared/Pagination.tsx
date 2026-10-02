export function Pagination({
    label,
    page,
    pageCount,
    busy,
    canPrevious,
    canNext,
    onChange,
}: {
    label: string;
    page: number;
    pageCount: number;
    busy: boolean;
    canPrevious: boolean;
    canNext: boolean;
    onChange: (direction: -1 | 1) => void;
}) {
    return (
        <nav className="row" aria-label={label}>
            <button className="button" disabled={busy || !canPrevious} onClick={() => onChange(-1)}>
                Previous
            </button>
            <span className="muted" aria-live="polite">
                Page {page + 1} of {pageCount}
            </span>
            <button className="button" disabled={busy || !canNext} onClick={() => onChange(1)}>
                Next
            </button>
        </nav>
    );
}
