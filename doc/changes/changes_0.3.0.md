# Exasol Virtual Schema (Lua) 0.3.0, released 2022-10-??

Code name: Remote EVSL (without TLS)

## Summary

In this release we added support for connecting to a remote Exasol database. Note that TLS is not yet supported, because at the time of this release the required Lua libraries were not yet available in production release of the Exasol database.

## Bugfixes

* #8: Added missing test for performance overhead

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

* Updated `com.exasol:error-code-crawler-maven-plugin:1.2.0` to `1.2.2`
* Updated `com.exasol:project-keeper-maven-plugin:2.8.0` to `2.9.1`
* Updated `io.github.zlika:reproducible-build-maven-plugin:0.15` to `0.16`
* Updated `org.apache.maven.plugins:maven-failsafe-plugin:3.0.0-M5` to `3.0.0-M7`
* Updated `org.apache.maven.plugins:maven-surefire-plugin:3.0.0-M5` to `3.0.0-M7`
* Updated `org.codehaus.mojo:flatten-maven-plugin:1.2.7` to `1.3.0`
* Updated `org.codehaus.mojo:versions-maven-plugin:2.10.0` to `2.13.0`
