/** Notify adapters when an object's state changes. */
export abstract class Observable {
    private revision = 0;
    private listeners = new Set<() => void>();

    protected changed() {
        this.revision++;
        this.listeners.forEach((listener) => listener());
    }

    subscribe = (listener: () => void) => {
        this.listeners.add(listener);

        return () => {
            this.listeners.delete(listener);
        };
    };

    getRevision = () => this.revision;
}
