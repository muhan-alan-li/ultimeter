import { useState, useSyncExternalStore } from 'react';
import { useApp } from './context';
import type { Controller } from '../controllers/Controller';

export function useController<T extends Controller>(create: () => T): T {
    const dependencies = useApp();
    const [controller] = useState(create);
    controller.connect(dependencies);
    useSyncExternalStore(controller.subscribe, controller.getRevision);

    return controller;
}
