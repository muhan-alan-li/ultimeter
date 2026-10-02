import { GameList } from '../games/GameList';
import { RosterTable } from './RosterTable';
import { Link, useLocation, useParams } from 'react-router-dom';
import { useApp } from '../../app/context';
import { useController } from '../../app/useController';
import { ConfirmDialog, Empty, PageHeader, Pagination } from '../shared';
import { GameForm } from '../games/GameForm';
import { PlayerForm } from '../players/PlayerForm';
import { TeamForm } from './TeamForm';
import { TeamDetailController } from '../../controllers/teams/TeamDetailController';

export function TeamPage() {
    const { teamId = '' } = useParams();
    const controller = useController(() => new TeamDetailController(teamId));
    const { busy } = useApp();
    const location = useLocation();
    const team = controller.team;
    if (!team)
        return (
            <main className="page">
                <Empty title="Team not found">
                    <Link to="/teams">Return to teams</Link>
                </Empty>
            </main>
        );
    const isGames = location.pathname.endsWith('/games');
    const base = `/teams/${teamId}`;

    return (
        <main className="page stack">
            <PageHeader
                title={team.name}
                subtitle={`${controller.divisionLabel} division`}
                back="/teams"
            >
                <button
                    className="button"
                    disabled={busy}
                    onClick={() => controller.openDialog('edit')}
                >
                    Edit team
                </button>
                {isGames && (
                    <button
                        className="button primary"
                        disabled={busy}
                        onClick={() => controller.openDialog('game')}
                    >
                        Add game
                    </button>
                )}
                {!isGames && (
                    <button
                        className="button primary"
                        disabled={busy}
                        onClick={() => controller.openDialog('players')}
                    >
                        Add players
                    </button>
                )}
            </PageHeader>
            <nav className="tabs" aria-label="Team sections">
                <Link className={!isGames ? 'active' : ''} to={`${base}/roster`}>
                    Roster
                </Link>
                <Link className={isGames ? 'active' : ''} to={`${base}/games`}>
                    Games
                </Link>
            </nav>
            {isGames ? (
                <>
                    <GameList
                        sections={controller.gameSections}
                        busy={busy}
                        onRemove={(id) => controller.selectGameRemoval(id)}
                    />
                </>
            ) : (
                <>
                    {controller.roster.length === 0 ? (
                        <Empty title="No players yet">Add players to build the team roster.</Empty>
                    ) : (
                        <section className="stack" aria-label="Roster">
                            <div className="row">
                                <p className="muted" aria-live="polite">
                                    {controller.rosterRangeText}
                                </p>
                                <div className="actions">
                                    {controller.selectingPlayers ? (
                                        <>
                                            <span className="muted" aria-live="polite">
                                                {controller.selectedCount} selected
                                            </span>
                                            <button
                                                className="button"
                                                disabled={busy}
                                                onClick={() => controller.toggleAllPlayers()}
                                            >
                                                {controller.allPlayersSelected
                                                    ? 'Clear selection'
                                                    : 'Select all players'}
                                            </button>
                                            <button
                                                className="button danger"
                                                disabled={busy || !controller.selectedCount}
                                                onClick={() =>
                                                    controller.openDialog('removePlayers')
                                                }
                                            >
                                                Delete selected
                                            </button>
                                            <button
                                                className="button"
                                                disabled={busy}
                                                onClick={() =>
                                                    controller.setSelectingPlayers(false)
                                                }
                                            >
                                                Cancel
                                            </button>
                                        </>
                                    ) : (
                                        <button
                                            className="button"
                                            disabled={busy}
                                            onClick={() => controller.setSelectingPlayers(true)}
                                        >
                                            Select players
                                        </button>
                                    )}
                                </div>
                            </div>
                            <RosterTable
                                rows={controller.rosterRows}
                                selecting={controller.selectingPlayers}
                                busy={busy}
                                onToggle={(id) => controller.togglePlayerSelection(id)}
                                genderLabel={(gender) => controller.genderLabel(gender)}
                            />
                            {controller.rosterPageCount > 1 && (
                                <Pagination
                                    label="Roster pages"
                                    page={controller.rosterPage}
                                    pageCount={controller.rosterPageCount}
                                    busy={busy}
                                    canPrevious={controller.canPreviousPage}
                                    canNext={controller.canNextPage}
                                    onChange={(direction) => controller.changeRosterPage(direction)}
                                />
                            )}
                        </section>
                    )}
                </>
            )}
            {controller.dialog === 'removePlayers' && (
                <ConfirmDialog
                    title="Delete selected players?"
                    confirmLabel="Delete selected"
                    busy={busy}
                    disabled={!controller.selectedCount}
                    onCancel={() => controller.closeDialog()}
                    onConfirm={() => void controller.confirmPlayerRemoval()}
                >
                    Remove {controller.selectedCount} selected players from this roster? Recorded
                    game history stays saved.
                </ConfirmDialog>
            )}
            {controller.dialog === 'edit' && (
                <TeamForm team={team} onClose={() => controller.closeDialog()} />
            )}
            {controller.dialog === 'players' && (
                <PlayerForm
                    key={team.id}
                    teamId={team.id}
                    division={team.division}
                    onClose={() => controller.closeDialog()}
                />
            )}
            {controller.dialog === 'game' && (
                <GameForm teamId={team.id} onClose={() => controller.closeDialog()} />
            )}
            {controller.removingGame && (
                <ConfirmDialog
                    title="Delete game?"
                    confirmLabel="Delete game"
                    busy={busy}
                    onCancel={() => controller.selectGameRemoval(null)}
                    onConfirm={() => void controller.confirmGameRemoval()}
                >
                    Delete this game and its recorded points?
                </ConfirmDialog>
            )}
        </main>
    );
}
