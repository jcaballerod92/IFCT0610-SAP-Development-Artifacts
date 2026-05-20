package com.jcaballerod92.financialbatch.database;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Initializes the H2 database schema before running the batch process.
 */
public final class DatabaseInitializer {

    private final String jdbcUrl;
    private final String jdbcUser;
    private final String jdbcPassword;

    /**
     * Creates the initializer with JDBC parameters.
     *
     * @param jdbcUrl database JDBC URL
     * @param jdbcUser database username
     * @param jdbcPassword database password
     */
    public DatabaseInitializer(String jdbcUrl, String jdbcUser, String jdbcPassword) {
        this.jdbcUrl = jdbcUrl;
        this.jdbcUser = jdbcUser;
        this.jdbcPassword = jdbcPassword;
    }

    /**
     * Loads the schema SQL file and executes each statement.
     *
     * @throws IOException if the schema resource cannot be read
     * @throws SQLException if a database error occurs
     */
    public void initialize() throws IOException, SQLException {
        String schemaScript = readResource("/schema.sql");

        try (Connection connection = DriverManager.getConnection(jdbcUrl, jdbcUser, jdbcPassword);
             Statement statement = connection.createStatement()) {

            String[] commands = schemaScript.split(";");
            for (String command : commands) {
                String sql = command.trim();
                if (!sql.isEmpty()) {
                    statement.execute(sql);
                }
            }
        }
    }

    /**
     * Reads a text resource from the classpath.
     *
     * @param resourcePath classpath resource path
     * @return resource content as string
     * @throws IOException if the resource cannot be found or read
     */
    private String readResource(String resourcePath) throws IOException {
        InputStream inputStream = DatabaseInitializer.class.getResourceAsStream(resourcePath);

        if (inputStream == null) {
            throw new IOException("Resource not found: " + resourcePath);
        }

        StringBuilder builder = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(inputStream, StandardCharsets.UTF_8))) {

            String line;
            while ((line = reader.readLine()) != null) {
                if (!line.trim().startsWith("--")) {
                    builder.append(line).append(System.lineSeparator());
                }
            }
        }

        return builder.toString();
    }
}