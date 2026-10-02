import type { ControllerDependencies } from './ports';
import { Observable } from '../app/Observable';

/** Handle user actions and notify views when interaction state changes. */
export abstract class Controller extends Observable {
    private dependencies?: ControllerDependencies;
    connect(dependencies: ControllerDependencies) {
        this.dependencies = dependencies;
    }

    protected get deps() {
        if (!this.dependencies) throw new Error('Connect the controller before use.');

        return this.dependencies;
    }

    get session() {
        return this.deps.session;
    }

    get busy() {
        return this.deps.busy;
    }
}
