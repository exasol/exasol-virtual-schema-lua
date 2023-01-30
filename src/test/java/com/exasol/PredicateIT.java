package com.exasol;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.Table;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static com.exasol.matcher.TypeMatchMode.NO_JAVA_TYPE_CHECK;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;

@Testcontainers
class PredicateIT extends  AbstractLuaVirtualSchemaIT {
    @Test
    void testPredicateEqual() {
        final Schema sourceSchema = createSchema("EQUAL_SCHEMA");
        sourceSchema.createTable("T", "C1", "VARCHAR(10)").insert("Alice").insert("Bob").insert("Charly");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("EQUAL_USER", virtualSchema);
        final String sql = "SELECT * FROM " + getVirtualSchemaName(sourceSchema) + ".T WHERE C1 = 'Bob'";
        assertPushDown(sql, user, containsString("WHERE (\"T\".\"C1\" = 'Bob')"));
        assertQueryWithUser(sql, user, table().row("Bob").matches());
    }

    @Test
    void testPredicateAndLess() {
        final Schema sourceSchema = createSchema("LESS_SCHEMA");
        sourceSchema.createTable("T", "C1", "INTEGER", "C2", "INTEGER")
                .insert(1, 1).insert(1, 2).insert(1, 3)
                .insert(2, 1).insert(2, 2).insert(2, 3)
                .insert(3, 1).insert(3, 2).insert(3, 3);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("LESS_USER", virtualSchema);
        final String sql = "SELECT * FROM " + getVirtualSchemaName(sourceSchema) + ".T WHERE C1 > 2 AND C2 < 3";
        assertPushDown(sql, user, containsString("WHERE ((2 < \"T\".\"C1\") AND (\"T\".\"C2\" < 3))"));
        assertQueryWithUser(sql, user, table().row(3, 1).row(3, 2).matches(NO_JAVA_TYPE_CHECK));
    }

    @Test
    void testPredicateOr() {
        final Schema sourceSchema = createSchema("OR_SCHEMA");
        sourceSchema.createTable("T", "C1", "BOOLEAN", "C2", "BOOLEAN")
                .insert(true, false).insert(false, true).insert(true, true).insert(false, false);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("OR_USER", virtualSchema);
        final String sql = "SELECT * FROM " + getVirtualSchemaName(sourceSchema) + ".T WHERE C1 OR C2";
        assertPushDown(sql, user, containsString("WHERE (\"T\".\"C1\" OR \"T\".\"C2\")"));
        assertQueryWithUser(sql, user, table().row(true, false).row(false, true).row(true, true).matches());
    }

    @Test
    void testPredicateLessEqual() {
        final Schema sourceSchema = createSchema("LESS_EQUAL_SCHEMA");
        sourceSchema.createTable("T", "C1", "INTEGER", "C2", "INTEGER").insert(1, 2).insert(2, 2).insert(3, 2);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("LESS_EQUAL_USER", virtualSchema);
        final String sql = "SELECT C1 FROM " + getVirtualSchemaName(sourceSchema) + ".T WHERE C1 <= C2";
        assertPushDown(sql, user, containsString("WHERE (\"T\".\"C1\" <= \"T\".\"C2\")"));
        assertQueryWithUser(sql, user, table().row(1).row(2).matches(NO_JAVA_TYPE_CHECK));
    }

    @Test
    void testPredicateLike() {
        final Schema sourceSchema = createSchema("LIKE_SCHEMA");
        sourceSchema.createTable("T", "C1", "VARCHAR(10)").insert("apple").insert("maple").insert("spruce");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("LIKE_USER", virtualSchema);
        final String sql = "SELECT * FROM " + getVirtualSchemaName(sourceSchema) + ".T WHERE C1 LIKE '%ple'";
        assertPushDown(sql, user, containsString("WHERE (\"T\".\"C1\" LIKE '%ple')"));
        assertQueryWithUser(sql, user, table().row("apple").row("maple").matches());
    }

    @Test
    void testPredicateLikeEscape() {
        final Schema sourceSchema = createSchema("LIKE_ESCAPE_SCHEMA");
        sourceSchema.createTable("T", "C1", "VARCHAR(10)").insert("max_temp").insert("avg_temp").insert("min_temp");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("LIKE_ESCAPE_USER", virtualSchema);
        final String sql = "SELECT * FROM " + getVirtualSchemaName(sourceSchema)
                + ".T WHERE C1 LIKE 'm__~_%' ESCAPE '~'";
        assertPushDown(sql, user, containsString("WHERE (\"T\".\"C1\" LIKE 'm__~_%' ESCAPE '~')"));
        assertQueryWithUser(sql, user, table().row("max_temp").row("min_temp").matches());
    }

    @Test
    void testPredicateRegexpLike() {
        final Schema sourceSchema = createSchema("REGEXP_LIKE_SCHEMA");
        sourceSchema.createTable("T", "C1", "VARCHAR(10)").insert("max_temp").insert("avg_temp").insert("min_temp");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("REGEXP_LIKE_USER", virtualSchema);
        final String sql = "SELECT * FROM " + getVirtualSchemaName(sourceSchema)
                + ".T WHERE C1 REGEXP_LIKE 'm(in|ax)_[a-z]*'";
        assertPushDown(sql, user, containsString("WHERE (\"T\".\"C1\" REGEXP_LIKE 'm(in|ax)_[a-z]*')"));
        assertQueryWithUser(sql, user, table().row("max_temp").row("min_temp").matches());
    }

    // This test combines a filter expression with a NULL check.
    // The main reason is that the insert method of the test-db-builder did not support inserting null values at the
    // time this test was designed.
    @Test
    void testPredicateIsNull() {
        final Schema sourceSchema = createSchema("IS_NULL_SCHEMA");
        sourceSchema.createTable("T", "C1", "INTEGER").insert(0).insert(1).insert(2);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("IS_NULL_USER", virtualSchema);
        final String sql = "SELECT COUNT(*) FROM " + getVirtualSchemaName(sourceSchema)
                + ".T WHERE NULLIFZERO(C1) IS NULL";
        assertPushDown(sql, user, containsString("WHERE (NULLIFZERO(\"T\".\"C1\") IS NULL)"));
        assertQueryWithUser(sql, user, table().row(1).matches(NO_JAVA_TYPE_CHECK));
    }

    @Test
    void testPredicateIsNotNull() {
        final Schema sourceSchema = createSchema("IS_NOT_NULL_SCHEMA");
        sourceSchema.createTable("T", "C1", "INTEGER").insert(0).insert(1).insert(2);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("IS_NOT_NULL_USER", virtualSchema);
        final String sql = "SELECT COUNT(*) FROM " + getVirtualSchemaName(sourceSchema)
                + ".T WHERE NULLIFZERO(C1) IS NOT NULL";
        assertPushDown(sql, user, containsString("WHERE (NULLIFZERO(\"T\".\"C1\") IS NOT NULL)"));
        assertQueryWithUser(sql, user, table().row(2).matches(NO_JAVA_TYPE_CHECK));
    }

    @Test
    void testPredicateBetween() {
        final Schema sourceSchema = createSchema("BETWEEN_SCHEMA");
        sourceSchema.createTable("T", "C1", "INTEGER").insert(0).insert(1).insert(2).insert(3).insert(4);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("BETWEEN_USER", virtualSchema);
        final String sql = "SELECT * FROM " + getVirtualSchemaName(sourceSchema)
                + ".T WHERE C1 BETWEEN 1 AND 3";
        assertPushDown(sql, user, containsString("WHERE (\"T\".\"C1\" BETWEEN 1 AND 3)"));
        assertQueryWithUser(sql, user, table().row(1).row(2).row(3).matches(NO_JAVA_TYPE_CHECK));
    }

    @Test
    void testPredicteNot() {
        final Schema sourceSchema = createSchema("NOT_SCHEMA");
        sourceSchema.createTable("T", "C1", "INTEGER").insert(1).insert(2).insert(3);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("NOT_USER", virtualSchema);
        final String sql = "SELECT * FROM " + getVirtualSchemaName(sourceSchema)
                + ".T WHERE NOT C1 = 2 ";
        assertPushDown(sql, user, containsString("WHERE (NOT (\"T\".\"C1\" = 2))"));
        assertQueryWithUser(sql, user, table().row(1).row(3).matches(NO_JAVA_TYPE_CHECK));
    }


    @Test
    void testIsJson() {
        final Schema sourceSchema = createSchema("IS_JSON_SCHEMA");
        final Table sourceTable = sourceSchema.createTable("T", "C1", "VARCHAR(40)") //
                .insert("this is no JSON") //
                .insert("{\"foo\" : \"bar\"}") ;
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("IS_JSON_USER", virtualSchema);
        final String sql = "SELECT C1 IS JSON FROM " + getVirtualSchemaName(sourceSchema) + ".T";
        assertPushDown(sql, user, equalTo("SELECT \"T\".\"C1\" IS JSON VALUE WITHOUT UNIQUE KEYS FROM "
                + sourceTable.getFullyQualifiedName()));
        assertQueryWithUser(sql, user, table().row(false).row(true).matches());
    }
}
