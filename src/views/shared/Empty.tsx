import type { ReactNode } from 'react';

export function Empty({ title, children }: { title: string; children?: ReactNode }) {
    return (
        <section className="empty">
            <div className="empty-disc" aria-hidden="true">
                ◌
            </div>
            <h2>{title}</h2>
            {children}
        </section>
    );
}
