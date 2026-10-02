import {
    allowsPointAction,
    lineIsEditable as pointLineIsEditable,
    pointNeedsPrune,
} from '../../app/pointActions';
import { pointState, type PointState } from '../../app/pointState';
import type { PointAction } from '../../app/pointActions';
import {
    eventsForPoint,
    gameById,
    gameScore,
    lineForPoint,
    opponentById,
    playerById,
    pointForGame,
    rosterForTeam,
    teamById,
} from '../../domain';
import type { Game, ID, Player, PlayEvent, Point, Session } from '../../domain';

/** Calculate point display values from a session snapshot. */
export function pointDisplay(session: Session, gameId: ID, pointId: ID) {
    function player(id?: ID): Player | undefined {
        return playerById(session, id);
    }

    function describeEvent(event: PlayEvent): { id: ID; description: string; people: string } {
        const names = [
            event.playerId && player(event.playerId)?.name,
            event.relatedPlayerId && player(event.relatedPlayerId)?.name,
        ].filter((name): name is string => !!name);
        const description =
            event.kind === 'turnover'
                ? event.turnoverCause === 'throwaway'
                    ? 'Opponent turnover'
                    : 'Our turnover'
                : event.kind === 'score'
                  ? `${event.scoringTeam === 'us' ? teamName : opponentName} scored`
                  : event.kind === 'sub'
                    ? event.substitutionPhase === 'started'
                        ? 'Substitution started'
                        : 'Substitution completed'
                    : event.kind === 'pull'
                      ? 'Pull'
                      : event.kind === 'pickup'
                        ? 'Pickup'
                        : event.kind === 'pass'
                          ? event.isScoringPass
                              ? 'Scoring pass'
                              : 'Pass'
                          : event.kind === 'drop'
                            ? 'Drop'
                            : 'Block';

        return { id: event.id, description, people: names.join(' → ') };
    }

    function allowed(action: PointAction): boolean {
        return !!game && !!point && allowsPointAction(action, game, point, session);
    }

    function canToggle(player: Player): boolean {
        return allowed({ kind: 'toggleLine', playerId: player.id });
    }

    const game: Game | undefined = gameById(session, gameId);
    const point: Point | undefined = pointForGame(session, gameId, pointId);
    const state: PointState = point
        ? pointState(point, session.events)
        : { phase: 'none', hasPull: false, blockerIds: [], lineLocked: false };
    const roster: Player[] = game ? rosterForTeam(session, game.teamId) : [];
    const line: Player[] = point ? lineForPoint(session, point) : [];
    const holder: Player | undefined = player(state.holderId);
    const stage: 'scheduled' | 'defense' | 'looseDisc' | 'possession' | 'complete' =
        !point || point.status === 'scheduled'
            ? 'scheduled'
            : point.status === 'complete'
              ? 'complete'
              : state.phase === 'defense'
                ? 'defense'
                : state.phase === 'awaitingPickup' || !holder || !point.lineIds.includes(holder.id)
                  ? 'looseDisc'
                  : 'possession';
    const lineChoices: Player[] = stage === 'complete' ? line : roster;
    const lineRows: Array<{ player: Player; selected: boolean; canToggle: boolean }> =
        lineChoices.map((player) => ({
            player,
            selected: point?.lineIds.includes(player.id) ?? false,
            canToggle: canToggle(player),
        }));
    const startsOnDefense: boolean = point?.startingPosition === 'defense';
    const activePlayerRows: Array<{
        player: Player;
        isHolder: boolean;
        actions: Array<{
            action: PointAction;
            label: string;
            accessibilityLabel: string;
            primary: boolean;
            closesPoint: boolean;
        }>;
    }> = line.map((player) => {
        const isHolder = stage === 'possession' && player.id === state.holderId;
        const kinds: Array<'pull' | 'block' | 'pickup' | 'pass' | 'drop' | 'score'> =
            stage === 'scheduled' && startsOnDefense
                ? ['pull']
                : stage === 'defense'
                  ? ['block']
                  : stage === 'looseDisc'
                    ? ['pickup']
                    : stage === 'possession' && !isHolder
                      ? ['pass', 'drop', 'score']
                      : [];

        return {
            player,
            isHolder,
            actions: kinds.map((kind) => ({
                action: { kind, playerId: player.id },
                label: {
                    pull: 'Pull',
                    block: 'Block',
                    pickup: 'Pickup',
                    pass: 'Pass',
                    drop: 'Drop',
                    score: 'Goal',
                }[kind],
                accessibilityLabel:
                    kind === 'pass'
                        ? `Pass to ${player.name}`
                        : `${player.name} ${{ pull: 'pulls', block: 'blocks', pickup: 'picks up', drop: 'drops', score: 'scores' }[kind]}`,
                primary: kind === 'pull' || kind === 'pickup' || kind === 'score',
                closesPoint: kind === 'score',
            })),
        };
    });
    const puller: Player | undefined = player(state.pullerId);
    const scorer: Player | undefined = player(state.scorerId);
    const assist: Player | undefined = player(state.assistId);
    const blockers: Player[] = state.blockerIds
        .map((id) => player(id))
        .filter((player): player is Player => !!player);
    const teamName: string = game
        ? (teamById(session, game.teamId)?.name ?? 'Our team')
        : 'Our team';
    const opponentName: string = game
        ? (opponentById(session, game.opponentId)?.name ?? 'Opponent')
        : 'Opponent';
    const score: { us: number; them: number } = game
        ? gameScore(game.id, session)
        : { us: 0, them: 0 };
    const stageLabel: string = {
        scheduled: 'Scheduled',
        defense: 'Defense',
        looseDisc: 'Loose disc',
        possession: 'Possession',
        complete: 'Complete',
    }[stage];
    const title: string = point ? `Point ${point.number}` : 'Point';
    const isActive: boolean =
        stage === 'defense' || stage === 'looseDisc' || stage === 'possession';
    const lineCount: number = point?.lineIds.length ?? 0;
    const start = startsOnDefense ? 'Defense start' : 'Offense start';
    const summary = `${stageLabel} · ${start}${holder ? ` · Disc: ${holder.name}` : ''}`;
    const startedOnText = `Started on ${startsOnDefense ? 'defense' : 'offense'}`;
    const pullerText: string = startsOnDefense ? (puller?.name ?? 'Not set') : 'They pulled';
    const outcomes: Record<string, string> = {
        weHold: `${teamName} held`,
        weBreak: `${teamName} broke`,
        theyHold: `${opponentName} held`,
        theyBreak: `${opponentName} broke`,
    };
    const resultText = state.outcome
        ? (outcomes[state.outcome] ?? state.outcome)
        : state.scoredBy
          ? state.scoredBy === 'us'
              ? teamName
              : opponentName
          : 'No result yet';
    const lineIsEditable: boolean = !!point && pointLineIsEditable(point, session);
    const showLine: boolean = !isActive || lineIsEditable;
    const smallRoster: boolean = point?.status !== 'complete' && roster.length < 7;
    const lineIssueText = smallRoster
        ? `Roster has ${roster.length} players. Add players to the team to reach 7.`
        : isActive && lineCount !== 7
          ? `Line has ${lineCount} of 7. Complete the sub to continue.`
          : undefined;
    const canSub: boolean = allowed({ kind: 'sub' });
    const showSubButton: boolean = canSub && state.lineLocked;
    const needsPrune: boolean = !!point && pointNeedsPrune(point, session);
    const history = point ? eventsForPoint(session, point.id).map(describeEvent) : [];
    const canUndo: boolean = allowed({ kind: 'undo' });
    const canOpponentScore: boolean =
        stage === 'defense' && allowed({ kind: 'result', scoringTeam: 'them' });

    return {
        game,
        point,
        state,
        lineRows,
        activePlayerRows,
        holder,
        scorer,
        assist,
        blockers,
        teamName,
        opponentName,
        score,
        stage,
        stageLabel,
        title,
        startsOnDefense,
        lineCount,
        summary,
        startedOnText,
        pullerText,
        resultText,
        showLine,
        lineIssueText,
        showSubButton,
        needsPrune,
        history,
        canUndo,
        canOpponentScore,
    };
}
