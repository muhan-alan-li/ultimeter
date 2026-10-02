import {
    allowsPointAction,
    eventsForPoint,
    gameById,
    gameScore,
    lineForPoint,
    lineIsEditable,
    opponentById,
    playerById,
    pointForGame,
    pointNeedsPrune,
    pointState,
    rosterForTeam,
    teamById,
} from '../../domain';
import { Controller } from '../Controller';
import type { Game, ID, Player, PlayEvent, Point, PointAction, PointState } from '../../domain';

export class PointDetailController extends Controller {
    constructor(
        readonly gameId: ID,
        readonly pointId: ID,
    ) {
        super();
    }

    detailsOpen = false;
    toggleDetails() {
        this.detailsOpen = !this.detailsOpen;
        this.changed();
    }

    get game(): Game | undefined {
        return gameById(this.session, this.gameId);
    }

    get point(): Point | undefined {
        return pointForGame(this.session, this.gameId, this.pointId);
    }

    get available(): boolean {
        return !!this.game && !!this.point;
    }

    get state(): PointState {
        const point = this.point;

        return point
            ? pointState(point, this.session.events)
            : { phase: 'none', hasPull: false, blockerIds: [], lineLocked: false };
    }

    get roster(): Player[] {
        const game = this.game;

        return game ? rosterForTeam(this.session, game.teamId) : [];
    }

    get line(): Player[] {
        const point = this.point;

        return point ? lineForPoint(this.session, point) : [];
    }

    get lineChoices(): Player[] {
        return this.stage === 'complete' ? this.line : this.roster;
    }

    get lineRows(): Array<{ player: Player; selected: boolean; canToggle: boolean }> {
        return this.lineChoices.map((player) => ({
            player,
            selected: this.point?.lineIds.includes(player.id) ?? false,
            canToggle: this.canToggle(player),
        }));
    }

    get activePlayerRows(): Array<{
        player: Player;
        isHolder: boolean;
        actions: Array<{
            action: PointAction;
            label: string;
            accessibilityLabel: string;
            primary: boolean;
            closesPoint: boolean;
        }>;
    }> {
        return this.line.map((player) => {
            const isHolder = this.stage === 'possession' && player.id === this.state.holderId;
            const kinds: Array<'pull' | 'block' | 'pickup' | 'pass' | 'drop' | 'score'> =
                this.stage === 'scheduled' && this.startsOnDefense
                    ? ['pull']
                    : this.stage === 'defense'
                      ? ['block']
                      : this.stage === 'looseDisc'
                        ? ['pickup']
                        : this.stage === 'possession' && !isHolder
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
    }

    get holder(): Player | undefined {
        return this.player(this.state.holderId);
    }

    get puller(): Player | undefined {
        return this.player(this.state.pullerId);
    }

    get scorer(): Player | undefined {
        return this.player(this.state.scorerId);
    }

    get assist(): Player | undefined {
        return this.player(this.state.assistId);
    }

    get blockers(): Player[] {
        return this.state.blockerIds
            .map((id) => this.player(id))
            .filter((player): player is Player => !!player);
    }

    get teamName(): string {
        const game = this.game;

        return game ? (teamById(this.session, game.teamId)?.name ?? 'Our team') : 'Our team';
    }

    get opponentName(): string {
        const game = this.game;

        return game
            ? (opponentById(this.session, game.opponentId)?.name ?? 'Opponent')
            : 'Opponent';
    }

    get score(): { us: number; them: number } {
        const game = this.game;

        return game ? gameScore(game.id, this.session) : { us: 0, them: 0 };
    }

    get stage(): 'scheduled' | 'defense' | 'looseDisc' | 'possession' | 'complete' {
        const point = this.point;
        if (!point || point.status === 'scheduled') return 'scheduled';
        if (point.status === 'complete') return 'complete';
        if (this.state.phase === 'defense') return 'defense';
        if (this.state.phase === 'awaitingPickup') return 'looseDisc';

        return !this.holder || !point.lineIds.includes(this.holder.id) ? 'looseDisc' : 'possession';
    }

    get stageLabel(): string {
        return {
            scheduled: 'Scheduled',
            defense: 'Defense',
            looseDisc: 'Loose disc',
            possession: 'Possession',
            complete: 'Complete',
        }[this.stage];
    }

    get title(): string {
        return this.point ? `Point ${this.point.number}` : 'Point';
    }

    get isActive(): boolean {
        return (
            this.stage === 'defense' || this.stage === 'looseDisc' || this.stage === 'possession'
        );
    }

    get startsOnDefense(): boolean {
        return this.point?.startingPosition === 'defense';
    }

    get lineCount(): number {
        return this.point?.lineIds.length ?? 0;
    }

    get summary(): string {
        const start = this.startsOnDefense ? 'Defense start' : 'Offense start';

        return `${this.stageLabel} · ${start}${this.holder ? ` · Disc: ${this.holder.name}` : ''}`;
    }

    get startedOnText(): string {
        return `Started on ${this.startsOnDefense ? 'defense' : 'offense'}`;
    }

    get pullerText(): string {
        return this.startsOnDefense ? (this.puller?.name ?? 'Not set') : 'They pulled';
    }

    get resultText(): string {
        if (this.state.outcome)
            return (
                (
                    {
                        weHold: `${this.teamName} held`,
                        weBreak: `${this.teamName} broke`,
                        theyHold: `${this.opponentName} held`,
                        theyBreak: `${this.opponentName} broke`,
                    } as Record<string, string>
                )[this.state.outcome] ?? this.state.outcome
            );
        if (this.state.scoredBy)
            return this.state.scoredBy === 'us' ? this.teamName : this.opponentName;

        return 'No result yet';
    }

    get lineIsEditable(): boolean {
        const point = this.point;

        return !!point && lineIsEditable(point, this.session);
    }

    get showLine(): boolean {
        return !this.isActive || this.lineIsEditable;
    }

    get smallRoster(): boolean {
        return this.point?.status !== 'complete' && this.roster.length < 7;
    }

    get lineIssueText(): string | undefined {
        if (this.smallRoster)
            return `Roster has ${this.roster.length} players. Add players to the team to reach 7.`;
        if (this.isActive && this.lineCount !== 7)
            return `Line has ${this.lineCount} of 7. Complete the sub to continue.`;

        return undefined;
    }

    get showSubButton(): boolean {
        return this.canSub && this.state.lineLocked;
    }

    get needsPrune(): boolean {
        const point = this.point;

        return !!point && pointNeedsPrune(point, this.session);
    }

    get history(): Array<{ id: ID; description: string; people: string }> {
        const point = this.point;
        if (!point) return [];

        return eventsForPoint(this.session, point.id).map((event) => this.describeEvent(event));
    }

    get canUndo(): boolean {
        return this.allowed({ kind: 'undo' });
    }

    get canSub(): boolean {
        return this.allowed({ kind: 'sub' });
    }

    get canOpponentScore(): boolean {
        return this.stage === 'defense' && this.allowed({ kind: 'result', scoringTeam: 'them' });
    }

    canToggle(player: Player): boolean {
        return this.allowed({ kind: 'toggleLine', playerId: player.id });
    }

    can(action: PointAction): boolean {
        return this.allowed(action);
    }

    async act(action: PointAction): Promise<boolean> {
        const game = this.game;
        const point = this.point;
        if (!game || !point) return false;
        const result = await this.deps.run(async () => {
            await this.deps.repository.pointAction(game.id, point.id, action);

            return true;
        });

        return result === true;
    }

    async prune(): Promise<boolean> {
        if (!this.needsPrune) return false;

        return this.act({ kind: 'pruneLine' });
    }

    private player(id?: ID): Player | undefined {
        return playerById(this.session, id);
    }

    private describeEvent(event: PlayEvent): { id: ID; description: string; people: string } {
        const names = [
            event.playerId && this.player(event.playerId)?.name,
            event.relatedPlayerId && this.player(event.relatedPlayerId)?.name,
        ].filter((name): name is string => !!name);
        const description =
            event.kind === 'turnover'
                ? event.turnoverCause === 'throwaway'
                    ? 'Opponent turnover'
                    : 'Our turnover'
                : event.kind === 'score'
                  ? `${event.scoringTeam === 'us' ? this.teamName : this.opponentName} scored`
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

    private allowed(action: PointAction): boolean {
        const game = this.game;
        const point = this.point;

        return !!game && !!point && allowsPointAction(action, game, point, this.session);
    }
}
