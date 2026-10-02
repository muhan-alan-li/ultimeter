import { type FormEvent, useState } from 'react';
import { useApp, useDirty } from '../../app/context';
import { Dialog } from '../shared';
import type { Game, Side } from '../../domain';
import {
    gameDateTimestamp,
    gameDraft,
    gameDraftIsValid,
    suggestionsForName,
    trimGameNames,
} from './gameDraft';
import { canEditGameSetup, gameById } from '../../domain';

export interface GameFormProps {
    teamId: string;
    game?: Game;
    onClose: () => void;
}

export function GameForm({ teamId, game, onClose }: GameFormProps) {
    const application = useApp();
    const { session, busy } = application;
    const [initial] = useState(() => gameDraft(game, session));
    const [draft, setDraft] = useState(initial);
    const currentGame = game ? gameById(session, game.id) : undefined;
    const scoringSetupLocked = !!game && (!currentGame || !canEditGameSetup(currentGame, session));
    const valid = gameDraftIsValid(draft);
    const opponentSuggestions = suggestionsForName(
        session.opponents.map((item) => item.name),
        draft.opponentName,
    );
    const tournamentSuggestions = suggestionsForName(
        session.tournaments.map((item) => item.name),
        draft.tournamentName,
    );
    useDirty(
        draft.date !== initial.date ||
            draft.opponentName.trim() !== initial.opponentName ||
            draft.tournamentName.trim() !== initial.tournamentName ||
            draft.targetPoints !== initial.targetPoints ||
            draft.startingPosition !== initial.startingPosition,
    );

    async function submit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (!valid || (game && !currentGame)) return;
        const saved = await application.run(() =>
            application.repository.saveGame(
                teamId,
                {
                    date: gameDateTimestamp(draft.date),
                    ...trimGameNames(draft),
                    targetPoints: draft.targetPoints,
                    startingPosition: draft.startingPosition,
                },
                game?.id,
            ),
        );
        if (saved) onClose();
    }

    return (
        <Dialog title={game ? 'Edit game' : 'New game'} onClose={onClose}>
            <form className="stack" onSubmit={submit}>
                <label className="field">
                    Opponent
                    <input
                        required
                        value={draft.opponentName}
                        list="opponent-suggestions"
                        onChange={(event) =>
                            setDraft({ ...draft, opponentName: event.target.value })
                        }
                        autoComplete="off"
                    />
                    <datalist id="opponent-suggestions">
                        {opponentSuggestions.map((name) => (
                            <option key={name} value={name} />
                        ))}
                    </datalist>
                </label>
                <label className="field">
                    Tournament (optional)
                    <input
                        value={draft.tournamentName}
                        list="tournament-suggestions"
                        onChange={(event) =>
                            setDraft({ ...draft, tournamentName: event.target.value })
                        }
                        autoComplete="off"
                    />
                    <datalist id="tournament-suggestions">
                        {tournamentSuggestions.map((name) => (
                            <option key={name} value={name} />
                        ))}
                    </datalist>
                </label>
                <label className="field">
                    Date
                    <input
                        type="date"
                        required
                        value={draft.date}
                        onChange={(event) => setDraft({ ...draft, date: event.target.value })}
                    />
                </label>
                <label className="field">
                    Target points
                    <input
                        type="number"
                        min="1"
                        max="21"
                        required
                        value={draft.targetPoints}
                        onChange={(event) =>
                            setDraft({ ...draft, targetPoints: Number(event.target.value) })
                        }
                        disabled={scoringSetupLocked}
                    />
                </label>
                <label className="field">
                    Starting position
                    <select
                        value={draft.startingPosition}
                        onChange={(event) =>
                            setDraft({ ...draft, startingPosition: event.target.value as Side })
                        }
                        disabled={scoringSetupLocked}
                    >
                        <option value="offense">Offense</option>
                        <option value="defense">Defense</option>
                    </select>
                </label>
                {scoringSetupLocked && (
                    <p className="muted">
                        Target and starting position are locked after the game starts.
                    </p>
                )}
                <div className="actions">
                    <button type="button" className="button" disabled={busy} onClick={onClose}>
                        Cancel
                    </button>
                    <button type="submit" className="button primary" disabled={busy || !valid}>
                        Save game
                    </button>
                </div>
            </form>
        </Dialog>
    );
}
