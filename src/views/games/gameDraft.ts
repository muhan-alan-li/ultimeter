import type { Game, Session, Side } from '../../domain';
import { opponentById, tournamentById } from '../../domain';

export interface GameDraft {
    date: string;
    opponentName: string;
    tournamentName: string;
    targetPoints: number;
    startingPosition: Side;
}

function dateField(timestamp: number): string {
    const date = new Date(timestamp);
    const offset = date.getTimezoneOffset() * 60_000;

    return new Date(timestamp - offset).toISOString().slice(0, 10);
}

export function gameDraft(game?: Game, session?: Session, snapshotDate = Date.now()): GameDraft {
    return {
        date: dateField(game?.date ?? snapshotDate),
        opponentName: game && session ? (opponentById(session, game.opponentId)?.name ?? '') : '',
        tournamentName:
            game?.tournamentId && session
                ? (tournamentById(session, game.tournamentId)?.name ?? '')
                : '',
        targetPoints: game?.targetPoints ?? 15,
        startingPosition: game?.startingPosition ?? 'offense',
    };
}

export function gameDateTimestamp(date: string): number {
    const [year, month, day] = date.split('-').map(Number);

    return new Date(year, month - 1, day).getTime();
}

export function gameDraftIsValid(draft: GameDraft): boolean {
    return (
        draft.opponentName.trim().length > 0 &&
        Number.isInteger(draft.targetPoints) &&
        draft.targetPoints >= 1 &&
        draft.targetPoints <= 21 &&
        !!draft.date
    );
}

export function trimGameNames(
    draft: GameDraft,
): Pick<GameDraft, 'opponentName' | 'tournamentName'> {
    return { opponentName: draft.opponentName.trim(), tournamentName: draft.tournamentName.trim() };
}

export function suggestionsForName(names: string[], query: string): string[] {
    const search = query.trim().toLocaleLowerCase();

    return names
        .filter((name) => !search || name.toLocaleLowerCase().includes(search))
        .sort((a, b) => a.localeCompare(b))
        .slice(0, 5);
}
