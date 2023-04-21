package com.exasol;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.Table;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import static com.exasol.MetadataAssertions.expectRows;

@Testcontainers
class TlsIT extends AbstractLuaVirtualSchemaIT {

    // https://github.com/exasol/exasol-virtual-schema-lua/issues/36:
    // When FS access is available, execute install_test_certificate.sh on the docker instance in the test preparation

    // [[itest -> dsn~tls-connection~0]]
    @Test
    void testTlsWithCertificateCheck() {
        assumeExasol8OrHigher();
        final Schema sourceSchema = createSchema("SCHEMA_REMOTE_COLUMN_TYPES");
        final Table table = sourceSchema.createTableBuilder("T").column("BO", "BOOLEAN").build();
        final String connectionName = "CONNECTION_TO_LOCALHOST";
        factory.createConnectionDefinition(connectionName, "localhost", "sys", "exasol");
        final VirtualSchema virtualSchema = createRemoteVirtualSchema(sourceSchema, connectionName);
        final User user = createUserWithVirtualSchemaAccess("USER_REMOTE_COLUMN_TYPE", virtualSchema);
        assertVirtualTableStructure(table, user, expectRows("BO", "BOOLEAN"));
    }
}