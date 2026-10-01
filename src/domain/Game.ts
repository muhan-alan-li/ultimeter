import type { GameStatus, ID, Side } from './types';

export interface Game {
    id: ID;
    teamId: ID;
    opponentId: ID;
    tournamentId?: ID;
    date: number;
    targetPoints: number;
    startingPosition: Side;
    status: GameStatus;
    halftimeTarget?: number;
    nextSequence: number;
}
