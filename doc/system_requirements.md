<head><link href="oft_spec.css" rel="stylesheet"></head>

# System Requirement Specification Exasol Row Level Security

## Introduction

Exasol Virtual Schema for Lua (short "EVSL") is a plug-in for Exasol that allows creating a Virtual Schema that connects to a regular Exasol Schema.

Virtual Schemas are conceptually related to database views. The main difference compared to database views is that Virtual Schema sources can be almost any data source. To make this possible, you need a so-called "Virtual Schema adapter", an Exasol extension that contains the logic to translate between the source and the projection provided by the Virtual Schema.

From an end-user's perspective a Virtual Schema looks and feels like an internal schema of Exasol &mdash; albeit one that can only be read.

## About This Document

### Target Audience

The target audience are end-users, requirement engineers, software designers and quality assurance. See section ["Stakeholders"](#stakeholders) for more details.

### Goal

The EVSL main goal is to provide a Virtual Schema that can project a regular database schema from one Exasol database to another one (or in case of a local Virtual Schema to the same database).

### Quality Goals

#### Affordable Performance Hit
`qg~affordable-performance-hit~1`

The Performance degradation caused by and EVSL query compared to the same query directly on the source schema is small.

Needs: qr

## Stakeholders

### Virtual Schema Owners

Virtual Schema Owners (short "VS Owners") have elevated rights on the database, allowing them to create, modify and drop Virtual Schemas. 

### Virtual Schema Consumers

Virtual Schema Consumers (short "VS Consumers") are users querying the data projected by the Virtual Schema.

## Terms and Abbreviations

The following list gives you an overview of terms and abbreviations commonly used in OFT documents.

* Schema: database schema. In Exasol the top-level grouping element for tables and scripts in a database.
* Virtual Schema: projection of data from a data source that - from the end-user's perspective - looks like a regular schema.

In the following subsections central terms are explained in more detail.

## Features

Features are the highest level requirements in this document that describe the main functionality of EVSL.

### Local Virtual Schema
`feat~local-virtual-schema~1`

VS Owners can create a projection of a database schema from an Exasol database onto a Virtual Schema on the _same_ database.

Rationale:

This feature mainly exists to be able to test the Exasol Virtual Schema engine in the database without large setup effort.

Needs: req

## Functional Requirements

### Creating a Local Virtual Schema
`req~creating-a-local-virtual-schema~1`

VS Owners can create a Virtual Schema that abstracts a database schema on the same Exasol database.

Rationale:

This allows testing the Virtual Schema engine without having to set up a remote Exasol database. For most functional tests this is sufficient and has the added benefit of being faster, since there is no network overhead.

Covers:

* [feat~local-virtual-schema~1](#local-virtual-schema)

Needs: dsn

### Reading Source Metadata
`req~reading-source-metadata~1`

EVSL (re-)reads the metadata from the data source whenever one of the following events occurs:

* VS Owners [create a Virtual Schema](#creating-a-local-virtual-schema)
* VS Owners [change the adapter properties](#setting-new-properties)
* VS Owners [refresh the virtual schema](#refreshing-a-virtual-schema)

Rationale:

It is obvious that the metadata needs to be read upon creation. This is necessary to allow the Exasol database to map source structure and data types to the Virtual Schema. Refreshing allows updating this information in case there is a change in the source that affects the source structure or types. Finally, changing the properties can impact which part of the source the Virtual Schema takes into account and can also affect the mapping and therefore also requires re-reading the metadata.  

Covers:

* [feat~local-virtual-schema~1](#local-virtual-schema)

Needs: dsn

### Dropping a Virtual Schema
`req~dropping-a-virtual-schema~1`

VS Owners can drop a Virtual Schema.

Covers:

* [feat~local-virtual-schema~1](#local-virtual-schema)

Needs: dsn

### Refreshing a Virtual Schema
`req~refreshing-a-virtual-schema~1`

VS Owners can refresh a Virtual Schema, causing the metadata of the underlying schema to be re-read.

Rationale:

This allows updating the structure of the underlying schema.

Covers:

* [feat~local-virtual-schema~1](#local-virtual-schema)

Needs: dsn

### Getting the Supported Capabilities
`req~getting-the-suppoted-capabilities~1`

EVSL offers a list of capabilities supported by the adapter on request of the Exasol database.

Rationale:

The Exasol database's query optimizer uses this information when deciding, which parts of the user's original query to push down to the data source. Think of a data source that can't group information. In this case, the adapter does not report that capability and Exasol groups the data after reading it from the source.

Covers:

* [feat~local-virtual-schema~1](#local-virtual-schema)

Needs: dsn

### Excluding Capabilities
`req~excluding-capabilities~1`

VS Owners can exclude zero or more Virtual Schema capabilities.

Rationale:

When a Virtual Schema excludes a capability from the list of supported capabilities, then the core database constructs push-down queries that only take the remaining capabilities into account. If VS Owners for example switch off a scalar function, that function won't be pushed down to the Virtual Schema. Instead the core database applies it on the results of the push-down.

VS Owners can do this in case the resulting query turns out to be more efficient for example.

Covers:

[feat~local-virtual-schema~1](#local-virtual-schema)

Needs: dsn

### Filtering Tables
`req~filtering-tables~1`

VS Owners can specify, which tables of the source schema should be visible through the Virtual Schema.

Rationale:

This serves two purposes. It allows to reduce the number of tables scanned for metadata, thus speeding up the creation and update of the Virtual Schema. And VS Owners can limit the visibility of tables in case not all tables are relevant in the Virtual Schema.

Covers:

[feat~local-virtual-schema~1](#local-virtual-schema)

Needs: dsn

### Querying the Data Source (Push-down)
`req~push-down~1`

EVSL can query the data source.

Rationale:

Depending on the filter, grouping and aggregation capabilities the data source offers, a query to a Virtual Schema can in parts or as a whole be push-down to the data source. This reduces the amount of data transferred between Exasol and the data source compared to a full data copy.

Comment:

Note that the decision about what parts of the query are being pushed down to the data source are made in the Exasol core database. The adapter (the project this document talks about) only translates the pushed-down part into a language the source understands.

Covers:

[feat~local-virtual-schema~1](#local-virtual-schema)

Needs: dsn

### Setting New Properties
`req~setting-properties~1`

VS Owners can change the properties of an existing Virtual Schema.

Rationale:

This is useful if VS Owners want to change the underlying settings (e.g. the table filter) without breaking the dependencies VS Consumers have on the existing Virtual Schema.

Covers:

[feat~local-virtual-schema~1](#local-virtual-schema)

Needs: dsn

## Quality Requirements

### Quality Tree

    Utility
      |
      |-- Performance
      |-- Modifiability
      '-- Security

### Quality Scenarios

#### Performance

##### Query Execution Time
`qr~query-execution-time~1`

The Performance degradation caused by an EVSL query compared to the same query without EVSL is below the greater of

* half a second
* 10%

on top of the original execution time.

Comment:

This is the complete runtime as the database client experiences it including the involved upstart times for the UDF language container and the contained runtime environment.

Covers:

* [qg~affordable-performance-hit~1](#affordable-performance-hit)

Needs: qs