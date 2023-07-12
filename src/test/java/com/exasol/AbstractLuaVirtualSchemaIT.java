package com.exasol;

import static com.exasol.ExasolVirtualSchemaTestConstants.DOCKER_DB;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.matchesPattern;
import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.*;
import java.time.Duration;
import java.util.Collections;
import java.util.Map;

import org.hamcrest.Matcher;
import org.junit.jupiter.api.BeforeAll;
import org.testcontainers.containers.JdbcDatabaseContainer.NoDriverFoundException;
import org.testcontainers.junit.jupiter.Container;

import com.exasol.containers.ExasolContainer;
import com.exasol.containers.ExasolDockerImageReference;
import com.exasol.dbbuilder.dialects.*;
import com.exasol.dbbuilder.dialects.exasol.*;
import com.exasol.matcher.ResultSetStructureMatcher;
import com.exasol.mavenprojectversiongetter.MavenProjectVersionGetter;

abstract class AbstractLuaVirtualSchemaIT {
    private static final int DEFAULT_LOG_PORT = 3000;
    private static final String LOG_PORT_PROPERTY = "com.exasol.log.port";
    private static final String LOG_HOST_PROPERTY = "com.exasol.log.host";
    private static final String VERSION = MavenProjectVersionGetter.getCurrentProjectVersion();
    private static final Path VS_PACKAGE_PATH = Path.of("target/exasol-virtual-schema-dist-" + VERSION + ".lua");
    @Container
    protected static final ExasolContainer<? extends ExasolContainer<?>> EXASOL = //
            new ExasolContainer<>(DOCKER_DB) //
                    .withRequiredServices() //
                    .withExposedPorts(8563) //
                    .withReuse(true);
    private static final String EXASOL_LUA_MODULE_LOADER_WORKAROUND = "table.insert(" //
            + "package.searchers" //
            + ",\n" //
            + "    function (module_name)\n" //
            + "        local loader = package.preload[module_name]\n" //
            + "        if(loader == nil) then\n" //
            + "            error(\"Module \" .. module_name .. \" not found in package.preload.\")\n" //
            + "        else\n" //
            + "            return loader\n" //
            + "        end\n" //
            + "    end\n" //
            + ")\n\n";
    protected static Connection connection;
    protected static ExasolObjectFactory factory;
    private static ExasolSchema scriptSchema;

    @BeforeAll
    static void beforeAll() throws NoDriverFoundException, SQLException {
        EXASOL.purgeDatabase();
        connection = EXASOL.createConnection("");
        factory = new ExasolObjectFactory(connection);
        scriptSchema = factory.createSchema("L");
    }

    /**
     * Creates a new virtual schema with the given source schema and properties.
     * <p>
     * Note: if you want to enable debug output, you can set <a href=
     * "https://github.com/exasol/test-db-builder-java/blob/main/doc/user_guide/user_guide.md#debug-output">system
     * properties defined by test-db-builder-java</a>.
     * 
     * @param sourceSchema the source schema for the new virtual schema
     * @param properties   the properties for the new virtual schema
     * @return the newly created virtual schema
     */
    protected VirtualSchema createVirtualSchema(final Schema sourceSchema, final Map<String, String> properties) {
        final String name = sourceSchema.getName();
        final AdapterScript adapterScript;
        try {
            adapterScript = createAdapterScript(name);
        } catch (final IOException exception) {
            throw new AssertionError("Unable to prepare adapter script \"" + name + "\" required for test", exception);
        }
        return factory.createVirtualSchemaBuilder(getVirtualSchemaName(name)) //
                .adapterScript(adapterScript) //
                .sourceSchema(sourceSchema) //
                .properties(properties) //
                .build();
    }

    protected VirtualSchema createVirtualSchema(final Schema sourceSchema) {
        return createVirtualSchema(sourceSchema, Collections.emptyMap());
    }

    protected VirtualSchema createRemoteVirtualSchema(final Schema sourceSchema, final String connectionName) {
        return createVirtualSchema(sourceSchema, Map.of("CONNECTION_NAME", connectionName));
    }

    protected AdapterScript createAdapterScript(final String prefix) throws IOException {
        final String content = EXASOL_LUA_MODULE_LOADER_WORKAROUND + Files.readString(VS_PACKAGE_PATH);
        return scriptSchema.createAdapterScript(prefix + "_ADAPTER", AdapterScript.Language.LUA, content);
    }

    protected String getVirtualSchemaName(final String sourceSchemaName) {
        return sourceSchemaName + "_VS";
    }

    protected String getVirtualSchemaName(final Schema sourceSchema) {
        return getVirtualSchemaName(sourceSchema.getName());
    }

    protected ResultSet executeQueryWithUser(final String query, final User user) throws SQLException {
        final Statement statement = EXASOL.createConnectionForUser(user.getName(), user.getPassword())
                .createStatement();
        return statement.executeQuery(query);
    }

    protected TimedResultSet executeTimedRlsQueryWithUser(final String query, final User user) throws SQLException {
        try (final Connection uncachedConnection = EXASOL.createConnectionForUser(user.getName(), user.getPassword());
                final Statement statement = uncachedConnection.createStatement()) {
            statement.execute("ALTER SESSION SET QUERY_CACHE = 'OFF'");
            final long before = System.nanoTime();
            final ResultSet result = statement.executeQuery(query);
            final long after = System.nanoTime();
            return new TimedResultSet(result, Duration.ofNanos(after - before));
        }
    }

    protected User createUserWithVirtualSchemaAccess(final String name, final VirtualSchema virtualSchema) {
        return factory.createLoginUser(name).grant(virtualSchema, ExasolObjectPrivilege.SELECT);
    }

    protected Schema createSchema(final String sourceSchemaName) {
        return factory.createSchema(sourceSchemaName);
    }

    protected void assertQueryWithUser(final String sql, final User user, final Matcher<ResultSet> expected) {
        try {
            final ResultSet result = executeQueryWithUser(sql, user);
            assertThat(result, expected);
        } catch (final SQLException exception) {
            throw new AssertionError("Unable to run assertion query:" + exception.getMessage());
        }
    }

    protected Duration assertTimedVsQueryWithUser(final String sql, final User user,
            final Matcher<ResultSet> expected) {
        try {
            final TimedResultSet timedResult = executeTimedRlsQueryWithUser(sql, user);
            assertThat(timedResult.getResultSet(), expected);
            return timedResult.getDuration();
        } catch (final SQLException exception) {
            throw new AssertionError("Unable to run assertion query.", exception);
        }
    }

    protected void assertJoinQuery(final String sql, final User user,
            final ResultSetStructureMatcher.Builder resultMatcher, final String expectedPushDown) {
        assertAll(() -> assertQueryWithUser(sql, user, resultMatcher.matches()),
                () -> assertPushDownMatches(sql, user, expectedPushDown));
    }

    protected void assertPushDownMatches(final String sql, final User user, final String expectedPattern) {
        assertPushDown(sql, user, matchesPattern(expectedPattern));
    }

    protected void assertPushDown(final String sql, final User user, final Matcher<String> matcher) {
        try (final ResultSet result = executeQueryWithUser("EXPLAIN VIRTUAL " + sql, user)) {
            result.next();
            final String pushDownSql = result.getString("PUSHDOWN_SQL");
            assertThat(pushDownSql, matcher);
        } catch (final SQLException exception) {
            throw new AssertionError("Unable to run push-down assertion query:" + exception.getMessage());
        }
    }

    static void assumeExasol8OrHigher() {
        assumeTrue(isExasol8OrHigher(), "is Exasol version 8 or higher");
    }

    static boolean isExasol8OrHigher() {
        final ExasolDockerImageReference imageReference = EXASOL.getDockerImageReference();
        return imageReference.hasMajor() && (imageReference.getMajor() >= 8);
    }

    protected void assumeExasol7OrLower() {
        final ExasolDockerImageReference imageReference = EXASOL.getDockerImageReference();
        assumeTrue(imageReference.hasMajor() && (imageReference.getMajor() <= 7), "is Exasol version 7 or lower");
    }

    protected void assertVirtualTableStructure(final Table table, final User user,
            final Matcher<ResultSet> tableMatcher) {
        assertQueryWithUser("/*snapshot execution*/DESCRIBE " + getVirtualSchemaName(table.getParent().getName()) + "."
                + table.getName(), user, tableMatcher);
    }
}