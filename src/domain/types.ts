export type ID = string;
export type Division = 'mixed' | 'open' | 'womens';
export type Gender = 'male' | 'female' | 'nonBinary';
export type Side = 'offense' | 'defense';
export type ScoringTeam = 'us' | 'them';
export type GameStatus = 'scheduled' | 'live' | 'ended';
export type PointStatus = 'scheduled' | 'active' | 'complete';
export type EventKind =
    'pull' | 'pickup' | 'pass' | 'block' | 'drop' | 'turnover' | 'score' | 'sub';
export type TurnoverCause =
    'throwaway' | 'drop' | 'block' | 'interception' | 'incompletion' | 'other';
export type PullOutcome = 'caught' | 'landed' | 'outOfBounds';
export type SubstitutionPhase = 'started' | 'completed';
