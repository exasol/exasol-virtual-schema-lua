# GH-53 TS(9) Support in Exasol VS Lua

## Goal

Preserve nanosecond timestamp precision when EVSL reads Exasol source metadata, proven by version-specific integration tests.

## Scope

In scope:

* Add an Exasol 8-only metadata-reading integration test that covers `TIMESTAMP`, `TIMESTAMP(3)`, and `TIMESTAMP(6)`, each expected to be reported as `TIMESTAMP(3)`.
* Add an Exasol 9-or-higher metadata-reading integration test that covers `TIMESTAMP(9)` and asserts that the virtual schema reports `TIMESTAMP(9)`.
* Select the test by the database major version obtained from `EXASOL.getDockerImageReference()`, using the Testcontainers image-reference version methods rather than a hard-coded image string.
* Preserve the existing OpenFastTrace coverage from the integration test to `dsn~reading-source-metadata~0`.
* Raise the adapter, Maven project, generated parent POM, and LuaRocks package version to `1.0.0`.
* Document the completed timestamp-precision support and release entry.

Out of scope:

* Changes to timestamp query rendering, literal conversion, or remote-connection behavior.
* New requirements or design items: `req~reading-source-metadata~1` already requires mapping source data types, and `dsn~reading-source-metadata~0` is the applicable runtime design item.

## Design References

* [System Requirements](../evsl/system_requirements.md) — `req~reading-source-metadata~1`
* [Deployment model](../evsl/model/diagrams/deployment/depl_library_structure.plantuml) — `dsn~reading-source-metadata~0`
* [Developer Guide](../evsl/developer_guide/developer_guide.md)
* [README](../../README.md)

## Strategy

Split the timestamp metadata assertions by database major version. On Exasol 8, test `TIMESTAMP`, `TIMESTAMP(3)`, and `TIMESTAMP(6)` and assert the known database behavior that all three are exposed as `TIMESTAMP(3)`. On Exasol 9 or higher, test `TIMESTAMP(9)` and assert that the virtual schema retains nanosecond precision. Use assumption helpers backed by `EXASOL.getDockerImageReference().getMajor()` and `hasMajor()` to skip the inapplicable test. This provides end-to-end evidence without changing production code, because metadata is forwarded by the underlying Exasol metadata reader.

## Task List

- [ ] Create and checkout a new Git branch `feature/53-ts-9-support-in-exasol-vs-lua`

### Requirements And Design

- [x] Confirm that `req~reading-source-metadata~1` and `dsn~reading-source-metadata~0` accurately cover `TIMESTAMP(9)` metadata; do not add redundant traced artifacts.
- [x] Confirm that no requirement or design gap requires user review.

### Implementation

- [x] Add explicit assumption helpers that use `EXASOL.getDockerImageReference().hasMajor()` and `.getMajor()` to select Exasol 8 and Exasol 9-or-higher tests.
- [x] Add an Exasol 8-only `MetadataReadingIT` test for `TIMESTAMP`, `TIMESTAMP(3)`, and `TIMESTAMP(6)`, each asserting `TIMESTAMP(3)` in the virtual schema.
- [x] Add an Exasol 9-or-higher `MetadataReadingIT` test for `TIMESTAMP(9)`, asserting `TIMESTAMP(9)` in the virtual schema.
- [x] Keep the `[itest -> dsn~reading-source-metadata~0]` coverage tag on each new integration test.

### Verification

- [ ] Run the Exasol 8-only and Exasol 9-or-higher timestamp integration tests against their respective Testcontainers image versions.
- [ ] Run the Lua unit tests, including the adapter-version consistency test.
- [ ] Run `mvn --batch-mode trace-requirements` and keep the OpenFastTrace trace clean.
- [ ] Run the required Maven verification and Project Keeper checks.

### Update User Documentation

- [x] Update README.md to list nanosecond (`TIMESTAMP(9)`) metadata support.

## Version And Changelog Update

- [x] Raise the adapter, Maven project, generated parent POM, and LuaRocks package version to 1.0.0.
- [x] Add the 1.0.0 changelog entry for TS(9) support.
