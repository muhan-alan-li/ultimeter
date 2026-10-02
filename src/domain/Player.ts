import type { ID, Session } from './Session';
import { teamById } from './Team';

export interface Player {
    id: ID;
    name: string;
    gender: 'male' | 'female' | 'nonBinary';
}

export type Gender = Player['gender'];

export function playerById(session: Session, id?: ID): Player | undefined {
    return session.players.find((player) => player.id === id);
}

export function rosterForTeam(session: Session, teamId: ID): Player[] {
    const ids = new Set(teamById(session, teamId)?.playerIds ?? []);

    return session.players
        .filter((player) => ids.has(player.id))
        .sort((a, b) => a.name.localeCompare(b.name));
}
