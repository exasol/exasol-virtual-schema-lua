# Exasol Virtual Schema Lua 1.0.0, released 2026-08-??

Code name: TIMESTAMP(9) Support

## Summary

This release adds nanosecond timestamp metadata support for Exasol 2025 and later.

The Lua module loader trick is now added directly to the installation bundle, so that users don't need to add it anymore themselves.

Breaking change: Exasol 7 is no longer supported

## Features

* #53: Added `TIMESTAMP(9)` support for Exasol 2025 and later.

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:25.2.2` to `26.2.8`
* Updated `com.exasol:exasol-testcontainers:7.1.7` to `8.0.1`
* Updated `com.exasol:hamcrest-resultset-matcher:1.7.0` to `1.7.3`
* Updated `com.exasol:maven-project-version-getter:1.2.1` to `1.2.2`
* Updated `com.exasol:test-db-builder-java:3.6.0` to `4.0.2`
* Updated `org.junit.jupiter:junit-jupiter-api:5.12.0` to `5.14.4`
* Updated `org.junit.jupiter:junit-jupiter-params:5.12.0` to `5.14.4`
* Updated `org.slf4j:slf4j-jdk14:2.0.17` to `2.0.18`
* Updated `org.testcontainers:junit-jupiter:1.20.6` to `1.21.4`

### Plugin Dependency Updates

* Updated `com.exasol:error-code-crawler-maven-plugin:1.3.0` to `2.1.1`
* Updated `com.exasol:project-keeper-maven-plugin:5.2.3` to `5.7.4`
* Removed `com.exasol:quality-summarizer-maven-plugin:0.2.0`
* Removed `com.github.funthomas424242:plantuml-maven-plugin:1.5.2`
* Updated `io.github.git-commit-id:git-commit-id-maven-plugin:9.0.1` to `10.0.0`
* Updated `org.apache.maven.plugins:maven-artifact-plugin:3.6.0` to `3.6.1`
* Updated `org.apache.maven.plugins:maven-clean-plugin:3.4.1` to `3.5.0`
* Updated `org.apache.maven.plugins:maven-compiler-plugin:3.14.0` to `3.15.0`
* Updated `org.apache.maven.plugins:maven-enforcer-plugin:3.5.0` to `3.6.3`
* Updated `org.apache.maven.plugins:maven-failsafe-plugin:3.5.3` to `3.5.6`
* Updated `org.apache.maven.plugins:maven-jar-plugin:3.3.0` to `3.5.1`
* Updated `org.apache.maven.plugins:maven-resources-plugin:3.3.1` to `3.5.0`
* Updated `org.apache.maven.plugins:maven-site-plugin:3.21.0` to `3.22.0`
* Updated `org.apache.maven.plugins:maven-surefire-plugin:3.5.3` to `3.5.6`
* Updated `org.codehaus.mojo:build-helper-maven-plugin:3.4.0` to `3.6.1`
* Updated `org.codehaus.mojo:exec-maven-plugin:3.1.0` to `3.6.3`
* Updated `org.codehaus.mojo:flatten-maven-plugin:1.7.0` to `1.7.3`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.18.0` to `2.21.0`
* Updated `org.itsallcode:openfasttrace-maven-plugin:2.3.0` to `3.0.0`
* Added `org.itsallcode:plantuml-maven-plugin:1.0.0`
* Updated `org.jacoco:jacoco-maven-plugin:0.8.13` to `0.8.15`
* Updated `org.sonarsource.scanner.maven:sonar-maven-plugin:5.1.0.4751` to `5.7.0.6970`
