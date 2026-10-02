import { Controller } from '../Controller';
import { sortedTeams, type Team } from '../../domain';

export function divisionLabel(division: Team['division']): string {
    switch (division) {
        case 'open':
            return 'Open';
        case 'womens':
            return 'Women’s';
        case 'mixed':
            return 'Mixed';
    }
}

export class TeamListController extends Controller {
    adding = false;
    private removingTeamId: string | null = null;
    get removing(): Team | undefined {
        return this.teams.find((team) => team.id === this.removingTeamId);
    }

    setAdding(adding: boolean) {
        this.adding = adding;
        this.changed();
    }

    selectRemoval(teamId: string | null) {
        this.removingTeamId = teamId;
        this.changed();
    }

    async confirmRemoval(): Promise<void> {
        const team = this.removing;
        if (team && (await this.deleteTeam(team.id))) this.selectRemoval(null);
    }

    get teams(): Team[] {
        return sortedTeams(this.session);
    }

    async deleteTeam(teamId: string): Promise<boolean> {
        const result = await this.deps.run(() =>
            this.deps.repository.deleteTeam(teamId).then(() => true),
        );

        return result === true;
    }
}
