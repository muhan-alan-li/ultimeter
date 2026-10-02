import { AppError, gameScore, halfTarget, sideForPoint } from '../domain';
import type { Game, ID, PlayEvent, Point, Session } from '../domain';
import { type PointAction, validatePointAction } from './pointActions';
import { pointState } from './pointState';

export type GameAction =
    | { kind: 'start'; gameId: ID }
    | { kind: 'cap'; gameId: ID; cap: number }
    | { kind: 'end'; gameId: ID; us: number; them: number }
    | { kind: 'point'; gameId: ID; pointId: ID; action: PointAction };

export interface GameTransition {
    action: GameAction;
    idPrefix: ID;
    createdAt: number;
}

function fail(code: string, details: Record<string, string | number> = {}): never {
    throw new AppError(code, details);
}

function required<T>(value: T | undefined, label: string): T {
    if (!value) fail('notFound', { field: label });

    return value;
}

/** Reduce a game action without changing the previous session or reading external state. */
export function gameReducer(previous: Session, transition: GameTransition): Session {
    const session = structuredClone(previous);
    let nextId = 0;
    const source = {
        id: () => `${transition.idPrefix}-${nextId++}`,
        now: () => transition.createdAt,
    };
    function nextEventSequence(events: PlayEvent[], pointId: ID): number {
        return events
            .filter((event) => event.pointId === pointId)
            .reduce((next, event) => Math.max(next, event.sequence + 1), 0);
    }

    function appendEvent(
        session: Session,
        point: Point,
        kind: PlayEvent['kind'],
        values: Partial<Omit<PlayEvent, 'id' | 'pointId' | 'sequence' | 'createdAt' | 'kind'>> = {},
    ): PlayEvent {
        const event: PlayEvent = {
            id: source.id(),
            pointId: point.id,
            sequence: nextEventSequence(session.events, point.id),
            createdAt: source.now(),
            kind,
            ...values,
        };
        session.events.push(event);

        return event;
    }

    function createPoint(
        session: Session,
        game: Game,
        number: number,
        status: Point['status'],
    ): Point {
        const point: Point = {
            id: source.id(),
            gameId: game.id,
            sequence: game.nextSequence,
            number,
            status,
            startingPosition: sideForPoint(game, number, session),
            createdAt: source.now(),
            lineIds: [],
        };
        game.nextSequence += 1;
        session.points.push(point);

        return point;
    }

    function sortedPoints(session: Session, gameId: ID): Point[] {
        return session.points
            .filter((point) => point.gameId === gameId)
            .sort((a, b) => a.sequence - b.sequence);
    }

    function removePoint(session: Session, pointId: ID): void {
        session.events = session.events.filter((event) => event.pointId !== pointId);
        session.points = session.points.filter((point) => point.id !== pointId);
    }

    function finishPoint(session: Session, game: Game, point: Point): void {
        point.status = 'complete';
        const score = gameScore(game.id, session);
        if (score.us >= game.targetPoints || score.them >= game.targetPoints) {
            game.status = 'ended';
            for (const open of session.points.filter(
                (p) => p.gameId === game.id && p.status !== 'complete',
            )) {
                removePoint(session, open.id);
            }

            return;
        }

        if (
            !session.halftimes.some((half) => half.gameId === game.id) &&
            (score.us === halfTarget(game) || score.them === halfTarget(game))
        ) {
            session.halftimes.push({
                id: source.id(),
                gameId: game.id,
                sequence: game.nextSequence,
                pointNumber:
                    Math.max(0, ...sortedPoints(session, game.id).map((p) => p.number)) + 1,
                createdAt: source.now(),
            });
            game.nextSequence += 1;
        }
        const nextNumber = Math.max(0, ...sortedPoints(session, game.id).map((p) => p.number)) + 1;
        createPoint(session, game, nextNumber, 'scheduled');
    }

    function eventForPoint(
        session: Session,
        point: Point,
        kind: PlayEvent['kind'],
    ): PlayEvent | undefined {
        return session.events.find((event) => event.pointId === point.id && event.kind === kind);
    }

    function applyPointAction(
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
                        appendEvent(session, point, 'sub', {
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
                        appendEvent(session, point, 'sub', {
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
                        appendEvent(session, point, 'sub', { substitutionPhase: 'started' });
                }
                break;
            }
            case 'startPull':
                if (point.startingPosition !== 'defense') {
                    const pull = eventForPoint(session, point, 'pull');
                    if (pull) pull.playerId = undefined;
                    else appendEvent(session, point, 'pull');
                }
                point.status = 'active';
                break;
            case 'pull':
                {
                    const pull = eventForPoint(session, point, 'pull');
                    if (pull) pull.playerId = action.playerId;
                    else appendEvent(session, point, 'pull', { playerId: action.playerId });
                    point.status = 'active';
                }
                break;
            case 'pickup':
                appendEvent(session, point, 'pickup', { playerId: action.playerId });
                break;
            case 'pass':
                appendEvent(session, point, 'pass', {
                    playerId: state.holderId,
                    relatedPlayerId: action.playerId,
                });
                break;
            case 'drop':
                appendEvent(session, point, 'drop', {
                    playerId: state.holderId,
                    relatedPlayerId: action.playerId,
                });
                break;
            case 'block':
                appendEvent(session, point, 'block', { playerId: action.playerId });
                break;
            case 'ourTurnover':
                appendEvent(session, point, 'turnover');
                break;
            case 'theirTurnover':
                appendEvent(session, point, 'turnover', { turnoverCause: 'throwaway' });
                break;
            case 'sub':
                appendEvent(session, point, 'sub', { substitutionPhase: 'started' });
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
                appendEvent(session, point, 'pass', {
                    playerId: state.holderId,
                    relatedPlayerId: action.playerId,
                    isScoringPass: true,
                });
                appendEvent(session, point, 'score', {
                    playerId: action.playerId,
                    scoringTeam: 'us',
                });
                finishPoint(session, game, point);
                break;
            case 'result': {
                const existing = eventForPoint(session, point, 'score');
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
                        appendEvent(session, point, 'score', {
                            scoringTeam: action.scoringTeam,
                        });
                    finishPoint(session, game, point);
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
                } else appendEvent(session, point, 'score', { scoringTeam: action.scoringTeam });
                const score = gameScore(game.id, session);
                if (
                    !session.halftimes.some((half) => half.gameId === game.id) &&
                    (score.us === halfTarget(game) || score.them === halfTarget(game))
                ) {
                    session.halftimes.push({
                        id: source.id(),
                        gameId: game.id,
                        sequence: game.nextSequence,
                        pointNumber:
                            Math.max(0, ...sortedPoints(session, game.id).map((p) => p.number)) + 1,
                        createdAt: source.now(),
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
                        removePoint(session, open.id);
                } else if (game.status === 'ended' && !reachedTarget) {
                    game.status = 'live';
                    const number =
                        Math.max(0, ...sortedPoints(session, game.id).map((p) => p.number)) + 1;
                    createPoint(session, game, number, 'scheduled');
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

    function startGame(gameId: ID): void {
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
        createPoint(session, game, 1, 'scheduled');
        game.status = 'live';
    }

    function setCap(gameId: ID, cap: number): void {
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

    function endGame(gameId: ID, us: number, them: number): void {
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
            removePoint(session, point.id);
        let number = Math.max(0, ...sortedPoints(session, gameId).map((point) => point.number)) + 1;
        for (let count = current.us; count < us; count += 1) {
            const point = createPoint(session, game, number++, 'complete');
            appendEvent(session, point, 'score', { scoringTeam: 'us' });
        }
        for (let count = current.them; count < them; count += 1) {
            const point = createPoint(session, game, number++, 'complete');
            appendEvent(session, point, 'score', { scoringTeam: 'them' });
        }
        game.status = 'ended';
    }

    function pointAction(gameId: ID, pointId: ID, action: PointAction): void {
        const game = required(
            session.games.find((item) => item.id === gameId),
            'Game',
        );
        const point = required(
            session.points.find((item) => item.id === pointId),
            'Point',
        );
        applyPointAction(session, game, point, action);
    }
    const { action } = transition;
    switch (action.kind) {
        case 'start':
            startGame(action.gameId);
            break;
        case 'cap':
            setCap(action.gameId, action.cap);
            break;
        case 'end':
            endGame(action.gameId, action.us, action.them);
            break;
        case 'point':
            pointAction(action.gameId, action.pointId, action.action);
            break;
    }

    return session;
}
