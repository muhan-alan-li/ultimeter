import type { FormEvent } from 'react';
import { useApp, useDirty } from '../../app/context';
import { useController } from '../../app/useController';
import { Dialog } from '../shared';
import type { Division, Team } from '../../domain';
import { TeamFormController } from '../../controllers/teams/TeamFormController';

const divisions: Array<{ value: Division; label: string }> = [
    { value: 'open', label: 'Open' },
    { value: 'womens', label: 'Women’s' },
    { value: 'mixed', label: 'Mixed' },
];

export function TeamForm({ team, onClose }: { team: Team | null; onClose: () => void }) {
    const controller = useController(() => new TeamFormController(team));
    const { busy } = useApp();
    useDirty(controller.dirty);

    async function submit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (await controller.save()) onClose();
    }

    return (
        <Dialog title={team ? 'Edit team' : 'New team'} onClose={onClose}>
            <form className="stack" onSubmit={submit}>
                <label className="field">
                    Team name
                    <input
                        autoFocus
                        required
                        value={controller.draft.name}
                        aria-invalid={controller.duplicateName}
                        aria-describedby={controller.duplicateName ? 'team-name-error' : undefined}
                        ref={(input) =>
                            input?.setCustomValidity(
                                controller.duplicateName
                                    ? 'A team with this name already exists.'
                                    : '',
                            )
                        }
                        onChange={(event) => controller.setName(event.target.value)}
                    />
                </label>
                {controller.duplicateName && (
                    <p id="team-name-error" className="error" role="status">
                        A team with this name already exists.
                    </p>
                )}
                <label className="field">
                    Division
                    <select
                        value={controller.draft.division}
                        onChange={(event) => controller.setDivision(event.target.value as Division)}
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
                    <button
                        type="submit"
                        className="button primary"
                        disabled={busy || !controller.valid}
                    >
                        Save team
                    </button>
                </div>
            </form>
        </Dialog>
    );
}
