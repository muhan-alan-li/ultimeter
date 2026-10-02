import { type ReactNode, useEffect, useId, useRef } from 'react';

export function Dialog({
    title,
    onClose,
    children,
}: {
    title: string;
    onClose: () => void;
    children: ReactNode;
}) {
    const ref = useRef<HTMLDialogElement>(null);
    const titleId = useId();
    useEffect(() => {
        const element = ref.current;
        const previous = document.activeElement;
        element?.showModal();

        return () => {
            element?.close();
            if (previous instanceof HTMLElement) previous.focus();
        };
    }, []);

    return (
        <dialog
            ref={ref}
            onCancel={(event) => {
                event.preventDefault();
                onClose();
            }}
            aria-labelledby={titleId}
        >
            <div className="dialog-header">
                <h2 id={titleId}>{title}</h2>
                <button className="icon-button" aria-label="Close dialog" onClick={onClose}>
                    ×
                </button>
            </div>
            {children}
        </dialog>
    );
}
