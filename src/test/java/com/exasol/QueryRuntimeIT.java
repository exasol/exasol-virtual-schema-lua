package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static com.exasol.matcher.TypeMatchMode.NO_JAVA_TYPE_CHECK;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;

import java.sql.ResultSet;
import java.util.List;
import java.util.logging.Logger;
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
    private static final Logger LOGGER = Logger.getLogger(QueryRuntimeIT.class.getName());
    private static final int RUNS = 100;
    private static final long MAX_ALLOWED_OVERHEAD_MILLIS = 50;

    // [itest -> qs~query-execution-time-local-connection~0]
    @ValueSource(ints = {1, 10, 100})
    @ParameterizedTest
    void testVirtualSchemaOverheadAcceptable(final int scalingFactor) {
        final long[] sourceQueryMillis = new long[RUNS];
        final long[] vsQueryMillis = new long[RUNS];
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
        assertPushDown(vsSql, vsUser, equalTo("SELECT COUNT(*), \"TICKETS\".\"TYPE\" "
                + "FROM \"PERFORMANCE_TEST_SCHEMA_SCALE" + scalingFactor + "\".\"TICKETS\" "
                + "LEFT OUTER JOIN \"PERFORMANCE_TEST_SCHEMA_SCALE" + scalingFactor + "\".\"TICKET_TYPES\" "
                + "ON (\"TICKETS\".\"TYPE\" = \"TICKET_TYPES\".\"TYPE\") "
                + "GROUP BY \"TICKETS\".\"TYPE\" "
                + "ORDER BY \"TICKETS\".\"TYPE\" ASC NULLS LAST LIMIT 2"));
        warmUpQueryAndIndexes(sourceUser, sourceSql, expectedResult);
        for(int run = 0; run < RUNS; ++run) {
            sourceQueryMillis[run] = assertTimedVsQueryWithUser(sourceSql, sourceUser, expectedResult).toMillis();
            vsQueryMillis[run] = assertTimedVsQueryWithUser(vsSql, vsUser, expectedResult).toMillis();
        }
        final long averageSourceQueryMillis = average(sourceQueryMillis);
        final long averageVsQueryMillis = average(vsQueryMillis);
        final long averageAbsoluteOverhead = averageVsQueryMillis - averageSourceQueryMillis;
        final long relativeOverheadPercent = 100 * averageAbsoluteOverhead / averageSourceQueryMillis;
        reportDurations(scalingFactor, averageSourceQueryMillis, averageVsQueryMillis, relativeOverheadPercent);
        assertThat("Average absolute overhead must be less than " + MAX_ALLOWED_OVERHEAD_MILLIS +"ms",
                averageAbsoluteOverhead, lessThanOrEqualTo(MAX_ALLOWED_OVERHEAD_MILLIS));
    }

    // Do a dry-run first to make sure that indices are committed before measuring.
    private void warmUpQueryAndIndexes(final User sourceUser, final String sourceSql,
                                       final Matcher<ResultSet> expectedResult) {
        assertQueryWithUser(sourceSql, sourceUser, expectedResult);
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


    private long average(final long[] values) {
        long total = 0;
        for(long value : values) {
            total += value;
        }
        return total / values.length;
    }

    private static void reportDurations(final int scalingFactor, final long averageSourceMillis,
                                        final long averageVsMillis, final long relativeOverheadPercent) {
        LOGGER.info(() -> "Query runtime (scaling factor " + scalingFactor + "): "
                + "average original " + averageSourceMillis + "ms, "
                + "average via VS: " + averageVsMillis +"ms, "
                + "overhead: " + relativeOverheadPercent + "%" );
    }
}
