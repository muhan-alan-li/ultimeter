import type { Team } from './Team';
import type { Player } from './Player';
import type { Opponent } from './Opponent';
import type { Tournament } from './Tournament';
import type { Game } from './Game';
import type { Point } from './Point';
import type { PlayEvent } from './PlayEvent';
import type { Halftime } from './Halftime';

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
