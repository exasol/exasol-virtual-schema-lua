# Exasol Virtual Schema (Lua) 0.3.0, released 2023-02-??

Code name: `IS [NOT] JSON` predicate support

## Summary

We added support for the `IS [NOT] JSON` predicate.

We also added a test that evaluates the performance overhead of running queries directly against Exasol and via the Virtual Schema. 

Additionally, we improved tests that ensure the package, module and rockspec all have the correct version numbers.

## Bufixes

* #8: Added missing test for performance overhead
* #18: Added `IS [NOT] JSON` predicate

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:maven-project-version-getter:1.2.0` to `1.1.1`
* Updated `org.testcontainers:junit-jupiter:1.17.3` to `1.17.4`
