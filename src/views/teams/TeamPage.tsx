import { useState } from 'react';
import { GameList } from '../games/GameList';
import { RosterTable } from './RosterTable';
import { Link, useLocation, useParams } from 'react-router-dom';
import { useApp } from '../../app/context';
import { ConfirmDialog, Empty, PageHeader, Pagination } from '../shared';
import { GameForm } from '../games/GameForm';
import { PlayerForm } from '../players/PlayerForm';
import { TeamForm } from './TeamForm';
import { gameById, rosterForTeam, teamById } from '../../domain';
import { divisionLabel, genderLabel } from './teamPresentation';
import { gameOpponent, gameResult, gameSectionsForTeam } from '../games/gamePresentation';

export function TeamPage() {
    const { teamId = '' } = useParams();
    const application = useApp();
    const { busy, session } = application;
    const location = useLocation();
    const [dialog, setDialog] = useState<'edit' | 'players' | 'game' | 'removePlayers'>();
    const [removingGameId, selectGameRemoval] = useState<string | null>(null);
    const [rosterPageIndex, setRosterPage] = useState(0);
    const [selectedPlayerIds, setSelectedPlayerIds] = useState(new Set<string>());
    const [selectingPlayers, setSelecting] = useState(false);
    const team = teamById(session, teamId);
    const roster = rosterForTeam(session, teamId);
    const candidate = removingGameId ? gameById(session, removingGameId) : undefined;
    const removingGame = team && candidate?.teamId === teamId ? candidate : undefined;
    const rosterPageSize = 10;
    const rosterPageCount = Math.max(1, Math.ceil(roster.length / rosterPageSize));
    const rosterPage = Math.min(rosterPageIndex, rosterPageCount - 1);
    const start = rosterPage * rosterPageSize;
    const rosterRows = roster.slice(start, start + rosterPageSize).map((player) => ({
        player,
        selected: selectedPlayerIds.has(player.id),
    }));
    const selectedPlayers = roster.filter((player) => selectedPlayerIds.has(player.id));
    const selectedCount = selectedPlayers.length;
    const allPlayersSelected = roster.length > 0 && selectedCount === roster.length;
    const gameSections = gameSectionsForTeam(teamId, session).map((section) => ({
        ...section,
        games: section.games.map((game) => ({
            id: game.id,
            opponent: gameOpponent(game, session),
            dateText: new Date(game.date).toLocaleDateString(),
            isLive: game.status === 'live',
            result: gameResult(game, session),
        })),
    }));
    function closeDialog() {
        setDialog(undefined);
    }
    function setSelectingPlayers(value: boolean) {
        setSelecting(value);
        setSelectedPlayerIds(new Set());
    }
    function togglePlayerSelection(id: string) {
        if (!selectingPlayers || busy || !roster.some((player) => player.id === id)) return;
        setSelectedPlayerIds((previous) => {
            const next = new Set(previous);
            if (next.has(id)) next.delete(id);
            else next.add(id);

            return next;
        });
    }
    function toggleAllPlayers() {
        if (!selectingPlayers || busy) return;
        setSelectedPlayerIds(
            allPlayersSelected ? new Set() : new Set(roster.map((player) => player.id)),
        );
    }
    function changeRosterPage(direction: -1 | 1) {
        setRosterPage(Math.max(0, Math.min(rosterPage + direction, rosterPageCount - 1)));
    }
    async function confirmGameRemoval() {
        if (!removingGame) return;
        const saved = await application.run(() =>
            application.repository.deleteGame(removingGame.id).then(() => true),
        );
        if (saved) selectGameRemoval(null);
    }
    async function confirmPlayerRemoval() {
        if (!selectedCount || busy) return;
        const saved = await application.run(() =>
            application.repository
                .removePlayers(
                    teamId,
                    selectedPlayers.map((player) => player.id),
                )
                .then(() => true),
        );
        if (saved) {
            setSelectingPlayers(false);
            closeDialog();
        }
    }
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
                subtitle={`${divisionLabel(team.division)} division`}
                back="/teams"
            >
                <button className="button" disabled={busy} onClick={() => setDialog('edit')}>
                    Edit team
                </button>
                {isGames && (
                    <button
                        className="button primary"
                        disabled={busy}
                        onClick={() => setDialog('game')}
                    >
                        Add game
                    </button>
                )}
                {!isGames && (
                    <button
                        className="button primary"
                        disabled={busy}
                        onClick={() => setDialog('players')}
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
                        sections={gameSections}
                        busy={busy}
                        onRemove={(id) => selectGameRemoval(id)}
                    />
                </>
            ) : (
                <>
                    {roster.length === 0 ? (
                        <Empty title="No players yet">Add players to build the team roster.</Empty>
                    ) : (
                        <section className="stack" aria-label="Roster">
                            <div className="row">
                                <p className="muted" aria-live="polite">
                                    {`${start + 1}–${Math.min(start + rosterPageSize, roster.length)} of ${roster.length} players`}
                                </p>
                                <div className="actions">
                                    {selectingPlayers ? (
                                        <>
                                            <span className="muted" aria-live="polite">
                                                {selectedCount} selected
                                            </span>
                                            <button
                                                className="button"
                                                disabled={busy}
                                                onClick={() => toggleAllPlayers()}
                                            >
                                                {allPlayersSelected
                                                    ? 'Clear selection'
                                                    : 'Select all players'}
                                            </button>
                                            <button
                                                className="button danger"
                                                disabled={busy || !selectedCount}
                                                onClick={() => setDialog('removePlayers')}
                                            >
                                                Delete selected
                                            </button>
                                            <button
                                                className="button"
                                                disabled={busy}
                                                onClick={() => setSelectingPlayers(false)}
                                            >
                                                Cancel
                                            </button>
                                        </>
                                    ) : (
                                        <button
                                            className="button"
                                            disabled={busy}
                                            onClick={() => setSelectingPlayers(true)}
                                        >
                                            Select players
                                        </button>
                                    )}
                                </div>
                            </div>
                            <RosterTable
                                rows={rosterRows}
                                selecting={selectingPlayers}
                                busy={busy}
                                onToggle={(id) => togglePlayerSelection(id)}
                                genderLabel={(gender) => genderLabel(gender)}
                            />
                            {rosterPageCount > 1 && (
                                <Pagination
                                    label="Roster pages"
                                    page={rosterPage}
                                    pageCount={rosterPageCount}
                                    busy={busy}
                                    canPrevious={rosterPage > 0}
                                    canNext={rosterPage + 1 < rosterPageCount}
                                    onChange={(direction) => changeRosterPage(direction)}
                                />
                            )}
                        </section>
                    )}
                </>
            )}
            {dialog === 'removePlayers' && (
                <ConfirmDialog
                    title="Delete selected players?"
                    confirmLabel="Delete selected"
                    busy={busy}
                    disabled={!selectedCount}
                    onCancel={() => closeDialog()}
                    onConfirm={() => void confirmPlayerRemoval()}
                >
                    Remove {selectedCount} selected players from this roster? Recorded game history
                    stays saved.
                </ConfirmDialog>
            )}
            {dialog === 'edit' && <TeamForm team={team} onClose={() => closeDialog()} />}
            {dialog === 'players' && (
                <PlayerForm
                    key={team.id}
                    teamId={team.id}
                    division={team.division}
                    onClose={() => closeDialog()}
                />
            )}
            {dialog === 'game' && <GameForm teamId={team.id} onClose={() => closeDialog()} />}
            {removingGame && (
                <ConfirmDialog
                    title="Delete game?"
                    confirmLabel="Delete game"
                    busy={busy}
                    onCancel={() => selectGameRemoval(null)}
                    onConfirm={() => void confirmGameRemoval()}
                >
                    Delete this game and its recorded points?
                </ConfirmDialog>
            )}
        </main>
    );
}
