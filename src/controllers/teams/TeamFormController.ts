import { Controller } from '../Controller';
import type { Division, Session, Team } from '../../domain';

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

export class TeamFormController extends Controller {
    readonly teamId?: string;
    private readonly initial: TeamDraft;
    draft: TeamDraft;

    constructor(team?: Team | null) {
        super();
        this.teamId = team?.id;
        this.initial = teamDraft(team?.name, team?.division);
        this.draft = { ...this.initial };
    }

    get duplicateName(): boolean {
        const name = this.draft.name.trim().toLocaleLowerCase();

        return (
            !!name &&
            this.session.teams.some(
                (team) => team.id !== this.teamId && team.name.toLocaleLowerCase() === name,
            )
        );
    }

    get valid(): boolean {
        return teamDraftIsValid(this.draft, this.session, this.teamId);
    }

    get dirty(): boolean {
        return (
            this.draft.name !== this.initial.name || this.draft.division !== this.initial.division
        );
    }

    setName(name: string) {
        this.draft = { ...this.draft, name };
        this.changed();
    }

    setDivision(division: Division) {
        this.draft = { ...this.draft, division };
        this.changed();
    }

    async save(): Promise<boolean> {
        if (!this.valid) return false;
        const result = await this.deps.run(() =>
            this.deps.repository.saveTeam(
                {
                    name: this.draft.name.trim(),
                    division: this.draft.division,
                },
                this.teamId,
            ),
        );

        return !!result;
    }
}
