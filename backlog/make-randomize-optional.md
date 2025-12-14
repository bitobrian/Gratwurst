
# Branch: make-randomize-optional

## Purpose

Make message selection deterministic *or* randomized based on a user setting.

Why this exists:
- Some players want consistent “signature” grats (always use the first message).
- Others want variety (pick a random message from the managed list).
- The addon already has a UI checkbox and a saved variable for this, but the runtime behavior does not currently line up with the intent.

## Current State (as of 1.8.0)

Relevant bits in the repo:
- Per-character saved variable exists: `GratwurstShouldRandomize` is listed in `SavedVariablesPerCharacter`.
- Config UI includes a checkbox labeled “Random message selection” and stores it in `GratwurstShouldRandomize`.
- Two message selection helpers exist:
	- `GetTopMessageFromList(author)` (first message)
	- `GetRandomMessageFromList(author)` (random index)

Behavior issues worth fixing in this branch:
- The send path checks `GratwurstMessage ~= ""` before sending. In 1.8.0, migration intentionally clears `GratwurstMessage` and moves users to `GratwurstMessages`, so this gate can prevent *any* sending after migration.
- The randomization toggle appears inverted in the send path: when `GratwurstShouldRandomize` is true it uses the “top message” function, and when false it uses the “random message” function.

## Desired Behavior

When an achievement event is handled and the addon decides it can grats:
- If `GratwurstShouldRandomize == true`:
	- Choose a message via `GetRandomMessageFromList(author)`.
- If `GratwurstShouldRandomize == false`:
	- Choose a message via `GetTopMessageFromList(author)`.

Also, the “can send” condition should be based on the current storage model:
- Send is allowed when there is at least one non-empty message in `GratwurstMessages`.
- Legacy `GratwurstMessage` should not be required for sending in 1.8.0+.

## Scope

In scope:
- Align runtime behavior with the checkbox + saved variable.
- Ensure migrated users (where `GratwurstMessage` is nil/empty) still send messages.
- Keep behavior per-character (matches `.toc` saved variable list).

Out of scope:
- Changing the message list UX (add/edit/delete/reorder) beyond what’s needed.
- Adding additional randomization strategies (e.g., “no repeats”, weighting).

## Acceptance Criteria

- With 3+ messages in the list and `GratwurstShouldRandomize` enabled, repeated triggers can produce different messages over time.
- With `GratwurstShouldRandomize` disabled, the addon always uses the first message in `GratwurstMessages`.
- The checkbox state persists across reloads/logouts (per-character).
- Users migrated to 1.8.0 (where `GratwurstMessage` is cleaned up) can still send grats.
- Debug flow (`/gw debug`) prints the same message selection behavior as the live send path.

## Implementation Notes

Expected code touchpoints:
- The send condition in the achievement handler should key off `GratwurstMessages` (and optionally guard against empty-string entries).
- Swap/fix the conditional that chooses between `GetTopMessageFromList` and `GetRandomMessageFromList`.

## Manual Test Plan

1. Set up 3 distinct messages via the UI.
2. Run `/gw debug` multiple times:
	 - With “Random message selection” checked, confirm message varies sometimes.
	 - With it unchecked, confirm the first message is always used.
3. (Optional) Verify migration scenario:
	 - Simulate an old install where `GratwurstMessage` exists, load 1.8.0, ensure messages migrate and sending still works.

