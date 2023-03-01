# Exasol Virtual Schema (Lua) 0.4.0, released 2023-02-??

Code name: Remote EVSL (without TLS)

## Summary

In this release we added support for connecting to a remote Exasol database. Note that you cannot use remote Exasol VS yet, since the libraries required are not yet available in production release of the Exasol database. That means while the feature is generally available, it only works with very recent development builds of Exasol. We will update the EVSL release once an Exasol version with the required libraries becomes available.

## Features

* #20: Added remote metadata reading

## Dependency Updates

### Plugin Dependency Updates

* Updated `com.exasol:error-code-crawler-maven-plugin:1.2.0` to `1.2.2`
