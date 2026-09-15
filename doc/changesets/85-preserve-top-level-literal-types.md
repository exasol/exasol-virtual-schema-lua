# GH-85 Preserve Types of Top-Level Literals

## Goal

Preserve the declared result type of top-level literal projections for local and remote virtual schemas.

## Scope

In scope:

* Apply the existing remote typed-`NULL` behavior to local queries.
* Preserve declared types for every top-level literal expression with matching `selectListDataTypes` metadata.
* Add local integration coverage and shared-rewriter unit coverage.

Out of scope:

* Nested literal expressions and type inference beyond direct select-list entries.
* A version bump: version `1.0.1` has not been released.

## Design References

* [EVSL System Requirements](../evsl/system_requirements.md) — `req~evsl.top-level-literal-types~1`
* [Query Push-down Sequence](../evsl/model/diagrams/sequence/seq_pushdown.plantuml) — `dsn~evsl.preserving-top-level-literal-types~0`
* [EVSL User Guide](../evsl/user_guide/user_guide.md)

## Task List

### Requirements And Design

- [x] Extend the typed-literal requirement and scenario to local and remote paths.
- [x] Update the push-down sequence and user guide for top-level literals.

### Implementation

- [x] Move literal type preservation into `AbstractQueryRewriter` and invoke it from both rewriters.
- [x] Add local and remote Lua unit coverage for typed literal rendering.
- [x] Add a local integration regression for a typed `NULL` projection and its push-down SQL.

### Verification

- [x] Run focused local and remote Lua rewriter tests.
- [x] Run the focused local integration test against Exasol Testcontainers.
- [x] Run the complete Lua test suite, OpenFastTrace trace, and Maven verification. The full Failsafe run exposed
      unrelated shared-database cleanup and concurrent LuaRocks-bundling failures.

## Version And Changelog Update

- [x] Keep version `1.0.1` and add the GH-85 bug-fix entry to its unreleased changelog.
