import type { Gender, ID } from './types';

export interface Player {
    id: ID;
    name: string;
    gender: Gender;
}
