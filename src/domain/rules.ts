import { gameById } from './Game';
import { teamById } from './Team';
import { AppError } from './AppError';
import type { Game, ID, PlayEvent, Point, ScoringTeam, Session } from './index';

export interface PointState {
    phase: 'none' | 'defense' | 'awaitingPickup' | 'possession';
    holderId?: ID;
    pullerId?: ID;
    hasPull: boolean;
    blockerIds: ID[];
    scorerId?: ID;
    assistId?: ID;
    scoredBy?: ScoringTeam;
    lineLocked: boolean;
    outcome?: string;
}

export function pointState(point: Point, events: PlayEvent[]): PointState {
    const state: PointState = {
        phase:
            point.status === 'active'
                ? point.startingPosition === 'offense'
                    ? 'awaitingPickup'
                    : 'defense'
                : 'none',
        hasPull: false,
        blockerIds: [],
        lineLocked: point.status === 'complete',
    };
    let pickupId: ID | undefined;
    let receiverId: ID | undefined;
    let lastThrowerId: ID | undefined;
    for (const event of events
        .filter((e) => e.pointId === point.id)
        .sort((a, b) => a.sequence - b.sequence)) {
        switch (event.kind) {
            case 'pull':
                state.pullerId ??= event.playerId;
                state.hasPull = true;
                state.lineLocked = true;
                break;
            case 'pickup':
                pickupId = event.playerId;
                receiverId = undefined;
                lastThrowerId = undefined;
                break;
            case 'pass':
                receiverId = event.relatedPlayerId;
                lastThrowerId = event.playerId;
                break;
            case 'block':
                if (event.playerId) state.blockerIds.push(event.playerId);
                break;
            case 'drop':
            case 'turnover':
                pickupId = undefined;
                receiverId = undefined;
                lastThrowerId = undefined;
                break;
            case 'score':
                state.scorerId = event.playerId;
                state.assistId = lastThrowerId;
                state.scoredBy = event.scoringTeam;
                break;
            case 'sub':
                state.lineLocked = event.substitutionPhase === 'completed';
                break;
        }
        if (state.phase === 'defense' && (event.kind === 'block' || event.kind === 'turnover'))
            state.phase = 'awaitingPickup';
        else if (
            (state.phase === 'awaitingPickup' || state.phase === 'possession') &&
            event.kind === 'pickup'
        )
            state.phase = 'possession';
        else if (
            state.phase === 'possession' &&
            (event.kind === 'turnover' || event.kind === 'drop')
        )
            state.phase = 'defense';
    }
    state.holderId = receiverId ?? pickupId;
    state.lineLocked = point.status === 'complete' || state.lineLocked;
    if (point.status === 'complete' && state.scoredBy) {
        state.outcome =
            point.startingPosition === 'offense'
                ? state.scoredBy === 'us'
                    ? 'weHold'
                    : 'theyBreak'
                : state.scoredBy === 'us'
                  ? 'weBreak'
                  : 'theyHold';
    }

    return state;
}

export interface PointAction {
    kind:
        | 'toggleLine'
        | 'pruneLine'
        | 'startPull'
        | 'pull'
        | 'pickup'
        | 'pass'
        | 'drop'
        | 'block'
        | 'ourTurnover'
        | 'theirTurnover'
        | 'sub'
        | 'undo'
        | 'score'
        | 'result';
    playerId?: ID;
    scoringTeam?: ScoringTeam;
}

export function validatePointAction(
    action: PointAction,
    game: Game,
    point: Point,
    session: Session,
): void {
    const fail = (code: string, details: Record<string, string | number> = {}): never => {
        throw new AppError(code, details);
    };
    const need = (
        condition: unknown,
        code: string,
        details?: Record<string, string | number>,
    ): void => {
        if (!condition) fail(code, details);
    };
    need(
        point.gameId === game.id &&
            session.points.some((p) => p.id === point.id && p.gameId === game.id),
        'detachedPoint',
    );
    const state = pointState(point, session.events);
    const team = session.teams.find((t) => t.id === game.teamId);
    const roster = new Set(team?.playerIds ?? []);
    const onLine = (id?: ID): boolean => !!id && point.lineIds.includes(id);
    const complete = point.lineIds.length === 7;
    const activePoints = session.points.filter(
        (p) => p.gameId === game.id && p.status === 'active',
    );
    const requireLive = (): void => need(game.status === 'live', 'notLive');
    const requireActive = (): void => need(point.status === 'active', 'invalidAction');
    const requireLocked = (): void => need(state.lineLocked, 'invalidAction');
    const requireFull = (): void =>
        need(complete, 'lineIncomplete', { current: point.lineIds.length, required: 7 });
    const activeForPlay = (): void => {
        requireLive();
        requireActive();
    };

    switch (action.kind) {
        case 'toggleLine': {
            need(
                point.status === 'scheduled' || (point.status === 'active' && !state.lineLocked),
                'lineLocked',
            );
            if (action.playerId && point.lineIds.includes(action.playerId)) return;
            need(!!action.playerId && roster.has(action.playerId), 'notOnTeam');
            need(point.lineIds.length < 7, 'lineFull', { required: 7 });

            return;
        }
        case 'pruneLine':
            return;
        case 'startPull': {
            requireLive();
            need(point.status === 'scheduled', 'notScheduled');
            need(activePoints.length === 0, 'multipleActivePoints');
            need(
                session.points.filter((p) => p.gameId === game.id && p.status !== 'complete')
                    .length === 1,
                'invalidAction',
            );
            requireFull();
            if (point.startingPosition === 'defense') {
                need(!!state.pullerId, 'missingPull');
                need(onLine(state.pullerId), 'notOnLine');
            }

            return;
        }
        case 'pull': {
            requireLive();
            need(point.status === 'scheduled', 'notScheduled');
            need(point.startingPosition === 'defense', 'invalidAction');
            need(activePoints.length === 0, 'multipleActivePoints');
            need(
                session.points.filter((p) => p.gameId === game.id && p.status !== 'complete')
                    .length === 1,
                'invalidAction',
            );
            requireFull();
            need(onLine(action.playerId), 'notOnLine');

            return;
        }
        case 'block':
            activeForPlay();
            need(state.phase === 'defense', 'invalidAction');
            need(onLine(action.playerId), 'notOnLine');

            return;
        case 'pickup': {
            activeForPlay();
            const allowed =
                state.phase === 'awaitingPickup' ||
                (state.phase === 'possession' && !onLine(state.holderId));
            need(allowed, 'invalidAction');
            need(onLine(action.playerId), 'notOnLine');

            return;
        }
        case 'pass':
        case 'drop':
            activeForPlay();
            requireLocked();
            need(state.phase === 'possession', 'invalidAction');
            need(!!state.holderId, 'missingPickup');
            need(onLine(state.holderId) && onLine(action.playerId), 'notOnLine');
            need(action.playerId !== state.holderId, 'invalidAction');

            return;
        case 'score':
            activeForPlay();
            requireLocked();
            need(activePoints.length === 1, 'multipleActivePoints');
            requireFull();
            need(state.hasPull, 'missingPull');
            need(state.phase === 'possession', 'invalidAction');
            need(!!state.holderId && onLine(state.holderId), 'missingPickup');
            need(onLine(action.playerId), 'notOnLine');
            need(action.playerId !== state.holderId, 'invalidAction');

            return;
        case 'ourTurnover':
            activeForPlay();
            need(state.phase === 'possession', 'invalidAction');
            need(!!state.holderId, 'missingPickup');

            return;
        case 'theirTurnover':
            activeForPlay();
            need(state.phase === 'defense', 'invalidAction');

            return;
        case 'sub':
            requireLive();
            requireActive();

            return;
        case 'undo':
            requireLive();
            requireActive();
            need(
                session.events.some(
                    (e) =>
                        e.pointId === point.id &&
                        ['pickup', 'pass', 'drop', 'block', 'turnover'].includes(e.kind),
                ),
                'invalidAction',
            );

            return;
        case 'result': {
            need(!!action.scoringTeam, 'invalidAction');
            if (point.status === 'complete') {
                need(game.status === 'live' || game.status === 'ended', 'notLive');

                return;
            }
            need(point.status === 'active', 'invalidAction');
            requireLive();
            requireLocked();
            need(activePoints.length === 1, 'multipleActivePoints');
            requireFull();
            need(state.hasPull, 'missingPull');
            if (action.scoringTeam === 'us') {
                need(!!state.holderId, 'missingPickup');
                need(!!state.scorerId, 'missingScorer');
                need(state.scorerId === state.holderId, 'notHolder');
                need(onLine(state.scorerId), 'notOnLine');
            }

            return;
        }
    }
}

export function lineIsEditable(point: Point, session: Session): boolean {
    return (
        point.status === 'scheduled' ||
        (point.status === 'active' && !pointState(point, session.events).lineLocked)
    );
}

export function pointNeedsPrune(point: Point, session: Session): boolean {
    if (point.status === 'complete') return false;
    const game = gameById(session, point.gameId);
    const roster = new Set(game ? (teamById(session, game.teamId)?.playerIds ?? []) : []);

    return point.lineIds.some((id) => !roster.has(id));
}

export function allowsPointAction(
    action: PointAction,
    game: Game,
    point: Point,
    session: Session,
): boolean {
    try {
        validatePointAction(action, game, point, session);

        return true;
    } catch {
        return false;
    }
}
