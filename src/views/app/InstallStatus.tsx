import { useEffect } from 'react';
import { useRegisterSW } from 'virtual:pwa-register/react';
import { useController } from '../../app/useController';
import {
    type InstallPrompt,
    InstallStatusController,
} from '../../controllers/app/InstallStatusController';

export function InstallStatus() {
    const controller = useController(() => new InstallStatusController());
    const {
        offlineReady: [offlineReady],
        needRefresh: [needRefresh, setNeedRefresh],
        updateServiceWorker,
    } = useRegisterSW({
        onRegisterError: () => controller.setRegistrationError(true),
    });
    const ready = offlineReady || controller.cached;
    useEffect(() => {
        let active = true;
        if ('serviceWorker' in navigator && import.meta.env.PROD) {
            void navigator.serviceWorker.ready
                .then((registration) => {
                    if (active && registration.active) controller.setCached(true);
                })
                .catch(() => {
                    if (active) controller.setRegistrationError(true);
                });
        }
        const updateOnline = () => controller.setOnline(navigator.onLine);
        const offerInstall = (event: Event) => {
            event.preventDefault();
            controller.setInstallPrompt(event as InstallPrompt);
        };
        const installed = () => controller.setInstallPrompt(undefined);
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
    }, [controller]);

    return (
        <>
            <div className="connection-status">
                <span className="status-dot" data-ready={ready} />
                <span>{controller.connectionText(ready, controller.online)}</span>
                <button
                    className="text-button install-button"
                    onClick={() => void controller.install()}
                >
                    Install app
                </button>
            </div>
            {controller.help && (
                <aside className="notice">
                    <strong>Add Ultimeter to your Home Screen</strong>
                    <p>
                        On iPhone or iPad, open Safari, tap Share, then Add to Home Screen. On
                        Android, use the browser’s Install app menu.
                    </p>
                    <p>Load the app once online before offline play.</p>
                    <button onClick={() => controller.setHelp(false)}>Got it</button>
                </aside>
            )}
            {controller.registrationError && (
                <p className="notice" role="status">
                    Offline assets could not be prepared. Reopen the app with a network connection.
                </p>
            )}
            {needRefresh && (
                <aside className="notice">
                    <strong>An app update is ready</strong>
                    <p>
                        {controller.updateBlocked
                            ? 'Finish live games and close forms before updating.'
                            : 'Update when you are ready to reload the app.'}
                    </p>
                    <div className="actions">
                        <button
                            className="primary"
                            disabled={controller.updateBlocked}
                            onClick={() => void controller.update(() => updateServiceWorker(true))}
                        >
                            Update
                        </button>
                        <button onClick={() => setNeedRefresh(false)}>Later</button>
                    </div>
                    {controller.updateError && (
                        <p role="alert">The update could not be applied. Try again when online.</p>
                    )}
                </aside>
            )}
        </>
    );
}
