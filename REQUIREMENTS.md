# Ulti Stats — Requirements

## 1. Overview

NOTE: not all of an ultimate frisbee game's mechanic will be available to start, we will add more features over time 

Ultimeter is an app used by ultimate frisbee players to track stats during games.
Over the course of a team's season, multiple tournaments can occur, and multiple games can occur in a tournament.
Individual games can also occur without being part of a tournament.

Ultimeter should support stat tracking across a game.
Ultimeter should support stat aggregating across multiple games in a tournament.
Ultimeter should support stat aggregating across multiple tournaments in a season.

A team can have as many players as the user decides.
A team can add players during an ongoing season.
A team can play in the mixed, open, or womens division.
In mixed division, a game's ruleset will be slightly different to include certain gender rules.

A game of ultimate frisbee will involve two teams, but it's only necessary to track our own team's stats.
A game of ultimate frisbee will be played up to 13, 15, 17, 19, or 21 points
A game will either end upon reaching the agreed upon cap for score, or the agreed upon cap for points

A game will consist of many points, each point will be played between two lines of 7 players each
The winner of a point will receive one point on the game's scoreboard
A point begins with a pull, where the defending team will 'kick off' the point, and the attacking team will 'field' the pull
A pull can be caught, landed, or go out of bounds
Over the course of a point, we want to track who receives the pull, who passes the frisbee to who, who scores. If there are turnovers, we want to track who throws an incompletion / who generates a turnover with their defense.
For each score, the assist is automatically assigned to the last thrower before the scorer
A turnover can be a block or interception, a throwaway, a drop, or an incompletion by the thrower

## 2. User Stories

As a user, I want to be able to create an ultimate team
As a user, I want to be able to add / remove players to / from this team
As a user, I want to be able to track a game played by this team

As a user, I want to be able to select which 7 players are on the field playing any given point in a game
As a user, I want to select who is pulling on a D point
As a user, I want to select who is fielding the pull on an O point
As a user, I want to select who generates a turnover on D
As a user, I want to select 'throwaway' if an unforced turnover occurs
As a user, I want to select who receives a pass on O
As a user, I want to select who scores on O

As a user, I want to know the current score during a live game

### 2.1 Teams

Create a team
Delete a team
Edit team info

### 2.2 Rosters

Add player to team
Remove player from team
Edit number of player on team

### 2.3 Games

Start new game
Select players on the line
Track half
Record final score

### 2.4 Live Stats

Log fielding a pull
Record pull state (caught, landed, or out of bounds)
Log pass
Log turnover
Record turnover type (block or interception, throwaway, drop, or incompletion by the thrower)
Log block
Log goal
Assign assist automatically to the last thrower before the goal

### 2.5 History

See stats table for a game
See stats table for a tournament (collection of games)
See stats table for a season

### 2.6 Export

Export game/tournament/season as csv

## 3. Data Model

Team -> Roster -> Player
     -> Season -> Tournament -> Game
     -> Season -> Game
Game -> Point -> Stat

A Stat records a pull with its state (caught, landed, or out of bounds), a pass, or a turnover with its type (block or interception, throwaway, drop, or incompletion by the thrower)
An assist is not stored, it is derived from the last pass before a goal

## 4. Non-Functional Requirements

### 4.1 Platform

IOS

### 4.2 Performance

Stat logging instant
Stat logging simple

### 4.3 Data

Offline only

### 4.4 Accessibility

None

## 5. Out of Scope

No cloud sync
No multiple devices for one game
No social features
No video
