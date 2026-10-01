import type { ID } from './types';

export interface Halftime {
    id: ID;
    gameId: ID;
    sequence: number;
    pointNumber: number;
    createdAt: number;
}
