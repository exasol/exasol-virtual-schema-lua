# GH-86 Render Boolean Literal Filters

## Goal

Allow VS Consumers to query virtual-schema tables with an always-false filter such as `WHERE 1 = 0`.

## Scope

In scope:

* Render a pushed-down boolean-literal filter through the general SQL expression renderer.
* Cover direct `TRUE` and `FALSE` filters in unit tests and the folded `WHERE 1 = 0` case in an integration test.
* Trace the renderer behavior, document the current-release bug fix, and retain version 1.0.1.

Out of scope:

* Short-circuiting false filters instead of pushing them down.
* Changing advertised capabilities or package versions.

## Design References

* [VSCL System Requirements](../vscl/system_requirements.md) — `req~vscl.render-sql-query~1`
* [Query Push-down Sequence](../vscl/model/diagrams/sequence/seq_push_down.plantuml) — `dsn~vscl.rendering-boolean-filter-expressions~0`

## Strategy

`SelectAppender` treats a filter as a boolean expression rather than a predicate-only AST node. Delegating to the existing expression renderer preserves predicate behavior and lets `literal_bool` render as SQL `true` or `false`.

## Task List

### Requirements And Design

- [x] Record a runtime-design trace for boolean filter expression rendering in the query push-down sequence.

### Implementation

- [x] Render `SelectSqlStatement.filter` through `ExpressionAppender:append_expression` and update its type annotations.
- [x] Add Lua unit coverage for direct `TRUE` and `FALSE` filters.
- [x] Add an integration regression test for `WHERE 1 = 0` and its folded `WHERE false` push-down.

### Verification

- [x] Run the focused integration regression test and all Lua unit tests.
- [x] Keep the OpenFastTrace trace clean.
- [x] Run the CI-equivalent Maven verification and shellcheck.

## Version And Changelog Update

- [x] Keep the version at 1.0.1.
- [x] Add the #86 bug fix to the 1.0.1 changelog.
