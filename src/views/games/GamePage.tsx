import { PointList } from './PointList';
import type { FormEvent } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useDirty } from '../../app/context';
import { useController } from '../../app/useController';
import { Dialog, Empty, PageHeader } from '../shared';
import { GameDetailController } from '../../controllers/games/GameDetailController';
import { GameForm } from './GameForm';

export function GamePage() {
    const { gameId } = useParams();
    const controller = useController(() => new GameDetailController(gameId ?? ''));
    if (!controller.exists)
        return (
            <main className="page">
                <Empty title="Game not found">
                    <Link to="/teams">Return to teams</Link>
                </Empty>
            </main>
        );
    const game = controller.game;

    return (
        <main className="page stack">
            <PageHeader
                title="Game"
                subtitle={controller.dateText}
                back={`/teams/${game.teamId}/games`}
            >
                <button disabled={controller.busy} onClick={() => controller.openDialog('edit')}>
                    Edit game
                </button>
            </PageHeader>
            <section className="scoreboard card">
                <span className={`badge ${game.status === 'live' ? 'live' : ''}`}>
                    {controller.statusText}
                </span>
                <h2>{controller.title}</h2>
                <div
                    className="score"
                    aria-label={`Score ${controller.score.us} to ${controller.score.them}`}
                >
                    {controller.scoreText}
                </div>
                <p>
                    Target {game.targetPoints} <span aria-hidden="true">·</span>{' '}
                    {controller.tournamentName}
                </p>
                {controller.half && (
                    <p className="muted">
                        Second half starts at point {controller.half.pointNumber}
                    </p>
                )}
                <div className="actions centered">
                    {controller.canStart && (
                        <button
                            className="primary"
                            disabled={controller.busy}
                            onClick={() => void controller.start()}
                        >
                            Start game
                        </button>
                    )}
                    {controller.canSetCap && (
                        <button
                            disabled={controller.busy}
                            onClick={() => controller.openDialog('cap')}
                        >
                            Set cap
                        </button>
                    )}
                    {controller.canEnd && (
                        <button
                            className="danger"
                            disabled={controller.busy}
                            onClick={() => controller.openDialog('end')}
                        >
                            End game
                        </button>
                    )}
                </div>
            </section>
            <PointList
                gameId={game.id}
                rows={controller.entries()}
                count={controller.points.length}
                expanded={controller.expanded}
                onToggleExpanded={() => controller.toggleExpanded()}
            />
            <details className="card">
                <summary>Game details</summary>
                <dl className="details-grid">
                    <dt>Team</dt>
                    <dd>{controller.teamName}</dd>
                    <dt>Opponent</dt>
                    <dd>{controller.opponentName}</dd>
                    <dt>Tournament</dt>
                    <dd>{controller.tournamentName}</dd>
                    <dt>Starting side</dt>
                    <dd>{game.startingPosition}</dd>
                    <dt>Target</dt>
                    <dd>{game.targetPoints}</dd>
                    <dt>Status</dt>
                    <dd>{controller.statusText}</dd>
                </dl>
            </details>
            {controller.dialog === 'edit' && (
                <GameForm
                    teamId={game.teamId}
                    game={game}
                    onClose={() => controller.closeDialog()}
                />
            )}
            {controller.dialog === 'cap' && (
                <CapForm controller={controller} onClose={() => controller.closeDialog()} />
            )}
            {controller.dialog === 'end' && (
                <EndForm controller={controller} onClose={() => controller.closeDialog()} />
            )}
        </main>
    );
}

function CapForm({
    controller,
    onClose,
}: {
    controller: GameDetailController;
    onClose: () => void;
}) {
    useDirty(controller.capDirty);
    async function submit(event: FormEvent) {
        event.preventDefault();
        const saved = await controller.saveCap();
        if (saved) onClose();
    }

    return (
        <Dialog title="Set point cap" onClose={onClose}>
            <form className="stack" onSubmit={submit}>
                <p>Current score: {controller.scoreText}</p>
                <label className="field">
                    Point cap
                    <input
                        type="number"
                        autoFocus
                        min={controller.capMinimum}
                        max={21}
                        step={1}
                        value={controller.cap}
                        onChange={(event) => controller.setCap(Number(event.target.value))}
                    />
                </label>
                <p className="muted">The halftime target stays fixed.</p>
                <div className="actions">
                    <button type="button" onClick={onClose}>
                        Cancel
                    </button>
                    <button
                        className="primary"
                        disabled={controller.busy || !controller.validCap(controller.cap)}
                    >
                        Save cap
                    </button>
                </div>
            </form>
        </Dialog>
    );
}

function EndForm({
    controller,
    onClose,
}: {
    controller: GameDetailController;
    onClose: () => void;
}) {
    useDirty(controller.endDirty);
    async function submit(event: FormEvent) {
        event.preventDefault();
        const saved = await controller.end();
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
                    {controller.teamName}
                    <input
                        type="number"
                        autoFocus
                        min={controller.score.us}
                        max={99}
                        step={1}
                        value={controller.endUs}
                        onChange={(event) => controller.setEndUs(Number(event.target.value))}
                    />
                </label>
                <label className="field">
                    {controller.opponentName}
                    <input
                        type="number"
                        min={controller.score.them}
                        max={99}
                        step={1}
                        value={controller.endThem}
                        onChange={(event) => controller.setEndThem(Number(event.target.value))}
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
                        disabled={
                            controller.busy ||
                            !controller.validFinalScore(controller.endUs, controller.endThem)
                        }
                    >
                        End game
                    </button>
                </div>
            </form>
        </Dialog>
    );
}
