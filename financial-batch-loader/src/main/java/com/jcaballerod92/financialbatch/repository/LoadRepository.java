package com.jcaballerod92.financialbatch.repository;

import com.jcaballerod92.financialbatch.model.FinancialTransaction;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * Repository that performs JDBC persistence operations against H2.
 */
public final class LoadRepository {

    private final String jdbcUrl;
    private final String jdbcUser;
    private final String jdbcPassword;

    /**
     * Creates the repository with database connection parameters.
     *
     * @param jdbcUrl database JDBC URL
     * @param jdbcUser database username
     * @param jdbcPassword database password
     */
    public LoadRepository(String jdbcUrl, String jdbcUser, String jdbcPassword) {
        this.jdbcUrl = jdbcUrl;
        this.jdbcUser = jdbcUser;
        this.jdbcPassword = jdbcPassword;
    }

    /**
     * Inserts one transaction into the staging table.
     *
     * @param transaction validated financial transaction
     */
    public void insertTransaction(FinancialTransaction transaction) {
        final String sql =
                "INSERT INTO FIN_STG_MOVEMENT " +
                "(TRANSACTION_ID, TRANSACTION_DATE, ACCOUNT_NUMBER, TRANSACTION_TYPE, " +
                "AMOUNT, CURRENCY, REFERENCE, CHANNEL) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection connection = DriverManager.getConnection(jdbcUrl, jdbcUser, jdbcPassword);
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setString(1, transaction.getTransactionId());
            statement.setDate(2, java.sql.Date.valueOf(transaction.getTransactionDate()));
            statement.setString(3, transaction.getAccountNumber());
            statement.setString(4, transaction.getTransactionType().toUpperCase());
            statement.setBigDecimal(5, transaction.getAmount());
            statement.setString(6, transaction.getCurrency().toUpperCase());
            statement.setString(7, transaction.getReference());
            statement.setString(8, "BATCH");

            statement.executeUpdate();

        } catch (SQLException ex) {
            throw new RuntimeException("H2 insert error for transaction " + transaction.getTransactionId(), ex);
        }
    }
}