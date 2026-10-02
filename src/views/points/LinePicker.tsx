import type { Player, PointAction } from '../../domain';

export function LinePicker({
    rows,
    count,
    issue,
    busy,
    showSubButton,
    canSub,
    onAction,
}: {
    rows: Array<{ player: Player; selected: boolean; canToggle: boolean }>;
    count: number;
    issue?: string;
    busy: boolean;
    showSubButton: boolean;
    canSub: boolean;
    onAction: (action: PointAction) => void;
}) {
    return (
        <section className="card stack" aria-label="Point line">
            <div className="row">
                <h2>Line</h2>
                <span className="badge">{count} of 7</span>
            </div>
            {issue && <p className="notice">{issue}</p>}
            {rows.length > 0 ? (
                <div className="player-grid">
                    {rows.map(({ player, selected, canToggle }) => {
                        const action: PointAction = { kind: 'toggleLine', playerId: player.id };

                        return (
                            <button
                                key={player.id}
                                className={`player-row ${selected ? 'selected' : ''}`}
                                disabled={busy || !canToggle}
                                onClick={() => onAction(action)}
                                aria-pressed={selected}
                            >
                                <span>{selected ? '✓' : '+'}</span>
                                {player.name}
                            </button>
                        );
                    })}
                </div>
            ) : (
                <p className="muted">Add players to the team roster before starting this point.</p>
            )}
            {showSubButton && (
                <button
                    className="button"
                    disabled={busy || !canSub}
                    onClick={() => onAction({ kind: 'sub' })}
                >
                    Sub players
                </button>
            )}
        </section>
    );
}
