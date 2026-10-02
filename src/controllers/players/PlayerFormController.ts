import { Controller } from '../Controller';
import type { Division, Gender } from '../../domain';

export function playerNamesFromLines(input: string): string[] {
    return input
        .split(/\r?\n/)
        .map((name) => name.trim())
        .filter(Boolean);
}

export function defaultGenderForDivision(division: Division): Gender {
    if (division === 'open') return 'male';
    if (division === 'womens') return 'female';

    return 'nonBinary';
}

export class PlayerFormController extends Controller {
    names = '';
    gender: Gender;
    private readonly initialGender: Gender;

    constructor(
        readonly teamId: string,
        division: Division,
    ) {
        super();
        this.gender = defaultGenderForDivision(division);
        this.initialGender = this.gender;
    }

    get cleanNames(): string[] {
        return playerNamesFromLines(this.names);
    }

    get dirty(): boolean {
        return this.names.trim().length > 0 || this.gender !== this.initialGender;
    }

    setNames(names: string) {
        this.names = names;
        this.changed();
    }

    setGender(gender: Gender) {
        this.gender = gender;
        this.changed();
    }

    async save(): Promise<boolean> {
        if (!this.cleanNames.length) return false;

        return (
            (await this.deps.run(() =>
                this.deps.repository
                    .addPlayers(this.teamId, this.cleanNames, this.gender)
                    .then(() => true),
            )) === true
        );
    }
}
