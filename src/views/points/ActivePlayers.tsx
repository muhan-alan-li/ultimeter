import type { Player, PointAction } from '../../domain';

export interface ActivePlayerRow {
    player: Player;
    isHolder: boolean;
    actions: Array<{
        action: PointAction;
        label: string;
        accessibilityLabel: string;
        primary: boolean;
        closesPoint: boolean;
    }>;
}

export function ActivePlayers({
    rows,
    busy,
    can,
    onAction,
}: {
    rows: ActivePlayerRow[];
    busy: boolean;
    can: (action: PointAction) => boolean;
    onAction: (action: PointAction, closeAfter: boolean) => void;
}) {
    return (
        <ul className="on-field-list" aria-label="Active players">
            {rows.map(({ player, isHolder, actions }) => (
                <li key={player.id} className={`on-field-row ${isHolder ? 'disc-holder' : ''}`}>
                    <span className="on-field-name">
                        {isHolder && <span className="holder-dot" aria-hidden="true" />}
                        {player.name}
                    </span>
                    {isHolder ? (
                        <span className="muted" aria-label={`${player.name} holds the disc`}>
                            Holder
                        </span>
                    ) : (
                        <div className="on-field-actions">
                            {actions.map(
                                ({ action, label, accessibilityLabel, primary, closesPoint }) => (
                                    <button
                                        key={action.kind}
                                        className={`button ${primary ? 'primary' : ''}`}
                                        aria-label={accessibilityLabel}
                                        disabled={busy || !can(action)}
                                        onClick={() => onAction(action, closesPoint)}
                                    >
                                        {label}
                                    </button>
                                ),
                            )}
                        </div>
                    )}
                </li>
            ))}
        </ul>
    );
}
