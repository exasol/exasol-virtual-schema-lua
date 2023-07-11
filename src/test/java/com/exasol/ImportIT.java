package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static com.exasol.matcher.TypeMatchMode.NO_JAVA_TYPE_CHECK;
import static org.hamcrest.Matchers.equalTo;

import java.sql.SQLException;

import org.junit.jupiter.api.*;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.ConnectionDefinition;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

// [itest -> dsn~creating-a-remote-virtual-schema~0] implicitly tested with each query on a Virtual Schema
@Testcontainers
class ImportIT extends AbstractLuaVirtualSchemaIT {

    @BeforeAll
    static void beforeAll() throws SQLException {
        assumeExasol8OrHigher();
        AbstractLuaVirtualSchemaIT.beforeAll();
    }

    // [itest -> dsn~remote-push-down~0]
    @Test
    void testSelectStarOnUnprotectedTable() {
        final String sourceSchemaName = "SELECT_STAR_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final ConnectionDefinition connection = factory.createConnectionDefinition("SELECT_STAR_CONNECTION",
                getAddressWithDynamicTlsFingerprint(), "sys", "exasol");
        final VirtualSchema virtualSchema = createRemoteVirtualSchema(sourceSchema, connection.getName());
        final User user = createUserWithVirtualSchemaAccess("SELECT_STAR_VS_USER", virtualSchema);
        final String sql = "SELECT * FROM " + getVirtualSchemaName(sourceSchemaName) + ".T";
        assertQueryWithUser(sql, user, table().row(true).row(false).matches());
        assertPushDown(sql, user, equalTo("IMPORT INTO (c1 BOOLEAN) FROM EXA AT \"SELECT_STAR_CONNECTION\" STATEMENT '"
                + "SELECT * FROM \"SELECT_STAR_SCHEMA\".\"T\"'"));
    }

    private static String getAddressWithDynamicTlsFingerprint() {
        return EXASOL.getTlsCertificateFingerprint() //
                .map(fingerprint -> "localhost/" + fingerprint) //
                .orElseThrow(() -> new AssertionError(
                        "TLS Fingerprint is missing when trying to construct connection object for test."));
    }

    // This test case describes a situation where a push-down query request with an empty select list is received. This
    // might happen because the core database evaluates constant expressions before performing the push-down query to
    // the Virtual Schema. In such cases the adapter internally fills the select list with a dummy expression that only
    // serves the purpose of providing the right number of rows in the result set.
    // [itest -> dsn~remote-push-down~0]
    @Disabled("https://github.com/exasol/exasol-virtual-schema-lua/issues/32")
    @Test
    void testEmptySelectList() {
        final String sourceSchemaName = "EMPTY_SELECT_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN").insert(true).insert(false);
        final ConnectionDefinition connection = factory.createConnectionDefinition("EMPTY_SELECT_CONNECTION",
                getAddressWithDynamicTlsFingerprint(), "sys", "exasol");
        final VirtualSchema virtualSchema = createRemoteVirtualSchema(sourceSchema, connection.getName());
        final User user = createUserWithVirtualSchemaAccess("EMPTY_SELECT_USER", virtualSchema);
        assertQueryWithUser("SELECT 'foo' FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                table().row("foo").row("foo").matches());
    }

    // [itest -> dsn~remote-push-down~0]
    @Test
    void testSelectWithOrderByColumnAndLimit() {
        final String sourceSchemaName = "ORDER_LIMIT_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "NR", "INTEGER").insert(1).insert(2).insert(3);
        final ConnectionDefinition connection = factory.createConnectionDefinition("ORDER_LIMIT_CONNECTION",
                getAddressWithDynamicTlsFingerprint(), "sys", "exasol");
        final VirtualSchema virtualSchema = createRemoteVirtualSchema(sourceSchema, connection.getName());
        final User user = createUserWithVirtualSchemaAccess("ORDER_LIMIT_USER", virtualSchema);
        assertQueryWithUser("SELECT NR FROM " + getVirtualSchemaName(sourceSchemaName) + ".T ORDER BY NR LIMIT 2", user,
                table().row(1).row(2).matches(NO_JAVA_TYPE_CHECK));
    }

    // [itest -> dsn~remote-push-down~0]
    @Test
    void testSelectWithOrderByExpressionAndLimitWithOffset() {
        final String sourceSchemaName = "ORDER_LIMIT_OFFSET_SCHEMA";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "TXT", "VARCHAR(10)").insert("a").insert("bb").insert("ccc").insert("dddd");
        final ConnectionDefinition connection = factory.createConnectionDefinition("ORDER_LIMIT_OFFSET_CONNECTION",
                getAddressWithDynamicTlsFingerprint(), "sys", "exasol");
        final VirtualSchema virtualSchema = createRemoteVirtualSchema(sourceSchema, connection.getName());
        final User user = createUserWithVirtualSchemaAccess("ORDER_LIMIT_OFFSET_USER", virtualSchema);
        assertQueryWithUser("SELECT TXT FROM " + getVirtualSchemaName(sourceSchemaName)
                + ".T ORDER BY LENGTH(TXT) LIMIT 2 OFFSET 1", user, table().row("bb").row("ccc").matches());
    }
}
