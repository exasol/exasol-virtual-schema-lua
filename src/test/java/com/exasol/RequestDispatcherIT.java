package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;

import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;

@Testcontainers
class RequestDispatcherIT extends AbstractLuaVirtualSchemaIT {
    @Test
    void testUnprotected() {
        final String sourceSchemaName = "UNPROTECTED";
        final Schema sourceSchema = createSchema(sourceSchemaName);
        sourceSchema.createTable("T", "C1", "BOOLEAN") //
                .insert("true") //
                .insert("false");
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User user = createUserWithVirtualSchemaAccess("UP_USER", virtualSchema);
        assertQueryWithUser("SELECT C1 FROM " + getVirtualSchemaName(sourceSchemaName) + ".T", user,
                table("BOOLEAN").row(true).row(false).matches());
    }
}