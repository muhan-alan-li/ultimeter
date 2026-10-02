import { AppError } from './AppError';
import type { Game } from './Game';
import type { ID, Session } from './Session';

export interface CommandSource {
    id(): ID;
    now(): number;
}

const clean = (value: string): string => value.trim();

function fail(code: string, details: Record<string, string | number> = {}): never {
    throw new AppError(code, details);
}

function required<T>(value: T | undefined, label: string): T {
    if (!value) fail('notFound', { field: label });

    return value;
}

/** Apply domain actions to plain session records without persistence or React. */
export class SessionCommands {
    constructor(
        private readonly session: Session,
        private readonly source: CommandSource,
    ) {}

    saveTeam(
        draft: { name: string; division: Session['teams'][number]['division'] },
        teamId?: ID,
    ): ID {
        const session = this.session;
        const name = clean(draft.name);
        if (!name) fail('emptyName', { field: 'Team name' });
        if (teamId && !session.teams.some((team) => team.id === teamId))
            fail('notFound', { field: 'Team' });
        if (
            session.teams.some(
                (team) =>
                    team.id !== teamId &&
                    team.name.toLocaleLowerCase() === name.toLocaleLowerCase(),
            )
        ) {
            fail('duplicateName', { name });
        }
        const team = session.teams.find((item) => item.id === teamId);
        if (team) {
            team.name = name;
            team.division = draft.division;

            return team.id;
        }
        const newTeam = {
            id: this.source.id(),
            name,
            division: draft.division,
            createdAt: this.source.now(),
            playerIds: [],
        };
        session.teams.push(newTeam);

        return newTeam.id;
    }

    deleteTeam(teamId: ID): void {
        const session = this.session;
        session.teams = session.teams.filter((team) => team.id !== teamId);
        const gameIds = new Set(
            session.games.filter((game) => game.teamId === teamId).map((game) => game.id),
        );
        const pointIds = new Set(
            session.points.filter((point) => gameIds.has(point.gameId)).map((point) => point.id),
        );
        session.events = session.events.filter((event) => !pointIds.has(event.pointId));
        session.points = session.points.filter((point) => !pointIds.has(point.id));
        session.halftimes = session.halftimes.filter((half) => !gameIds.has(half.gameId));
        session.games = session.games.filter((game) => !gameIds.has(game.id));
    }

    addPlayers(teamId: ID, names: string[], gender: Session['players'][number]['gender']): void {
        const session = this.session;
        const team = required(
            session.teams.find((item) => item.id === teamId),
            'Team',
        );
        const cleanNames = names.map(clean).filter(Boolean);
        if (!cleanNames.length) fail('emptyName', { field: 'Player name' });
        for (const name of cleanNames) {
            const player = { id: this.source.id(), name, gender };
            session.players.push(player);
            team.playerIds.push(player.id);
        }
    }

    removePlayers(teamId: ID, playerIds: ID[]): void {
        const session = this.session;
        const team = required(
            session.teams.find((item) => item.id === teamId),
            'Team',
        );
        const removedIds = new Set(playerIds);
        team.playerIds = team.playerIds.filter((id) => !removedIds.has(id));
    }

    saveGame(
        teamId: ID,
        draft: {
            date: number;
            opponentName: string;
            tournamentName?: string;
            targetPoints: number;
            startingPosition: Game['startingPosition'];
        },
        gameId?: ID,
    ): ID {
        const session = this.session;
        required(
            session.teams.find((team) => team.id === teamId),
            'Team',
        );
        const opponentName = clean(draft.opponentName);
        const tournamentName = clean(draft.tournamentName ?? '');
        if (!opponentName) fail('emptyName', { field: 'Opponent name' });
        if (!Number.isFinite(draft.date)) fail('invalidDate');
        if (
            !Number.isSafeInteger(draft.targetPoints) ||
            draft.targetPoints < 1 ||
            draft.targetPoints > 21
        )
            fail('invalidTarget', { target: draft.targetPoints });
        let opponent = session.opponents.find(
            (item) => item.name.toLocaleLowerCase() === opponentName.toLocaleLowerCase(),
        );
        if (!opponent) {
            opponent = { id: this.source.id(), name: opponentName };
            session.opponents.push(opponent);
        }
        let tournament = tournamentName
            ? session.tournaments.find(
                  (item) => item.name.toLocaleLowerCase() === tournamentName.toLocaleLowerCase(),
              )
            : undefined;
        if (tournamentName && !tournament) {
            tournament = { id: this.source.id(), name: tournamentName };
            session.tournaments.push(tournament);
        }
        const game = session.games.find((item) => item.id === gameId);
        if (gameId && !game) fail('notFound', { field: 'Game' });
        if (game) {
            if (game.teamId !== teamId) fail('detachedGame');
            const setupChanged =
                game.targetPoints !== draft.targetPoints ||
                game.startingPosition !== draft.startingPosition;
            if (
                setupChanged &&
                (game.status !== 'scheduled' ||
                    session.points.some((point) => point.gameId === game.id))
            ) {
                fail('alreadyStarted');
            }
            game.date = draft.date;
            game.opponentId = opponent.id;
            game.tournamentId = tournament?.id;
            if (setupChanged) {
                game.targetPoints = draft.targetPoints;
                game.startingPosition = draft.startingPosition;
            }

            return game.id;
        }
        const newGame: Game = {
            id: this.source.id(),
            teamId,
            opponentId: opponent.id,
            tournamentId: tournament?.id,
            date: draft.date,
            targetPoints: draft.targetPoints,
            startingPosition: draft.startingPosition,
            status: 'scheduled',
            nextSequence: 0,
        };
        session.games.push(newGame);

        return newGame.id;
    }

    deleteGame(gameId: ID): void {
        const session = this.session;
        const pointIds = new Set(
            session.points.filter((point) => point.gameId === gameId).map((point) => point.id),
        );
        session.events = session.events.filter((event) => !pointIds.has(event.pointId));
        session.points = session.points.filter((point) => point.gameId !== gameId);
        session.halftimes = session.halftimes.filter((half) => half.gameId !== gameId);
        session.games = session.games.filter((game) => game.id !== gameId);
    }
}
