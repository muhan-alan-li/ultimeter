import type { Player } from '../../domain';

export function RosterTable({
    rows,
    selecting,
    busy,
    onToggle,
    genderLabel,
}: {
    rows: Array<{ player: Player; selected: boolean }>;
    selecting: boolean;
    busy: boolean;
    onToggle: (id: string) => void;
    genderLabel: (gender: Player['gender']) => string;
}) {
    return (
        <div className="roster-table-wrap">
            <table className="roster-table">
                <thead>
                    <tr>
                        {selecting && (
                            <th scope="col" className="roster-selection-column">
                                <span className="sr-only">Select player</span>
                            </th>
                        )}
                        <th scope="col">Name</th>
                        <th scope="col">Gender</th>
                    </tr>
                </thead>
                <tbody>
                    {rows.map(({ player, selected }) => (
                        <tr className={selected ? 'selected' : ''} key={player.id}>
                            {selecting && (
                                <td className="roster-selection-column">
                                    <input
                                        id={`select-player-${player.id}`}
                                        type="checkbox"
                                        checked={selected}
                                        disabled={busy}
                                        onChange={() => onToggle(player.id)}
                                        aria-label={`Select ${player.name}`}
                                    />
                                </td>
                            )}
                            <th scope="row">
                                {selecting ? (
                                    <label htmlFor={`select-player-${player.id}`}>
                                        {player.name}
                                    </label>
                                ) : (
                                    player.name
                                )}
                            </th>
                            <td>{genderLabel(player.gender)}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}
