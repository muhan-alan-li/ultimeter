import { Link } from 'react-router-dom';
import { Empty } from '../shared';

export interface GameListRow {
    id: string;
    opponent: string;
    dateText: string;
    isLive: boolean;
    result: { score: string; label: string };
}

export function GameList({
    sections,
    busy,
    onRemove,
}: {
    sections: Array<{ id: string; title: string; games: GameListRow[] }>;
    busy: boolean;
    onRemove: (id: string) => void;
}) {
    return (
        <>
            {sections.length === 0 ? (
                <Empty title="No games yet">Add a game to begin tracking scores.</Empty>
            ) : (
                sections.map((section) => (
                    <section className="stack" key={section.id}>
                        <h2>{section.title}</h2>
                        <ul className="games-list" aria-label={`${section.title} games`}>
                            {section.games.map((game) => {
                                const row = game;

                                return (
                                    <li className="games-list-row" key={game.id}>
                                        <Link
                                            className="games-list-link"
                                            to={`/games/${game.id}`}
                                            aria-label={`Game against ${row.opponent}, ${row.dateText}, ${row.result.label}${row.result.score ? `, ${row.result.score}` : ''}`}
                                        >
                                            <span className="games-list-opponent">
                                                <strong>vs {row.opponent}</strong>
                                                <span className="muted">{row.dateText}</span>
                                            </span>
                                            <span className="games-list-result">
                                                {row.result.score && (
                                                    <strong>{row.result.score}</strong>
                                                )}
                                                <span
                                                    className={`badge ${row.isLive ? 'live' : ''}`}
                                                >
                                                    {row.result.label}
                                                </span>
                                            </span>
                                            <span aria-hidden="true">›</span>
                                        </Link>
                                        <button
                                            className="button danger game-delete"
                                            aria-label={`Delete game against ${row.opponent}`}
                                            disabled={busy}
                                            onClick={() => onRemove(game.id)}
                                        >
                                            Delete
                                        </button>
                                    </li>
                                );
                            })}
                        </ul>
                    </section>
                ))
            )}
        </>
    );
}
