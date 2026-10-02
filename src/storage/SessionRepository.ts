import { type GameAction, gameReducer } from '../app/gameReducer';
import { createId } from '../app/createId';
import type { PointAction } from '../app/pointActions';
import { SessionCommands } from '../domain/SessionCommands';
import type { RepositoryPort } from './Repository';
import Dexie, { type Table } from 'dexie';
import { AppError, emptySession, type Game, type ID, type Session } from '../domain';

interface SessionRecord {
    id: 'session';
    value: Session;
}

/** Keep the active session in one IndexedDB record so each action commits atomically. */
class SessionDatabase extends Dexie {
    state!: Table<SessionRecord, string>;

    constructor() {
        super('ulti-stats-session');
        this.version(1).stores({ state: 'id' });
    }
}

const recordId = 'session' as const;

function isSession(value: unknown): value is Session {
    if (typeof value !== 'object' || value === null) return false;
    const data = value as Record<string, unknown>;

    return [
        'teams',
        'players',
        'opponents',
        'tournaments',
        'games',
        'points',
        'events',
        'halftimes',
    ].every(
        (key) =>
            Array.isArray(data[key]) &&
            (data[key] as unknown[]).every(
                (item) =>
                    typeof item === 'object' &&
                    item !== null &&
                    typeof (item as { id?: unknown }).id === 'string',
            ),
    );
}

function storedSession(record: SessionRecord | undefined): Session {
    if (!record) return emptySession();
    if (!isSession(record.value)) {
        throw new AppError('storageCorrupt');
    }

    return record.value;
}

export class SessionRepository implements RepositoryPort {
    private readonly database = new SessionDatabase();
    async read(): Promise<Session> {
        const record = await this.database.transaction('r', this.database.state, () =>
            this.database.state.get(recordId),
        );

        return structuredClone(storedSession(record));
    }

    private async update<T>(change: (commands: SessionCommands) => T): Promise<T> {
        return this.database.transaction('rw', this.database.state, async () => {
            const value = storedSession(await this.database.state.get(recordId));
            const result = change(new SessionCommands(value, { id: createId, now: Date.now }));
            await this.database.state.put({ id: recordId, value });

            return result;
        });
    }

    private async transition(action: GameAction): Promise<void> {
        const transition = { action, idPrefix: createId(), createdAt: Date.now() };
        await this.database.transaction('rw', this.database.state, async () => {
            const previous = storedSession(await this.database.state.get(recordId));
            const value = gameReducer(previous, transition);
            await this.database.state.put({ id: recordId, value });
        });
    }

    async saveTeam(
        draft: { name: string; division: Session['teams'][number]['division'] },
        teamId?: ID,
    ): Promise<ID> {
        return this.update((commands) => commands.saveTeam(draft, teamId));
    }

    async deleteTeam(teamId: ID): Promise<void> {
        return this.update((commands) => commands.deleteTeam(teamId));
    }

    async addPlayers(
        teamId: ID,
        names: string[],
        gender: Session['players'][number]['gender'],
    ): Promise<void> {
        return this.update((commands) => commands.addPlayers(teamId, names, gender));
    }

    async removePlayers(teamId: ID, playerIds: ID[]): Promise<void> {
        return this.update((commands) => commands.removePlayers(teamId, playerIds));
    }

    async saveGame(
        teamId: ID,
        draft: {
            date: number;
            opponentName: string;
            tournamentName?: string;
            targetPoints: number;
            startingPosition: Game['startingPosition'];
        },
        gameId?: ID,
    ): Promise<ID> {
        return this.update((commands) => commands.saveGame(teamId, draft, gameId));
    }

    async deleteGame(gameId: ID): Promise<void> {
        return this.update((commands) => commands.deleteGame(gameId));
    }

    async startGame(gameId: ID): Promise<void> {
        return this.transition({ kind: 'start', gameId });
    }

    async setCap(gameId: ID, cap: number): Promise<void> {
        return this.transition({ kind: 'cap', gameId, cap });
    }

    async endGame(gameId: ID, us: number, them: number): Promise<void> {
        return this.transition({ kind: 'end', gameId, us, them });
    }

    async pointAction(gameId: ID, pointId: ID, action: PointAction): Promise<void> {
        return this.transition({ kind: 'point', gameId, pointId, action });
    }
}
