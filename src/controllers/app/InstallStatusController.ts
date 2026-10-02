import { Controller } from '../Controller';

export interface InstallPrompt extends Event {
    prompt(): Promise<void>;
    userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export class InstallStatusController extends Controller {
    online = navigator.onLine;
    installPrompt?: InstallPrompt;
    help = false;
    registrationError = false;
    updateError = false;
    cached = false;

    setOnline(value: boolean) {
        this.online = value;
        this.changed();
    }

    setInstallPrompt(value?: InstallPrompt) {
        this.installPrompt = value;
        this.changed();
    }

    setHelp(value: boolean) {
        this.help = value;
        this.changed();
    }

    setRegistrationError(value: boolean) {
        this.registrationError = value;
        this.changed();
    }

    setCached(value: boolean) {
        this.cached = value;
        this.changed();
    }

    async install() {
        if (!this.installPrompt) {
            this.setHelp(!this.help);

            return;
        }
        try {
            await this.installPrompt.prompt();
            await this.installPrompt.userChoice;
        } catch {
            this.setHelp(true);
        } finally {
            this.setInstallPrompt(undefined);
        }
    }

    async update(applyUpdate: () => Promise<void>) {
        this.updateError = false;
        this.changed();
        try {
            await applyUpdate();
        } catch {
            this.updateError = true;
            this.changed();
        }
    }

    get updateBlocked() {
        return (
            this.busy ||
            this.deps.dirty ||
            this.session.games.some((game) => game.status === 'live')
        );
    }

    connectionText(ready: boolean, online: boolean) {
        return ready
            ? online
                ? 'Ready for offline play'
                : 'Offline · ready to play'
            : online
              ? 'Local game storage'
              : 'Offline · app cache not confirmed';
    }
}
