package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;

import com.exasol.dbbuilder.dialects.Table;
import com.exasol.matcher.TypeMatchMode;
import org.hamcrest.Matchers;
import org.jetbrains.annotations.NotNull;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

import java.sql.Timestamp;

// [itest -> dsn~evsl.creating-a-local-virtual-schema~0] implicitly tested with each query on a Virtual Schema
@Testcontainers
class SelectIT extends AbstractLuaVirtualSchemaIT {
    //  [itest -> dsn~evsl.local-push-down~0]
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
    //  [itest -> dsn~evsl.local-push-down~0]
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

    //  [itest -> dsn~evsl.local-push-down~0]
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

    //  [itest -> dsn~evsl.local-push-down~0]
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

    // Test for complex join conditions.
    // To understand the next test, we need a bit of explanation. We use an expression in the join condition here based
    // on the string length of two columns in the source schema.
    //
    // The following logic table shows which combinations match the join criteria.
    //
    // Left    Right   Length
    // -----------------------------
    // L       L+R     1 >? 3 : true
    // L+R     L+R     3 >? 3 : false
    // L       R       1 >? 1 : false
    // L+R     R       3 >? 1 : false
    @Test
    void testComplexJoinCriteria() {
        final Schema sourceSchema = createJoinSchema("COMPLEX_JOIN_SCHEMA");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("COMPLEX_JOIN_USER", virtualSchema);
        final String virtualSchemaName = getVirtualSchemaName(sourceSchema.getName());
        assertJoinQuery("SELECT LJC, RJC FROM " + virtualSchemaName + ".T_LEFT"
                        + " INNER JOIN " + virtualSchemaName + ".T_RIGHT"
                        + " ON LENGTH(LJC) < LENGTH(RJC) ORDER BY LJC, RJC", user,
                table().row("L", "L+R"), "SELECT.*FROM.*INNER JOIN.*ON \\(LENGTH.*");
    }

    @NotNull
    private Schema createJoinSchema(final String sourceSchemaName) {
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T_LEFT", "LJC", "VARCHAR(3)").insert("L").insert("L+R");
        sourceSchema.createTable("T_RIGHT", "RJC", "VARCHAR(3)").insert("L+R").insert("R");
        return sourceSchema;
    }

    @Test
    void testTimestampPrecision() {
        assumeTimestampPrecisionSupported();
        final Schema sourceSchema = factory.createSchema("TIMESTAMP_SCHEMA");
        final Table table = sourceSchema.createTable("TT", "TS", "TIMESTAMP", "TS1", "TIMESTAMP(1)",
                "TS9", "TIMESTAMP(9)");
        final Timestamp timestamp = Timestamp.valueOf("1234-05-06 07:08:09.123");
        final Timestamp epoch = Timestamp.valueOf("1970-01-01 00:00:00");
        final Timestamp timestamp9 = Timestamp.valueOf("1999-12-31 23:59:59.999999999");
        table.insert(timestamp, epoch, timestamp9);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("TIMESTAMP_USER", virtualSchema);
        assertQueryWithUser("SELECT * FROM " + virtualSchema.getName() + ".TT",
                user,
                table().row(timestamp, Matchers.anything(), timestamp9)
                        .matches(TypeMatchMode.NO_JAVA_TYPE_CHECK));
    }

    @Test
    void testThreeTableJoin() {
        final Schema sourceSchema = factory.createSchema("THREE_TABLE_JOIN_SCHEMA");
        sourceSchema.createTable("A", "ID", "CHAR(5)", "A1", "INTEGER")
                .insert("ID_A1", 1).insert("ID_A2", 2).insert("ID_A3", 3);
        sourceSchema.createTable("B", "ID", "CHAR(5)", "B1", "INTEGER", "B2", "INTEGER")
                .insert("ID_B1", 1, 1).insert("ID_B2", 1, 2).insert("ID_B3", 2, 3);
        sourceSchema.createTable("C", "ID", "CHAR(5)", "C1", "INTEGER")
                .insert("ID_C1", 1).insert("ID_C2", 2).insert("ID_C3", 3);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("THREE_TABLE_JOIN_USER", virtualSchema);
        final String vsName = virtualSchema.getName();
        assertQueryWithUser("SELECT A.ID, B.ID, C.ID FROM " + vsName + ".A"
                + " INNER JOIN " + vsName + ".B ON A1 = B1"
                + " INNER JOIN " + vsName + ".C ON B2 = C1",
                user,
                table()
                        .row("ID_A1", "ID_B1", "ID_C1")
                        .row("ID_A1", "ID_B2", "ID_C2")
                        .row("ID_A2", "ID_B3", "ID_C3")
                        .matches());
    }
}
