import type { Gender, Team } from '../../domain';

export function divisionLabel(division: Team['division']): string {
    switch (division) {
        case 'open':
            return 'Open';
        case 'womens':
            return 'Women’s';
        case 'mixed':
            return 'Mixed';
    }
}

export function genderLabel(gender: Gender): string {
    return { male: 'Male', female: 'Female', nonBinary: 'Non-binary' }[gender];
}
