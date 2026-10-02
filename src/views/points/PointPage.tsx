import { ActivePlayers } from './ActivePlayers';
import { LinePicker } from './LinePicker';
import { PlayHistory } from './PlayHistory';
import { useEffect } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { Empty, PageHeader } from '../shared';
import { useController } from '../../app/useController';
import type { PointAction, ScoringTeam } from '../../domain';
import { PointDetailController } from '../../controllers/points/PointDetailController';

export function PointPage() {
    const { gameId, pointId } = useParams();

    return (
        <PointContent
            key={`${gameId ?? ''}:${pointId ?? ''}`}
            gameId={gameId ?? ''}
            pointId={pointId ?? ''}
        />
    );
}

function PointContent({ gameId, pointId }: { gameId: string; pointId: string }) {
    const navigate = useNavigate();
    const controller = useController(() => new PointDetailController(gameId, pointId));

    useEffect(() => {
        void controller.prune();
    }, [controller, controller.needsPrune]);

    const game = controller.game;
    const point = controller.point;
    if (!game || !point)
        return (
            <main className="page stack">
                <PageHeader title="Point" back={gameId ? `/games/${gameId}` : '/teams'} />
                <Empty title="Point not found">
                    <Link to={gameId ? `/games/${gameId}` : '/teams'}>Return to the game</Link>
                </Empty>
            </main>
        );

    async function act(action: PointAction, closeAfter = false) {
        const saved = await controller.act(action);
        if (saved && closeAfter) navigate(`/games/${gameId}`);
    }
    const disabled = (action: PointAction): boolean => controller.busy || !controller.can(action);
    const activePlayerList = (
        <ActivePlayers
            rows={controller.activePlayerRows}
            busy={controller.busy}
            can={(action) => controller.can(action)}
            onAction={(action, closeAfter) => void act(action, closeAfter)}
        />
    );
    const resultButton = (team: ScoringTeam, label: string) => (
        <button
            className={`button ${team === 'us' ? 'primary' : 'danger'}`}
            disabled={disabled({ kind: 'result', scoringTeam: team })}
            onClick={() => void act({ kind: 'result', scoringTeam: team }, true)}
        >
            {label}
        </button>
    );

    return (
        <main className="page stack">
            <PageHeader
                title={controller.title}
                subtitle={`${controller.teamName} vs. ${controller.opponentName}`}
                back={`/games/${game.id}`}
            >
                {controller.canUndo && (
                    <button
                        className="button"
                        disabled={controller.busy}
                        onClick={() => void act({ kind: 'undo' })}
                    >
                        Undo last play
                    </button>
                )}
            </PageHeader>

            <section className="card stack" aria-label="Point summary">
                {controller.stage === 'complete' && (
                    <div
                        className={`score-strip ${controller.state.scoredBy === 'us' ? 'good' : 'bad'}`}
                    >
                        <strong>{controller.resultText}</strong>
                        <span>
                            {controller.score.us} – {controller.score.them}
                        </span>
                    </div>
                )}
                <div className="row">
                    <div>
                        <span className="badge">{controller.stageLabel}</span>
                        <p className="muted">{controller.summary}</p>
                    </div>
                    <strong>
                        {controller.score.us} – {controller.score.them}
                    </strong>
                </div>
                <button
                    className="button muted"
                    aria-expanded={controller.detailsOpen}
                    onClick={() => controller.toggleDetails()}
                >
                    {controller.detailsOpen ? 'Hide details' : 'Show details'}
                </button>
                {controller.detailsOpen && (
                    <dl className="details-grid">
                        <dt>Started on</dt>
                        <dd>{controller.startedOnText}</dd>
                        <dt>Puller</dt>
                        <dd>{controller.pullerText}</dd>
                        <dt>Disc</dt>
                        <dd>{controller.holder?.name ?? 'No one'}</dd>
                        <dt>Scorer</dt>
                        <dd>
                            {controller.scorer?.name ??
                                (controller.state.scoredBy === 'them' ? 'No scorer' : 'Not set')}
                        </dd>
                        <dt>Assist</dt>
                        <dd>{controller.assist?.name ?? 'None'}</dd>
                        <dt>Blocks</dt>
                        <dd>
                            {controller.blockers.map((player) => player.name).join(', ') || 'None'}
                        </dd>
                    </dl>
                )}
            </section>

            {controller.showLine && (
                <LinePicker
                    rows={controller.lineRows}
                    count={controller.lineCount}
                    issue={controller.lineIssueText}
                    busy={controller.busy}
                    showSubButton={controller.showSubButton}
                    canSub={controller.can({ kind: 'sub' })}
                    onAction={(action) => void act(action)}
                />
            )}

            {controller.stage === 'scheduled' && (
                <section className="card stack">
                    <h2>{controller.startsOnDefense ? 'Choose the puller' : 'Start the point'}</h2>
                    {!controller.startsOnDefense ? (
                        <button
                            className="button primary"
                            disabled={disabled({ kind: 'startPull' })}
                            onClick={() => void act({ kind: 'startPull' })}
                        >
                            Start point
                        </button>
                    ) : (
                        activePlayerList
                    )}
                </section>
            )}

            {(controller.stage === 'defense' ||
                controller.stage === 'looseDisc' ||
                controller.stage === 'possession') && (
                <section className="card stack">
                    <h2>{controller.stageLabel}</h2>
                    {controller.stage === 'looseDisc' && <p className="muted">Who picks up?</p>}
                    {activePlayerList}
                    {controller.stage === 'defense' && (
                        <button
                            className="button"
                            disabled={disabled({ kind: 'theirTurnover' })}
                            onClick={() => void act({ kind: 'theirTurnover' })}
                        >
                            Opponent turnover
                        </button>
                    )}
                    {controller.stage === 'possession' && (
                        <button
                            className="button danger"
                            disabled={disabled({ kind: 'ourTurnover' })}
                            onClick={() => void act({ kind: 'ourTurnover' })}
                        >
                            Our turnover
                        </button>
                    )}
                    <div className="actions">
                        {controller.canOpponentScore && (
                            <button
                                className="button danger"
                                disabled={controller.busy}
                                onClick={() =>
                                    void act({ kind: 'result', scoringTeam: 'them' }, true)
                                }
                            >
                                Opponent scores
                            </button>
                        )}
                        {controller.showSubButton && (
                            <button
                                className="button"
                                disabled={controller.busy}
                                onClick={() => void act({ kind: 'sub' })}
                            >
                                Sub players
                            </button>
                        )}
                        {controller.canUndo && (
                            <button
                                className="button"
                                disabled={controller.busy}
                                onClick={() => void act({ kind: 'undo' })}
                            >
                                Undo last play
                            </button>
                        )}
                    </div>
                </section>
            )}

            {controller.stage === 'complete' && (
                <section className="card stack">
                    <h2>Correct result</h2>
                    <p className="muted">Change which team won this point.</p>
                    <div className="actions">
                        {resultButton('us', `${controller.teamName} scored`)}
                        {resultButton('them', `${controller.opponentName} scored`)}
                    </div>
                    <Link className="button" to={`/games/${game.id}`}>
                        Back to game
                    </Link>
                </section>
            )}

            {controller.history.length > 0 && <PlayHistory events={controller.history} />}
        </main>
    );
}
