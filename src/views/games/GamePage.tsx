import { PointList } from './PointList';
import { type FormEvent, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useApp, useDirty } from '../../app/context';
import {
    canEndGame,
    canSetGameCap,
    canStartGame,
    type Game,
    gameById,
    gameCapMinimum,
    gameScore,
    halftimeForGame,
    opponentById,
    pointsForGame,
    teamById,
    tournamentById,
    validFinalScore,
    validGameCap,
} from '../../domain';
import { gamePointRows } from './gamePresentation';
import { Dialog, Empty, PageHeader } from '../shared';
import { GameForm } from './GameForm';

export function GamePage() {
    const { gameId } = useParams();
    const application = useApp();
    const { session, busy } = application;
    const [expanded, setExpanded] = useState(false);
    const [dialog, setDialog] = useState<'cap' | 'end' | 'edit'>();
    const game = gameById(session, gameId ?? '');
    if (!game)
        return (
            <main className="page">
                <Empty title="Game not found">
                    <Link to="/teams">Return to teams</Link>
                </Empty>
            </main>
        );
    const score = gameScore(game.id, session);
    const scoreText = `${score.us} – ${score.them}`;
    const teamName = teamById(session, game.teamId)?.name ?? 'Our team';
    const opponentName = opponentById(session, game.opponentId)?.name ?? 'Opponent';
    const tournamentName = tournamentById(session, game.tournamentId)?.name ?? 'Standalone';
    const half = halftimeForGame(session, game.id);
    const statusText =
        game.status === 'ended' ? 'Game over' : game.status === 'live' ? 'Live game' : 'Scheduled';
    const dateText = new Date(game.date).toLocaleDateString(undefined, {
        month: 'long',
        day: 'numeric',
        year: 'numeric',
    });
    const closeDialog = () => setDialog(undefined);

    return (
        <main className="page stack">
            <PageHeader title="Game" subtitle={dateText} back={`/teams/${game.teamId}/games`}>
                <button disabled={busy} onClick={() => setDialog('edit')}>
                    Edit game
                </button>
            </PageHeader>
            <section className="scoreboard card">
                <span className={`badge ${game.status === 'live' ? 'live' : ''}`}>
                    {statusText}
                </span>
                <h2>{`${teamName} vs ${opponentName}`}</h2>
                <div className="score" aria-label={`Score ${score.us} to ${score.them}`}>
                    {scoreText}
                </div>
                <p>
                    Target {game.targetPoints} <span aria-hidden="true">·</span> {tournamentName}
                </p>
                {half && <p className="muted">Second half starts at point {half.pointNumber}</p>}
                <div className="actions centered">
                    {canStartGame(game, session) && (
                        <button
                            className="primary"
                            disabled={busy}
                            onClick={() =>
                                void application.run(() =>
                                    application.repository.startGame(game.id),
                                )
                            }
                        >
                            Start game
                        </button>
                    )}
                    {canSetGameCap(game, session) && (
                        <button disabled={busy} onClick={() => setDialog('cap')}>
                            Set cap
                        </button>
                    )}
                    {canEndGame(game) && (
                        <button className="danger" disabled={busy} onClick={() => setDialog('end')}>
                            End game
                        </button>
                    )}
                </div>
            </section>
            <PointList
                gameId={game.id}
                rows={gamePointRows(game, session, expanded)}
                count={pointsForGame(session, game.id).length}
                expanded={expanded}
                onToggleExpanded={() => setExpanded((value) => !value)}
            />
            <details className="card">
                <summary>Game details</summary>
                <dl className="details-grid">
                    <dt>Team</dt>
                    <dd>{teamName}</dd>
                    <dt>Opponent</dt>
                    <dd>{opponentName}</dd>
                    <dt>Tournament</dt>
                    <dd>{tournamentName}</dd>
                    <dt>Starting side</dt>
                    <dd>{game.startingPosition}</dd>
                    <dt>Target</dt>
                    <dd>{game.targetPoints}</dd>
                    <dt>Status</dt>
                    <dd>{statusText}</dd>
                </dl>
            </details>
            {dialog === 'edit' && (
                <GameForm teamId={game.teamId} game={game} onClose={() => closeDialog()} />
            )}
            {dialog === 'cap' && <CapForm game={game} onClose={() => closeDialog()} />}
            {dialog === 'end' && <EndForm game={game} onClose={() => closeDialog()} />}
        </main>
    );
}

function CapForm({ game, onClose }: { game: Game; onClose: () => void }) {
    const application = useApp();
    const { session, busy } = application;
    const capMinimum = gameCapMinimum(game.id, session);
    const [initial] = useState(() => Math.min(21, Math.max(game.targetPoints, capMinimum)));
    const [cap, setCap] = useState(initial);
    const score = gameScore(game.id, session);
    const scoreText = `${score.us} – ${score.them}`;
    useDirty(cap !== initial);
    async function submit(event: FormEvent) {
        event.preventDefault();
        if (!validGameCap(game, session, cap)) return;
        const saved = await application.run(() =>
            application.repository.setCap(game.id, cap).then(() => true),
        );
        if (saved) onClose();
    }

    return (
        <Dialog title="Set point cap" onClose={onClose}>
            <form className="stack" onSubmit={submit}>
                <p>Current score: {scoreText}</p>
                <label className="field">
                    Point cap
                    <input
                        type="number"
                        autoFocus
                        min={capMinimum}
                        max={21}
                        step={1}
                        value={cap}
                        onChange={(event) => setCap(Number(event.target.value))}
                    />
                </label>
                <p className="muted">The halftime target stays fixed.</p>
                <div className="actions">
                    <button type="button" onClick={onClose}>
                        Cancel
                    </button>
                    <button
                        className="primary"
                        disabled={busy || !validGameCap(game, session, cap)}
                    >
                        Save cap
                    </button>
                </div>
            </form>
        </Dialog>
    );
}

function EndForm({ game, onClose }: { game: Game; onClose: () => void }) {
    const application = useApp();
    const { session, busy } = application;
    const score = gameScore(game.id, session);
    const teamName = teamById(session, game.teamId)?.name ?? 'Our team';
    const opponentName = opponentById(session, game.opponentId)?.name ?? 'Opponent';
    const [initial] = useState(score);
    const [endUs, setEndUs] = useState(initial.us);
    const [endThem, setEndThem] = useState(initial.them);
    useDirty(endUs !== initial.us || endThem !== initial.them);
    async function submit(event: FormEvent) {
        event.preventDefault();
        if (!validFinalScore(game.id, session, endUs, endThem)) return;
        const saved = await application.run(() =>
            application.repository.endGame(game.id, endUs, endThem).then(() => true),
        );
        if (saved) onClose();
    }

    return (
        <Dialog title="End game" onClose={onClose}>
            <form className="stack" onSubmit={submit}>
                <p>
                    Keep the current score, or add missing points. Final scores cannot be below the
                    recorded scores.
                </p>
                <label className="field">
                    {teamName}
                    <input
                        type="number"
                        autoFocus
                        min={score.us}
                        max={99}
                        step={1}
                        value={endUs}
                        onChange={(event) => setEndUs(Number(event.target.value))}
                    />
                </label>
                <label className="field">
                    {opponentName}
                    <input
                        type="number"
                        min={score.them}
                        max={99}
                        step={1}
                        value={endThem}
                        onChange={(event) => setEndThem(Number(event.target.value))}
                    />
                </label>
                <p className="muted">
                    Added points contain only a team result. The current open point will be removed.
                </p>
                <div className="actions">
                    <button type="button" onClick={onClose}>
                        Cancel
                    </button>
                    <button
                        className="danger"
                        disabled={busy || !validFinalScore(game.id, session, endUs, endThem)}
                    >
                        End game
                    </button>
                </div>
            </form>
        </Dialog>
    );
}
