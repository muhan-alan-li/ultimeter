import type { ID, Session } from './Session';

export interface Team {
    id: ID;
    name: string;
    division: 'mixed' | 'open' | 'womens';
    createdAt: number;
    playerIds: ID[];
}

export type Division = Team['division'];

export function sortedTeams(session: Session): Team[] {
    return [...session.teams].sort((a, b) => a.name.localeCompare(b.name));
}

export function teamById(session: Session, id: ID): Team | undefined {
    return session.teams.find((team) => team.id === id);
}
