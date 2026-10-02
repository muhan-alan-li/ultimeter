import type { Session } from '../domain';
import type { SessionQuery } from '../storage/queries';
import type { RepositoryPort } from '../storage/Repository';
import { errorMessage } from './errorMessages';
import { Observable } from './Observable';

/** Own the active session, action lock, and shared errors. */
export class Application extends Observable {
    private current?: Session;
    private dirtyTokens = new Set<symbol>();
    busy = false;
    error?: string;
    loadError?: string;

    constructor(
        readonly repository: RepositoryPort,
        private readonly query: SessionQuery,
    ) {
        super();
    }

    get ready() {
        return this.current !== undefined;
    }

    get session(): Session {
        if (!this.current) throw new Error('Open the local session before use.');

        return this.current;
    }

    get dirty() {
        return this.dirtyTokens.size > 0;
    }

    observe() {
        return this.query.subscribe(
            (session) => {
                this.current = session;
                this.loadError = undefined;
                this.changed();
            },
            (failure) => {
                this.loadError = errorMessage(failure);
                this.changed();
            },
        );
    }

    setDirty = (token: symbol, dirty: boolean) => {
        const wasDirty = this.dirty;
        if (dirty) this.dirtyTokens.add(token);
        else this.dirtyTokens.delete(token);
        if (this.dirty !== wasDirty) this.changed();
    };

    dismissError() {
        this.error = undefined;
        this.changed();
    }

    run = async <T>(action: () => Promise<T>): Promise<T | undefined> => {
        if (this.busy) return undefined;
        this.busy = true;
        this.changed();
        try {
            const result = await action();
            try {
                this.current = await this.repository.read();
            } catch (failure) {
                this.loadError = `The action saved, but local data could not be read. ${errorMessage(failure)}`;
            }

            return result;
        } catch (failure) {
            this.error = errorMessage(failure);

            return undefined;
        } finally {
            this.busy = false;
            this.changed();
        }
    };
}
