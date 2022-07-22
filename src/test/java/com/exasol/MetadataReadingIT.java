package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.anything;
import static org.hamcrest.Matchers.equalTo;

import java.sql.*;
import java.util.Map;

import org.hamcrest.Matcher;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.*;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;
import com.exasol.matcher.ResultSetStructureMatcher.Builder;

@Testcontainers
class MetadataReadingIT extends AbstractLuaVirtualSchemaIT {

    public static final String BOOLEAN = "BOOLEAN";
    public static final String DOUBLE = "DOUBLE";

    // [itest -> dsn~reading-source-metadata~0]
    @Test
    void testDetermineColumnTypes() {
        final Schema sourceSchema = createSchema("SCHEMA_COLUMN_TYPES");
        final Table table = sourceSchema.createTableBuilder("T") //
                .column("BO", BOOLEAN) //
                .column("CA", "CHAR(34) ASCII") //
                .column("CU", "CHAR(345) UTF8") //
                .column("DA", "DATE") //
                .column("DO", DOUBLE) //
                .column("DE", "DECIMAL(15,9)") //
                .column("G1", "GEOMETRY(7)") //
                .column("G2", "GEOMETRY") //
                .column("H1", "HASHTYPE(32 BIT)") //
                .column("H2", "HASHTYPE(20 BYTE)") //
                .column("I1", "INTERVAL YEAR TO MONTH") //
                .column("I2", "INTERVAL YEAR(7) TO MONTH") //
                .column("I3", "INTERVAL DAY TO SECOND") //
                .column("I4", "INTERVAL DAY(4) TO SECOND(2)") //
                .column("T1", "TIMESTAMP") //
                .column("T2", "TIMESTAMP WITH LOCAL TIME ZONE") //
                .column("VA", "VARCHAR(123) ASCII") //
                .column("VU", "VARCHAR(12) UTF8") //
                .build();
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("USER_COLUMN_TYPE", virtualSchema);
        assertVirtualTableStructure(table, user, expectRows("BO", BOOLEAN, //
                "CA", "CHAR(34) ASCII", //
                "CU", "CHAR(345) UTF8", //
                "DA", "DATE", //
                "DO", DOUBLE, //
                "DE", "DECIMAL(15,9)", //
                "G1", "GEOMETRY(7)", //
                "G2", "GEOMETRY", //
                "H1", "HASHTYPE(4 BYTE)", //
                "H2", "HASHTYPE(20 BYTE)", //
                "I1", "INTERVAL YEAR(2) TO MONTH", //
                "I2", "INTERVAL YEAR(7) TO MONTH", //
                "I3", "INTERVAL DAY(2) TO SECOND(3)", //
                "I4", "INTERVAL DAY(4) TO SECOND(2)", //
                "T1", "TIMESTAMP", //
                "T2", "TIMESTAMP WITH LOCAL TIME ZONE", //
                "VA", "VARCHAR(123) ASCII", //
                "VU", "VARCHAR(12) UTF8"));
    }

    private void assertVirtualTableStructure(final Table table, final User user,
            final Matcher<ResultSet> tableMatcher) {
        assertRlsQueryWithUser("/*snapshot execution*/DESCRIBE " + getVirtualSchemaName(table.getParent().getName())
                        + "." + table.getName(), user, tableMatcher);
    }

    private Matcher<ResultSet> expectRows(final String... strings) {
        assertThat("Expected metadata rows must be given as tuples of field name and data type.", strings.length % 2,
                equalTo(0));
        final Builder builder = table();
        for (int i = 0; i < strings.length; i += 2) {
            builder.row(strings[i], strings[i + 1], anything(), anything(), anything());
        }
        return builder.matches();
    }

    // [itest -> dsn~refreshing-a-virtual-schema~0]
    @Test
    void testRefreshMetadata() {
        final Schema sourceSchema = createSchema("SCHEMA_FOR_REFRESH");
        final Table originalTable = sourceSchema.createTable("T", "BO", BOOLEAN, "DA", "DATE");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("USER_FOR_SCHEMA_REFRESH", virtualSchema);
        assertVirtualTableStructure(originalTable, user, expectRows("BO", BOOLEAN, "DA", "DATE"));
        originalTable.drop();

        final Table modifiedTable = sourceSchema.createTable("T", "VU", "VARCHAR(40)", "DO", DOUBLE);
        refreshVirtualSchema(virtualSchema);
        assertVirtualTableStructure(modifiedTable, user, expectRows("VU", "VARCHAR(40) UTF8", "DO", DOUBLE));
    }

    private void refreshVirtualSchema(final VirtualSchema virtualSchema) {
        final String sql = "ALTER VIRTUAL SCHEMA " + virtualSchema.getFullyQualifiedName() + " REFRESH";
        try {
            execute(sql);
        } catch (final SQLException exception) {
            throw new AssertionError("Unable to refresh Virtual Schema using query '" + sql + "'", exception);
        }
    }

    private void execute(final String sql) throws SQLException {
        try (final Statement statement = connection.createStatement()) {
            statement.execute(sql);
        }
    }

    // [itest -> dsn~filtering-tables~0]
    @Test
    void testTableFilter() throws SQLException {
        final Schema sourceSchema = createSchema("SCHEMA_FOR_TABLE_FILTER");
        sourceSchema.createTable("T1", "C1_1", BOOLEAN);
        sourceSchema.createTable("T2", "C2_1", BOOLEAN);
        sourceSchema.createTable("T3", "C3_1", BOOLEAN);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema, Map.of("TABLE_FILTER", "T2, T3"));
        final String sql = "/*snapshot execution*/"
                + " SELECT TABLE_NAME FROM SYS.EXA_ALL_TABLES WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME";
        try ( //
                final Connection connection = EXASOL.createConnection(); //
                final PreparedStatement statement = connection.prepareStatement(sql) //
        ) {
            statement.setString(1, virtualSchema.getName());
            final ResultSet resultSet = statement.executeQuery();
            assertThat(resultSet, table().row("T2").row("T3").matches());
        }
    }

    // [itest -> dsn~filtering-tables~0]
    @Test
    void testSetPropertiesRereadsMetadata() throws SQLException {
        final Schema sourceSchemaA = createSchema("SCHEMA_FOR_SET_SOURCE_A");
        sourceSchemaA.createTable("TA", "CB", BOOLEAN);
        final Schema sourceSchemaB = createSchema("SCHEMA_FOR_SET_SOURCE_B");
        sourceSchemaB.createTable("TB", "CV", "VARCHAR(27)");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchemaA);
        final String sql = "/*snapshot execution*/"
                + " SELECT TABLE_NAME FROM SYS.EXA_ALL_TABLES WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME";
        try ( //
                final Connection connection = EXASOL.createConnection(); //
                final PreparedStatement statement = connection.prepareStatement(sql) //
        ) {
            statement.setString(1, virtualSchema.getName());
            final ResultSet resultSetA = statement.executeQuery();
            assertThat(resultSetA, table().row("TA").matches());

            changeVirtualSchemaSource(virtualSchema, sourceSchemaB);

            statement.setString(1, virtualSchema.getName());
            final ResultSet resultSetB = statement.executeQuery();
            assertThat(resultSetB, table().row("TB").matches());
        }
    }

    void changeVirtualSchemaSource(final VirtualSchema virtualSchema, final Schema sourceSchema)
    {
        final String sql = "ALTER VIRTUAL SCHEMA " + virtualSchema.getFullyQualifiedName()
                + " SET SCHEMA_NAME = '" + sourceSchema.getName() +"'";
        try {
            execute(sql);
        } catch (final SQLException exception) {
            throw new AssertionError("Unable to change source schema using query '" + sql + "'", exception);
        }
    }

    @Test
    void testSwitchingSourceSchemaWithAlterVirtualSchema() throws SQLException {
        final String expectedText = "Hello";
        final Schema schemaA = createSchema("SCHEMA_SET_PROPS_A");
        schemaA.createTable("T", "C1", "VARCHAR(10)").insert(expectedText);
        final Date expectedDate = Date.valueOf("1970-01-01");
        final Schema schemaB = createSchema("SCHEMA_SET_PROPS_B");
        schemaB.createTable("T", "C1", "DATE").insert(expectedDate);
        final VirtualSchema virtualSchema = createVirtualSchema(schemaA);
        final User user = createUserWithVirtualSchemaAccess("USER_SET_PROPS", virtualSchema);
        assertRlsQueryWithUser("SELECT * FROM " + virtualSchema.getName() + ".T", user,
                table().row(expectedText).matches());
        execute("ALTER VIRTUAL SCHEMA " + virtualSchema.getName() + " SET SCHEMA_NAME = '" + schemaB.getName() + "'");
        assertRlsQueryWithUser("SELECT * FROM " + virtualSchema.getName() + ".T", user,
                table().row(expectedDate).matches());
    }
}