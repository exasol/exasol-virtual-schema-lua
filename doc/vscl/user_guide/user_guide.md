# Virtual Schema Common Lua &mdash; User Guide

Users from the perspective of VSCL are developers integrating the library into their Virtual Schema and using the API.

Note that there is a [Developer Guide](../developer_guide/developer_guide.md) for developers who want to build or modify the library or contribute to the project.

## Validators

For common validation tasks you can find ready-to-use validators in `exasol.validator`.

* `validate_user(user)`: check that the user has a compliant SQL object identifier
* `validate_port(port)`: check that the given port is a number between 1 and 65535.

If the validation fails, the validator raises an error. Otherwise, the function silently succeeds.