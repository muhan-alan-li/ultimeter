import type { ID, Session } from './Session';

export interface PlayEvent {
    id: ID;
    pointId: ID;
    sequence: number;
    createdAt: number;
    kind: 'pull' | 'pickup' | 'pass' | 'block' | 'drop' | 'turnover' | 'score' | 'sub';
    playerId?: ID;
    relatedPlayerId?: ID;
    scoringTeam?: 'us' | 'them';
    turnoverCause?: 'throwaway' | 'drop' | 'block' | 'interception' | 'incompletion' | 'other';
    pullOutcome?: 'caught' | 'landed' | 'outOfBounds';
    isScoringPass?: boolean;
    substitutionPhase?: 'started' | 'completed';
}

export type EventKind = PlayEvent['kind'];
export type ScoringTeam = NonNullable<PlayEvent['scoringTeam']>;
export type TurnoverCause = NonNullable<PlayEvent['turnoverCause']>;
export type PullOutcome = NonNullable<PlayEvent['pullOutcome']>;
export type SubstitutionPhase = NonNullable<PlayEvent['substitutionPhase']>;

export function eventsForPoint(session: Session, pointId: ID): PlayEvent[] {
    return session.events
        .filter((event) => event.pointId === pointId)
        .sort((a, b) => a.sequence - b.sequence);
}

export function scoringTeamForPoint(session: Session, pointId: ID): ScoringTeam | undefined {
    return eventsForPoint(session, pointId).reduce<ScoringTeam | undefined>(
        (team, event) => (event.kind === 'score' ? event.scoringTeam : team),
        undefined,
    );
}
