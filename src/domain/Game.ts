import type { ID, Session } from './Session';
import type { Side } from './Point';
import { scoringTeamForPoint } from './PlayEvent';
import { teamById } from './Team';

export interface Game {
    id: ID;
    teamId: ID;
    opponentId: ID;
    tournamentId?: ID;
    date: number;
    targetPoints: number;
    startingPosition: Side;
    status: 'scheduled' | 'live' | 'ended';
    halftimeTarget?: number;
    nextSequence: number;
}

export type GameStatus = Game['status'];

export interface Opponent {
    id: ID;
    name: string;
}

export interface Tournament {
    id: ID;
    name: string;
}

export interface Halftime {
    id: ID;
    gameId: ID;
    sequence: number;
    pointNumber: number;
    createdAt: number;
}

export function gameById(session: Session, id: ID): Game | undefined {
    return session.games.find((game) => game.id === id);
}

export function opponentById(session: Session, id: ID): Opponent | undefined {
    return session.opponents.find((opponent) => opponent.id === id);
}

export function tournamentById(session: Session, id?: ID): Tournament | undefined {
    return session.tournaments.find((tournament) => tournament.id === id);
}

export function gamesForTeam(session: Session, teamId: ID): Game[] {
    if (!teamById(session, teamId)) return [];

    return session.games.filter((game) => game.teamId === teamId).sort((a, b) => b.date - a.date);
}

export function halftimeForGame(session: Session, gameId: ID): Halftime | undefined {
    return session.halftimes.find((half) => half.gameId === gameId);
}

export function gameScore(gameId: ID, session: Session): { us: number; them: number } {
    const scored = session.points
        .filter((p) => p.gameId === gameId && p.status === 'complete')
        .map((p) => scoringTeamForPoint(session, p.id));

    return {
        us: scored.filter((team) => team === 'us').length,
        them: scored.filter((team) => team === 'them').length,
    };
}

export function halfTarget(game: Game): number {
    return game.halftimeTarget ?? Math.floor((game.targetPoints + 1) / 2);
}

export function canEditGameSetup(game: Game, session?: Session): boolean {
    return (
        game.status === 'scheduled' &&
        (!session || !session.points.some((point) => point.gameId === game.id))
    );
}

export function canStartGame(game: Game, session: Session): boolean {
    return game.status === 'scheduled' && !session.points.some((point) => point.gameId === game.id);
}

export function canEndGame(game: Game): boolean {
    return game.status === 'live';
}

export function gameCapMinimum(gameId: ID, session: Session): number {
    const score = gameScore(gameId, session);

    return Math.max(score.us, score.them) + 1;
}

export function canSetGameCap(game: Game, session: Session): boolean {
    return canEndGame(game) && gameCapMinimum(game.id, session) <= 21;
}

export function validGameCap(game: Game, session: Session, value: number): boolean {
    return Number.isInteger(value) && value >= gameCapMinimum(game.id, session) && value <= 21;
}

export function validFinalScore(gameId: ID, session: Session, us: number, them: number): boolean {
    const score = gameScore(gameId, session);

    return (
        Number.isInteger(us) &&
        Number.isInteger(them) &&
        us >= score.us &&
        them >= score.them &&
        us <= 99 &&
        them <= 99
    );
}
