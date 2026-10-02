# Device Acceptance

Keep these checks incomplete until a person performs them.
Run them on physical devices and desktop browsers.

## Game Entry

- Complete offense and defense points.
- Record passes, drops, blocks, turnovers, goals, substitutions, and undo.
- Change caps, reach halftime, and finish games.
- Edit completed results and check the next point.
- End games with added final scores.
- Keep missing player data empty in added points.
- Remove roster members and preserve completed history.
- Repair open lines after roster changes.
- Reload during a game and resume saved state.

## Offline Use

- Load the production app once online.
- Wait for the offline readiness message.
- Complete a game offline.
- Reload a nested route offline.
- Launch the installed app offline.
- Check simultaneous tabs, repeated taps, and failed writes.
- Accept and defer updates without losing drafts or saved actions.

## Devices

- Check iOS Safari and its Home Screen app.
- Check Android Chrome.
- Check desktop Safari, Chrome, and Firefox.
- Check keyboard access and screen reader output.
- Check narrow layouts and storage failure messages.

## Release

- Select minimum browser versions after device checks.
- Record checks and known limits before release.
- Serve static assets through HTTPS.
- Return `index.html` for app routes.
- Keep old assets available during updates.
- Check the hosted app before release.

Defer migration, backups, cloud storage, and long-term retention.
Track later reports, seasons, player editing, and export in `REQUIREMENTS.md`.
