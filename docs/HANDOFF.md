# Agent Handoff Protocol

A lightweight checklist so any agent can pick up work and continue smoothly.

## Read First
- `docs/STATUS.md` — current snapshot and Next Steps
- `docs/ARCHITECTURE.md` — system + flows
- `contracts/scripts/verify-e2e.lua` — end-to-end USDA → TIM3 driver
- `docs/PIDs.md` — current PIDs for TEST/PROD (keep updated)

## Make Changes
- Keep PR-sized commits with clear messages: `type(scope): summary`
- Prefer small, reversible steps; avoid broad refactors without need
- Do not persist secret PIDs/keys in code; use `docs/PIDs.md`

## Verify
- Inside AOS:
  - `aos --load contracts/verify/verify-test-processes.lua`
  - `aos --load contracts/scripts/verify-e2e.lua`

## Handoff (End of Session)
- Update `docs/STATUS.md` (What works now + Next Steps)
- Append `docs/IMPLEMENTATION_LOG.md` with bullets + commit SHA
- If work remains, open a GitHub Issue with a 2–3 bullet plan
- Link the issue in STATUS “Next Steps” if it’s the next action

## PID Hygiene
- Record current PIDs in `docs/PIDs.md` under the correct environment
- Update PIDs in:
  - `contracts/scripts/configure-integration.lua`
  - `contracts/scripts/verify-e2e.lua`
  - `contracts/verify/verify-test-processes.lua`
- Avoid hardcoding PIDs in other sources
