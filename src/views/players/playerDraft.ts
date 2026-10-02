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
