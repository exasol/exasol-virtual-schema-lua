package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.jupiter.api.Assertions.assertAll;

import com.exasol.matcher.ResultSetStructureMatcher;
import com.exasol.matcher.TypeMatchMode;
import org.hamcrest.Matchers;
import org.jetbrains.annotations.NotNull;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

import java.sql.ResultSet;
import java.sql.SQLException;

// [itest -> dsn~creating-a-local-virtual-schema~0] implicitly tested with each query on a Virtual Schema
@Testcontainers
class SelectIT extends AbstractLuaVirtualSchemaIT {
    //  [itest -> dsn~push-down~0]
    @Test
    void testSelectStarOnUnprotectedTable() {
        final String sourceSchemaName = "SELECT_STAR_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("SELECT_STAR_USER", virtualSchema);
        assertQueryWithUser("SELECT * FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                table().row(true).row(false).matches());
    }

     // This test case describes a situation where a push-down query request with an empty select list is received. This
    // might happen because the core database evaluates constant expressions before performing the push-down query to
    // the Virtual Schema. In such cases the adapter internally fills the select list with a dummy expression that only
    // serves the purpose of providing the right number of rows in the result set.
    //  [itest -> dsn~push-down~0]
    @Test
    void testEmptySelectList() {
        final String sourceSchemaName = "EMPTY_SELECT_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("EMPTY_SELECT_USER", virtualSchema);
        assertQueryWithUser("SELECT 'foo' FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                table().row("foo").row("foo").matches());
    }

    //  [itest -> dsn~push-down~0]
    @Test
    void testSelectWithOrderByColumnAndLimit() {
        final String sourceSchemaName = "ORDER_LIMIT_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "NR", "INTEGER").insert(1).insert(2).insert(3);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("ORDER_LIMIT_USER", virtualSchema);
        assertQueryWithUser("SELECT NR FROM " + getVirtualSchemaName(sourceSchemaName)
                        + ".T ORDER BY NR LIMIT 2", user,
                table().row(1).row(2).matches(TypeMatchMode.NO_JAVA_TYPE_CHECK));
    }

    //  [itest -> dsn~push-down~0]
    @Test
    void testSelectWithOrderByExpressionAndLimitWithOffset() {
        final String sourceSchemaName = "ORDER_LIMIT_OFFSET_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "TXT", "VARCHAR(10)").insert("a").insert("bb").insert("ccc").insert("dddd");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("ORDER_LIMIT_OFFSET_USER", virtualSchema);
        assertQueryWithUser("SELECT TXT FROM " + getVirtualSchemaName(sourceSchemaName)
                        + ".T ORDER BY LENGTH(TXT) LIMIT 2 OFFSET 1", user,
                table().row("bb").row("ccc").matches());
    }

    @Test
    void testInnerJoin() {
        final Schema sourceSchema = createJoinSchema("INNER_JOIN_SCHEMA");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("INNER_JOIN_USER", virtualSchema);
        final String virtualSchemaName = getVirtualSchemaName(sourceSchema.getName());
        assertJoinQuery("SELECT LJC, RJC FROM " + virtualSchemaName + ".T_LEFT"
                + " INNER JOIN " + virtualSchemaName + ".T_RIGHT ON LJC = RJC ORDER BY LJC, RJC", user,
                table().row("L+R", "L+R"), "SELECT.*FROM.*INNER JOIN.*");
    }

    @Test
    void testFullOuterJoin() {
        final Schema sourceSchema = createJoinSchema("FULL_OUTER_JOIN_SCHEMA");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("FULL_OUTER_JOIN_USER", virtualSchema);
        final String virtualSchemaName = getVirtualSchemaName(sourceSchema.getName());
        assertJoinQuery("SELECT LJC, RJC FROM " + virtualSchemaName + ".T_LEFT"
                + " FULL OUTER JOIN " + virtualSchemaName + ".T_RIGHT ON LJC = RJC ORDER BY LJC, RJC", user,
                table().row("L", null).row("L+R", "L+R").row(null, "R"), "SELECT.*FROM.*FULL OUTER JOIN.*");
    }

    @Test
    void testLeftJoin() {
        final Schema sourceSchema = createJoinSchema("LEFT_JOIN_SCHEMA");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("LEFT_JOIN_USER", virtualSchema);
        final String virtualSchemaName = getVirtualSchemaName(sourceSchema.getName());
        assertJoinQuery("SELECT LJC, RJC FROM " + virtualSchemaName + ".T_LEFT"
                + " LEFT JOIN " + virtualSchemaName + ".T_RIGHT ON LJC = RJC ORDER BY LJC, RJC", user,
                table().row("L", null).row("L+R", "L+R"), "SELECT.*FROM.*LEFT OUTER JOIN.*");
    }

    @Test
    void testRightJoin() {
        final Schema sourceSchema = createJoinSchema("RIGHT_JOIN_SCHEMA");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("RIGHT_JOIN_USER", virtualSchema);
        final String virtualSchemaName = getVirtualSchemaName(sourceSchema.getName());
        assertJoinQuery("SELECT LJC, RJC FROM " + virtualSchemaName + ".T_LEFT"
                + " RIGHT JOIN " + virtualSchemaName + ".T_RIGHT ON LJC = RJC ORDER BY LJC, RJC", user,
                table().row("L+R", "L+R").row(null, "R"), "SELECT.*FROM.*RIGHT OUTER JOIN.*");
    }

    private void assertJoinQuery(final String sql, final User user,
                                 final ResultSetStructureMatcher.Builder resultMatcher, final String expectedPushDown) {
        assertAll(()-> assertQueryWithUser(sql, user, resultMatcher.matches()),
                ()->assertPushDownMatches(sql, user, expectedPushDown));
    }

    @NotNull
    private Schema createJoinSchema(final String sourceSchemaName) {
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T_LEFT", "LJC", "VARCHAR(3)").insert("L").insert("L+R");
        sourceSchema.createTable("T_RIGHT", "RJC", "VARCHAR(3)").insert("L+R").insert("R");
        return sourceSchema;
    }

    private void assertPushDownMatches(final String sql, final User user, final String expectedPattern) {
        try (final ResultSet result = executeQueryWithUser("EXPLAIN VIRTUAL " + sql, user)){
            result.next();
            final String pushDownSql = result.getString("PUSHDOWN_SQL");
            assertThat(pushDownSql, Matchers.matchesPattern(expectedPattern));
        } catch (final SQLException exception) {
            throw new AssertionError("Unable to run push-down assertion query:" + exception.getMessage());
        }
    }
}