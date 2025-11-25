Reputation Decay Smart Contract

Overview

The Reputation Decay Contract introduces a time-based governance reputation system designed to prevent perpetual elites within decentralized communities. Reputation decays automatically over time based on customizable decay parameters, ensuring that influence must be continuously earned.

This mechanism is useful for DAOs, contributor programs, decentralized governance, and systems where long-term fairness and active participation are important.

Key Features
✅ Automatic Time-Based Reputation Decay

Reputation decays at a fixed rate defined in basis points (e.g., 50 = 0.5%).

Decay is applied every N blocks (default: every 100 blocks).

Reduces governance stagnation by ensuring inactive users gradually lose influence.

✅ Per-User Reputation Tracking

The contract tracks:

Reputation value

Last update block

Decay is applied lazily when:

A user earns reputation

Someone calls update-reputation

Someone queries get-reputation

✅ Admin-Configurable Parameters

The contract owner can update:

Decay rate (0–100%)

Decay interval (minimum 1 block)

✅ Reputation Governance Checks

Includes a simple has-governance-power read-only function that checks if a user meets a configured threshold.

How It Works
1. Earning Reputation

Users earn reputation via:

(earn-reputation u100)


Before adding new reputation, the contract:

Applies decay based on blocks elapsed

Updates reputation and total system reputation

2. Automatic Decay Calculation

Decay occurs in discrete periods:

decay-periods = blocks-elapsed / decay-interval


Reputation is reduced by:

decay-amount = current-reputation * (decay-rate/10000) * periods


This ensures:

Decay only occurs after a full interval

Heavy inactivity results in larger reductions

3. Read-Only Reputation Access

To fetch the up-to-date (decayed) reputation:

(get-reputation user)


To fetch the raw stored data:

(get-reputation-data user)

Contract API Reference
Public Functions
Function	Purpose
(earn-reputation amount)	Adds reputation after applying decay
(update-reputation user)	Manually updates a user's decayed reputation
(set-decay-rate new-rate)	Owner-only: sets decay rate (in basis points)
(set-decay-interval new-interval)	Owner-only: sets number of blocks per decay cycle
Read-Only Functions
Function	Description
(get-reputation user)	Returns reputation with decay applied
(get-reputation-data user)	Returns raw stored reputation + last block
(get-total-reputation)	Returns total reputation in the system
(get-decay-rate)	Returns current decay rate
(get-decay-interval)	Returns decay interval
(has-governance-power user threshold)	Returns true if user meets threshold
Error Reference
Error	Code	Condition
err-owner-only	100	Caller is not contract owner
err-invalid-amount	101	Invalid reputation amount or interval
err-no-reputation	102	User has no stored reputation
err-invalid-decay-rate	103	Decay rate > 100%
Design Philosophy

This contract is inspired by principles of:

Dynamic governance — active contributors maintain influence.

Anti-whale control — large holders lose power without continued participation.

Fairness over time — no permanent elites.

It provides an automated and configurable mechanism for healthy governance evolution.

Security Considerations

Only the contract owner can adjust decay parameters.

Decay calculations use integer math; rounding favors stability.

Total system reputation increases only when reputation is earned—not from decay.