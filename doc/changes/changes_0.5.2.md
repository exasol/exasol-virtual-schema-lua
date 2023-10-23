# Exasol Virtual Schema (Lua) 0.5.2, released 2023-10-23

Code name: Fix CVE-2023-42503 in test dependency

## Summary

This release we replaced a testing dependency that was vulnerable to CVE-2023-42503. Production code was not affected.

We also changed the namespace for the virtual schema adapter in the code from `exasolvs` to `exasol.evsl` for uniformity across projects. This has not impact on the function of the virtual schema.

## Features

* #40: Changed namespace `exasolvs` to `exasol.evsl`
* #45: Fix CVE-2023-42503 in test dependency

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-testcontainers:6.6.1` to `6.6.2`
* Updated `com.exasol:hamcrest-resultset-matcher:1.6.0` to `1.6.1`
* Updated `com.exasol:test-db-builder-java:3.4.2` to `3.5.1`
* Updated `org.junit.jupiter:junit-jupiter-api:5.9.3` to `5.10.0`
* Updated `org.junit.jupiter:junit-jupiter-params:5.9.3` to `5.10.0`
* Updated `org.slf4j:slf4j-jdk14:2.0.7` to `2.0.9`
* Updated `org.testcontainers:junit-jupiter:1.18.3` to `1.19.1`

### Plugin Dependency Updates

* Updated `com.exasol:project-keeper-maven-plugin:2.9.9` to `2.9.12`
* Updated `org.apache.maven.plugins:maven-enforcer-plugin:3.3.0` to `3.4.0`
