# Interface Model Refactor

1. Describe stored models with TypeScript interfaces.
2. Keep each model interface in its own file.
3. Remove model classes and record wrappers.
4. Keep parent and child lookups in shared selectors.
5. Keep game and point decisions in pure functions.
6. Read plain session data in controllers.
7. Remove the cached object graph from the application.
8. Keep the database name, schema, and record format.
9. Keep the web project at the repository root.
10. Use lint rules to enforce interface models.
11. Run lint, format checks, and build.
12. Do not run tests or simulators.

## Check

Keep manual device checks incomplete.
Use `docs/ACCEPTANCE.md` to complete device checks.
