# exasol-virtual-schema-lua, released 2022-06-??
 
Code name: Initial release
 
## Summary
 
In Version 0.1.0 is the initial release of the Lua-based Exasol Virtual Schema. It is derived from RLS Lua.

### Known Limitations

* Only supports local Exasol virtual schemas. This means source schema and virtual schema need to be on the same database. Network is not yet supported.
* Aggregate functions are not yet supported.
 
## Features / Enhancements

## Refactoring
 
* #2: Ported sources from [`row-level-security-lua`](https://github.com/exasol/row-level-security-lua).