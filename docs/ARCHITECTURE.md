# App Structure

Describe domain data with TypeScript interfaces.
Use React components for view composition.

## Models

Keep each model interface in `src/domain/`.
Use `Session` for the current local data.
Use `Team`, `Player`, `Game`, `Point`, and `PlayEvent` for stored records.
Use `Opponent`, `Tournament`, and `Halftime` for related records.
Keep IDs and domain unions in `src/domain/types.ts`.
Connect parent and child records with IDs.
Store plain objects and arrays.

Use this relationship map:

```text
Session
  Team
    Game
      Point
        PlayEvent
```

Keep selectors in `src/domain/selectors.ts`.
Use selectors to find records and read sorted child lists.
Keep pure rules in `src/domain/rules.ts`.
Pass model values and session data to rules.
Keep derived display values outside model interfaces.

Use `SessionCommands` to change related records.
Inject ID and time sources through `CommandSource` when needed.
Keep shared domain errors in `src/domain/AppError.ts`.

## Storage

Implement `RepositoryPort` with `SessionRepository`.
Run commands inside one IndexedDB transaction.
Write the session once for each user action.
Keep the database name, schema, and record format.
Use `sessionQuery` to observe saved changes.
Keep database imports inside `src/storage/`.

## Application

Create the repository and query adapter in `src/main.tsx`.
Inject both into `Application`.
Use `Application` to own session data, the save lock, draft status, and shared errors.
Read current session data directly.
Connect controllers through `useController`.
Keep React subscriptions in app adapters.
Keep route definitions in `src/app/routes.tsx`.

## Controllers

Keep screen actions and draft state in `src/controllers/`.
Read current session data through the application.
Use shared selectors for related records.
Use pure functions for domain rules.
Use repository methods for saved actions.
Keep derived display values in controllers.
Keep React and database imports outside controllers.

## Views

Keep pages, forms, and lists in `src/views/`.
Group views by team, player, game, or point.
Keep shared controls in `src/views/shared/`.
Compose pages from reusable components.
Pass values and callbacks to reusable components.
Keep browser event setup and cleanup in React effects.
Keep navigation in pages.
