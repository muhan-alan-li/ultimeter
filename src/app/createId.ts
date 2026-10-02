import { v4 as uuidv4 } from 'uuid';
import type { ID } from '../domain/Session';

export function createId(): ID {
    return uuidv4();
}
