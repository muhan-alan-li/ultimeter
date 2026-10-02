import { type FormEvent, useState } from 'react';
import { useApp, useDirty } from '../../app/context';
import { Dialog } from '../shared';
import type { Division, Team } from '../../domain';
import { teamDraft, teamDraftIsValid } from './teamDraft';

const divisions: Array<{ value: Division; label: string }> = [
    { value: 'open', label: 'Open' },
    { value: 'womens', label: 'Women’s' },
    { value: 'mixed', label: 'Mixed' },
];

export function TeamForm({ team, onClose }: { team: Team | null; onClose: () => void }) {
    const application = useApp();
    const { session, busy } = application;
    const [initial] = useState(() => teamDraft(team?.name, team?.division));
    const [draft, setDraft] = useState(initial);
    const name = draft.name.trim().toLocaleLowerCase();
    const duplicateName =
        !!name &&
        session.teams.some(
            (item) => item.id !== team?.id && item.name.toLocaleLowerCase() === name,
        );
    const valid = teamDraftIsValid(draft, session, team?.id);
    useDirty(draft.name !== initial.name || draft.division !== initial.division);

    async function submit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (!valid) return;
        const saved = await application.run(() =>
            application.repository.saveTeam(
                { name: draft.name.trim(), division: draft.division },
                team?.id,
            ),
        );
        if (saved) onClose();
    }

    return (
        <Dialog title={team ? 'Edit team' : 'New team'} onClose={onClose}>
            <form className="stack" onSubmit={submit}>
                <label className="field">
                    Team name
                    <input
                        autoFocus
                        required
                        value={draft.name}
                        aria-invalid={duplicateName}
                        aria-describedby={duplicateName ? 'team-name-error' : undefined}
                        ref={(input) =>
                            input?.setCustomValidity(
                                duplicateName ? 'A team with this name already exists.' : '',
                            )
                        }
                        onChange={(event) => setDraft({ ...draft, name: event.target.value })}
                    />
                </label>
                {duplicateName && (
                    <p id="team-name-error" className="error" role="status">
                        A team with this name already exists.
                    </p>
                )}
                <label className="field">
                    Division
                    <select
                        value={draft.division}
                        onChange={(event) =>
                            setDraft({ ...draft, division: event.target.value as Division })
                        }
                    >
                        {divisions.map((item) => (
                            <option key={item.value} value={item.value}>
                                {item.label}
                            </option>
                        ))}
                    </select>
                </label>
                <div className="actions">
                    <button type="button" className="button" disabled={busy} onClick={onClose}>
                        Cancel
                    </button>
                    <button type="submit" className="button primary" disabled={busy || !valid}>
                        Save team
                    </button>
                </div>
            </form>
        </Dialog>
    );
}
