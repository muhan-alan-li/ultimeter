# Ulti Stats

Use the PWA to record ultimate frisbee games.
Manage teams, add players, select lines, and record play.
Track scores, assists, blocks, substitutions, and halftime.
Undo live actions and correct completed point results.

## Run

Use Node.js 24 or later.
Run these commands from the repository root:

```sh
npm ci
npm run dev
```

Open the URL from Vite.
Use `http://localhost:5173` for local development with the default port.
Use HTTPS to access the app from another device.

## Build

Run these commands from the repository root:

```sh
npm run lint
npm run format:check
npm run build
npm run preview
```

Use `npm run lint:fix` to fix lint errors.
Use `npm run format` to format source and documentation.

Serve `dist/` through HTTPS for production.
Return `index.html` for app routes.
Use `public/_redirects` on compatible static hosts.
Use `public/_headers` on hosts that support header files.
Keep `sw.js` fresh and retain old asset files during updates.

## Install and Record

Load the production app once online.
Wait for the offline readiness message before offline play.
Use the browser install control.
On iOS, use Safari Share, then Add to Home Screen.

Keep game data in the same browser and app origin.
Save each action immediately to IndexedDB.
Resume saved game state after a reload or normal app restart.
Treat local records as temporary data.
Defer migration, backups, cloud storage, and long-term retention.

## Code

Read `AGENTS.md` before code changes.
Use this source structure:

```text
src/
  domain/        # Model interfaces, selectors, rules, commands
  storage/       # Repository contract, IndexedDB, live queries
  views/         # Pages, forms, React state, display functions
  app/           # Application object, reducers, React adapters, routes, errors
  styles/        # Layout and themes
public/          # Icons and host settings
```

Read `docs/ARCHITECTURE.md` for model and component duties.
Read `docs/BEHAVIOR.md` for action behavior and known limits.
Use `docs/ACCEPTANCE.md` for the remaining device checks.
Read `REQUIREMENTS.md` for later features.
