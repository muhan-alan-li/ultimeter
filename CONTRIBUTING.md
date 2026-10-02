# Contribute to Ulti Stats

Read `AGENTS.md` and `docs/ARCHITECTURE.md` before changes.
Use Node.js 24 or later.
Run `npm ci` from the repository root.
Start development with `npm run dev`.

## Change Code

Use four spaces for each indentation level.
Keep one blank line between imports and code.
Use explicit type imports.
Use model interfaces for data.
Use pure selectors for child records.
Keep domain rules in pure functions.
Use domain commands or application reducers to change related records.
Keep storage behind `RepositoryPort`.
Keep actions and draft state in React components.
Use React hooks directly in views.
Use pure functions for display values.
Compose React pages from reusable components.
Pass values and callbacks to shared components.
Commit one action in one database transaction.
Keep the local database name and record format.
Keep migration and long-term storage outside the current scope.

## Check Changes

Run `npm run lint`, `npm run format:check`, and `npm run build` from the repository root.
Run `npm run lint:fix` to fix lint errors.
Run `npm run format` to format files.
Do not run automated tests or simulators.
Use `docs/ACCEPTANCE.md` for device review.
Record any incomplete checks.

## Submit Changes

Use a branch for each change.
Describe user behavior and relevant checks in the pull request.
Use a commit prefix such as `feat:`, `fix:`, or `docs:`.
Keep documentation concise and use Simplified Technical English.
