<!-- @formatter:off -->
# Dependencies

## Test Dependencies

| Dependency                                     | License                           |
| ---------------------------------------------- | --------------------------------- |
| [Exasol JDBC Driver][0]                        | [EXAClient License][1]            |
| [Test containers for Exasol on Docker][2]      | [MIT License][3]                  |
| [Testcontainers :: JUnit Jupiter Extension][4] | [MIT][5]                          |
| [Hamcrest][6]                                  | [BSD-3-Clause][7]                 |
| [Matcher for SQL Result Sets][8]               | [MIT License][9]                  |
| [JUnit Jupiter API][10]                        | [Eclipse Public License v2.0][11] |
| [JUnit Jupiter Params][10]                     | [Eclipse Public License v2.0][11] |
| [SLF4J JDK14 Provider][12]                     | [MIT][13]                         |
| [Test Database Builder for Java][14]           | [MIT License][15]                 |
| [Maven Project Version Getter][16]             | [MIT License][17]                 |

## Plugin Dependencies

| Dependency                                              | License                                     |
| ------------------------------------------------------- | ------------------------------------------- |
| [SonarQube Scanner for Maven][18]                       | [GNU LGPL 3][19]                            |
| [Apache Maven Toolchains Plugin][20]                    | [Apache-2.0][21]                            |
| [Apache Maven Compiler Plugin][22]                      | [Apache-2.0][21]                            |
| [Apache Maven Enforcer Plugin][23]                      | [Apache-2.0][21]                            |
| [Maven Flatten Plugin][24]                              | [Apache Software License][21]               |
| [org.sonatype.ossindex.maven:ossindex-maven-plugin][25] | [ASL2][26]                                  |
| [Maven Surefire Plugin][27]                             | [Apache-2.0][21]                            |
| [Versions Maven Plugin][28]                             | [Apache License, Version 2.0][21]           |
| [duplicate-finder-maven-plugin Maven Mojo][29]          | [Apache License 2.0][30]                    |
| [Apache Maven Artifact Plugin][31]                      | [Apache-2.0][21]                            |
| [Maven Failsafe Plugin][32]                             | [Apache-2.0][21]                            |
| [JaCoCo :: Maven Plugin][33]                            | [EPL-2.0][34]                               |
| [Project Keeper Maven plugin][35]                       | [The MIT License][36]                       |
| [Exec Maven Plugin][37]                                 | [Apache License 2][21]                      |
| [OpenFastTrace Maven Plugin][38]                        | [GNU General Public License v3.0][39]       |
| [Build Helper Maven Plugin][40]                         | [The MIT License][41]                       |
| [Apache Maven JAR Plugin][42]                           | [Apache-2.0][21]                            |
| [PlantUML Maven Plugin][43]                             | [Apache License, Version 2.0][21]           |
| [error-code-crawler-maven-plugin][44]                   | [MIT License][45]                           |
| [Git Commit Id Maven Plugin][46]                        | [GNU Lesser General Public License 3.0][47] |
| [Apache Maven Clean Plugin][48]                         | [Apache-2.0][21]                            |
| [Apache Maven Resources Plugin][49]                     | [Apache-2.0][21]                            |
| [Apache Maven Install Plugin][50]                       | [Apache-2.0][21]                            |
| [Apache Maven Site Plugin][51]                          | [Apache-2.0][21]                            |

[0]: https://www.exasol.com/
[1]: https://repo1.maven.org/maven2/com/exasol/exasol-jdbc/26.2.8/exasol-jdbc-26.2.8-license.txt
[2]: https://github.com/exasol/exasol-testcontainers/
[3]: https://github.com/exasol/exasol-testcontainers/blob/main/LICENSE
[4]: https://java.testcontainers.org
[5]: http://opensource.org/licenses/MIT
[6]: http://hamcrest.org/JavaHamcrest/
[7]: https://raw.githubusercontent.com/hamcrest/JavaHamcrest/master/LICENSE
[8]: https://github.com/exasol/hamcrest-resultset-matcher/
[9]: https://github.com/exasol/hamcrest-resultset-matcher/blob/main/LICENSE
[10]: https://junit.org/
[11]: https://www.eclipse.org/legal/epl-v20.html
[12]: http://www.slf4j.org
[13]: https://opensource.org/license/mit
[14]: https://github.com/exasol/test-db-builder-java/
[15]: https://github.com/exasol/test-db-builder-java/blob/main/LICENSE
[16]: https://github.com/exasol/maven-project-version-getter/
[17]: https://github.com/exasol/maven-project-version-getter/blob/main/LICENSE
[18]: https://docs.sonarsource.com/sonarqube-server/latest/extension-guide/developing-a-plugin/plugin-basics/sonar-scanner-maven/sonar-maven-plugin/
[19]: http://www.gnu.org/licenses/lgpl.txt
[20]: https://maven.apache.org/plugins/maven-toolchains-plugin/
[21]: https://www.apache.org/licenses/LICENSE-2.0.txt
[22]: https://maven.apache.org/plugins/maven-compiler-plugin/
[23]: https://maven.apache.org/enforcer/maven-enforcer-plugin/
[24]: https://www.mojohaus.org/flatten-maven-plugin/
[25]: https://sonatype.github.io/ossindex-maven/maven-plugin/
[26]: http://www.apache.org/licenses/LICENSE-2.0.txt
[27]: https://maven.apache.org/surefire/maven-surefire-plugin/
[28]: https://www.mojohaus.org/versions/versions-maven-plugin/
[29]: https://basepom.github.io/duplicate-finder-maven-plugin
[30]: http://www.apache.org/licenses/LICENSE-2.0.html
[31]: https://maven.apache.org/plugins/maven-artifact-plugin/
[32]: https://maven.apache.org/surefire/maven-failsafe-plugin/
[33]: https://www.jacoco.org/jacoco/trunk/doc/maven.html
[34]: https://www.eclipse.org/legal/epl-2.0/
[35]: https://github.com/exasol/project-keeper/
[36]: https://github.com/exasol/project-keeper/blob/main/LICENSE
[37]: https://www.mojohaus.org/exec-maven-plugin
[38]: https://github.com/itsallcode/openfasttrace-maven-plugin
[39]: https://www.gnu.org/licenses/gpl-3.0.html
[40]: https://www.mojohaus.org/build-helper-maven-plugin/
[41]: https://spdx.org/licenses/MIT.txt
[42]: https://maven.apache.org/plugins/maven-jar-plugin/
[43]: http://github.com/itsallcode/plantuml-maven-plugin
[44]: https://github.com/exasol/error-code-crawler-maven-plugin/
[45]: https://github.com/exasol/error-code-crawler-maven-plugin/blob/main/LICENSE
[46]: https://github.com/git-commit-id/git-commit-id-maven-plugin
[47]: http://www.gnu.org/licenses/lgpl-3.0.txt
[48]: https://maven.apache.org/plugins/maven-clean-plugin/
[49]: https://maven.apache.org/plugins/maven-resources-plugin/
[50]: https://maven.apache.org/plugins/maven-install-plugin/
[51]: https://maven.apache.org/plugins/maven-site-plugin/
