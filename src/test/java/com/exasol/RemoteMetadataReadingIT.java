package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.anything;
import static org.hamcrest.Matchers.equalTo;

import java.sql.ResultSet;

import org.hamcrest.Matcher;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.*;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;
import com.exasol.matcher.ResultSetStructureMatcher.Builder;

// [[itest -> dsn~defining-the-remote-connection~0]]
@Testcontainers
class RemoteMetadataReadingIT extends AbstractLuaVirtualSchemaIT {
    public static final String BOOLEAN = "BOOLEAN";
    public static final String DOUBLE = "DOUBLE";

    @Test
    void testDetermineColumnTypes() {
        assumeExasol8OrHigher();
        final Schema sourceSchema = createSchema("SCHEMA_REMOTE_COLUMN_TYPES");
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
        final String connectionName = "CONNECTION_TO_LOCALHOST";
        factory.createConnectionDefinition(connectionName, "localhost", "sys", "exasol");
        final VirtualSchema virtualSchema = createRemoteVirtualSchema(sourceSchema, connectionName);
        final User user = createUserWithVirtualSchemaAccess("USER_REMOTE_COLUMN_TYPE", virtualSchema);
        assertVirtualTableStructure(table, user, expectRows( //
                "BO", BOOLEAN, //
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
                "T1", "TIMESTAMP(3)", //
                "T2", "TIMESTAMP(3) WITH LOCAL TIME ZONE", //
                "VA", "VARCHAR(123) ASCII", //
                "VU", "VARCHAR(12) UTF8"));
    }

    private Matcher<ResultSet> expectRows(final String... strings) {
        assertThat("Expected metadata rows must be given as tuples of field name and data type.", strings.length % 2,
                equalTo(0));
        final Builder builder = table();
        for (int i = 0; i < strings.length; i += 2) {
            builder.row(strings[i], strings[i + 1], anything("nullable"), anything("distribution_key"),
                    anything("partition_key"), anything("zonemapped"));
        }
        return builder.matches();
    }
}