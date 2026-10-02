import type { Session } from '../domain';
import type { RepositoryPort } from '../storage/Repository';

export interface ControllerDependencies {
    session: Session;
    repository: RepositoryPort;
    busy: boolean;
    dirty?: boolean;
    run: <T>(action: () => Promise<T>) => Promise<T | undefined>;
}
