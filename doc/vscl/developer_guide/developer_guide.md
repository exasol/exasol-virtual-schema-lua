# Developer Guide

## Preparation

Before you can build and test the application, you need to install Lua packages on the build machine.

### Installing LuaRocks

First install the package manager LuaRocks.

```bash
sudo apt install luarocks
```

Now update your `LUA_PATH`, so that it contains the packages (aka. "rocks"). You can auto-generate that path.

```bash
luarocks path
```

Of course generating it is not enough, you also need to make sure the export is actually executed &mdash; preferably automatically each time. Here is an example that appends the path to the `.bashrc`:

```bash
luarocks path >> ~/.bashrc
```

### Installing the Required Lua Packages

You need the packages for unit testing, mocking and JSON processing.

Execute this to install in your home directory:

```bash
luarocks install --local --deps-only *.rockspec
```

Most of the packages are only required for testing. While `cjson` is needed at runtime, it is prepackaged with Exasol, so no need to install it at runtime.

The `luacov` and `luacov-coveralls` libraries take care of measuring and reporting code coverage in the tests.

## How to Run Lua Unit Tests

### Run Unit Tests From Terminal

To run unit tests from terminal, you first need to install Lua:

```bash
sudo apt install lua5.4
```

The tests reside in the `spec` directory. You can run all tests by calling `busted` from the project root.

```bash
busted
```

To run a single test add the file name:

```bash
busted spec/exasol/vscl/validator_spec.lua
```

If you want to run all unit tests including code coverage, issue the following command:

```bash
./tools/run_tests.sh
```

## Building API Documentation

To build the API documentation using `luals` issue the following command:

```bash
./tools/build_docs.sh
```

The documentation will be written as a Markdown file to `target/luals-doc/doc.md`.

## Formatting Sources

First install [LuaFormatter](https://github.com/Koihik/LuaFormatter) by executing the following command:

```bash
luarocks install --local --server=https://luarocks.org/dev luaformatter
```

Then format all Lua sources by executing the following command:

```bash
./tools/format_lua.sh
```

## Running Static Code Analysis

To run static code analysis for Lua using luacheck issue the following command:

```bash
./tools/run_luacheck.sh
```

## Running Type Checker

```bash
./tools/run-type-check.sh
```

### Understanding the Sources

Under [doc/model](../model/) you find a UML model of the project that you can render with [PlantUML](https://plantuml.com/). We recommend studying the model to understand structure and behavior.

You can render the model by running:

```bash
./tools/build_diagrams.sh
```

The resulting SVG files are located under `doc/images/generated/`. They contain links for drilling down.

Since the model contains all important information, here just a very short summary.

1. VSCL provides a base library for writing your own Virtual Schemas in Lua
2. The resulting package is available as LuaRocks package `virtual-schema-common-lua`
3. In your concrete Virtual Schema implementation you need to write an `entry` module, that has an `adapter_call` entry function
4. The `entry` module should create and wire up all static objects (like the `RequestDispatcher` for example)
5. Use the `remotelog` package for logging

#### Wrapping the Push-down Query into an Import

Virtual Schemas often use the ExaLoader to get the data from the remote data source. To use the ExaLoader, you need an `IMPORT` statement.

The original push-down query is a `SELECT` and the `IMPORT` must wrap that `SELECT` after rewriting it.

```lua
ImportQueryBuilder:new()
       :connection("my_connection")
       :statement({
            type = "select"
            -- ... rest of the push-down query
        })
       :column_types({
            {type = "VARCHAR", size = 80},
            {type = "BOOLEAN"}
        })
       :build()
```

### Running the Unit Tests From Intellij IDEA

First, you need to install a plug-in that handles Lua code. We recommend the [EmmyLua](https://github.com/EmmyLua/IntelliJ-EmmyLua), which is also available directly from the IntelliJ marketplace. 

1. Get the Lua path (including your local LuaRocks repository) by running:
    ```bash
    luarocks path --local
    ```
   This will output a set of `export` commands that set the right paths.
2. Create a wrapper script for starting IntelliJ with the right Lua path and use the `export` commands you generated in the previous step
3. Start IntelliJ from the wrapper script
4. Open the terminal in IntelliJ (`[ALT] + [F12]`)
5. Verify the Lua path in the integrated terminal:
    ```bash
    echo $LUA_PATH
    ```
6. Verify that the test suit runs by running busted in the integrated terminal:
   ```bash
   busted
   ```
7. The project comes with an `.idea` directory and `<project-name>.iml` which contain setup information for IntelliJ
  
Now you can right-click any unit-test class and `Run...` (`[CTRL] + [SHIFT] + [F10]`).

### Running the Unit Tests From Eclipse IDE

We usually recommend you install the [Lua Development Tools (LDT)](https://www.eclipse.org/ldt/). Unfortunately Lua 5.4 is not supported and the project does not receive any updates anymore.

## Virtual Schema Limitations

Developers writing Virtual Schema adapters should know about the limitations of Virtual Schemas.

### No Push-down for Analytic Functions

[Analytic functions](https://docs.exasol.com/db/latest/sql_references/functions/analyticfunctions.htm) are aggregate functions that have an `OVER` clause. Since they are connected, this also applies to the `PARTITION`, `WINDOW FRAME` and partition `ORDER` clauses.  

Exasol does not support pushing analytic functions to the source database. This would be too complex and is very seldom useful in the situations were Virtual Schemas are needed. Virtual Schemas mainly exist to explore a remote data source through Exasol. Often as preparation for later data export directly through the ExaLoader.

So to recapitulate: while basic aggregate functions are supported, the `OVER` clause is not.

### Read the Documentation on Functions

Sometimes limitations come in the form of SQL phrases that Exasol ignores. Take [`RESPECT NULLS` in `FIRST_VALUE`](https://docs.exasol.com/db/latest/sql_references/functions/alphabeticallistfunctions/first_value.htm) for example. The Exasol core database simply ignores it, so there is also no push-down.

So if you are unsure about the behavior of a certain function, please check [Exasol's online user guide](https://docs.exasol.com/db/latest/sql_references/functions/built-in_functions.htm).
