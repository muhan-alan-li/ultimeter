import { type FormEvent, useState } from 'react';
import { useApp, useDirty } from '../../app/context';
import { Dialog } from '../shared';
import type { Division, Gender } from '../../domain';
import { defaultGenderForDivision, playerNamesFromLines } from './playerDraft';

export function PlayerForm({
    teamId,
    division,
    onClose,
}: {
    teamId: string;
    division: Division;
    onClose: () => void;
}) {
    const application = useApp();
    const { busy } = application;
    const [names, setNames] = useState('');
    const [initialGender] = useState(() => defaultGenderForDivision(division));
    const [gender, setGender] = useState(initialGender);
    const cleanNames = playerNamesFromLines(names);
    useDirty(names.trim().length > 0 || gender !== initialGender);

    async function submit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (!cleanNames.length) return;
        const saved = await application.run(() =>
            application.repository.addPlayers(teamId, cleanNames, gender).then(() => true),
        );
        if (saved) onClose();
    }

    return (
        <Dialog title="Add players" onClose={onClose}>
            <form className="stack" onSubmit={submit}>
                <label className="field">
                    Player names
                    <textarea
                        autoFocus
                        rows={6}
                        value={names}
                        onChange={(event) => setNames(event.target.value)}
                        placeholder="Enter one name per line"
                    />
                </label>
                <label className="field">
                    Gender
                    <select
                        value={gender}
                        onChange={(event) => setGender(event.target.value as Gender)}
                    >
                        <option value="male">Male</option>
                        <option value="female">Female</option>
                        <option value="nonBinary">Non-binary</option>
                    </select>
                </label>
                <div className="actions">
                    <button type="button" className="button" disabled={busy} onClick={onClose}>
                        Cancel
                    </button>
                    <button
                        type="submit"
                        className="button primary"
                        disabled={busy || !cleanNames.length}
                    >
                        Add {cleanNames.length || 'players'}
                    </button>
                </div>
            </form>
        </Dialog>
    );
}
