import type { PointAction } from '../../app/pointActions';
import { ActivePlayers } from './ActivePlayers';
import { LinePicker } from './LinePicker';
import { PlayHistory } from './PlayHistory';
import { useEffect, useReducer } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { Empty, PageHeader } from '../shared';
import { useApp } from '../../app/context';
import { pointDisplay } from './pointPresentation';
import { allowsPointAction, pointNeedsPrune } from '../../app/pointActions';
import { pointForGame } from '../../domain';
import type { ScoringTeam } from '../../domain';

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
    const application = useApp();
    const [detailsOpen, toggleDetails] = useReducer((open: boolean) => !open, false);
    const { session, busy } = application;
    const display = pointDisplay(session, gameId, pointId);
    const { game, point, needsPrune } = display;

    useEffect(() => {
        const currentPoint = pointForGame(application.session, gameId, pointId);
        if (needsPrune && currentPoint && pointNeedsPrune(currentPoint, application.session)) {
            void application.run(() =>
                application.repository.pointAction(gameId, pointId, { kind: 'pruneLine' }),
            );
        }
    }, [application, gameId, pointId, needsPrune]);

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
        if (!game || !point) return;
        const saved = await application.run(() =>
            application.repository.pointAction(game.id, point.id, action).then(() => true),
        );
        if (saved && closeAfter) navigate(`/games/${gameId}`);
    }
    const can = (action: PointAction): boolean =>
        !!game && !!point && allowsPointAction(action, game, point, session);
    const disabled = (action: PointAction): boolean => busy || !can(action);
    const activePlayerList = (
        <ActivePlayers
            rows={display.activePlayerRows}
            busy={busy}
            can={(action) => can(action)}
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
                title={display.title}
                subtitle={`${display.teamName} vs. ${display.opponentName}`}
                back={`/games/${game.id}`}
            >
                {display.canUndo && (
                    <button
                        className="button"
                        disabled={busy}
                        onClick={() => void act({ kind: 'undo' })}
                    >
                        Undo last play
                    </button>
                )}
            </PageHeader>

            <section className="card stack" aria-label="Point summary">
                {display.stage === 'complete' && (
                    <div
                        className={`score-strip ${display.state.scoredBy === 'us' ? 'good' : 'bad'}`}
                    >
                        <strong>{display.resultText}</strong>
                        <span>
                            {display.score.us} – {display.score.them}
                        </span>
                    </div>
                )}
                <div className="row">
                    <div>
                        <span className="badge">{display.stageLabel}</span>
                        <p className="muted">{display.summary}</p>
                    </div>
                    <strong>
                        {display.score.us} – {display.score.them}
                    </strong>
                </div>
                <button
                    className="button muted"
                    aria-expanded={detailsOpen}
                    onClick={() => toggleDetails()}
                >
                    {detailsOpen ? 'Hide details' : 'Show details'}
                </button>
                {detailsOpen && (
                    <dl className="details-grid">
                        <dt>Started on</dt>
                        <dd>{display.startedOnText}</dd>
                        <dt>Puller</dt>
                        <dd>{display.pullerText}</dd>
                        <dt>Disc</dt>
                        <dd>{display.holder?.name ?? 'No one'}</dd>
                        <dt>Scorer</dt>
                        <dd>
                            {display.scorer?.name ??
                                (display.state.scoredBy === 'them' ? 'No scorer' : 'Not set')}
                        </dd>
                        <dt>Assist</dt>
                        <dd>{display.assist?.name ?? 'None'}</dd>
                        <dt>Blocks</dt>
                        <dd>
                            {display.blockers.map((player) => player.name).join(', ') || 'None'}
                        </dd>
                    </dl>
                )}
            </section>

            {display.showLine && (
                <LinePicker
                    rows={display.lineRows}
                    count={display.lineCount}
                    issue={display.lineIssueText}
                    busy={busy}
                    showSubButton={display.showSubButton}
                    canSub={can({ kind: 'sub' })}
                    onAction={(action) => void act(action)}
                />
            )}

            {display.stage === 'scheduled' && (
                <section className="card stack">
                    <h2>{display.startsOnDefense ? 'Choose the puller' : 'Start the point'}</h2>
                    {!display.startsOnDefense ? (
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

            {(display.stage === 'defense' ||
                display.stage === 'looseDisc' ||
                display.stage === 'possession') && (
                <section className="card stack">
                    <h2>{display.stageLabel}</h2>
                    {display.stage === 'looseDisc' && <p className="muted">Who picks up?</p>}
                    {activePlayerList}
                    {display.stage === 'defense' && (
                        <button
                            className="button"
                            disabled={disabled({ kind: 'theirTurnover' })}
                            onClick={() => void act({ kind: 'theirTurnover' })}
                        >
                            Opponent turnover
                        </button>
                    )}
                    {display.stage === 'possession' && (
                        <button
                            className="button danger"
                            disabled={disabled({ kind: 'ourTurnover' })}
                            onClick={() => void act({ kind: 'ourTurnover' })}
                        >
                            Our turnover
                        </button>
                    )}
                    <div className="actions">
                        {display.canOpponentScore && (
                            <button
                                className="button danger"
                                disabled={busy}
                                onClick={() =>
                                    void act({ kind: 'result', scoringTeam: 'them' }, true)
                                }
                            >
                                Opponent scores
                            </button>
                        )}
                        {display.showSubButton && (
                            <button
                                className="button"
                                disabled={busy}
                                onClick={() => void act({ kind: 'sub' })}
                            >
                                Sub players
                            </button>
                        )}
                        {display.canUndo && (
                            <button
                                className="button"
                                disabled={busy}
                                onClick={() => void act({ kind: 'undo' })}
                            >
                                Undo last play
                            </button>
                        )}
                    </div>
                </section>
            )}

            {display.stage === 'complete' && (
                <section className="card stack">
                    <h2>Correct result</h2>
                    <p className="muted">Change which team won this point.</p>
                    <div className="actions">
                        {resultButton('us', `${display.teamName} scored`)}
                        {resultButton('them', `${display.opponentName} scored`)}
                    </div>
                    <Link className="button" to={`/games/${game.id}`}>
                        Back to game
                    </Link>
                </section>
            )}

            {display.history.length > 0 && <PlayHistory events={display.history} />}
        </main>
    );
}
