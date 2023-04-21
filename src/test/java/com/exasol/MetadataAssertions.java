package com.exasol;

import com.exasol.matcher.ResultSetStructureMatcher;
import org.hamcrest.Matcher;

import java.sql.ResultSet;

import static com.exasol.matcher.ResultSetStructureMatcher.table;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.anything;
import static org.hamcrest.Matchers.equalTo;

public final class MetadataAssertions {
    private MetadataAssertions () {
        // Prevent instantiation.
    }

    public static Matcher<ResultSet> expectRows(final String... strings) {
        assertThat("Expected metadata rows must be given as tuples of field name and data type.", strings.length % 2,
                equalTo(0));
        final ResultSetStructureMatcher.Builder builder = table();
        for (int i = 0; i < strings.length; i += 2) {
            builder.row(strings[i], strings[i + 1], anything(), anything(), anything());
        }
        return builder.matches();
    }
}
