# Exasol Virtual Schema Lua 0.5.4, released 2024-03-12

Code name: Fix CVE-2024-25710, CVE-2024-26308 in test dependencies

## Summary

In this security release we fixed CVE-2024-25710 and CVE-2024-26308 by updating test dependencies that contained the vulnerable `org.apache.commons:commons-compress` 1.24.0.

## Features

* 50: Fixed CVE-2024-25710 in test dependency
* 51: Fixed CVE-2024-26308 in test dependency

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-testcontainers:6.6.3` to `7.0.1`
* Updated `com.exasol:hamcrest-resultset-matcher:1.6.2` to `1.6.5`
* Updated `com.exasol:test-db-builder-java:3.5.2` to `3.5.4`
* Updated `org.junit.jupiter:junit-jupiter-api:5.10.1` to `5.10.2`
* Updated `org.junit.jupiter:junit-jupiter-params:5.10.1` to `5.10.2`
* Updated `org.slf4j:slf4j-jdk14:2.0.9` to `2.0.12`
* Updated `org.testcontainers:junit-jupiter:1.19.2` to `1.19.7`

### Plugin Dependency Updates

* Updated `com.exasol:project-keeper-maven-plugin:2.9.16` to `4.2.0`
* Updated `org.apache.maven.plugins:maven-compiler-plugin:3.11.0` to `3.12.1`
* Updated `org.apache.maven.plugins:maven-failsafe-plugin:3.2.2` to `3.2.5`
* Updated `org.apache.maven.plugins:maven-surefire-plugin:3.2.2` to `3.2.5`
* Added `org.apache.maven.plugins:maven-toolchains-plugin:3.1.0`
* Updated `org.codehaus.mojo:flatten-maven-plugin:1.5.0` to `1.6.0`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.16.1` to `2.16.2`
* Updated `org.itsallcode:openfasttrace-maven-plugin:1.6.2` to `1.8.0`
