export class AppError extends Error {
    constructor(
        public readonly code: string,
        public readonly details: Record<string, string | number> = {},
    ) {
        super(code);
        this.name = 'AppError';
    }
}
