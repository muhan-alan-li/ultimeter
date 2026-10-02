import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useApp } from '../../app/context';
import { ConfirmDialog, Empty, PageHeader } from '../shared';
import { TeamForm } from './TeamForm';
import { divisionLabel } from './teamPresentation';
import { sortedTeams } from '../../domain';

export function TeamListPage() {
    const application = useApp();
    const { busy, session } = application;
    const [adding, setAdding] = useState(false);
    const [removingTeamId, selectRemoval] = useState<string | null>(null);
    const teams = sortedTeams(session);
    const removing = teams.find((team) => team.id === removingTeamId);

    async function confirmRemoval() {
        if (!removing) return;
        const saved = await application.run(() =>
            application.repository.deleteTeam(removing.id).then(() => true),
        );
        if (saved) selectRemoval(null);
    }

    return (
        <main className="page stack">
            <PageHeader title="Teams">
                <button className="button primary" disabled={busy} onClick={() => setAdding(true)}>
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
                                onClick={() => selectRemoval(team.id)}
                            >
                                Delete
                            </button>
                        </li>
                    ))}
                </ul>
            )}
            {adding && <TeamForm team={null} onClose={() => setAdding(false)} />}
            {removing && (
                <ConfirmDialog
                    title="Delete team?"
                    confirmLabel="Delete team"
                    busy={busy}
                    onCancel={() => selectRemoval(null)}
                    onConfirm={() => void confirmRemoval()}
                >
                    Delete {removing.name} and its games?
                </ConfirmDialog>
            )}
        </main>
    );
}
