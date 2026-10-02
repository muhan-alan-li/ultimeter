import type { FormEvent } from 'react';
import { useApp, useDirty } from '../../app/context';
import { useController } from '../../app/useController';
import { Dialog } from '../shared';
import type { Division, Gender } from '../../domain';
import { PlayerFormController } from '../../controllers/players/PlayerFormController';

export function PlayerForm({
    teamId,
    division,
    onClose,
}: {
    teamId: string;
    division: Division;
    onClose: () => void;
}) {
    const controller = useController(() => new PlayerFormController(teamId, division));
    const { busy } = useApp();
    useDirty(controller.dirty);

    async function submit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (await controller.save()) onClose();
    }

    return (
        <Dialog title="Add players" onClose={onClose}>
            <form className="stack" onSubmit={submit}>
                <label className="field">
                    Player names
                    <textarea
                        autoFocus
                        rows={6}
                        value={controller.names}
                        onChange={(event) => controller.setNames(event.target.value)}
                        placeholder="Enter one name per line"
                    />
                </label>
                <label className="field">
                    Gender
                    <select
                        value={controller.gender}
                        onChange={(event) => controller.setGender(event.target.value as Gender)}
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
                        disabled={busy || !controller.cleanNames.length}
                    >
                        Add {controller.cleanNames.length || 'players'}
                    </button>
                </div>
            </form>
        </Dialog>
    );
}
