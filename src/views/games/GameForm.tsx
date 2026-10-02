import type { FormEvent } from 'react';
import { useApp, useDirty } from '../../app/context';
import { useController } from '../../app/useController';
import { Dialog } from '../shared';
import type { Game, Side } from '../../domain';
import { GameFormController } from '../../controllers/games/GameFormController';

export interface GameFormProps {
    teamId: string;
    game?: Game;
    onClose: () => void;
}

export function GameForm({ teamId, game, onClose }: GameFormProps) {
    const { session, busy } = useApp();
    const controller = useController(() => new GameFormController(teamId, game, session));
    useDirty(controller.dirty);

    async function submit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (await controller.save()) onClose();
    }

    return (
        <Dialog title={game ? 'Edit game' : 'New game'} onClose={onClose}>
            <form className="stack" onSubmit={submit}>
                <label className="field">
                    Opponent
                    <input
                        required
                        value={controller.draft.opponentName}
                        list="opponent-suggestions"
                        onChange={(event) => controller.setOpponentName(event.target.value)}
                        autoComplete="off"
                    />
                    <datalist id="opponent-suggestions">
                        {controller.opponentSuggestions.map((name) => (
                            <option key={name} value={name} />
                        ))}
                    </datalist>
                </label>
                <label className="field">
                    Tournament (optional)
                    <input
                        value={controller.draft.tournamentName}
                        list="tournament-suggestions"
                        onChange={(event) => controller.setTournamentName(event.target.value)}
                        autoComplete="off"
                    />
                    <datalist id="tournament-suggestions">
                        {controller.tournamentSuggestions.map((name) => (
                            <option key={name} value={name} />
                        ))}
                    </datalist>
                </label>
                <label className="field">
                    Date
                    <input
                        type="date"
                        required
                        value={controller.draft.date}
                        onChange={(event) => controller.setDate(event.target.value)}
                    />
                </label>
                <label className="field">
                    Target points
                    <input
                        type="number"
                        min="1"
                        max="21"
                        required
                        value={controller.draft.targetPoints}
                        onChange={(event) => controller.setTargetPoints(Number(event.target.value))}
                        disabled={controller.scoringSetupLocked}
                    />
                </label>
                <label className="field">
                    Starting position
                    <select
                        value={controller.draft.startingPosition}
                        onChange={(event) =>
                            controller.setStartingPosition(event.target.value as Side)
                        }
                        disabled={controller.scoringSetupLocked}
                    >
                        <option value="offense">Offense</option>
                        <option value="defense">Defense</option>
                    </select>
                </label>
                {controller.scoringSetupLocked && (
                    <p className="muted">
                        Target and starting position are locked after the game starts.
                    </p>
                )}
                <div className="actions">
                    <button type="button" className="button" disabled={busy} onClick={onClose}>
                        Cancel
                    </button>
                    <button
                        type="submit"
                        className="button primary"
                        disabled={busy || !controller.valid}
                    >
                        Save game
                    </button>
                </div>
            </form>
        </Dialog>
    );
}
