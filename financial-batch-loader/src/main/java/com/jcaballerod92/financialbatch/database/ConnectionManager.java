package com.jcaballerod92.financialbatch.database;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Utility class responsible for opening JDBC connections.
 * It centralizes the database connection parameters used by the
 * batch loader and by the reconciliation components.
 */
public final class ConnectionManager {

    private final String jdbcUrl;
    private final String jdbcUser;
    private final String jdbcPassword;

    /**
     * Creates a new connection manager using the provided JDBC settings.
     *
     * @param jdbcUrl database JDBC URL
     * @param jdbcUser database username
     * @param jdbcPassword database password
     */
    public ConnectionManager(String jdbcUrl, String jdbcUser, String jdbcPassword) {
        this.jdbcUrl = jdbcUrl;
        this.jdbcUser = jdbcUser;
        this.jdbcPassword = jdbcPassword;
    }

    /**
     * Opens a new JDBC connection to the configured H2 database.
     *
     * @return open JDBC connection
     * @throws SQLException if the connection cannot be created
     */
    public Connection openConnection() throws SQLException {
        return DriverManager.getConnection(jdbcUrl, jdbcUser, jdbcPassword);
    }

    /**
     * Returns the configured JDBC URL.
     *
     * @return JDBC URL
     */
    public String getJdbcUrl() {
        return jdbcUrl;
    }

    /**
     * Returns the configured database user.
     *
     * @return database user
     */
    public String getJdbcUser() {
        return jdbcUser;
    }

    /**
     * Returns the configured database password.
     *
     * @return database password
     */
    public String getJdbcPassword() {
        return jdbcPassword;
    }
}