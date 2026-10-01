import type {
    EventKind,
    ID,
    PullOutcome,
    ScoringTeam,
    SubstitutionPhase,
    TurnoverCause,
} from './types';

export interface PlayEvent {
    id: ID;
    pointId: ID;
    sequence: number;
    createdAt: number;
    kind: EventKind;
    playerId?: ID;
    relatedPlayerId?: ID;
    scoringTeam?: ScoringTeam;
    turnoverCause?: TurnoverCause;
    pullOutcome?: PullOutcome;
    isScoringPass?: boolean;
    substitutionPhase?: SubstitutionPhase;
}
