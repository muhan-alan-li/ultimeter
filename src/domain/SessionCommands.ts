import { AppError } from './AppError';
import type { Game, ID, PlayEvent, Point, Session } from './index';
import {
    gameScore,
    halfTarget,
    type PointAction,
    pointState,
    sideForPoint,
    validatePointAction,
} from './rules';

export interface CommandSource {
    id(): ID;
    now(): number;
}

const defaultSource: CommandSource = {
    id: () => crypto.randomUUID(),
    now: () => Date.now(),
};
const clean = (value: string): string => value.trim();

function fail(code: string, details: Record<string, string | number> = {}): never {
    throw new AppError(code, details);
}

function required<T>(value: T | undefined, label: string): T {
    if (!value) fail('notFound', { field: label });

    return value;
}

/** Apply domain actions to plain session records without persistence or React. */
export class SessionCommands {
    constructor(
        private readonly session: Session,
        private readonly source: CommandSource = defaultSource,
    ) {}

    private nextEventSequence(events: PlayEvent[], pointId: ID): number {
        return events
            .filter((event) => event.pointId === pointId)
            .reduce((next, event) => Math.max(next, event.sequence + 1), 0);
    }

    private appendEvent(
        session: Session,
        point: Point,
        kind: PlayEvent['kind'],
        values: Partial<Omit<PlayEvent, 'id' | 'pointId' | 'sequence' | 'createdAt' | 'kind'>> = {},
    ): PlayEvent {
        const event: PlayEvent = {
            id: this.source.id(),
            pointId: point.id,
            sequence: this.nextEventSequence(session.events, point.id),
            createdAt: this.source.now(),
            kind,
            ...values,
        };
        session.events.push(event);

        return event;
    }

    private createPoint(
        session: Session,
        game: Game,
        number: number,
        status: Point['status'],
    ): Point {
        const point: Point = {
            id: this.source.id(),
            gameId: game.id,
            sequence: game.nextSequence,
            number,
            status,
            startingPosition: sideForPoint(game, number, session),
            createdAt: this.source.now(),
            lineIds: [],
        };
        game.nextSequence += 1;
        session.points.push(point);

        return point;
    }

    private sortedPoints(session: Session, gameId: ID): Point[] {
        return session.points
            .filter((point) => point.gameId === gameId)
            .sort((a, b) => a.sequence - b.sequence);
    }

    private removePoint(session: Session, pointId: ID): void {
        session.events = session.events.filter((event) => event.pointId !== pointId);
        session.points = session.points.filter((point) => point.id !== pointId);
    }

    private finishPoint(session: Session, game: Game, point: Point): void {
        point.status = 'complete';
        const score = gameScore(game.id, session);
        if (score.us >= game.targetPoints || score.them >= game.targetPoints) {
            game.status = 'ended';
            for (const open of session.points.filter(
                (p) => p.gameId === game.id && p.status !== 'complete',
            )) {
                this.removePoint(session, open.id);
            }

            return;
        }

        if (
            !session.halftimes.some((half) => half.gameId === game.id) &&
            (score.us === halfTarget(game) || score.them === halfTarget(game))
        ) {
            session.halftimes.push({
                id: this.source.id(),
                gameId: game.id,
                sequence: game.nextSequence,
                pointNumber:
                    Math.max(0, ...this.sortedPoints(session, game.id).map((p) => p.number)) + 1,
                createdAt: this.source.now(),
            });
            game.nextSequence += 1;
        }
        const nextNumber =
            Math.max(0, ...this.sortedPoints(session, game.id).map((p) => p.number)) + 1;
        this.createPoint(session, game, nextNumber, 'scheduled');
    }

    private eventForPoint(
        session: Session,
        point: Point,
        kind: PlayEvent['kind'],
    ): PlayEvent | undefined {
        return session.events.find((event) => event.pointId === point.id && event.kind === kind);
    }

    private applyPointAction(
        session: Session,
        game: Game,
        point: Point,
        action: PointAction,
    ): void {
        validatePointAction(action, game, point, session);
        const state = pointState(point, session.events);
        switch (action.kind) {
            case 'toggleLine': {
                const playerId = required(action.playerId, 'Player');
                const index = point.lineIds.indexOf(playerId);
                if (index >= 0) {
                    point.lineIds.splice(index, 1);
                    if (
                        point.status === 'active' &&
                        pointState(point, session.events).lineLocked === false &&
                        point.lineIds.length === 7
                    ) {
                        this.appendEvent(session, point, 'sub', {
                            substitutionPhase: 'completed',
                        });
                    }
                } else {
                    point.lineIds.push(playerId);
                    if (
                        point.status === 'active' &&
                        state.holderId &&
                        state.holderId !== playerId &&
                        !point.lineIds.includes(state.holderId)
                    ) {
                        let defining: PlayEvent | undefined;
                        let isPass = false;
                        for (const event of session.events
                            .filter((e) => e.pointId === point.id)
                            .sort((a, b) => a.sequence - b.sequence)) {
                            if (event.kind === 'turnover' || event.kind === 'drop') {
                                defining = undefined;
                                isPass = false;
                            } else if (event.kind === 'pickup') {
                                defining = event;
                                isPass = false;
                            } else if (event.kind === 'pass') {
                                defining = event;
                                isPass = true;
                            }
                        }
                        if (defining) {
                            if (isPass) defining.relatedPlayerId = playerId;
                            else defining.playerId = playerId;
                        }
                    }
                    if (
                        point.status === 'active' &&
                        !state.lineLocked &&
                        point.lineIds.length === 7
                    ) {
                        this.appendEvent(session, point, 'sub', {
                            substitutionPhase: 'completed',
                        });
                    }
                }
                break;
            }
            case 'pruneLine': {
                const wasLocked = point.status === 'active' && state.lineLocked;
                const isEditable =
                    point.status === 'scheduled' ||
                    (point.status === 'active' && !state.lineLocked);
                if (!wasLocked && !isEditable) break;
                const team = session.teams.find((item) => item.id === game.teamId);
                const roster = new Set(team?.playerIds ?? []);
                const line = point.lineIds.filter((playerId) => roster.has(playerId));
                if (line.length !== point.lineIds.length) {
                    point.lineIds = line;
                    if (wasLocked)
                        this.appendEvent(session, point, 'sub', { substitutionPhase: 'started' });
                }
                break;
            }
            case 'startPull':
                if (point.startingPosition !== 'defense') {
                    const pull = this.eventForPoint(session, point, 'pull');
                    if (pull) pull.playerId = undefined;
                    else this.appendEvent(session, point, 'pull');
                }
                point.status = 'active';
                break;
            case 'pull':
                {
                    const pull = this.eventForPoint(session, point, 'pull');
                    if (pull) pull.playerId = action.playerId;
                    else this.appendEvent(session, point, 'pull', { playerId: action.playerId });
                    point.status = 'active';
                }
                break;
            case 'pickup':
                this.appendEvent(session, point, 'pickup', { playerId: action.playerId });
                break;
            case 'pass':
                this.appendEvent(session, point, 'pass', {
                    playerId: state.holderId,
                    relatedPlayerId: action.playerId,
                });
                break;
            case 'drop':
                this.appendEvent(session, point, 'drop', {
                    playerId: state.holderId,
                    relatedPlayerId: action.playerId,
                });
                break;
            case 'block':
                this.appendEvent(session, point, 'block', { playerId: action.playerId });
                break;
            case 'ourTurnover':
                this.appendEvent(session, point, 'turnover');
                break;
            case 'theirTurnover':
                this.appendEvent(session, point, 'turnover', { turnoverCause: 'throwaway' });
                break;
            case 'sub':
                this.appendEvent(session, point, 'sub', { substitutionPhase: 'started' });
                break;
            case 'undo': {
                const undoable = new Set(['pickup', 'pass', 'drop', 'block', 'turnover']);
                const event = session.events
                    .filter((item) => item.pointId === point.id && undoable.has(item.kind))
                    .sort((a, b) => b.sequence - a.sequence)[0];
                if (event) session.events = session.events.filter((item) => item.id !== event.id);
                break;
            }
            case 'score':
                this.appendEvent(session, point, 'pass', {
                    playerId: state.holderId,
                    relatedPlayerId: action.playerId,
                    isScoringPass: true,
                });
                this.appendEvent(session, point, 'score', {
                    playerId: action.playerId,
                    scoringTeam: 'us',
                });
                this.finishPoint(session, game, point);
                break;
            case 'result': {
                const existing = this.eventForPoint(session, point, 'score');
                if (point.status === 'active') {
                    if (existing) {
                        existing.scoringTeam = action.scoringTeam;
                        if (action.scoringTeam === 'them') {
                            existing.playerId = undefined;
                            session.events = session.events.filter(
                                (event) => !(event.pointId === point.id && event.isScoringPass),
                            );
                        }
                    } else
                        this.appendEvent(session, point, 'score', {
                            scoringTeam: action.scoringTeam,
                        });
                    this.finishPoint(session, game, point);
                    break;
                }
                if (existing?.scoringTeam === action.scoringTeam) break;
                if (existing) {
                    existing.scoringTeam = action.scoringTeam;
                    if (action.scoringTeam === 'them') {
                        existing.playerId = undefined;
                        session.events = session.events.filter(
                            (event) => !(event.pointId === point.id && event.isScoringPass),
                        );
                    }
                } else
                    this.appendEvent(session, point, 'score', { scoringTeam: action.scoringTeam });
                const score = gameScore(game.id, session);
                if (
                    !session.halftimes.some((half) => half.gameId === game.id) &&
                    (score.us === halfTarget(game) || score.them === halfTarget(game))
                ) {
                    session.halftimes.push({
                        id: this.source.id(),
                        gameId: game.id,
                        sequence: game.nextSequence,
                        pointNumber:
                            Math.max(
                                0,
                                ...this.sortedPoints(session, game.id).map((p) => p.number),
                            ) + 1,
                        createdAt: this.source.now(),
                    });
                    game.nextSequence += 1;
                }
                const reachedTarget =
                    score.us >= game.targetPoints || score.them >= game.targetPoints;
                if (game.status === 'live' && reachedTarget) {
                    game.status = 'ended';
                    for (const open of session.points.filter(
                        (p) => p.gameId === game.id && p.status !== 'complete',
                    ))
                        this.removePoint(session, open.id);
                } else if (game.status === 'ended' && !reachedTarget) {
                    game.status = 'live';
                    const number =
                        Math.max(0, ...this.sortedPoints(session, game.id).map((p) => p.number)) +
                        1;
                    this.createPoint(session, game, number, 'scheduled');
                }
                const openPoint = session.points.find(
                    (p) => p.gameId === game.id && p.status !== 'complete',
                );
                if (openPoint)
                    openPoint.startingPosition = sideForPoint(game, openPoint.number, session);
                break;
            }
        }
    }

    saveTeam(
        draft: { name: string; division: Session['teams'][number]['division'] },
        teamId?: ID,
    ): ID {
        const session = this.session;
        const name = clean(draft.name);
        if (!name) fail('emptyName', { field: 'Team name' });
        if (teamId && !session.teams.some((team) => team.id === teamId))
            fail('notFound', { field: 'Team' });
        if (
            session.teams.some(
                (team) =>
                    team.id !== teamId &&
                    team.name.toLocaleLowerCase() === name.toLocaleLowerCase(),
            )
        ) {
            fail('duplicateName', { name });
        }
        const team = session.teams.find((item) => item.id === teamId);
        if (team) {
            team.name = name;
            team.division = draft.division;

            return team.id;
        }
        const newTeam = {
            id: this.source.id(),
            name,
            division: draft.division,
            createdAt: this.source.now(),
            playerIds: [],
        };
        session.teams.push(newTeam);

        return newTeam.id;
    }

    deleteTeam(teamId: ID): void {
        const session = this.session;
        session.teams = session.teams.filter((team) => team.id !== teamId);
        const gameIds = new Set(
            session.games.filter((game) => game.teamId === teamId).map((game) => game.id),
        );
        const pointIds = new Set(
            session.points.filter((point) => gameIds.has(point.gameId)).map((point) => point.id),
        );
        session.events = session.events.filter((event) => !pointIds.has(event.pointId));
        session.points = session.points.filter((point) => !pointIds.has(point.id));
        session.halftimes = session.halftimes.filter((half) => !gameIds.has(half.gameId));
        session.games = session.games.filter((game) => !gameIds.has(game.id));
    }

    addPlayers(teamId: ID, names: string[], gender: Session['players'][number]['gender']): void {
        const session = this.session;
        const team = required(
            session.teams.find((item) => item.id === teamId),
            'Team',
        );
        const cleanNames = names.map(clean).filter(Boolean);
        if (!cleanNames.length) fail('emptyName', { field: 'Player name' });
        for (const name of cleanNames) {
            const player = { id: this.source.id(), name, gender };
            session.players.push(player);
            team.playerIds.push(player.id);
        }
    }

    removePlayers(teamId: ID, playerIds: ID[]): void {
        const session = this.session;
        const team = required(
            session.teams.find((item) => item.id === teamId),
            'Team',
        );
        const removedIds = new Set(playerIds);
        team.playerIds = team.playerIds.filter((id) => !removedIds.has(id));
    }

    saveGame(
        teamId: ID,
        draft: {
            date: number;
            opponentName: string;
            tournamentName?: string;
            targetPoints: number;
            startingPosition: Game['startingPosition'];
        },
        gameId?: ID,
    ): ID {
        const session = this.session;
        required(
            session.teams.find((team) => team.id === teamId),
            'Team',
        );
        const opponentName = clean(draft.opponentName);
        const tournamentName = clean(draft.tournamentName ?? '');
        if (!opponentName) fail('emptyName', { field: 'Opponent name' });
        if (!Number.isFinite(draft.date)) fail('invalidDate');
        if (
            !Number.isSafeInteger(draft.targetPoints) ||
            draft.targetPoints < 1 ||
            draft.targetPoints > 21
        )
            fail('invalidTarget', { target: draft.targetPoints });
        let opponent = session.opponents.find(
            (item) => item.name.toLocaleLowerCase() === opponentName.toLocaleLowerCase(),
        );
        if (!opponent) {
            opponent = { id: this.source.id(), name: opponentName };
            session.opponents.push(opponent);
        }
        let tournament = tournamentName
            ? session.tournaments.find(
                  (item) => item.name.toLocaleLowerCase() === tournamentName.toLocaleLowerCase(),
              )
            : undefined;
        if (tournamentName && !tournament) {
            tournament = { id: this.source.id(), name: tournamentName };
            session.tournaments.push(tournament);
        }
        const game = session.games.find((item) => item.id === gameId);
        if (gameId && !game) fail('notFound', { field: 'Game' });
        if (game) {
            if (game.teamId !== teamId) fail('detachedGame');
            const setupChanged =
                game.targetPoints !== draft.targetPoints ||
                game.startingPosition !== draft.startingPosition;
            if (
                setupChanged &&
                (game.status !== 'scheduled' ||
                    session.points.some((point) => point.gameId === game.id))
            ) {
                fail('alreadyStarted');
            }
            game.date = draft.date;
            game.opponentId = opponent.id;
            game.tournamentId = tournament?.id;
            if (setupChanged) {
                game.targetPoints = draft.targetPoints;
                game.startingPosition = draft.startingPosition;
            }

            return game.id;
        }
        const newGame: Game = {
            id: this.source.id(),
            teamId,
            opponentId: opponent.id,
            tournamentId: tournament?.id,
            date: draft.date,
            targetPoints: draft.targetPoints,
            startingPosition: draft.startingPosition,
            status: 'scheduled',
            nextSequence: 0,
        };
        session.games.push(newGame);

        return newGame.id;
    }

    deleteGame(gameId: ID): void {
        const session = this.session;
        const pointIds = new Set(
            session.points.filter((point) => point.gameId === gameId).map((point) => point.id),
        );
        session.events = session.events.filter((event) => !pointIds.has(event.pointId));
        session.points = session.points.filter((point) => point.gameId !== gameId);
        session.halftimes = session.halftimes.filter((half) => half.gameId !== gameId);
        session.games = session.games.filter((game) => game.id !== gameId);
    }

    startGame(gameId: ID): void {
        const session = this.session;
        const game = required(
            session.games.find((item) => item.id === gameId),
            'Game',
        );
        if (game.status !== 'scheduled') fail('notScheduled');
        if (session.points.some((point) => point.gameId === gameId)) fail('alreadyStarted');
        if (
            !Number.isSafeInteger(game.targetPoints) ||
            game.targetPoints < 1 ||
            game.targetPoints > 21
        )
            fail('invalidTarget', { target: game.targetPoints });
        game.halftimeTarget = halfTarget(game);
        this.createPoint(session, game, 1, 'scheduled');
        game.status = 'live';
    }

    setCap(gameId: ID, cap: number): void {
        const session = this.session;
        const game = required(
            session.games.find((item) => item.id === gameId),
            'Game',
        );
        if (game.status !== 'live') fail('notLive');
        const score = gameScore(gameId, session);
        if (!Number.isSafeInteger(cap) || cap < Math.max(score.us, score.them) + 1 || cap > 21)
            fail('invalidTarget', { target: cap });
        game.targetPoints = cap;
    }

    endGame(gameId: ID, us: number, them: number): void {
        const session = this.session;
        const game = required(
            session.games.find((item) => item.id === gameId),
            'Game',
        );
        if (game.status !== 'live') fail('notLive');
        const current = gameScore(gameId, session);
        if (
            !Number.isSafeInteger(us) ||
            !Number.isSafeInteger(them) ||
            us < 0 ||
            them < 0 ||
            us > 99 ||
            them > 99
        )
            fail('invalidScore');
        if (us < current.us || them < current.them) fail('finalScoreBelowCurrent');
        for (const point of session.points.filter(
            (item) => item.gameId === gameId && item.status !== 'complete',
        ))
            this.removePoint(session, point.id);
        let number =
            Math.max(0, ...this.sortedPoints(session, gameId).map((point) => point.number)) + 1;
        for (let count = current.us; count < us; count += 1) {
            const point = this.createPoint(session, game, number++, 'complete');
            this.appendEvent(session, point, 'score', { scoringTeam: 'us' });
        }
        for (let count = current.them; count < them; count += 1) {
            const point = this.createPoint(session, game, number++, 'complete');
            this.appendEvent(session, point, 'score', { scoringTeam: 'them' });
        }
        game.status = 'ended';
    }

    pointAction(gameId: ID, pointId: ID, action: PointAction): void {
        const session = this.session;
        const game = required(
            session.games.find((item) => item.id === gameId),
            'Game',
        );
        const point = required(
            session.points.find((item) => item.id === pointId),
            'Point',
        );
        this.applyPointAction(session, game, point, action);
    }
}
