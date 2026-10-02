import {
    createContext,
    type ReactNode,
    useContext,
    useEffect,
    useState,
    useSyncExternalStore,
} from 'react';
import { Dialog } from '../views/shared';
import type { Application } from './Application';

const AppContext = createContext<{ application: Application } | undefined>(undefined);

export function AppProvider({
    children,
    application,
}: {
    children: ReactNode;
    application: Application;
}) {
    useSyncExternalStore(application.subscribe, application.getRevision);
    useEffect(() => application.observe(), [application]);

    if (application.loadError)
        return (
            <main className="startup">
                <h1>Local storage unavailable</h1>
                <p role="alert">{application.loadError}</p>
                <button onClick={() => window.location.reload()}>Try again</button>
            </main>
        );
    if (!application.ready)
        return (
            <main className="startup" aria-busy="true">
                <h1>Ultimeter</h1>
                <p>Opening your local game data…</p>
            </main>
        );

    return (
        <AppContext.Provider value={{ application }}>
            {children}
            <div className="sr-only" role="status">
                {application.busy ? 'Saving action' : 'Ready'}
            </div>
            {application.error && (
                <Dialog title="Action failed" onClose={() => application.dismissError()}>
                    <div className="stack">
                        <p role="alert">{application.error}</p>
                        <button onClick={() => application.dismissError()}>OK</button>
                    </div>
                </Dialog>
            )}
        </AppContext.Provider>
    );
}

export function useApp(): Application {
    const context = useContext(AppContext);
    if (!context) throw new Error('Connect the screen to AppProvider.');

    return context.application;
}

export function useDirty(dirty: boolean): void {
    const { setDirty } = useApp();
    const [token] = useState(() => Symbol('screen draft'));
    useEffect(() => {
        setDirty(token, dirty);

        return () => setDirty(token, false);
    }, [dirty, setDirty, token]);
}
