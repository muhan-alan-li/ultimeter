export function PlayHistory({
    events,
}: {
    events: Array<{ id: string; description: string; people: string }>;
}) {
    return (
        <section className="card stack">
            <h2>Play history</h2>
            <ol className="event-list">
                {events.map((event) => (
                    <li key={event.id}>
                        <span>{event.description}</span>
                        <span>{event.people}</span>
                    </li>
                ))}
            </ol>
        </section>
    );
}
