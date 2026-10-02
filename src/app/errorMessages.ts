import { AppError } from '../domain';

type Message = (details: Record<string, string | number>) => string;

const messages: Record<string, Message> = {
    notLive: () => 'The game is not live. This action is not allowed.',
    notScheduled: () => 'The game is not scheduled. This action is not allowed.',
    alreadyStarted: () => 'The game already started. This action is not allowed.',
    invalidAction: () => 'This action is not allowed in the current state.',
    noActivePoint: () => 'There is no active point.',
    multipleActivePoints: () => 'There is more than one active point.',
    detachedPoint: () => 'This point does not belong to this game.',
    detachedGame: () => 'This game does not belong to this team.',
    lineIncomplete: (details) =>
        `The line has ${details.current ?? 0} of ${details.required ?? 7} players. Add more players.`,
    lineFull: (details) => `The line already has ${details.required ?? 7} players.`,
    lineLocked: () => 'The line is locked. Press Sub to change it.',
    notOnLine: () => 'This player is not on the line.',
    notOnTeam: () => 'This player is not on the team.',
    missingPull: () => 'This point has no puller. Select a puller.',
    missingPickup: () => 'This point has no pickup. Select who picks up.',
    missingScorer: () => 'This point has no scorer. Select a scorer.',
    notHolder: () => 'Only the holder can score.',
    notFound: (details) => `${details.field ?? 'Record'} was not found.`,
    emptyName: (details) => `${details.field ?? 'Name'} cannot be empty.`,
    duplicateName: (details) => `A record named “${details.name ?? ''}” already exists.`,
    invalidTarget: (details) =>
        `Invalid target ${details.target ?? ''}. Choose a value from 1 to 21.`,
    invalidDate: () => 'Game date is invalid.',
    invalidScore: () => 'Invalid score. Scores must be whole numbers from zero to 99.',
    finalScoreBelowCurrent: () => 'Final score cannot be below the current score.',
    storageCorrupt: () => 'The local game data is damaged. Do not overwrite it.',
};

export function errorMessage(error: unknown): string {
    if (error instanceof AppError) {
        return messages[error.code]?.(error.details) ?? error.message;
    }
    if (error instanceof Error && error.message) return error.message;

    return 'The action failed. Please try again.';
}
