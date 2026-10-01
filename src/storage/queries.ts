import { liveQuery } from 'dexie';
import type { Session } from '../domain';
import type { RepositoryPort } from './Repository';

export interface SessionQuery {
    subscribe(onValue: (session: Session) => void, onError: (error: unknown) => void): () => void;
}

/** Share the storage observation boundary across app views. */
export function sessionQuery(repository: RepositoryPort): SessionQuery {
    return {
        subscribe(onValue, onError) {
            const subscription = liveQuery(() => repository.read()).subscribe({
                next: onValue,
                error: onError,
            });

            return () => subscription.unsubscribe();
        },
    };
}
