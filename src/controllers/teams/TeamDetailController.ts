import { Controller } from '../Controller';
import { type Game, gameById, type Gender, rosterForTeam, type Team, teamById } from '../../domain';
import {
    gameOpponent,
    gameResult,
    type GameSection,
    gameSectionsForTeam,
} from '../games/gamePresentation';

export class TeamDetailController extends Controller {
    constructor(readonly teamId: string) {
        super();
    }

    dialog: 'edit' | 'players' | 'game' | 'removePlayers' | undefined;
    private removingGameId: string | null = null;
    get removingGame(): Game | undefined {
        const game = this.removingGameId ? gameById(this.session, this.removingGameId) : undefined;

        return this.team && game?.teamId === this.teamId ? game : undefined;
    }

    openDialog(dialog: 'edit' | 'players' | 'game' | 'removePlayers') {
        this.dialog = dialog;
        this.changed();
    }

    closeDialog() {
        this.dialog = undefined;
        this.changed();
    }

    selectGameRemoval(gameId: string | null) {
        this.removingGameId = gameId;
        this.changed();
    }

    async confirmGameRemoval(): Promise<void> {
        const game = this.removingGame;
        if (game && (await this.deleteGame(game.id))) this.selectGameRemoval(null);
    }

    async confirmPlayerRemoval(): Promise<void> {
        if (await this.deleteSelectedPlayers()) this.closeDialog();
    }

    private rosterPageIndex = 0;
    private selectedPlayerIds = new Set<string>();
    selectingPlayers = false;
    readonly rosterPageSize = 10;

    get rosterPageCount(): number {
        return Math.max(1, Math.ceil(this.roster.length / this.rosterPageSize));
    }

    get rosterPage(): number {
        return Math.min(this.rosterPageIndex, this.rosterPageCount - 1);
    }

    get rosterPagePlayers() {
        return this.roster.slice(
            this.rosterPage * this.rosterPageSize,
            (this.rosterPage + 1) * this.rosterPageSize,
        );
    }

    get rosterRows() {
        return this.rosterPagePlayers.map((player) => ({
            player,
            selected: this.selectedPlayerIds.has(player.id),
        }));
    }

    get selectedPlayers() {
        return this.roster.filter((player) => this.selectedPlayerIds.has(player.id));
    }

    get selectedCount(): number {
        return this.selectedPlayers.length;
    }

    get allPlayersSelected(): boolean {
        return this.roster.length > 0 && this.selectedCount === this.roster.length;
    }

    get canPreviousPage(): boolean {
        return this.rosterPage > 0;
    }

    get canNextPage(): boolean {
        return this.rosterPage + 1 < this.rosterPageCount;
    }

    get rosterRangeText(): string {
        const start = this.rosterPage * this.rosterPageSize;

        return `${start + 1}–${Math.min(start + this.rosterPageSize, this.roster.length)} of ${this.roster.length} players`;
    }

    changeRosterPage(direction: -1 | 1) {
        this.rosterPageIndex = Math.max(
            0,
            Math.min(this.rosterPage + direction, this.rosterPageCount - 1),
        );
        this.changed();
    }

    setSelectingPlayers(selecting: boolean) {
        this.selectingPlayers = selecting;
        this.selectedPlayerIds.clear();
        this.changed();
    }

    togglePlayerSelection(playerId: string) {
        if (
            !this.selectingPlayers ||
            this.busy ||
            !this.roster.some((player) => player.id === playerId)
        )
            return;
        if (this.selectedPlayerIds.has(playerId)) this.selectedPlayerIds.delete(playerId);
        else this.selectedPlayerIds.add(playerId);
        this.changed();
    }

    toggleAllPlayers() {
        if (!this.selectingPlayers || this.busy) return;
        this.selectedPlayerIds = this.allPlayersSelected
            ? new Set()
            : new Set(this.roster.map((player) => player.id));
        this.changed();
    }

    get team(): Team | undefined {
        return teamById(this.session, this.teamId);
    }

    get roster() {
        return rosterForTeam(this.session, this.teamId);
    }

    get sections(): GameSection[] {
        return gameSectionsForTeam(this.teamId, this.session);
    }

    get gameSections() {
        return this.sections.map((section) => ({
            ...section,
            games: section.games.map((game) => ({ id: game.id, ...this.gameRow(game) })),
        }));
    }

    genderLabel(gender: Gender): string {
        switch (gender) {
            case 'male':
                return 'Male';
            case 'female':
                return 'Female';
            case 'nonBinary':
                return 'Non-binary';
        }
    }

    get divisionLabel(): string {
        switch (this.team?.division) {
            case 'open':
                return 'Open';
            case 'womens':
                return 'Women’s';
            case 'mixed':
                return 'Mixed';
            default:
                return '';
        }
    }

    gameRow(game: Game) {
        return {
            opponent: gameOpponent(game, this.session),
            dateText: new Date(game.date).toLocaleDateString(),
            isLive: game.status === 'live',
            result: gameResult(game, this.session),
        };
    }

    async deleteGame(gameId: string): Promise<boolean> {
        return (
            (await this.deps.run(() =>
                this.deps.repository.deleteGame(gameId).then(() => true),
            )) === true
        );
    }

    async deleteSelectedPlayers(): Promise<boolean> {
        const ids = this.selectedPlayers.map((player) => player.id);
        if (!ids.length || this.busy) return false;
        const saved =
            (await this.deps.run(() =>
                this.deps.repository.removePlayers(this.teamId, ids).then(() => true),
            )) === true;
        if (saved) this.setSelectingPlayers(false);

        return saved;
    }

    async addPlayers(names: string[], gender: Gender): Promise<boolean> {
        return (
            (await this.deps.run(() =>
                this.deps.repository.addPlayers(this.teamId, names, gender).then(() => true),
            )) === true
        );
    }
}
