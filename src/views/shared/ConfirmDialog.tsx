import type { ReactNode } from 'react';
import { Dialog } from './Dialog';

export function ConfirmDialog({
    title,
    children,
    confirmLabel,
    busy,
    disabled = false,
    onCancel,
    onConfirm,
}: {
    title: string;
    children: ReactNode;
    confirmLabel: string;
    busy: boolean;
    disabled?: boolean;
    onCancel: () => void;
    onConfirm: () => void;
}) {
    return (
        <Dialog title={title} onClose={onCancel}>
            <div className="stack">
                <p>{children}</p>
                <div className="actions">
                    <button type="button" className="button" disabled={busy} onClick={onCancel}>
                        Cancel
                    </button>
                    <button
                        type="button"
                        className="button danger"
                        disabled={busy || disabled}
                        onClick={onConfirm}
                    >
                        {confirmLabel}
                    </button>
                </div>
            </div>
        </Dialog>
    );
}
