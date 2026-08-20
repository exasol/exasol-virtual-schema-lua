# System Requirement Specification &mdash; Virtual Schema Common Lua

## Introduction

Virtual Schemas are an adapter layer between the Exasol database and external data sources. You can use a Virtual Schema to project data from the data source into what looks and feels like a Schema in Exasol. This allows you to query data from the source with the built-in Exasol SQL as you would do on regular tables.

With Exasol version 7.1 we introduced Lua-based Virtual Schemas. The "Virtual Schema Common Lua" library (short "VSCL") abstracts the Virtual Schema interface and handles initialization of a Virtual Schema. You can use it to skip the step of writing the boilerplate code for communicating with the Exasol database and instead focus on the implementation of the actual source adapter code.

## About This Document

### Target Audience

The target audience are end-users, requirement engineers, software designers and quality assurance. See section ["Stakeholders"](#stakeholders) for more details.

### Goal

The VSCL main goal is to provide a ready-to-use abstraction between the Exasol database and the data source adapter.

## Stakeholders

### Software Developers

Software Developers use this library as basis for writing Virtual Schema adapters in Lua.

### Terms and Abbreviations

The following list gives you an overview of terms and abbreviations commonly used in OFT documents.

* Data Source: Usually external source of data ranging from relational database management systems, over NoSQL sources to web services.
* UDF: see "User Defined Function"
* User Defined Function: Extension point in the Exasol database that allows users to write their own SQL functions.
* Virtual Schema: Projection of an external data source that can be access like an Exasol database schema.
* Virtual Schema adapter: Plug-in for Exasol based on the Virtual Schema API that translates between Exasol and the data source.
* [Virtual Schema API](https://github.com/exasol/virtual-schema-common-java/blob/main/doc/development/api/virtual_schema_api.md): Interface between the Exasol core database and a Virtual Schema Adapter.
* Virtual Schema properties: Configuration options that can be set to change the behavior of a Virtual Schema.

## Features

Features are the highest level requirements in this document that describe the main functionality of RLS.

### Request Handling
`feat~request-handling~1`

VSCL receives and decodes requests that the Virtual Schema Adapter gets from the core database and dispatches them to an adapter object written in Lua. It also encodes the Adapter's response before sending it to the core database.

Rationale:

Handling the Virtual Schema API, decoding of request and encoding of responses are a common part that is identical for all Virtual Schemas. Having that in a base library frees developer time for focusing on the actual adapter code.

Needs: req

### Logging
`feat~logging~1`

VSCL can log to the console or a remote log receiver. 

Rationale:

Console logging is useful for unit tests, remote logging for debugging a running Virtual Schema.

Needs: req

## Functional Requirements

### Lua Virtual Schema Adapter Abstraction
`req~lua-virtual-schema-adapter-abstraction~1`

VSCJ offers an object-oriented Lua interface for a Virtual Schema adapters.

Rationale:

This is a more convenient starting point for Software Developers who want to implement their own than having to work directly on the Virtual Schema API provided by the Exasol core database.

Covers:

* [feat~request-handling~1](#request-handling)

Needs: dsn

### Handling Requests

The Virtual Schema API offered by the Exasol core database uses a request-response mechanism. Without abstraction users have to provide a central callback function, and parse the JSON based format used to exchange data with the core.

VSCL abstracts this, so that Software Developers don't have to do it themselves. Instead, they implement an adapter that must offer a predefined interface.

#### Translating JSON Requests to Lua Tables
`req~translating-json-request-to-lua-tables~1`

VSCL translates the contents of a Virtual Schema request from JSON to a LUA table.

Rationale:

JSON decoding is boilerplate code. What developers need are Lua objects (read "tables" that abstract the contents of the request).

Covers:

* [feat~request-handling~1](#request-handling)

Needs: dsn

#### Reading User-defined Properties
`req~reading-user-defined-properties~1`

VSCL extracts user-defined Virtual Schema Properties from the Virtual Schema request.

Comment:

Properties are key-value pairs that users can supply at creation of the Virtual Schema to control the behavior of the Virtual Schema. While most properties are specific to an individual Virtual Schema, their structure is uniform, so that the general decoding functions are available in VSCL.

Rationale:

Properties let users change the settings of a Virtual Schema.

Needs: dsn

#### Merging User-defined Properties
`req~merging-user-defined-properties~1`

VSCL supports merging a set of changed properties into a set of existing properties:

1. If there is no match for an old property in the set of new properties, the old value remains unchanged in the merge product
2. If a new property has a new non-null value, the property in the merge product has the new value
3. If there is no match for a new property in the set of old properties, the new property is added to the merge product
4. If a new property contains a null value, that property does not appear in the merge product

Rationale:

In the [`SET PROPERTIES` request](#dispatching-set-properties-requests), the Virtual Schema API provides both current and new (added / modified / unset) properties. To avoid code duplication, VSCL supports merging the new properties with the current ones.

Needs: dsn

#### Request Dispatching

The bare Virtual Schema API expects an adapter to handle all incoming request with one central callback function. This is not very convenient for Software developers.

VSCL examines the content of an incoming request and dispatches it to a dedicated adapter callback function defined in the Lua Virtual Schema Lua Adapter interface.

##### Dispatching Create-Virtual-Schema Requests
`req~dispatching-create-virtual-schema-requests~1`

VSCL dispatches request to create a Virtual Schema to the Virtual Schema adapter.

Covers:

* [feat~request-handling~1](#request-handling)

Needs: dsn

##### Dispatching Drop-Virtual-Schema Requests
`req~dispatching-drop-virtual-schema-requests~1`

VSCL dispatches request to drop a Virtual Schema to the Virtual Schema adapter.

Covers:

* [feat~request-handling~1](#request-handling)

Needs: dsn

##### Dispatching Get-Capabilities Requests
`req~dispatching-get-capabilities-requests~1`

VSCL dispatches request to list all supported capabilities of the Virtual Schema to the Virtual Schema adapter.

Covers:

* [feat~request-handling~1](#request-handling)

Needs: dsn

##### Dispatching Set-Properties Requests
`req~dispatching-set-properties-requests~1`

VSCL dispatches request to change the Virtual Schema properties to the Virtual Schema adapter with old and new properties as parameters.

Covers:

* [feat~request-handling~1](#request-handling)

Needs: dsn

##### Dispatching Refresh Requests
`req~dispatching-refresh-requests~1`

VSCL dispatches request to refresh the metadata of a Virtual Schema to the Virtual Schema adapter.

Covers:

* [feat~request-handling~1](#request-handling)

Needs: dsn

##### Dispatching Push-down Requests
`req~dispatching-push-down-requests~1`

VSCL dispatches request to push a query down to the data source to the Virtual Schema adapter.

Covers:

* [feat~request-handling~1](#request-handling)

Needs: dsn

### Adapter Capabilities

Adapter capabilities are a kind of labels that indicate what an adapter can do. The complete set is defined by the Exasol database and part of the [Virtual Schema API](https://github.com/exasol/virtual-schema-common-java/blob/main/doc/development/api/virtual_schema_api.md#get-capabilities).

Each adapter implements a subset of these capabilities and reports them to the Exasol database on request.

Since that mechanism is for most adapters identical, VSCL provides a base implementation that will fit the 90% case.
Exception are adapters that decide on capabilities dynamically, e.g. depending on the version of the attached data source &mdash; an admittedly rare use case. In those special cases adapters can override the base implementation.

#### Excluding Capabilities
`req~excluding-capabilities~1`

VSCL allows users to exclude individual capabilities from being used by the Exasol database.

Rationale:

This is mainly useful if users know that Exasol can handle some function more efficiently than the data source and thus want to prevent push-down of that particular function even though the source would support that.

Covers:

* [feat~request-handling~1](#request-handling)

Needs: dsn

### Handling Responses

#### Translating Lua Tables to JSON Responses
`req~translating-lua-tables-to-json-responses~1`

VSCL translates the contents Virtual Schema response from a LUA table to JSON.

Rationale:

JSON encoding is boilerplate code. Developers formulate the responses as Lua objects (tables) and VSCL translates that to a JSON Response.

Covers:

* [feat~request-handling~1](#request-handling)

Needs: dsn

#### Render SQL Query
`req~render-sql-query~1`

VSCL can render a query provides as [abstract syntax tree](https://en.wikipedia.org/wiki/Abstract_syntax_tree) to an textual SQL statement.

Rationale:

While the Virtual Schema API expresses the query to be pushed down in form of an abstract syntax tree, it expects the SQL commands that should be executed by the ExaLoader (for `IMPORT`) to be provided as textual SQL string in the push-down response. Rendering that string is identical for all standard SQL parts.

Covers:

* [feat~request-handling~1](#request-handling)

Needs: dsn

### Logging

Virtual Schemas run headless. That means that under normal circumstances the result of a Virtual Schema request is the only way users can observe. For monitoring and debugging we therefore need logging.

#### Console Logging
`req~console-logging~1`

VSCL can write log messages to the console.

Rationale:

This is useful for unit testing.

Covers:

* [feat~logging~1](#logging)

Needs: dsn

#### Remote Logging
`req~remote-logging~1`

VSCL can write log messages to a remote log listener.

Rationale:

In an Exasol cluster, the console is not reachable for Lua UDFs, therefore the logger must send the log message to a remote receiver.

Covers:

* [feat~logging~1](#logging)

Needs: dsn