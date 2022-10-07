# Exasol Virtual Schema (Lua) 0.2.0, released 2022-10-06

Code name: JSON predicate support

## Summary

For the reviewer Next CR #18 Will solve IS [NOT] JSON. That is also why the code name and the version number were chosen this way.

We also added a test that evaluates the performance overhead of running queries directly against Exasol and via the Virtual Schema. 

Additionally, we improved tests that ensure the package, module and rockspec all have the correct version numbers.

## Bufixes

* #8: Added missing test for performance overhead

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:maven-project-version-getter:1.2.0` to `1.1.1`
* Updated `org.testcontainers:junit-jupiter:1.17.3` to `1.17.4`
