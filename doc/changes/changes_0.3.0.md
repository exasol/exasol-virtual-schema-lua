# Exasol Virtual Schema (Lua) 0.3.0, released 2023-02-??

Code name: `IS [NOT] JSON` and `LISTAGG` support

## Summary

We added support for the `IS [NOT] JSON` predicate and the `LISTAGG` aggregate function.

We also added a test that evaluates the performance overhead of running queries directly against Exasol and via the Virtual Schema. 

Additionally, we improved tests that ensure the package, module and rockspec all have the correct version numbers.

## Bufixes

* #8: Added missing test for performance overhead
* #18: Added `IS [NOT] JSON` predicate
* #24: Added `LISTAGG` aggregate function

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:7.1.11` to `7.1.17`
* Updated `com.exasol:exasol-testcontainers:6.2.0` to `6.5.0`
* Updated `com.exasol:test-db-builder-java:3.3.4` to `3.4.2`
* Updated `org.junit.jupiter:junit-jupiter-api:5.9.1` to `5.9.2`
* Updated `org.junit.jupiter:junit-jupiter-params:5.9.1` to `5.9.2`
* Updated `org.slf4j:slf4j-jdk14:2.0.3` to `2.0.6`
* Updated `org.testcontainers:junit-jupiter:1.17.3` to `1.17.6`

### Plugin Dependency Updates

* Updated `com.exasol:project-keeper-maven-plugin:2.8.0` to `2.9.1`
* Updated `io.github.zlika:reproducible-build-maven-plugin:0.15` to `0.16`
* Updated `org.apache.maven.plugins:maven-failsafe-plugin:3.0.0-M5` to `3.0.0-M7`
* Updated `org.apache.maven.plugins:maven-surefire-plugin:3.0.0-M5` to `3.0.0-M7`
* Updated `org.codehaus.mojo:flatten-maven-plugin:1.2.7` to `1.3.0`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.10.0` to `2.13.0`
