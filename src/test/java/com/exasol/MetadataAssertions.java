package com.exasol;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.anything;
import static org.hamcrest.Matchers.equalTo;

import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import org.hamcrest.Matcher;

import com.exasol.matcher.ResultSetStructureMatcher;

public final class MetadataAssertions {
    private MetadataAssertions() {
        // Prevent instantiation.
    }

    public static Matcher<ResultSet> expectRows(final String... strings) {
        assertThat("Expected metadata rows must be given as tuples of field name and data type.", strings.length % 2,
                equalTo(0));
        final ResultSetStructureMatcher.Builder builder = table();
        for (int i = 0; i < strings.length; i += 2) {
            final String columnName = strings[i];
            final String sqlType = strings[i + 1];
            addExpectedRow(builder, columnName, sqlType);
        }
        return builder.matches();
    }

    private static void addExpectedRow(final ResultSetStructureMatcher.Builder builder, final String columnName,
            final String sqlType) {
        final List<Object> list = new ArrayList<>(List.of( //
                columnName, //
                sqlType, //
                anything("nullable"), //
                anything("distribution_key"), //
                anything("partition_key")));
        if (AbstractLuaVirtualSchemaIT.isExasol8OrHigher()) {
            list.add(anything("zonemapped"));
        }
        builder.row(list.toArray());
    }
}
