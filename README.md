# Exasol Virtual Schema (Lua)

[![Build Status](https://github.com/exasol/exasol-virtual-schema-lua/actions/workflows/ci-build.yml/badge.svg)](https://github.com/exasol/exasol-virtual-schema-lua/actions/workflows/ci-build.yml)

<!-- Reenable when Sonar is set up
[![Build Status](https://github.com/exasol/exasol-virtual-schema-lua/actions/workflows/ci-build.yml/badge.svg)](https://github.com/exasol/exasol-virtual-schema-lua/actions/workflows/ci-build.yml)

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Aexasol-virtual-schema-lua&metric=alert_status)](https://sonarcloud.io/dashboard?id=com.exasol%3Aexasol-virtual-schema-lua)

[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Aexasol-virtual-schema-lua&metric=security_rating)](https://sonarcloud.io/dashboard?id=com.exasol%3Aexasol-virtual-schema-lua)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Aexasol-virtual-schema-lua&metric=reliability_rating)](https://sonarcloud.io/dashboard?id=com.exasol%3Aexasol-virtual-schema-lua)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Aexasol-virtual-schema-lua&metric=sqale_rating)](https://sonarcloud.io/dashboard?id=com.exasol%3Aexasol-virtual-schema-lua)
[![Technical Debt](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Aexasol-virtual-schema-lua&metric=sqale_index)](https://sonarcloud.io/dashboard?id=com.exasol%3Aexasol-virtual-schema-lua)

[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Aexasol-virtual-schema-lua&metric=code_smells)](https://sonarcloud.io/dashboard?id=com.exasol%3Aexasol-virtual-schema-lua)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Aexasol-virtual-schema-lua&metric=coverage)](https://sonarcloud.io/dashboard?id=com.exasol%3Aexasol-virtual-schema-lua)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Aexasol-virtual-schema-lua&metric=duplicated_lines_density)](https://sonarcloud.io/dashboard?id=com.exasol%3Aexasol-virtual-schema-lua)
[![Lines of Code](https://sonarcloud.io/api/project_badges/measure?project=com.exasol%3Aexasol-virtual-schema-lua&metric=ncloc)](https://sonarcloud.io/dashboard?id=com.exasol%3Aexasol-virtual-schema-lua)
-->

Abstract read access from Exasol to Exasol via a Virtual Schema.

## Features

* Access a local Exasol schema through a Virtual Schema

## Table of Contents

### Information for Users

* [User Guide](doc/user_guide/user_guide.md)
* [Changelog](doc/changes/changelog.md)

### Information for Contributors

Requirement, design documents and coverage tags are written in [OpenFastTrace](https://github.com/itsallcode/openfasttrace) format.

* [Developer Guide](doc/developer_guide/developer_guide.md)

### Runtime Dependencies

#### Lua Dependencies

Running the Exasol Virtual Schema (Lua) requires an Exasol database with built-in Lua 5.4 or later.

| Dependency                               | Purpose                                                | License                       |
|------------------------------------------|--------------------------------------------------------|-------------------------------|
| [Lua CJSON][luacjson]                    | JSON parsing and writing                               | MIT License                   |
| [remotelog][remotelog]                   | Logging through a TCP socket                           | MIT License                   |

`remotelog` has a transitive dependency to [LuaSocket][luasocket] (MIT License). Note that Lua CSON and LuaSocket are pre-installed on an Exasol database.

For local unit testing you need to install them on the test machine though.

[luacjson]: https://www.kyne.com.au/~mark/software/lua-cjson.php
[luasocket]: https://github.com/diegonehab/luasocket
[remotelog]: https://github.com/exasol/remotelog-lua

### Test Dependencies

#### Unit Test Dependencies

Unit tests are written in Lua. 

| Dependency           | Purpose                                                | License                       |
|----------------------|--------------------------------------------------------|-------------------------------|
| [busted][busted]     | Unit testing framework                                 | BSD License                   |
| [Mockagne][mockagne] | Mocking framework                                      | MIT License                   |

[busted]: https://lunarmodules.github.io/busted/
[mockagne]: https://github.com/vertti/mockagne

#### Integration Test Dependencies

The integration tests require `exasol-testcontainers` to provide an Exasol instance. They are written in Java and require version 11 or later.

See also: Java [Dependencies](dependencies.md).

### Build Dependencies

This project has a complex build setup due to the mixture of Lua and Java. [Apache Maven](https://maven.apache.org/) serves as the main build tool.

Lua build steps are also encapsulated by Maven.

| Dependency                                | Purpose                                                | License                       |
|-------------------------------------------|--------------------------------------------------------|-------------------------------|
| [Amalg][amalg]                            | Bundling Lua modules (and scripts)                     | MIT License                   |
| [LuaRocks][luarocks]                      | Package management                                     | MIT License                   |

[amalg]: https://github.com/siffiejoe/lua-amalg
[luarocks]: https://luarocks.org/

See also: Java [Dependencies](dependencies.md).