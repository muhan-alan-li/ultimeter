# Arch Review

## Findings

Observe that ViewModels hold no state.
Remove stateless ViewModels from simple screens.
Bind views to models with @Query and @Bindable.
Stop passing ModelContext through view init.

Observe that three layers compute point state.
Move phase logic to pure domain functions.
Keep views free of business guards.
Test folds without a container.

Observe that features depend on each other.
Merge Game, Point, Player, Stat into one domain.
Stop isolating code by folder only.
Use protocols for store access.

Observe that each ViewModel saves directly.
Move all writes to GameStore and PointStore.
Make multi-step writes atomic in one save.
Roll back context on all errors.

Fix schema to include Stat in app.
Add Stat to all preview containers.
Delete duplicate save and alert code.
Use one error type and one alert modifier.

## Recommendation

Use SwiftUI with SwiftData directly.
Keep reads in views through live models.
Keep writes in stores behind protocols.
Keep domain logic pure and testable.

Delete TeamList, GameList, and roster ViewModels.
Keep GameService and PointService only.
Inject stores through environment, not init.
Update AGENTS.md to enforce this model.

## Second Review

I read the full codebase. I agree with the main findings. I found two wording errors. The recommendation is sound.

The review says "ViewModels hold no state". That claim is too broad. TeamFormViewModel, GameFormViewModel, and PlayerFormViewModel hold form state. They bind to text fields and pickers. Delete only the stateless view models.

The review says "Keep GameService and PointService". These services do not exist in the code. Write "Create", not "Keep".

The most serious finding is the missing Stat model. The app schema lists seven models. Stat is not one of them. Stat is related to Point and Player. SwiftData needs every related model in the schema. Every preview container omits Stat too. Fix the schema first.

The atomicity finding is correct and important. The scoreForUs method saves two times. recordPass saves once. completeActivePoint saves again. A failure in the second save leaves the pass on disk. context.rollback() does not undo saved data. Make the full score one save.

Three layers compute point state. The review is right. Point computes phase and holder. PointDetailView computes canScore and needsPickup. PointDetailViewModel repeats the guards. GameDetailViewModel and PointDetailViewModel both compute sideForNextPoint. Move these folds to pure functions. Test them without a container.

The feature folders do not isolate code. Team depends on Player and Game. Game depends on Point. Views depend on other views. TeamDetailView embeds GameListView. GameDetailView embeds PointListView. The folders split one domain by type only. Merge the domain. Use protocols for store access.

The save and alert code repeats. Nine view models repeat the same save method. GameFormViewModel saves the context inline. Eight views use the same alert binding. Use one error type and one alert modifier.

I agree with the recommendation. Reads stay in views through live models. Writes go to stores behind protocols. Domain logic stays pure. Inject stores through the environment, not init.
