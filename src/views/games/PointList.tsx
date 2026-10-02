import { Link } from 'react-router-dom';
import type { Point } from '../../domain';

export interface PointListRow {
    point: Point;
    showHalf: boolean;
    tone: string;
    side: string;
    result: string;
    scoreText: string;
}

export function PointList({
    gameId,
    rows,
    count,
    expanded,
    onToggleExpanded,
}: {
    gameId: string;
    rows: PointListRow[];
    count: number;
    expanded: boolean;
    onToggleExpanded: () => void;
}) {
    return (
        <section className="card stack">
            <div className="row">
                <h2>Points</h2>
                {count > 3 && (
                    <button className="text-button" onClick={() => onToggleExpanded()}>
                        {expanded ? 'Show fewer' : `Show all ${count}`}
                    </button>
                )}
            </div>
            {count === 0 && <p className="muted">Start the game to choose your first line.</p>}
            <div className="point-list">
                {rows.map((row) => (
                    <div key={row.point.id}>
                        {row.showHalf && <div className="half-divider">Halftime</div>}
                        <Link
                            className={`point-row ${row.tone}`}
                            to={`/games/${gameId}/points/${row.point.id}`}
                        >
                            <span className="side-marker">{row.side}</span>
                            <div>
                                <strong>Point {row.point.number}</strong>
                                <span>{row.result}</span>
                            </div>
                            <strong className="point-score">{row.scoreText}</strong>
                            <span aria-hidden="true">→</span>
                        </Link>
                    </div>
                ))}
            </div>
        </section>
    );
}
