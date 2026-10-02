import type { Team } from './Team';
import type { Player } from './Player';
import type { Game, Halftime, Opponent, Tournament } from './Game';
import type { Point } from './Point';
import type { PlayEvent } from './PlayEvent';

export type ID = string;

export interface Session {
    teams: Team[];
    players: Player[];
    opponents: Opponent[];
    tournaments: Tournament[];
    games: Game[];
    points: Point[];
    events: PlayEvent[];
    halftimes: Halftime[];
}

export function emptySession(): Session {
    return {
        teams: [],
        players: [],
        opponents: [],
        tournaments: [],
        games: [],
        points: [],
        events: [],
        halftimes: [],
    };
}
