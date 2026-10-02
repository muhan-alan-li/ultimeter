import type { PointAction } from '../app/pointActions';
import type { Division, Game, Gender, Session } from '../domain';

export interface RepositoryPort {
    read(): Promise<Session>;
    saveTeam(draft: { name: string; division: Division }, id?: string): Promise<string>;
    deleteTeam(id: string): Promise<void>;
    addPlayers(teamId: string, names: string[], gender: Gender): Promise<void>;
    removePlayers(teamId: string, playerIds: string[]): Promise<void>;
    saveGame(
        teamId: string,
        draft: {
            date: number;
            opponentName: string;
            tournamentName?: string;
            targetPoints: number;
            startingPosition: Game['startingPosition'];
        },
        id?: string,
    ): Promise<string>;
    deleteGame(id: string): Promise<void>;
    startGame(id: string): Promise<void>;
    setCap(id: string, cap: number): Promise<void>;
    endGame(id: string, us: number, them: number): Promise<void>;
    pointAction(gameId: string, pointId: string, action: PointAction): Promise<void>;
}
