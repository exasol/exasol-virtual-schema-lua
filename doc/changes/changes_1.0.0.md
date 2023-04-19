# Exasol Virtual Schema (Lua) 1.0.0, released 2023-04-19

Code name: Partial TLS Support (without certificate validation)

## Summary

With version 0.5.0 the connection between the Virtual Schema Adapter and the remote Exasol uses TLS for encrypting the communication.

Note however, that this feature is not complete yet. It lacks validation of the peer certificate. The reason is that Lua does not yet have access to the certificate store, so the feature requires a change in the Exasol database. Once certificate validation is available, the EVSL will reach version 1.0.0.

What does this mean for users? They can test connecting the Exasol Virtual Schema to a remote Exasol server with an encrypted connection. The connection **cannot be treated as secure** though, because validating the peer certificate is a required step in establishing trust between the VS and the remote server. Without this attackers can pretend to be an Exasol server or run a man-in-the-middle attack.

If you need an actually secure connection you will unfortunately have to wait until version 1.0.0.

## Features

* #23: Added TLS Support

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:7.1.17` to `7.1.19`
* Updated `com.exasol:exasol-testcontainers:6.5.1` to `6.5.2`
* Updated `com.exasol:hamcrest-resultset-matcher:1.5.2` to `1.6.0`
* Updated `org.slf4j:slf4j-jdk14:2.0.6` to `2.0.7`
* Updated `org.testcontainers:junit-jupiter:1.17.6` to `1.18.0`

### Plugin Dependency Updates

* Updated `com.exasol:project-keeper-maven-plugin:2.9.3` to `2.9.7`
* Updated `org.apache.maven.plugins:maven-enforcer-plugin:3.1.0` to `3.2.1`
