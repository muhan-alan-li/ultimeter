import type { ID, Session } from './Session';
import { type Game, gameById } from './Game';
import { type Player, playerById } from './Player';
import { scoringTeamForPoint } from './PlayEvent';

export interface Point {
    id: ID;
    gameId: ID;
    sequence: number;
    number: number;
    status: 'scheduled' | 'active' | 'complete';
    startingPosition: 'offense' | 'defense';
    createdAt: number;
    lineIds: ID[];
}

export type PointStatus = Point['status'];
export type Side = Point['startingPosition'];

export function pointById(session: Session, id: ID): Point | undefined {
    return session.points.find((point) => point.id === id);
}

export function pointForGame(session: Session, gameId: ID, pointId: ID): Point | undefined {
    if (!gameById(session, gameId)) return undefined;

    return session.points.find((point) => point.id === pointId && point.gameId === gameId);
}

export function pointsForGame(session: Session, gameId: ID): Point[] {
    return session.points
        .filter((point) => point.gameId === gameId)
        .sort((a, b) => a.sequence - b.sequence);
}

export function lineForPoint(session: Session, point: Point): Player[] {
    return point.lineIds.flatMap((id) => {
        const player = playerById(session, id);

        return player ? [player] : [];
    });
}

export function sideForPoint(game: Game, number: number, session: Session): Side {
    const half = session.halftimes.find((h) => h.gameId === game.id);
    if (half?.pointNumber === number)
        return game.startingPosition === 'offense' ? 'defense' : 'offense';
    const lastPoint = session.points
        .filter((p) => p.gameId === game.id && p.status === 'complete')
        .sort((a, b) => b.number - a.number)[0];
    if (!lastPoint) return game.startingPosition;
    const result = scoringTeamForPoint(session, lastPoint.id);

    return result === 'us' ? 'defense' : result === 'them' ? 'offense' : game.startingPosition;
}
