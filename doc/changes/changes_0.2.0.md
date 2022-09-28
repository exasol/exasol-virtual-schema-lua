# Exasol Virtual Schema (Lua) 0.2.0, released 2022-09-28

Code name: Join support

## Summary

In version 0.2.0 of the Exasol Virtual Schema for Lua we activated support for JOINs.

We also updated the dependencies.

## Features

* #13: Join support
* #16: Support of all predicates (except JSON predicates)

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-testcontainers:6.1.2` to `6.2.0`
* Updated `com.exasol:hamcrest-resultset-matcher:1.5.1` to `1.5.2`
* Updated `com.exasol:maven-project-version-getter:1.1.0` to `1.2.0`
* Updated `com.exasol:test-db-builder-java:3.3.3` to `3.3.4`
* Added `org.junit.jupiter:junit-jupiter-api:5.9.1`
* Removed `org.junit.jupiter:junit-jupiter-engine:5.8.2`
* Updated `org.junit.jupiter:junit-jupiter-params:5.8.2` to `5.9.1`
* Updated `org.slf4j:slf4j-jdk14:1.7.36` to `2.0.3`

### Plugin Dependency Updates

* Updated `com.exasol:error-code-crawler-maven-plugin:1.1.1` to `1.2.0`
* Updated `com.exasol:project-keeper-maven-plugin:2.4.6` to `2.8.0`
* Updated `org.apache.maven.plugins:maven-enforcer-plugin:3.0.0` to `3.1.0`
* Updated `org.apache.maven.plugins:maven-jar-plugin:3.2.2` to `3.3.0`
* Updated `org.codehaus.mojo:exec-maven-plugin:3.0.0` to `3.1.0`
* Updated `org.itsallcode:openfasttrace-maven-plugin:1.5.0` to `1.6.1`
