# Exasol Virtual Schema (Lua)

Exasol Virtual Schema for Lua (short "EVSL") is an implementation of a [Virtual Schema](https://docs.exasol.com/db/latest/database_concepts/virtual_schemas.htm).

With EVSL you can make a read-only connection from a schema in an Exasol database to a so-called "Virtual Schema". A Virtual Schema is a projection of the data in the source schema. It looks and feels like a real schema with the main difference being that you can only read data and not write it.

Exasol Virtual Schema comes in two flavors:

* Local database access
* Remote database connection

Local access means that origin schema and Virtual Schema must be on the same database. The remote database connection is more useful, as it allows projecting a schema from a different Exasol database into your own.

Remote connections are also often used as a means of access control layer to database-external data sources for local database users. That is because the Virtual Schema itself can have different permissions than the users of the Virtual Schema.

## Introduction

Each Virtual Schema needs a data source. In the case of Exasol Virtual Schema for Lua, this source is a database schema in an Exasol database. We call that the "origin schema".

Conceptually Virtual Schemas are very similar to database views. They have an owner (typically the one who creates them) and share that owner's access permissions. This means that for a Virtual Schema to be useful, the owner must have the permissions to view the source.

Users of the Virtual Schema must have permissions to view the Virtual Schema itself, but they don't need permissions to view the source.

### Virtual Schema Adapter

Each Virtual Schema requires an Adapter. Think of this as a plug-in for Exasol that defines how to access data from a specific source.

Check the section ["Installation"](#installation) for details on how to install the EVSL adapter. 

### Lua Versus Java

Exasol Virtual Schema for Lua is much faster than the Java Variant. The reason for this is that it does not have the overhead of starting the OS container and runtime environment that Java variant requires. This allows for much lower query latency. Typically, milliseconds instead of seconds.

EVSL requires Exasol 8 or later to run.

### Use Cases

The use cases for a remote connection are more intuitive, so let's start with those:

1. Make data that is missing in an Exasol database, but present in another one available without copying it (data consolidation)
2. Create a staging area that holds external data so that you can transform and import it ([ETL / ELT](https://docs.exasol.com/db/latest/loading_data/etl.htm))
3. Provide partial access to external data without giving users credentials for the remote database

Local connections mainly exist as a means of testing Virtual Schemas without dependencies and as a basis for [Row Level Security](https://github.com/exasol/row-level-security-lua).

### Query Rewriting and Push-Down

The main function of a Virtual Schema is to take a query and turn it into a different one that reads from the data source. The input query — that means the query users of a Virtual Schema run — is always a `SELECT` statement.

If your EVSL uses local access the output query will also be a `SELECT` statement — after all the data is on the same database.

In the remote connection case the output query is an `IMPORT` statement, thus allowing to get data via a network connection.

Make sure you always use local access if source and Virtual Schema are on the same database, because this is much more efficient.

The output query is also called "push-down query", since it is pushed down to the data source. See section ["Examining the Push-down query"](#examining-the-push-down-query)

## Installation

What you will need before you begin:

1. Exasol Version 8 or higher
2. A database schema where you can install the adapter script
3. The database privilege to install the script
4. A copy of the adapter script from the [release page](https://github.com/exasol/exasol-virtual-schema-lua/releases) (check for latest release)

   `exasol-virtual-schema-dist-<version>.lua`

Make sure you pick the file with `-dist-` in the name, because that is the installation package that contains everything you need.

### Creating a Schema to Hold the Adapter Script

For the purpose of the user guide we will assume that you install the adapter in a schema called `EVSL_SCHEMA`.

If you are not the admin the database, please ask an administrator to create that schema for you and grant you write permissions.

```sql
CREATE SCHEMA EVSL_SCHEMA;
```

### Creating Virtual Schema Adapter Script

Now you need to install the adapter script (i.e. the plug-in that drives the Virtual Schema):

```sql
CREATE OR REPLACE LUA ADAPTER SCRIPT EVSL_SCHEMA.EVSL_ADAPTER AS
    -- Replace this comment here with the whole content of exasol-virtual-schema-dist-<version>.lua
/
;
```

The first fixed part is a module loading preamble that is required since Exasol's Lua implementation changes module loading from vanilla Lua. These lines are required to re-add the missing loader feature.

### Creating a Virtual Schema

Now that the adapter is ready, you can define the actual Virtual Schema. The VS definition references the adapter, so that Exasol knows which piece of software it should delegate requests to the VS to.

Here's how you create a local Virtual Schema:

```sql
CREATE VIRTUAL SCHEMA EVSL_VIRTUAL_SCHEMA
    USING EVSL_SCHEMA.EVSL_ADAPTER
    WITH
    SCHEMA_NAME = '<schema name>'
```
The adapter property `SCHEMA_NAME` points to the _source_ schema on top of which the Virtual Schema acts as projection. This is a _mandatory_ adapter property.

See ["Adapter Properties"](#adapter-properties) for details on the configuration options.

For a remote virtual schema you first need to [create a connection](https://docs.exasol.com/db/latest/sql/create_connection.htm).

```sql
CREATE CONNECTION VS_CONNECTION
   TO '<host-or-list>:<port>'
   USER '<user>'
   IDENTIFIED BY '<password>'
```

Then you can reference that connection in the Virtual Schema creation:

```sql
CREATE VIRTUAL SCHEMA EVSL_VIRTUAL_SCHEMA
    USING EVSL_SCHEMA.EVSL_ADAPTER
    WITH
    SCHEMA_NAME = '<schema name>'
    CONNECTION_NAME = 'VS_CONNECTION'
```

Remote connections have been supported since EVSL 0.4.0.

#### Adapter Properties

Adapter properties are configuration key-value pairs that you can use to control the behavior of the Virtual Schema. When you create the Virtual Schema, adapter properties follow the `WITH` keyword.


| Property              | Meaning                                                                       | Example          | Mandatory |
|-----------------------|-------------------------------------------------------------------------------|------------------|:---------:|
| **SCHEMA_NAME**       | Name of the source schema                                                     | `SALES`          |    ✅     |
| **CONNECTION_NAME**   | Name of the connection object containing access configuration and credentials | `VS_CONNECTION`  |  remote   |
| DEBUG_ADDRESS         | Host and port where the debug log should go                                   | `localhost:3000` |    ❌     |
| EXCLUDED_CAPABILITIES | Comma-separated list of capabilities not to push down                         | `LIMIT`          |    ❌     |
| LOG_LEVEL             | How detailed the log should be                                                | `TRACE`          |    ❌     |
| TABLE_FILTER          | Comma-separated include-list for tables from the source                       | `STOCK, PRICES`  |    ❌     |


### Granting Access to the Virtual Schema

Granting permissions requires admin privileges on the database, so if you are not the administrator, please ask your admin to do that for you.

> [!IMPORTANT]
> Make sure you grant regular users only access to the Exasol Virtual Schema. _Not to the origin_ schema. Otherwise, those users can simply bypass the Virtual Schema by going to the source.

Here is an example for allowing `SELECT` statements to a user.

```sql
GRANT SELECT ON SCHEMA <virtual schema name> TO <user>;
```

Please refer to the documentation of the [`GRANT`](https://docs.exasol.com/sql/grant.htm) statement for further details.

The minimum requirements for a regular user in order to be able to access the Virtual Schema are:

* User must exist (`CREATE USER`)
* User is allowed to create sessions (`GRANT CREATE SESSION`)
* User can execute `SELECT` statements on the Virtual Schema (`GRANT SELECT`)

Here is an example where we create a user `JOHN_DOE` and grant just the minimal permissions required to use the Virtual Schema.

```sql
CREATE USER JOHN_DOE IDENTIFIED BY "<strong password goes here>";
GRANT CREATE SESSION TO JOHN_DOE;
GRANT SELECT ON EVSL_VIRTUAL_SCHEMA TO JOHN_DOE;
```

### Adapter Capabilities

Which SQL constructs are pushed-down to Exasol's Virtual Schema is decided by the optimizer based on the original query and on the capabilities reported by the [Virtual Schema adapter](#virtual-schema-adapter).

The Exasol Virtual Schema supports the capabilities listed in the file [`adapter_capabilities.lua`](../../src/main/lua/exasol/evsl/adapter_capabilities.lua).

Please note that excluded capabilities are not the only reason why a construct might not be pushed down. Given the nature of the queries pushed to the Virtual Schema, the `LIMIT`-clause for example will rarely — if ever — be pushed down with a local setup even though the adapter can handle that. The Virtual Schema creates `SELECT` statements and not `IMPORT` statements.

The simple reason `LIMIT` not pushed is, that the optimizer decides it is more efficient in this particular case.

#### Excluding Capabilities

Sometimes you want to prevent constructs from being pushed down. In this case, you can tell the Virtual Schema adapter to exclude one or more capabilities from being reported to the core database.

The core database will then refrain from pushing down the related SQL constructs.

Just add the property `EXCLUDED_CAPABILITIES` to the Virtual Schema creation statement and provide a comma-separated list of capabilities you want to exclude.

```sql
CREATE VIRTUAL SCHEMA EVSL_VIRTUAL_SCHEMA
    USING EVSL_SCHEMA.EVSL_ADAPTER
    WITH
    SCHEMA_NAME = '<schema name>'
    EXCLUDED_CAPABILITIES = 'SELECTLIST_PROJECTION, ORDER_BY_COLUMN'
```

### Filtering Tables

Often you will not need or even want all the tables in the source schema to be visible in the RLS-protected schema. In those cases you can simply specify an include-list as a property when creating the Virtual Schema.

Just provide a comma-separated list of table names in the property `TABLE_FILTER` and the scan of the source schema will skip all tables that are not listed. In a source schema with a large number of tables, this can also speed up the scan.

```sql
CREATE VIRTUAL SCHEMA EVSL_VIRTUAL_SCHEMA
    USING EVSL_SCHEMA.EVSL_ADAPTER
    WITH
    SCHEMA_NAME = '<schema name>'
    TABLE_FILTER = 'ORDERS, ORDER_ITEMS, PRODUCTS'
```

Spaces around the table names are ignored.

### Changing the Properties of an Existing Virtual Schema

While you could in theory drop and re-create a Virtual Schema, there is a more convenient way to apply changes in the adapter properties.

Use `ALTER VIRTUAL SCHEMA ... SET ...` to update the properties of an existing Virtual Schema.

Example:

```sql
ALTER VIRTUAL SCHEMA EVSL_VIRTUAL_SCHEMA
SET SCHEMA_NAME = '<new schema name>'
```

You can for example change the `SCHEMA_NAME` property to point the Virtual Schema to a new source schema or widen the [table filter](#filtering-tables).

## Refreshing a Virtual Schema

All Virtual Schemas cache their metadata. That metadata for example contains all information about structure and data types of the underlying data source. This makes the VS fast, since it does not have to query the metadata from the source with each push down.

The downside is that like any other cache this can get stale. Please use the [`ALTER VIRTUAL SCHEMA ... REFRESH`](https://docs.exasol.com/sql/alter_schema.htm) statement to refresh the metadata when it changed on the source.

```
ALTER VIRTUAL SCHEMA <virtul schema name> REFRESH
```

## Using the Virtual Schema

You use Virtual Schemas exactly like you would use a regular schema. The main difference is that they are read-only.

So if you want to query a table in a Virtual Schema, just use the `SELECT` statement.

Example:

```sql
SELECT * FROM EVSL_VIRTUAL_SCHEMA.<table>
```

### Examining the Push-down Query

To understand what a Virtual Schema really does and as a starting point for optimizing your queries, it often helps to take a look at the push-down query Exasol generates. This is as easy as prepending `EXPLAIN VIRTUAL` to your Query.

Example:

```sql
EXPLAIN VIRTUAL SELECT * FROM EVSL_VIRTUAL_SCHEMA.<table>
```

## Known Limitations

### No TLS Certificates

Lua in Exasol does not have filesystem access. Not even to BucketFS. The [Virtual Schema Adapter](#virtual-schema-adapter) uses the [Exasol Lua driver](https://github.com/exasol/exasol-driver-lua/) which in turn accesses the [Exasol Websocket API](https://github.com/exasol/websocket-api/). This is done via a TLS connection.

But since Lua does not have filesystem access, we cannot load certificates, which means that the Lua adapter **cannot verify TLS certificates**. This is a severe limitation that we plan to fix in future versions with dedicated certificate access. Not checking the certificate means you cannot establish the authenticity of the peer of a TLS connection. This makes the connection vulnerable to man-in-the-middle attacks. 
