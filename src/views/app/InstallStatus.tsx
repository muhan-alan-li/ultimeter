import { useEffect, useState } from 'react';
import { useApp } from '../../app/context';
import { useRegisterSW } from 'virtual:pwa-register/react';

interface InstallPrompt extends Event {
    prompt(): Promise<void>;
    userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export function InstallStatus() {
    const application = useApp();
    const [online, setOnline] = useState(() => navigator.onLine);
    const [installPrompt, setInstallPrompt] = useState<InstallPrompt>();
    const [help, setHelp] = useState(false);
    const [registrationError, setRegistrationError] = useState(false);
    const [updateError, setUpdateError] = useState(false);
    const [cached, setCached] = useState(false);
    const updateBlocked =
        application.busy ||
        application.dirty ||
        application.session.games.some((game) => game.status === 'live');
    async function install() {
        if (!installPrompt) {
            setHelp((value) => !value);

            return;
        }
        try {
            await installPrompt.prompt();
            await installPrompt.userChoice;
        } catch {
            setHelp(true);
        } finally {
            setInstallPrompt(undefined);
        }
    }
    async function update(applyUpdate: () => Promise<void>) {
        setUpdateError(false);
        try {
            await applyUpdate();
        } catch {
            setUpdateError(true);
        }
    }
    const {
        offlineReady: [offlineReady],
        needRefresh: [needRefresh, setNeedRefresh],
        updateServiceWorker,
    } = useRegisterSW({
        onRegisterError: () => setRegistrationError(true),
    });
    const ready = offlineReady || cached;
    useEffect(() => {
        let active = true;
        if ('serviceWorker' in navigator && import.meta.env.PROD) {
            void navigator.serviceWorker.ready
                .then((registration) => {
                    if (active && registration.active) setCached(true);
                })
                .catch(() => {
                    if (active) setRegistrationError(true);
                });
        }
        const updateOnline = () => setOnline(navigator.onLine);
        const offerInstall = (event: Event) => {
            event.preventDefault();
            setInstallPrompt(event as InstallPrompt);
        };
        const installed = () => setInstallPrompt(undefined);
        window.addEventListener('online', updateOnline);
        window.addEventListener('offline', updateOnline);
        window.addEventListener('beforeinstallprompt', offerInstall);
        window.addEventListener('appinstalled', installed);

        return () => {
            active = false;
            window.removeEventListener('online', updateOnline);
            window.removeEventListener('offline', updateOnline);
            window.removeEventListener('beforeinstallprompt', offerInstall);
            window.removeEventListener('appinstalled', installed);
        };
    }, []);

    return (
        <>
            <div className="connection-status">
                <span className="status-dot" data-ready={ready} />
                <span>
                    {ready
                        ? online
                            ? 'Ready for offline play'
                            : 'Offline · ready to play'
                        : online
                          ? 'Local game storage'
                          : 'Offline · app cache not confirmed'}
                </span>
                <button className="text-button install-button" onClick={() => void install()}>
                    Install app
                </button>
            </div>
            {help && (
                <aside className="notice">
                    <strong>Add Ultimeter to your Home Screen</strong>
                    <p>
                        On iPhone or iPad, open Safari, tap Share, then Add to Home Screen. On
                        Android, use the browser’s Install app menu.
                    </p>
                    <p>Load the app once online before offline play.</p>
                    <button onClick={() => setHelp(false)}>Got it</button>
                </aside>
            )}
            {registrationError && (
                <p className="notice" role="status">
                    Offline assets could not be prepared. Reopen the app with a network connection.
                </p>
            )}
            {needRefresh && (
                <aside className="notice">
                    <strong>An app update is ready</strong>
                    <p>
                        {updateBlocked
                            ? 'Finish live games and close forms before updating.'
                            : 'Update when you are ready to reload the app.'}
                    </p>
                    <div className="actions">
                        <button
                            className="primary"
                            disabled={updateBlocked}
                            onClick={() => void update(() => updateServiceWorker(true))}
                        >
                            Update
                        </button>
                        <button onClick={() => setNeedRefresh(false)}>Later</button>
                    </div>
                    {updateError && (
                        <p role="alert">The update could not be applied. Try again when online.</p>
                    )}
                </aside>
            )}
        </>
    );
}
