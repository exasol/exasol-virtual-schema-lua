# Exasol Virtual Schema (Lua)

Exasol Virtual Schema for Lua (short "EVSL") is an implementation of a [Virtual Schema](https://docs.exasol.com/db/latest/database_concepts/virtual_schemas.htm).

With EVSL you can make a read-only connection from a schema in an Exasol database to a so-called "Virtual Schema". A Virtual Schema is a projection of the data in the source schema. It looks and feels like a real schema with the main difference being that you can only read data and not write it.

Exasol Virtual Schema comes in two flavors:

* Local database access
* Remote database connection

Local access means that origin schema and Virtual Schema must be on the same database. The remote database connection is more useful, as it allows projecting a schema from a different Exasol database into your own.

Remote connections are not yet implemented in the Lua-Variant. If you need it, please use [Exasol Virtual Schema for Java](https://github.com/exasol/exasol-virtual-schema). Remote support is on the roadmap for the Lua variant. You can check [ticket #80](https://github.com/exasol/exasol-virtual-schema/issues/80) to monitor the progress.

## Introduction

Each Virtual Schema needs a data source. In the case of Exasol Virtual Schema for Lua, this source is a database schema in an Exasol database. We call that the "origin schema".

Conceptually Virtual Schemas are very similar to database views. They have an owner (typically the one who creates them) and share that owners access permissions. This means that for a Virtual Schema to be useful, the owner must have the permissions to view the source.

Users of the Virtual Schema must have permissions to view the Virtual Schema itself, but they don't need permissions to view the source.

### Virtual Schema Adapter

Each Virtual Schema requires an Adapter. Think of this as a plug-in for Exasol that defines how to access data from a specific source.

Check the section ["Installation"](#installation) for details on how to install the EVSL adapter. 

### Lua Versus Java

Exasol Virtual Schema for Lua is much faster than the Java Variant. The reason for this is that is does not have the overhead of starting the sandbox and runtime environment that Java variant requires. This allows for much lower query latency. Typically, milliseconds instead of seconds.

EVSL requires Exasol 7.1 or later to run, since Virtual Schema support for the Lua language has been introduced with 7.1.

### Exasol Virtual Schema Lua Supersedes the Java Variant

Since the Lua variant is a lot faster, we will retire the Java variant once EVSL is a feature parity (i.e. version 1.0.0) and Exasol 7.0 goes out of support. See our [product life cycle](https://www.exasol.com/portal/display/DOWNLOAD/Exasol+Life+Cycle) for details.

### Use Cases

The use cases for a remote connection are more intuitive, so let's start with those:

1. Make data that is missing in an Exasol database, but present in another one available without copying it (data consolidation)
2. Create a staging area that holds external data so that you can transform and import it ([ETL / ELT](https://docs.exasol.com/db/latest/loading_data/etl.htm))
3. Provide partial access to external data without giving users credentials for the remote database

Local connections mainly exist as a means of testing Virtual Schemas without dependencies and as a basis for [Row Level Security](https://github.com/exasol/row-level-security-lua).

### Query Rewriting and Push-Down

The main function of a Virtual Schema is to take a query and turn it into a different one that reads from the data source. The input query &mdash; that means the query users of a Virtual Schema run &mdash; is always a `SELECT` statement.

If your EVSL uses local access the output query will also be a `SELECT` statement &mdash; after all the data is on the same database.

In the remote connection case the output query is an `IMPORT` statement, thus allowing to get data via a network connection.

Make sure you always use local access if source and Virtual schema are on the same database, because this is much more efficient.

The output query is also called "push-down query", since it is pushed down to the data source. See section ["Examining the Push-down query"](#examining-the-push-down-query)

## Installation

What you will need before you begin:

1. Exasol Version 7.1
2. A database schema where you can install the adapter script
3. The database privilege to install the script
4. A copy of the adapter script from the [release page](https://github.com/exasol/exasol-virtual-schema-lua/releases) (check for latest release)

   `exasol-virtual-schema-dist-<version>.lua`

Make sure you pick the file with `-dist-` in the name, because that is the installation package that contains everything you need.

### Creating a Schema to Hold the Adapter Script

For the purpose of the User Guide we will assume that you install the adapter in a schema called `EVSL_SCHEMA`.

If you are not the admin the database, please ask an administrator to create that schema for you and grant you write permissions.

```sql
CREATE SCHEMA EVSL_SCHEMA;
```

### Creating Virtual Schema Adapter Script

Now you need to install the adapter script (i.e. the plug-in that drives the Virtual Schema):

```sql
CREATE OR REPLACE LUA ADAPTER SCRIPT EVLS_SCHEMA.EVSL_ADAPTER AS
    table.insert(package.searchers,
        function (module_name)
            local loader = package.preload[module_name]
            if(loader == nil) then
                error("Module " .. module_name .. " not found in package.preload.")
            else
                return loader
            end
        end
    )
    
    <copy the whole content of row-level-security-dist-<version>.lua here>
/
;
```

The first fixed part is a module loading preamble that is required with 7.1. Later versions will make this unnecessary, the user guide will be updated accordingly if an Exasol release is available that incorporates that module loading feature by default.

### Creating Virtual Schema

```sql
CREATE VIRTUAL SCHEMA EVSL_VIRTUAL_SCHEMA
    USING EVSL_SCHEMA.EVSL_ADAPTER
    WITH
    SCHEMA_NAME     = '<schema name>'
```

### Granting Access to the Virtual Schema

Granting permissions requires admin privileges on the database, so if you are not the administrator, please ask your admin to do that for you.

⚠ 
A word or warning before you start granting permissions. Make sure you grant only access to the Exasol Virtual Schema to regular users and _not to the origin_ schema. Otherwise, those users can simply bypass the Virtual Schema by going to the source.

Here is an example for allowing `SELECT` statements to a user.

```sql
GRANT SELECT ON SCHEMA <virtual schema name> TO <user>;
```

Please refer to the documentation of the [`GRANT`](https://docs.exasol.com/sql/grant.htm) statement for further details.

The minimum requirements for a regular user in order to be able to access the RLS are:

* User must exist (`CREATE USER`)
* User is allowed to create sessions (`GRANT CREATE SESSION`)
* User can execute `SELECT` statements on the Virtual Schema (`GRANT SELECT`)

Here is an example where we create a user `JOHN_DOE` and grant just the minimal permissions required to use the Virtual Schema.

```sql
CREATE USER JOHN_DOE IDENTIFIED BY "the password";
GRANT CREATE SESSION TO JOHN_DOE;
GRANT SELECT ON EVSL_VIRTUAL_SCHEMA TO JOHN_DOE;
```

Of course, we trust that you will pick a stronger password in real life than we used for the purpose of this example. 

### Adapter Capabilities

Which SQL constructs are pushed-down to Exasol's Virtual Schema is decided by the optimizer based on the original query and on the capabilities reported by the Virtual Schema adapter (i.e. the software driving RLS).

The Exasol Virtual Schema supports the capabilities listed in the file [`adapter_capabilities.lua`](../../src/main/lua/exasolvs/adapter_capabilities.lua).

Please note that excluded capabilities are not the only reason why a construct might not be pushed down. Given the nature of the queries pushed to RLS, the `LIMIT`-clause for example will rarely &mdash; if ever &mdash; be pushed down even though the adapter can handle that. RLS creates `SELECT` statements and not `IMPORT` statements.
The simple reason `LIMIT` not pushed is, that the optimizer decides it is more efficient in this particular case.

#### Excluding Capabilities

Sometimes you want to prevent constructs from being pushed down. In this case, you can tell the RLS adapter to exclude one or more capabilities from being reported to the core database.

The core database will then refrain from pushing down the related SQL constructs.

Just add the property `EXCLUDED_CAPABILITIES` to the Virtual Schema creation statement and provide a comma-separated list of capabilities you want to exclude.

```sql
CREATE VIRTUAL SCHEMA EVSL_VIRTUAL_SCHEMA
    USING EVSL_SCHEMA.EVSL_ADAPTER
    WITH
    SCHEMA_NAME           = '<schema name>'
    EXCLUDED_CAPABILITIES = 'SELECTLIST_PROJECTION, ORDER_BY_COLUMN'
```

### Filtering Tables

Often you will not need or even want all the tables in the source schema to be visible in the RLS-protected schema. In those cases you can simply specify an include-list as a property when creating the RLS Virtual Schema.

Just provide a comma-separated list of table names in the property `TABLE_FILTER` and the scan of the source schema will skip all tables that are not listed. In a source schema with a large number of tables, this can also speed up the scan.

```sql
CREATE VIRTUAL SCHEMA EVSL_VIRTUAL_SCHEMA
    USING EVSL_SCHEMA.EVSL_ADAPTER
    WITH
    SCHEMA_NAME  = '<schema name>'
    TABLE_FILTER = 'ORDERS, ORDER_ITEMS, PRODUCTS'
```

Spaces around the table names are ignored.

### Changing the Properties of an Existing Virtual Schema

While you could in theory drop and re-create an Virtual Schema, there is a more convenient way to apply changes in the adapter properties.

Use `ALTER VIRTUAL SCHEMA ... SET ...` to update the properties of an existing Virtual Schema.

Example:

```sql
ALTER VIRTUAL SCHEMA EVSL_VIRTUAL_SCHEMA
SET SCHEMA_NAME = '<new schema name>'
```

You can for example change the `SCHEMA_NAME` property to point the Virtual Schema to a new source schema or the [table filter](#filtering-tables).

## Updating a Virtual Schema

All Virtual Schemas cache their metadata. That metadata for example contains all information about structure and data types of the underlying data source. RLS is a Virtual Schema and uses the same caching mechanism.

To let RLS know that something changed in the metadata, please use the [`ALTER VIRTUAL SCHEMA ... REFRESH`](https://docs.exasol.com/sql/alter_schema.htm) statement.

```
ALTER VIRTUAL SCHEMA <virtul schema name> REFRESH
```

Please note that this is also required if you change the special columns that control the RLS protection.


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

* `SELECT *` is not yet supported due to an issue between the core database and the LUA Virtual Schemas in push-down requests (SPOT-10626)
* Source Schema and Virtual Schema must be on the same database.