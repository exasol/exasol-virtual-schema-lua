// Add missing test [itest -> qs~query-execution-time~0] : https://github.com/exasol/exasol-virtual-schema-lua/issues/8

package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static com.exasol.matcher.TypeMatchMode.NO_JAVA_TYPE_CHECK;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.lessThanOrEqualTo;
import static org.junit.jupiter.api.Assertions.assertAll;

import java.sql.ResultSet;
import java.time.Duration;
import java.util.List;
import java.util.stream.Stream;

import com.exasol.dbbuilder.dialects.Table;
import com.exasol.dbbuilder.dialects.exasol.ExasolObjectPrivilege;
import org.hamcrest.Matcher;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import com.exasol.dbbuilder.dialects.Schema;
import com.exasol.dbbuilder.dialects.User;
import com.exasol.dbbuilder.dialects.exasol.VirtualSchema;
import org.testcontainers.junit.jupiter.Testcontainers;

@Testcontainers
class QueryRuntimeIT extends AbstractLuaVirtualSchemaIT {
    @ValueSource(ints = {1, 10, 100})
    @ParameterizedTest
    void testVirtualSchemaOverheadAcceptable(final int scalingFactor) {
        final Schema sourceSchema = createPerformanceTestSchema(scalingFactor);
        final VirtualSchema virtualSchema = createVirtualSchema(sourceSchema);
        final User sourceUser = factory.createLoginUser("PTEST_SOURCE_USER_SCALE" + scalingFactor)
                .grant(sourceSchema, ExasolObjectPrivilege.SELECT);
        final User vsUser = createUserWithVirtualSchemaAccess("PTEST_VS_USER_SCALE" + scalingFactor, virtualSchema);
        final String templateSql = "SELECT COUNT(*), TICKETS.TYPE FROM %s.TICKETS LEFT JOIN %s.TICKET_TYPES ON " +
                "TICKETS.TYPE = TICKET_TYPES.TYPE GROUP BY TICKETS.TYPE ORDER BY TICKETS.TYPE LIMIT 2";
        final String sourceSql = String.format(templateSql, sourceSchema.getName(), sourceSchema.getName());
        final String vsSql = String.format(templateSql, virtualSchema.getName(), virtualSchema.getName());
        final Matcher<ResultSet> expectedResult = table() //
                .row(scalingFactor, "type_000001") //
                .row(scalingFactor, "type_000002") //
                .matches(NO_JAVA_TYPE_CHECK);
        final Duration sourceQueryDuration = assertTimedRlsQueryWithUser(sourceSql, sourceUser, expectedResult);
        final Duration vsQueryDuration = assertTimedRlsQueryWithUser(vsSql, vsUser, expectedResult);
        final Duration absoluteOverhead = vsQueryDuration.minus(sourceQueryDuration);
        final long relativeOverheadPercent = absoluteOverhead.multipliedBy(100).dividedBy(sourceQueryDuration);
        assertAll(
                () -> assertThat("Absolute overhead must be less than 100ms", absoluteOverhead,
                        lessThanOrEqualTo(Duration.ofMillis(500))),
                () -> assertThat("Relative overhead must be less than 10%", relativeOverheadPercent,
                        lessThanOrEqualTo(15l))
        );
    }

    private Schema createPerformanceTestSchema(final int scalingFactor) {
        final String sourceSchemaName = "PERFORMANCE_TEST_SCHEMA_SCALE" + scalingFactor ;
        final Schema sourceSchema = createSchema(sourceSchemaName);
        populateSchemaWithScalingFactor(sourceSchema, scalingFactor);
        return sourceSchema;
    }

    private void populateSchemaWithScalingFactor(final Schema schema, final int scalingFactor)   {
        final Table ticketTypes = schema.createTable("TICKET_TYPES", "TYPE", "VARCHAR(40)", "DESCIPTION",
                "VARCHAR(1000)");
        final Stream<List<Object>> typeRows = createIteratedStreamUpTo(scalingFactor) //
                .map(i -> List.of(attachNumber("type_", i), "Description for type " + i));
        ticketTypes.bulkInsert(typeRows);
        final Table tickets = schema.createTable("TICKETS", "NUMBER", "INTEGER", "TYPE", "VARCHAR(40)", "TITLE",
                "VARCHAR(250)");
        final Stream<List<Object>> ticketRows = createIteratedStreamUpTo(100 * scalingFactor) //
                .map(i -> List.of(i, attachNumber("type_", ((i % 100) + 1)), "Title of ticket " + i));
        tickets.bulkInsert(ticketRows);
    }


    private Stream<Integer> createIteratedStreamUpTo(final int max) {
        return Stream.iterate(1, (Integer i) -> i + 1).limit(max);
    }

    private String attachNumber(final String prefix, final int number) {
        return String.format("%s%06d", prefix, number);
    }
}