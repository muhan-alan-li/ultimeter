# PWA behavior

## Storage

Keep the current session snapshot in one IndexedDB row.

Commit each action in one transaction.

Read data without a write transaction.

Return an empty snapshot when no row exists.

Create the session row with the first saved action.

Reject damaged data. Do not replace it with an empty snapshot.

## Behavior matrix

| Command         | Behavior                                                                                       |
| --------------- | ---------------------------------------------------------------------------------------------- |
| Save a team     | Trim its name and reject a duplicate name.                                                     |
| Add players     | Trim names and skip blank entries.                                                             |
| Remove a player | Remove the player from that team's roster. Keep the player record.                             |
| Save a game     | Reuse opponents and tournaments by name. Keep setup fixed after play starts.                   |
| Start a game    | Freeze the half target and create point one.                                                   |
| Record a score  | Complete the point and update the score. Add halftime and the next point unless the game ends. |
| Edit a result   | Change the point winner and update the open point or game status.                              |
| End a game      | Remove open points and add missing score points.                                               |
| Delete a team   | Delete its games, points, events, and halftime records. Keep player records.                   |

## Known behavior

Require seven players on the line before recording a defensive pull.

Move the recorded holder to the incoming player when a substitution removes the holder.

Create final-score points for our team first, then create opponent points.
