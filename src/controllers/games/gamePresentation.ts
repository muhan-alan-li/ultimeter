import {
    type Game,
    gameScore,
    gamesForTeam,
    opponentById,
    type Session,
    tournamentById,
} from '../../domain';

export interface GameSection {
    id: string;
    title: string;
    games: Game[];
}

export function gameSectionsForTeam(teamId: string, session: Session): GameSection[] {
    const games = gamesForTeam(session, teamId);
    const buckets = new Map<string, Game[]>();
    for (const game of games) {
        const id = game.tournamentId ?? 'standalone';
        buckets.set(id, [...(buckets.get(id) ?? []), game]);
    }

    return [...buckets]
        .map(([id, grouped]) => ({
            id,
            title:
                id === 'standalone'
                    ? 'Standalone'
                    : (session.tournaments.find((tournament) => tournament.id === id)?.name ??
                      'Tournament'),
            games: grouped,
        }))
        .sort((a, b) =>
            a.id === 'standalone' ? 1 : b.id === 'standalone' ? -1 : a.title.localeCompare(b.title),
        );
}

export function gameOpponent(game: Game, session: Session): string {
    return opponentById(session, game.opponentId)?.name ?? 'Opponent';
}

export function gameTournament(game: Game, session: Session): string {
    return game.tournamentId ? (tournamentById(session, game.tournamentId)?.name ?? '') : '';
}

export function gameResult(game: Game, session: Session): { score: string; label: string } {
    if (game.status === 'scheduled') return { score: '', label: 'Scheduled' };
    const score = gameScore(game.id, session);
    const label =
        game.status === 'live'
            ? 'Live'
            : score.us > score.them
              ? 'W'
              : score.us < score.them
                ? 'L'
                : 'T';

    return { score: `${score.us}–${score.them}`, label };
}
