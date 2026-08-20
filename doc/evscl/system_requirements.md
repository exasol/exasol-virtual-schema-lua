# System Requirement Specification Exasol Virtual Schema Common for Lua

## Introduction

Exasol Virtual Schema Common for Lua (short "EVSCL") is a base library for [Virtual Schemas](https://docs.exasol.com/db/latest/database_concepts/virtual_schemas.htm) that connect to Exasol databases. 

Virtual Schemas are conceptually related to database views. The main difference compared to database views is that Virtual Schema sources can be almost any data source. To make this possible, you need a so-called "Virtual Schema adapter", an Exasol extension that contains the logic to translate between the source and the projection provided by the Virtual Schema.

From an end-user's perspective a Virtual Schema looks and feels like an internal schema of Exasol &mdash; albeit one that can only be read.

## About This Document

### Target Audience

The target audience are end-users (VS Owners and Consumers), requirement engineers, software designers and quality assurance. See section ["Stakeholders"](#stakeholders) for more details.

### Goal

EVSCL's main goal is to prevent code duplication in Virtual Schemas.

## Stakeholders

Stakeholder have a vested interest in the project. As stakeholders are roles, many people can have the same role or one person multiple &mdash; as long as there is no conflict of interest. 

### Quality Assurance

Quality Assurance verifies that documents and software are made in a state-of-the art manner and that test and review processes are planned and adhered to.

### Requirement Engineers

Requirement Engineers collect, refine and trace the requirements of the software.

### Software Designers

Software Designers plan the construction of the software. Their responsibility is to create a design that fits the user requirements while balancing maintainability, security and complexity.

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

Since features are defined in the actual Virtual Schemas that depend on this library, none are listed here. We intentionally start the requirement chain with the next level.

## Functional Requirements

### Source Metadata Scan

The main work when creating a new virtual schema is to map the structure and data types of the data source to virtual schema metadata. This happens by scanning the data source and then reporting table and column structure back. This section holds requirements that are common for scanning an Exasol data source. 

#### Reading Table Metadata From a Schema
`req~reading-table-metadata-from-a-schema~1`

EVSCL reads the list of tables contained in the source database schema.

Needs: dsn

#### Reading Column Metadata From a Table
`req~reading-column-metadata-from-a-table~1`

EVSCL reads the list of columns and their attributes from a table in the source database.

Needs: dsn

#### Reading Timestamp Precision From Column Metadata
`req~reading-timestamp-precision-from-column-metadata~1`

When source column metadata declares a precision for a `TIMESTAMP` or `TIMESTAMP WITH LOCAL TIME ZONE`
column, EVSCL reports that precision in the virtual schema metadata. For timestamps without an explicit
precision, EVSCL preserves the existing metadata representation.

Needs: dsn

#### Include Tables
`req~include-tables~1`

EVSCL offers an interface to specify the tables from the source database schema that should be included in the virtual schema. 

Needs: dsn

### Shared Adapter Properties of Virtual Schemas That Access an Exasol Database

Adapter properties allow VS Owners to configure their virtual schemas. In this section we define properties that all virtual schemas share which access an Exasol data source. 

#### Schema Name Property
`req~schema-name-property~1`

EVSCL provides an API to read the data source's schema name that the virtual schema projects.

Needs: dsn

#### Table Filter Property
`req~table-filter-property~1`

EVSCL provides and API to read the list of source tables that should be present in the virtual schema projection.

Needs: dsn

#### Validation of Common Exasol Virtual Schema Properties
`req~evscl~property~validation~1`

EVSCL validates the following properties:

1. Properties that are introduced in the virtual schema base layer (VSCL)
2. Schema Name
3. Table Filter

Needs: dsn

### Rewriting Queries

At its core a virtual schema adapter is a query rewriter. It gets a data structure representing a push-down query from the code database wrapped in a push-down request. The rewriter then rewrites the logical structure of the push-down query so that it gets the required data.

#### Rewriting a Query for Local Access
`req~rewriting-a-query-for-local-access~1`

EVSCL rewrites a query that is aimed to access local Exasol data into an `SELECT` statement.

Needs: dsn
