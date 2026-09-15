# Exasol Virtual Schema Lua 1.0.1, released 2026-08-??

Code name: Fixed vulnerability CVE-2026-86231 in com.github.mwiede:jsch:jar:2.28.5:test

## Summary

This release fixes remote queries with typed `NULL` literals in top-level select lists.

This release fixes the following vulnerability:

### CVE-2026-86231 (CWE-298) in dependency `com.github.mwiede:jsch:jar:2.28.5:test`
A security flaw has been discovered in mwiede jsch up to 2.28.5. Affected is the function getRevokedKeys of the file src/main/java/com/jcraft/jsch/KnownHosts.java. Performing a manipulation of the argument known_hosts results in improper check for certificate revocation. The attack is possible to be carried out remotely. The attack is considered to have high complexity. The exploitability is told to be difficult. The exploit has been released to the public and may be used for attacks. Upgrading to version 2.28.6 is able to address this issue.

#### References
* https://guide.sonatype.com/vulnerability/CVE-2026-86231?component-type=maven&component-name=com.github.mwiede%2Fjsch&utm_source=ossindex-client&utm_medium=integration&utm_content=1.8.1
* http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2026-86231
* https://github.com/mwiede/jsch/issues/1091
* https://github.com/mwiede/jsch/pull/1098
* https://github.com/mwiede/jsch/releases/tag/jsch-2.28.6

## Security

* #87: Fixed vulnerability CVE-2026-86231 in dependency `com.github.mwiede:jsch:jar:2.28.5:test`

## Bug Fixes

* #83: Fixed remote queries with typed `NULL` literals in top-level select lists.
* #85: Fixed local queries with top-level literals whose declared result type differs from the literal's inferred type.

## Dependency Updates

### Test Dependency Updates

* Updated `com.exasol:exasol-jdbc:26.2.8` to `26.2.9`
* Updated `com.exasol:exasol-testcontainers:8.0.1` to `8.0.2`
* Removed `org.junit.jupiter:junit-jupiter-api:5.14.4`
* Removed `org.junit.jupiter:junit-jupiter-params:5.14.4`
* Added `org.junit.jupiter:junit-jupiter:6.1.3`
* Updated `org.slf4j:slf4j-jdk14:2.0.18` to `2.0.19`
* Removed `org.testcontainers:junit-jupiter:1.21.4`
* Added `org.testcontainers:testcontainers-junit-jupiter:2.0.5`

### Plugin Dependency Updates

* Updated `com.exasol:error-code-crawler-maven-plugin:2.1.1` to `2.1.2`
* Updated `com.exasol:project-keeper-maven-plugin:5.7.4` to `5.7.5`
* Updated `io.github.git-commit-id:git-commit-id-maven-plugin:10.0.0` to `10.0.1`
* Updated `org.apache.maven.plugins:maven-toolchains-plugin:3.2.0` to `3.3.0`
* Updated `org.codehaus.mojo:build-helper-maven-plugin:3.6.1` to `3.6.2`
* Updated `org.codehaus.mojo:exec-maven-plugin:3.6.3` to `3.6.4`
* Updated `org.codehaus.mojo:flatten-maven-plugin:1.7.3` to `1.8.0`
