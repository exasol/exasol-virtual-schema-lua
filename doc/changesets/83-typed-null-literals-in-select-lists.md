# GH-83 Typed `NULL` Literals in Select Lists   

<!-- markdown-link-check-disable -->

## Goal

Enable remote EVSL queries with typed `NULL` literals in their top-level select list by preserving the result-column type in the SQL executed through `IMPORT`.

## Scope

In scope:

* For a remote query only, replace each top-level `literal_null` projection with a `CAST(NULL AS <select-list-result-type>)` AST expression before rendering the wrapped `IMPORT` statement.
* Use the existing `selectListDataTypes` entry at the same projection index; do not infer types from SQL expressions.
* Add unit and remote integration coverage for a `DECIMAL(18,0)` typed `NULL` projection, including the rendered `IMPORT` SQL and its successful execution.
* Document the supported top-level case and the limitation for nested `NULL` expressions in the EVSL user guide's **Known Limitations** section.

Out of scope:

* Type inference or a general SQL type system in VSCL or EVSL.
* Rewriting `NULL` in predicates, function arguments, `CASE` expressions, subqueries, or any other nested expression.
* Changing ExaLoader. A direct SQL probe established that `IMPORT` accepts `CAST(NULL AS DECIMAL(18,0))` but rejects bare `NULL` for a declared `DECIMAL(18,0)` import column.
* The unrelated three-or-more-table join failure tracked in GH-71.

## Design References

* [EVSL System Requirements](../evsl/system_requirements.md) — `req~evsl.remote-push-down~1`
* [Query Push-down Sequence](../evsl/model/diagrams/sequence/seq_pushdown.plantuml) — `dsn~evsl.remote-push-down~0`
* [EVSL User Guide](../evsl/user_guide/user_guide.md)
* [Remote Query Rewriter](../../src/main/lua/exasol/evsl/RemoteQueryRewriter.lua)

## Strategy

`RemoteQueryRewriter` already receives both the top-level `selectList` and the positionally aligned `selectListDataTypes`; it passes the latter to `IMPORT INTO` but currently renders a `literal_null` projection as bare `null`. Before rendering the remote statement, transform only a top-level `literal_null` at index `i` into the existing `function_scalar_cast` representation with `dataType = selectListDataTypes[i]`. The existing query renderer then produces `CAST(NULL AS <type>)` without introducing a parser or type inference.

The adapter has no corresponding type metadata for nested expressions. The documentation must therefore explicitly limit the guarantee to top-level select-list entries and explain why the same workaround cannot safely be generalized.

## Task List

- [ ] Create and checkout a new Git branch `bugfix/83-typed-null-literals-in-select-lists`

### Requirements And Design

- [x] Add a user-facing requirement and scenario for typed `NULL` literals in remote top-level select lists, preserving the existing generic remote-push-down requirement.
- [ ] Stop and ask user for a review of the system requirements.
- [x] Add a runtime design item for the index-based top-level projection transformation; update the query push-down sequence diagram to show that it uses the matching result-column type before building the `IMPORT`.
- [ ] Stop and ask user for a review of the design.

### Implementation

- [x] In `RemoteQueryRewriter`, transform only top-level `literal_null` projections into `function_scalar_cast` expressions using the same-index `selectListDataTypes` entry.
- [x] Keep local query rendering and every nested `literal_null` expression unchanged.
- [x] Add Lua unit tests for the transformed remote SQL and for leaving non-`literal_null` projections unchanged.
- [x] Add an `ImportIT` test that queries a remote virtual table with `CAST(NULL AS DECIMAL(18,0))`, asserts the null decimal result, and verifies the push-down contains `CAST(NULL AS DECIMAL(18,0))`.
- [x] Preserve or add OFT coverage tags from the implementation, unit test, and integration test to the new runtime design item.

### Verification

- [ ] Run the focused Lua `RemoteQueryRewriter` unit tests and all Lua unit tests.
- [x] Run the focused `ImportIT` typed-NULL integration test against Exasol Testcontainers.
- [x] Run `mvn --batch-mode trace-requirements` and keep the OpenFastTrace trace clean.
- [x] Run the CI-equivalent `mvn --batch-mode clean verify -DossindexSkip=true` and `tools/shellcheck.sh`.

### Update User Documentation

- [x] Add **Typed `NULL` Literals in Remote Select Lists** under the EVSL user guide's **Known Limitations**. Document that a typed `NULL` is supported only as a direct select-list entry for a remote virtual schema, because the Virtual Schema API supplies result types only for that list; nested expressions have no safe type information for a cast.

## Version And Changelog Update

- [x] Raise the adapter, Maven project, generated parent POM, and LuaRocks package version to 1.0.1.
- [x] Add the 1.0.1 bug-fix entry to the changelog.
