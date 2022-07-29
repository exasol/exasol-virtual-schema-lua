# eExasol Virtual Schema (Lua) 0.1.1, released 2022-07-25

Code name: Documentation complete

## Summary

Version 0.1.1 brings updated (and now complete) user requirements, design and requirement tracing.

We also fixed an issue in the "set properties" request. The VS API does not behave like it was described in the API documentation, causing property changes to be ignored. The API documentation was fixed in [virtual-schema-common-java #247](https://github.com/exasol/virtual-schema-common-java/issues/247) after which we fixed the Lua implementation. 

## Features

* #1: Completed system requirements, design and requirement tracing.

## Dependency Updates

### Test Dependency Updates

* Added `com.exasol:exasol-jdbc:7.1.11`
* Added `com.exasol:exasol-testcontainers:6.1.2`
* Added `com.exasol:hamcrest-resultset-matcher:1.5.1`
* Added `com.exasol:maven-project-version-getter:1.1.0`
* Added `com.exasol:test-db-builder-java:3.3.3`
* Added `org.hamcrest:hamcrest:2.2`
* Added `org.junit.jupiter:junit-jupiter-engine:5.8.2`
* Added `org.junit.jupiter:junit-jupiter-params:5.8.2`
* Added `org.slf4j:slf4j-jdk14:1.7.36`
* Added `org.testcontainers:junit-jupiter:1.17.3`

### Plugin Dependency Updates

* Added `com.exasol:error-code-crawler-maven-plugin:1.1.1`
* Added `com.exasol:project-keeper-maven-plugin:2.4.6`
* Added `com.github.funthomas424242:plantuml-maven-plugin:1.5.2`
* Added `io.github.zlika:reproducible-build-maven-plugin:0.15`
* Added `org.apache.maven.plugins:maven-clean-plugin:2.5`
* Added `org.apache.maven.plugins:maven-compiler-plugin:3.10.1`
* Added `org.apache.maven.plugins:maven-deploy-plugin:2.7`
* Added `org.apache.maven.plugins:maven-enforcer-plugin:3.0.0`
* Added `org.apache.maven.plugins:maven-failsafe-plugin:3.0.0-M5`
* Added `org.apache.maven.plugins:maven-install-plugin:2.4`
* Added `org.apache.maven.plugins:maven-jar-plugin:3.2.2`
* Added `org.apache.maven.plugins:maven-resources-plugin:2.6`
* Added `org.apache.maven.plugins:maven-site-plugin:3.3`
* Added `org.apache.maven.plugins:maven-surefire-plugin:3.0.0-M5`
* Added `org.codehaus.mojo:build-helper-maven-plugin:3.3.0`
* Added `org.codehaus.mojo:exec-maven-plugin:3.0.0`
* Added `org.codehaus.mojo:flatten-maven-plugin:1.2.7`
* Added `org.codehaus.mojo:versions-maven-plugin:2.10.0`
* Added `org.itsallcode:openfasttrace-maven-plugin:1.5.0`
* Added `org.jacoco:jacoco-maven-plugin:0.8.8`
* Added `org.sonarsource.scanner.maven:sonar-maven-plugin:3.9.1.2184`
* Added `org.sonatype.ossindex.maven:ossindex-maven-plugin:3.2.0`
