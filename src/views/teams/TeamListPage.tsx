import { Link } from 'react-router-dom';
import { useApp } from '../../app/context';
import { useController } from '../../app/useController';
import { ConfirmDialog, Empty, PageHeader } from '../shared';
import { TeamForm } from './TeamForm';
import { divisionLabel, TeamListController } from '../../controllers/teams/TeamListController';

export function TeamListPage() {
    const controller = useController(() => new TeamListController());
    const { busy } = useApp();
    const teams = controller.teams;
    const removing = controller.removing;

    return (
        <main className="page stack">
            <PageHeader title="Teams">
                <button
                    className="button primary"
                    disabled={busy}
                    onClick={() => controller.setAdding(true)}
                >
                    Add team
                </button>
            </PageHeader>
            {teams.length === 0 ? (
                <Empty title="No teams yet">
                    Create a team to start tracking a roster and games.
                </Empty>
            ) : (
                <ul className="team-list">
                    {teams.map((team) => (
                        <li className="team-list-row" key={team.id}>
                            <Link className="team-list-link" to={`/teams/${team.id}`}>
                                <span className="team-list-name">
                                    <strong>{team.name}</strong>
                                    <span className="muted">
                                        {divisionLabel(team.division)} · {team.playerIds.length}{' '}
                                        players
                                    </span>
                                </span>
                                <span aria-hidden="true">›</span>
                            </Link>
                            <button
                                className="button danger team-delete"
                                aria-label={`Delete ${team.name}`}
                                disabled={busy}
                                onClick={() => controller.selectRemoval(team.id)}
                            >
                                Delete
                            </button>
                        </li>
                    ))}
                </ul>
            )}
            {controller.adding && (
                <TeamForm team={null} onClose={() => controller.setAdding(false)} />
            )}
            {removing && (
                <ConfirmDialog
                    title="Delete team?"
                    confirmLabel="Delete team"
                    busy={busy}
                    onCancel={() => controller.selectRemoval(null)}
                    onConfirm={() => void controller.confirmRemoval()}
                >
                    Delete {removing.name} and its games?
                </ConfirmDialog>
            )}
        </main>
    );
}
