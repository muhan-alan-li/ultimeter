import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';

export function PageHeader({
    title,
    subtitle,
    back,
    children,
}: {
    title: string;
    subtitle?: string;
    back?: string;
    children?: ReactNode;
}) {
    return (
        <header className="page-header">
            <div>
                {back && (
                    <Link className="back-link" to={back}>
                        ← Back
                    </Link>
                )}
                <h1>{title}</h1>
                {subtitle && <p className="muted">{subtitle}</p>}
            </div>
            <div className="actions">{children}</div>
        </header>
    );
}
