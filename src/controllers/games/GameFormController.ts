import { Controller } from '../Controller';
import type { Game, Session, Side } from '../../domain';
import { canEditGameSetup, gameById, opponentById, tournamentById } from '../../domain';

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

export class GameFormController extends Controller {
    readonly gameId?: string;
    private readonly initial: GameDraft;
    draft: GameDraft;
    readonly teamId: string;

    constructor(teamId: string, game: Game | undefined, session: Session) {
        super();
        this.teamId = teamId;
        this.gameId = game?.id;
        this.initial = gameDraft(game, session);
        this.draft = { ...this.initial };
    }

    private get game(): Game | undefined {
        return this.gameId ? gameById(this.session, this.gameId) : undefined;
    }

    get dirty(): boolean {
        return (
            this.draft.date !== this.initial.date ||
            this.draft.opponentName.trim() !== this.initial.opponentName ||
            this.draft.tournamentName.trim() !== this.initial.tournamentName ||
            this.draft.targetPoints !== this.initial.targetPoints ||
            this.draft.startingPosition !== this.initial.startingPosition
        );
    }

    get valid(): boolean {
        return gameDraftIsValid(this.draft);
    }

    get scoringSetupLocked(): boolean {
        if (!this.gameId) return false;
        const currentGame = this.game;

        return !currentGame || !canEditGameSetup(currentGame, this.session);
    }

    get opponentSuggestions(): string[] {
        return suggestionsForName(
            this.session.opponents.map((opponent) => opponent.name),
            this.draft.opponentName,
        );
    }

    get tournamentSuggestions(): string[] {
        return suggestionsForName(
            this.session.tournaments.map((tournament) => tournament.name),
            this.draft.tournamentName,
        );
    }

    setDate(value: string) {
        this.draft = { ...this.draft, date: value };
        this.changed();
    }

    setOpponentName(value: string) {
        this.draft = { ...this.draft, opponentName: value };
        this.changed();
    }

    setTournamentName(value: string) {
        this.draft = { ...this.draft, tournamentName: value };
        this.changed();
    }

    setTargetPoints(value: number) {
        this.draft = { ...this.draft, targetPoints: value };
        this.changed();
    }

    setStartingPosition(value: Side) {
        this.draft = { ...this.draft, startingPosition: value };
        this.changed();
    }

    async save(): Promise<boolean> {
        if (!this.valid || (this.gameId && !this.game)) return false;
        const names = trimGameNames(this.draft);

        return !!(await this.deps.run(() =>
            this.deps.repository.saveGame(
                this.teamId,
                {
                    date: gameDateTimestamp(this.draft.date),
                    ...names,
                    targetPoints: this.draft.targetPoints,
                    startingPosition: this.draft.startingPosition,
                },
                this.gameId,
            ),
        ));
    }
}
