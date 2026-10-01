import type {
    Game,
    Halftime,
    ID,
    Opponent,
    Player,
    PlayEvent,
    Point,
    Session,
    Team,
    Tournament,
} from './index';

export function sortedTeams(session: Session): Team[] {
    return [...session.teams].sort((a, b) => a.name.localeCompare(b.name));
}

export function teamById(session: Session, id: ID): Team | undefined {
    return session.teams.find((team) => team.id === id);
}

export function gameById(session: Session, id: ID): Game | undefined {
    return session.games.find((game) => game.id === id);
}

export function pointById(session: Session, id: ID): Point | undefined {
    return session.points.find((point) => point.id === id);
}

export function pointForGame(session: Session, gameId: ID, pointId: ID): Point | undefined {
    if (!gameById(session, gameId)) return undefined;

    return session.points.find((point) => point.id === pointId && point.gameId === gameId);
}

export function playerById(session: Session, id?: ID): Player | undefined {
    return session.players.find((player) => player.id === id);
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

export function rosterForTeam(session: Session, teamId: ID): Player[] {
    const ids = new Set(teamById(session, teamId)?.playerIds ?? []);

    return session.players
        .filter((player) => ids.has(player.id))
        .sort((a, b) => a.name.localeCompare(b.name));
}

export function pointsForGame(session: Session, gameId: ID): Point[] {
    return session.points
        .filter((point) => point.gameId === gameId)
        .sort((a, b) => a.sequence - b.sequence);
}

export function halftimeForGame(session: Session, gameId: ID): Halftime | undefined {
    return session.halftimes.find((half) => half.gameId === gameId);
}

export function eventsForPoint(session: Session, pointId: ID): PlayEvent[] {
    return session.events
        .filter((event) => event.pointId === pointId)
        .sort((a, b) => a.sequence - b.sequence);
}

export function lineForPoint(session: Session, point: Point): Player[] {
    return point.lineIds.flatMap((id) => {
        const player = playerById(session, id);

        return player ? [player] : [];
    });
}
