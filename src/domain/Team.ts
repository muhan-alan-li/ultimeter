import type { Division, ID } from './types';

export interface Team {
    id: ID;
    name: string;
    division: Division;
    createdAt: number;
    playerIds: ID[];
}
