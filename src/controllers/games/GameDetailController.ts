import {
    canEndGame,
    canSetGameCap,
    canStartGame,
    type Game,
    gameById,
    gameCapMinimum,
    gameScore,
    halftimeForGame,
    opponentById,
    pointsForGame,
    pointState,
    teamById,
    tournamentById,
    validFinalScore,
    validGameCap,
} from '../../domain';
import { Controller } from '../Controller';

const outcomes: Record<string, string> = {
    weHold: 'We hold',
    weBreak: 'We break',
    theyHold: 'They hold',
    theyBreak: 'They break',
};

export class GameDetailController extends Controller {
    expanded = false;
    dialog: 'cap' | 'end' | 'edit' | undefined;
    toggleExpanded() {
        this.expanded = !this.expanded;
        this.changed();
    }

    openDialog(dialog: 'cap' | 'end' | 'edit') {
        if (dialog === 'cap') this.prepareCap();
        if (dialog === 'end') this.prepareEnd();
        this.dialog = dialog;
        this.changed();
    }

    closeDialog() {
        this.dialog = undefined;
        this.changed();
    }

    cap = 15;
    endUs = 0;
    endThem = 0;
    private initialCap = 15;
    private initialEndUs = 0;
    private initialEndThem = 0;
    constructor(readonly gameId: string) {
        super();
    }

    get exists() {
        return !!gameById(this.session, this.gameId);
    }

    get game(): Game {
        const game = gameById(this.session, this.gameId);
        if (!game) throw new Error('Game not found.');

        return game;
    }

    get teamName() {
        const game = gameById(this.session, this.gameId);

        return game ? (teamById(this.session, game.teamId)?.name ?? 'Our team') : 'Our team';
    }

    get opponentName() {
        const game = gameById(this.session, this.gameId);

        return game
            ? (opponentById(this.session, game.opponentId)?.name ?? 'Opponent')
            : 'Opponent';
    }

    get title() {
        return `${this.teamName} vs ${this.opponentName}`;
    }

    get score() {
        return gameScore(this.game.id, this.session);
    }

    get scoreText() {
        return `${this.score.us} – ${this.score.them}`;
    }

    get points() {
        return pointsForGame(this.session, this.gameId);
    }

    get canStart() {
        return canStartGame(this.game, this.session);
    }

    get canEnd() {
        return canEndGame(this.game);
    }

    get capMinimum() {
        return gameCapMinimum(this.gameId, this.session);
    }

    get canSetCap() {
        return canSetGameCap(this.game, this.session);
    }

    get capDirty() {
        return this.cap !== this.initialCap;
    }

    get endDirty() {
        return this.endUs !== this.initialEndUs || this.endThem !== this.initialEndThem;
    }

    get half() {
        return halftimeForGame(this.session, this.gameId);
    }

    get tournamentName() {
        const game = gameById(this.session, this.gameId);

        return tournamentById(this.session, game?.tournamentId)?.name ?? 'Standalone';
    }

    get statusText() {
        return this.game.status === 'ended'
            ? 'Game over'
            : this.game.status === 'live'
              ? 'Live game'
              : 'Scheduled';
    }

    get dateText() {
        return new Date(this.game.date).toLocaleDateString(undefined, {
            month: 'long',
            day: 'numeric',
            year: 'numeric',
        });
    }

    validCap(value: number) {
        return validGameCap(this.game, this.session, value);
    }

    validFinalScore(us: number, them: number) {
        return validFinalScore(this.gameId, this.session, us, them);
    }

    prepareCap() {
        this.cap = this.initialCap = Math.min(
            21,
            Math.max(this.game.targetPoints, this.capMinimum),
        );
        this.changed();
    }

    prepareEnd() {
        this.endUs = this.initialEndUs = this.score.us;
        this.endThem = this.initialEndThem = this.score.them;
        this.changed();
    }

    setCap(value: number) {
        this.cap = value;
        this.changed();
    }

    setEndUs(value: number) {
        this.endUs = value;
        this.changed();
    }

    setEndThem(value: number) {
        this.endThem = value;
        this.changed();
    }

    async start() {
        if (this.canStart) await this.deps.run(() => this.deps.repository.startGame(this.gameId));
    }

    async saveCap() {
        if (!this.validCap(this.cap)) return false;

        return !!(await this.deps.run(async () => {
            await this.deps.repository.setCap(this.gameId, this.cap);

            return true;
        }));
    }

    async end() {
        if (!this.validFinalScore(this.endUs, this.endThem)) return false;

        return !!(await this.deps.run(async () => {
            await this.deps.repository.endGame(this.gameId, this.endUs, this.endThem);

            return true;
        }));
    }

    entries() {
        let us = 0;
        let them = 0;
        const rows = this.points.map((point) => {
            const state = pointState(point, this.session.events);
            if (point.status === 'complete') {
                if (state.scoredBy === 'us') us++;
                if (state.scoredBy === 'them') them++;
            }

            return {
                point,
                scoreText: `${us} – ${them}`,
                result: state.outcome
                    ? outcomes[state.outcome]
                    : point.status === 'active'
                      ? 'Live'
                      : 'Scheduled',
                tone: state.scoredBy === 'us' ? 'good' : state.scoredBy === 'them' ? 'bad' : '',
                side: point.startingPosition === 'offense' ? 'O' : 'D',
            };
        });
        const shown = this.expanded ? rows : rows.slice(-3);

        return shown.map((row, index) => ({
            ...row,
            showHalf:
                !!this.half &&
                row.point.number >= this.half.pointNumber &&
                index > 0 &&
                shown[index - 1].point.number < this.half.pointNumber,
        }));
    }
}
