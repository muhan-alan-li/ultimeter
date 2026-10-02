import type { Division, Session } from '../../domain';

export interface TeamDraft {
    name: string;
    division: Division;
}

export function teamDraft(name = '', division: Division = 'open'): TeamDraft {
    return { name, division };
}

export function teamDraftIsValid(draft: TeamDraft, session: Session, teamId?: string): boolean {
    const value = draft.name.trim();

    return (
        value.length > 0 &&
        !session.teams.some(
            (team) =>
                team.id !== teamId && team.name.toLocaleLowerCase() === value.toLocaleLowerCase(),
        )
    );
}
