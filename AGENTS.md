# Ulti Stats

Build the TypeScript PWA at the repository root.
Use Node.js 24 or later.

## Structure

- Use `src/domain/` for model interfaces, selectors, rules, and domain commands.
- Use `src/storage/` for repository interfaces, IndexedDB, and live queries.
- Use `src/views/` for pages, forms, React state, and display functions.
- Use `src/views/shared/` for shared controls.
- Use `src/app/` for the application object, reducers, React adapters, errors, and routes.
- Use `src/main.tsx` to create and inject dependencies.

## Rules

Describe model data with TypeScript interfaces.
Group related model interfaces in one file.
Keep related utility types and pure functions in that file.
Use IDs to connect teams, games, points, and events.
Use pure selectors to read parent and child records.
Use pure functions for domain rules.
Store plain data without model class instances.
Keep React and database imports outside the domain.
Keep all local storage access in `src/storage/`.
Read live data through the shared query adapter.
Inject repositories through the application object.
Use domain commands or application reducers to change related records.
Commit one user action in one transaction.
Keep the current database name, schema, and record format.
Use four spaces for each indentation level.
Keep one blank line between imports and code.
Use explicit type imports and consistent array types.
Compose pages from reusable components with values and callbacks.
Keep user actions and draft state in React components.
Use React hooks directly in views.
Use pure functions for display values.
Use shared error alerts for failed actions.
Store game sessions locally.
Defer migration and long-term storage design.

## Check

Run `npm run lint`, `npm run format:check`, and `npm run build` from the repository root.
Run `npm run lint:fix` to fix lint errors.
Run `npm run format` to format files.
Fix every lint, format, and build error.
Do not run automated tests or simulators.
Use `docs/ACCEPTANCE.md` for manual device checks.

## Documentation

Write all Markdown files in ASD-STE100 Simplified Technical English.
Use approved words, active voice, and imperative sentences.
Keep each sentence under 20 words.
Keep paragraphs and documents short.
Read `docs/ARCHITECTURE.md` for code duties.
Read `docs/BEHAVIOR.md` for action behavior.
