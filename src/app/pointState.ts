import type { ID, PlayEvent, Point, ScoringTeam } from '../domain';

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

export interface PointEventState {
    state: PointState;
    pickupId?: ID;
    receiverId?: ID;
    lastThrowerId?: ID;
}

/** Replay one recorded event without changing the previous point state. */
export function pointEventReducer(previous: PointEventState, event: PlayEvent): PointEventState {
    const next = { ...previous, state: { ...previous.state } };
    const { state } = next;
    switch (event.kind) {
        case 'pull':
            state.pullerId ??= event.playerId;
            state.hasPull = true;
            state.lineLocked = true;
            break;
        case 'pickup':
            next.pickupId = event.playerId;
            next.receiverId = undefined;
            next.lastThrowerId = undefined;
            break;
        case 'pass':
            next.receiverId = event.relatedPlayerId;
            next.lastThrowerId = event.playerId;
            break;
        case 'block':
            if (event.playerId) state.blockerIds = [...state.blockerIds, event.playerId];
            break;
        case 'drop':
        case 'turnover':
            next.pickupId = undefined;
            next.receiverId = undefined;
            next.lastThrowerId = undefined;
            break;
        case 'score':
            state.scorerId = event.playerId;
            state.assistId = next.lastThrowerId;
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
    else if (state.phase === 'possession' && (event.kind === 'turnover' || event.kind === 'drop'))
        state.phase = 'defense';
    state.holderId = next.receiverId ?? next.pickupId;

    return next;
}

/** Rebuild state after a saved action, undo, result edit, or live query update. */
export function pointState(point: Point, events: PlayEvent[]): PointState {
    const initial: PointState = {
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
    const { state } = events
        .filter((event) => event.pointId === point.id)
        .sort((a, b) => a.sequence - b.sequence)
        .reduce(pointEventReducer, { state: initial });
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
