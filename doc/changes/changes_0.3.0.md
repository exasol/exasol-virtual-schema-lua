# Exasol Virtual Schema (Lua) 0.2.0, released 2022-09-29

Code name: JSON predicate support

## Summary

For the reviewer Next CR #18 Will solve IS [NOT] JSON. That is also why the code name and the version number were chosen this way.

We also added a test that evaluates the performance overhead of running queries directly against Exasol and via the Virtual Schema. 

Additionally, we improved tests that ensure the package, module and rockspec all have the correct version numbers.

## Bufixes

* #8: Added missing test for Performance overhead
## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-testcontainers:6.1.2` to `6.2.0`
* Updated `com.exasol:hamcrest-resultset-matcher:1.5.1` to `1.5.2`
* Updated `com.exasol:maven-project-version-getter:1.1.0` to `1.1.1`
* Updated `com.exasol:test-db-builder-java:3.3.3` to `3.3.4`
* Added `org.junit.jupiter:junit-jupiter-api:5.9.1`
* Removed `org.junit.jupiter:junit-jupiter-engine:5.8.2`
* Updated `org.junit.jupiter:junit-jupiter-params:5.8.2` to `5.9.1`
* Updated `org.slf4j:slf4j-jdk14:1.7.36` to `2.0.3`
* Updated `org.testcontainers:junit-jupiter:1.17.3` to `1.17.4`
