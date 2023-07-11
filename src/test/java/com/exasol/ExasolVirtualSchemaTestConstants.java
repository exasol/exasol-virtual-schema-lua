package com.exasol;

public final class ExasolVirtualSchemaTestConstants {
    public static final String DOCKER_DB = isCi() ? "exasol/docker-db:7.1.21" : "exasol/docker-db:8.18.1";

    private static boolean isCi() {
        return "true".equals(System.getenv("CI"));
    }

    private ExasolVirtualSchemaTestConstants() {
        // prevent instantiation
    }
}