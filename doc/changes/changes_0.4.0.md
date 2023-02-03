# Exasol Virtual Schema (Lua) 0.4.0, released 2023-02-??

Code name: Remote EVSL (without TLS)

## Summary

In this release we added support for connecting to a remote Exasol database. Note that TLS is not yet supported, because at the time of this release the required Lua libraries were not yet available in production release of the Exasol database.

## Features

* #20: Added remote metadata reading

## Dependency Updates

### Plugin Dependency Updates

* Updated `com.exasol:error-code-crawler-maven-plugin:1.2.0` to `1.2.2`
