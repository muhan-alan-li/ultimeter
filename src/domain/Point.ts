import type { ID, PointStatus, Side } from './types';

export interface Point {
    id: ID;
    gameId: ID;
    sequence: number;
    number: number;
    status: PointStatus;
    startingPosition: Side;
    createdAt: number;
    lineIds: ID[];
}
