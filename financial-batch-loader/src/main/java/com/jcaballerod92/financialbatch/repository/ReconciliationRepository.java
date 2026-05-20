package com.jcaballerod92.financialbatch.repository;

import com.jcaballerod92.financialbatch.database.ConnectionManager;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Repository responsible for reconciliation database operations.
 * It reads staging rows, checks master data, stores control records,
 * stores discrepancy rows and updates audit/status information.
 */
public final class ReconciliationRepository {

    private final ConnectionManager connectionManager;

    /**
     * Creates the repository using a connection manager.
     *
     * @param connectionManager JDBC connection manager
     */
    public ReconciliationRepository(ConnectionManager connectionManager) {
        this.connectionManager = connectionManager;
    }

    /**
     * Reads all pending movements from the staging table.
     * Pending records are those with PROCESS_STATUS = 'N'.
     *
     * @return list of pending reconciliation rows
     */
    public List<ReconciliationRow> findPendingMovements() {
        List<ReconciliationRow> rows = new ArrayList<ReconciliationRow>();

        String sql =
                "SELECT STG_ID, TRANSACTION_ID, TRANSACTION_DATE, ACCOUNT_NUMBER, " +
                "TRANSACTION_TYPE, AMOUNT, CURRENCY, REFERENCE, CHANNEL " +
                "FROM FIN_STG_MOVEMENT " +
                "WHERE PROCESS_STATUS = 'N' " +
                "ORDER BY TRANSACTION_DATE, STG_ID";

        try (Connection connection = connectionManager.openConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {

            while (rs.next()) {
                rows.add(new ReconciliationRow(
                        rs.getLong("STG_ID"),
                        rs.getString("TRANSACTION_ID"),
                        rs.getDate("TRANSACTION_DATE").toLocalDate(),
                        rs.getString("ACCOUNT_NUMBER"),
                        rs.getString("TRANSACTION_TYPE"),
                        rs.getBigDecimal("AMOUNT"),
                        rs.getString("CURRENCY"),
                        rs.getString("REFERENCE"),
                        rs.getString("CHANNEL")
                ));
            }

        } catch (SQLException ex) {
            throw new RuntimeException("Error reading pending staging movements", ex);
        }

        return rows;
    }

    /**
     * Finds the account reference data by business account number.
     *
     * @param accountNumber business account number
     * @return account reference or null if not found
     */
    public AccountReference findAccountReference(String accountNumber) {
        String sql =
                "SELECT ACCOUNT_ID, ACCOUNT_NUMBER, ACCOUNT_STATUS, CURRENCY " +
                "FROM FIN_ACCOUNT " +
                "WHERE ACCOUNT_NUMBER = ?";

        try (Connection connection = connectionManager.openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setString(1, accountNumber);

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return new AccountReference(
                            rs.getLong("ACCOUNT_ID"),
                            rs.getString("ACCOUNT_NUMBER"),
                            rs.getString("ACCOUNT_STATUS"),
                            rs.getString("CURRENCY")
                    );
                }
            }

        } catch (SQLException ex) {
            throw new RuntimeException("Error reading account reference data", ex);
        }

        return null;
    }

    /**
     * Finds the definitive movement record by transaction identifier and account.
     *
     * @param transactionId transaction identifier
     * @param accountId internal account identifier
     * @return movement reference or null if not found
     */
    public MovementReference findMovementReference(String transactionId, long accountId) {
        String sql =
                "SELECT MOVEMENT_ID, TRANSACTION_ID, ACCOUNT_ID, MOVEMENT_DATE, " +
                "MOVEMENT_TYPE, AMOUNT, CURRENCY, REFERENCE " +
                "FROM FIN_MOVEMENT " +
                "WHERE TRANSACTION_ID = ? AND ACCOUNT_ID = ?";

        try (Connection connection = connectionManager.openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setString(1, transactionId);
            statement.setLong(2, accountId);

            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return new MovementReference(
                            rs.getLong("MOVEMENT_ID"),
                            rs.getString("TRANSACTION_ID"),
                            rs.getLong("ACCOUNT_ID"),
                            rs.getDate("MOVEMENT_DATE").toLocalDate(),
                            rs.getString("MOVEMENT_TYPE"),
                            rs.getBigDecimal("AMOUNT"),
                            rs.getString("CURRENCY"),
                            rs.getString("REFERENCE")
                    );
                }
            }

        } catch (SQLException ex) {
            throw new RuntimeException("Error reading definitive movement data", ex);
        }

        return null;
    }

    /**
     * Stores the reconciliation control result for a processed row.
     *
     * @param row staging row being processed
     * @param status reconciliation status
     * @param differenceAmount computed difference amount
     * @param remarks operational remarks
     */
    public void saveControlRecord(
            ReconciliationRow row,
            String status,
            BigDecimal differenceAmount,
            String remarks) {

        String sql =
                "INSERT INTO FIN_RECON_CONTROL " +
                "(STG_ID, TRANSACTION_ID, ACCOUNT_ID, ACCOUNT_NUMBER, STATUS, DIFFERENCE_AMOUNT, RECON_DATE, REMARKS) " +
                "VALUES (?, ?, ?, ?, ?, ?, CURRENT_DATE, ?)";

        try (Connection connection = connectionManager.openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setLong(1, row.getStgId());
            statement.setString(2, row.getTransactionId());
            if (row.getAccountId() == null) {
                statement.setNull(3, java.sql.Types.BIGINT);
            } else {
                statement.setLong(3, row.getAccountId());
            }
            statement.setString(4, row.getAccountNumber());
            statement.setString(5, status);
            statement.setBigDecimal(6, differenceAmount);
            statement.setString(7, remarks);

            statement.executeUpdate();

        } catch (SQLException ex) {
            throw new RuntimeException("Error inserting reconciliation control record", ex);
        }
    }

    /**
     * Stores a discrepancy row for a non-reconciled movement.
     *
     * @param row staging row being processed
     * @param errorCode error code
     * @param errorDescription error description
     * @param expectedAmount expected amount from definitive data
     * @param registeredAmount amount found in staging
     */
    public void saveDiscrepancy(
            ReconciliationRow row,
            String errorCode,
            String errorDescription,
            BigDecimal expectedAmount,
            BigDecimal registeredAmount) {

        String sql =
                "INSERT INTO FIN_DISCREPANCY " +
                "(STG_ID, TRANSACTION_ID, ACCOUNT_ID, ACCOUNT_NUMBER, ERROR_CODE, ERROR_DESCRIPTION, " +
                "EXPECTED_AMOUNT, REGISTERED_AMOUNT, DISC_DATE) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_DATE)";

        try (Connection connection = connectionManager.openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setLong(1, row.getStgId());
            statement.setString(2, row.getTransactionId());
            if (row.getAccountId() == null) {
                statement.setNull(3, java.sql.Types.BIGINT);
            } else {
                statement.setLong(3, row.getAccountId());
            }
            statement.setString(4, row.getAccountNumber());
            statement.setString(5, errorCode);
            statement.setString(6, errorDescription);
            statement.setBigDecimal(7, expectedAmount);
            statement.setBigDecimal(8, registeredAmount);

            statement.executeUpdate();

        } catch (SQLException ex) {
            throw new RuntimeException("Error inserting discrepancy record", ex);
        }
    }

    /**
     * Updates the status of the staging row after reconciliation.
     *
     * @param row staging row being processed
     * @param reconciliationStatus reconciliation outcome
     * @param errorCode error code if any
     * @param errorDescription error description if any
     */
    public void updateStagingStatus(
            ReconciliationRow row,
            String reconciliationStatus,
            String errorCode,
            String errorDescription) {

        String sql =
                "UPDATE FIN_STG_MOVEMENT " +
                "SET ACCOUNT_ID = ?, " +
                "PROCESS_STATUS = ?, " +
                "RECON_STATUS = ?, " +
                "ERROR_CODE = ?, " +
                "ERROR_DESCRIPTION = ?, " +
                "RECON_DATE = CURRENT_DATE, " +
                "RECON_TIMESTAMP = CURRENT_TIMESTAMP " +
                "WHERE STG_ID = ?";

        try (Connection connection = connectionManager.openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            if (row.getAccountId() == null) {
                statement.setNull(1, java.sql.Types.BIGINT);
            } else {
                statement.setLong(1, row.getAccountId());
            }

            statement.setString(2, "RECONCILED".equals(reconciliationStatus) ? "P" : "E");
            statement.setString(3, reconciliationStatus);

            if (errorCode == null) {
                statement.setNull(4, java.sql.Types.VARCHAR);
            } else {
                statement.setString(4, errorCode);
            }

            if (errorDescription == null) {
                statement.setNull(5, java.sql.Types.VARCHAR);
            } else {
                statement.setString(5, errorDescription);
            }

            statement.setLong(6, row.getStgId());

            statement.executeUpdate();

        } catch (SQLException ex) {
            throw new RuntimeException("Error updating staging status", ex);
        }
    }

    /**
     * Stores an audit record for traceability.
     *
     * @param processName process name
     * @param stepName step or module name
     * @param entityName affected entity
     * @param entityId affected entity identifier
     * @param eventType event type
     * @param eventStatus event status
     * @param messageText message description
     */
    public void saveAudit(
            String processName,
            String stepName,
            String entityName,
            String entityId,
            String eventType,
            String eventStatus,
            String messageText) {

        String sql =
                "INSERT INTO FIN_AUDIT_LOG " +
                "(PROCESS_NAME, STEP_NAME, ENTITY_NAME, ENTITY_ID, EVENT_TYPE, EVENT_STATUS, MESSAGE_TEXT, EVENT_TIMESTAMP) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)";

        try (Connection connection = connectionManager.openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setString(1, processName);
            statement.setString(2, stepName);
            statement.setString(3, entityName);
            statement.setString(4, entityId);
            statement.setString(5, eventType);
            statement.setString(6, eventStatus);
            statement.setString(7, messageText);

            statement.executeUpdate();

        } catch (SQLException ex) {
            throw new RuntimeException("Error inserting audit record", ex);
        }
    }

    /**
     * Immutable structure representing a pending staging row.
     */
    public static final class ReconciliationRow {
        private final long stgId;
        private final String transactionId;
        private final java.time.LocalDate transactionDate;
        private final String accountNumber;
        private final String transactionType;
        private final BigDecimal amount;
        private final String currency;
        private final String reference;
        private final String channel;
        private Long accountId;

        /**
         * Builds the staging row holder.
         *
         * @param stgId staging row identifier
         * @param transactionId business transaction identifier
         * @param transactionDate transaction date
         * @param accountNumber account number
         * @param transactionType transaction type
         * @param amount transaction amount
         * @param currency currency code
         * @param reference external reference
         * @param channel input channel
         */
        public ReconciliationRow(
                long stgId,
                String transactionId,
                java.time.LocalDate transactionDate,
                String accountNumber,
                String transactionType,
                BigDecimal amount,
                String currency,
                String reference,
                String channel) {
            this.stgId = stgId;
            this.transactionId = transactionId;
            this.transactionDate = transactionDate;
            this.accountNumber = accountNumber;
            this.transactionType = transactionType;
            this.amount = amount;
            this.currency = currency;
            this.reference = reference;
            this.channel = channel;
        }

        /**
         * Returns the staging identifier.
         *
         * @return staging identifier
         */
        public long getStgId() {
            return stgId;
        }

        /**
         * Returns the transaction identifier.
         *
         * @return transaction identifier
         */
        public String getTransactionId() {
            return transactionId;
        }

        /**
         * Returns the transaction date.
         *
         * @return transaction date
         */
        public java.time.LocalDate getTransactionDate() {
            return transactionDate;
        }

        /**
         * Returns the business account number.
         *
         * @return account number
         */
        public String getAccountNumber() {
            return accountNumber;
        }

        /**
         * Returns the transaction type.
         *
         * @return transaction type
         */
        public String getTransactionType() {
            return transactionType;
        }

        /**
         * Returns the transaction amount.
         *
         * @return amount
         */
        public BigDecimal getAmount() {
            return amount;
        }

        /**
         * Returns the currency code.
         *
         * @return currency
         */
        public String getCurrency() {
            return currency;
        }

        /**
         * Returns the external reference.
         *
         * @return reference
         */
        public String getReference() {
            return reference;
        }

        /**
         * Returns the input channel.
         *
         * @return channel
         */
        public String getChannel() {
            return channel;
        }

        /**
         * Returns the internal account identifier resolved during reconciliation.
         *
         * @return account identifier
         */
        public Long getAccountId() {
            return accountId;
        }

        /**
         * Sets the internal account identifier resolved during reconciliation.
         *
         * @param accountId account identifier
         */
        public void setAccountId(Long accountId) {
            this.accountId = accountId;
        }

        @Override
        public String toString() {
            return "ReconciliationRow{" +
                    "stgId=" + stgId +
                    ", transactionId='" + transactionId + '\'' +
                    ", transactionDate=" + transactionDate +
                    ", accountNumber='" + accountNumber + '\'' +
                    ", transactionType='" + transactionType + '\'' +
                    ", amount=" + amount +
                    ", currency='" + currency + '\'' +
                    ", reference='" + reference + '\'' +
                    ", channel='" + channel + '\'' +
                    ", accountId=" + accountId +
                    '}';
        }
    }

    /**
     * Immutable holder for master account data.
     */
    public static final class AccountReference {
        private final long accountId;
        private final String accountNumber;
        private final String accountStatus;
        private final String currency;

        /**
         * Builds the account reference holder.
         *
         * @param accountId internal account identifier
         * @param accountNumber business account number
         * @param accountStatus account status
         * @param currency account currency
         */
        public AccountReference(long accountId, String accountNumber, String accountStatus, String currency) {
            this.accountId = accountId;
            this.accountNumber = accountNumber;
            this.accountStatus = accountStatus;
            this.currency = currency;
        }

        /**
         * Returns the internal account identifier.
         *
         * @return account identifier
         */
        public long getAccountId() {
            return accountId;
        }

        /**
         * Returns the business account number.
         *
         * @return account number
         */
        public String getAccountNumber() {
            return accountNumber;
        }

        /**
         * Returns the account status.
         *
         * @return account status
         */
        public String getAccountStatus() {
            return accountStatus;
        }

        /**
         * Returns the account currency.
         *
         * @return currency
         */
        public String getCurrency() {
            return currency;
        }
    }

    /**
     * Immutable holder for definitive movement data.
     */
    public static final class MovementReference {
        private final long movementId;
        private final String transactionId;
        private final long accountId;
        private final java.time.LocalDate movementDate;
        private final String movementType;
        private final BigDecimal amount;
        private final String currency;
        private final String reference;

        /**
         * Builds the movement reference holder.
         *
         * @param movementId movement identifier
         * @param transactionId transaction identifier
         * @param accountId internal account identifier
         * @param movementDate movement date
         * @param movementType movement type
         * @param amount movement amount
         * @param currency movement currency
         * @param reference movement reference
         */
        public MovementReference(
                long movementId,
                String transactionId,
                long accountId,
                java.time.LocalDate movementDate,
                String movementType,
                BigDecimal amount,
                String currency,
                String reference) {
            this.movementId = movementId;
            this.transactionId = transactionId;
            this.accountId = accountId;
            this.movementDate = movementDate;
            this.movementType = movementType;
            this.amount = amount;
            this.currency = currency;
            this.reference = reference;
        }

        /**
         * Returns the movement identifier.
         *
         * @return movement identifier
         */
        public long getMovementId() {
            return movementId;
        }

        /**
         * Returns the transaction identifier.
         *
         * @return transaction identifier
         */
        public String getTransactionId() {
            return transactionId;
        }

        /**
         * Returns the internal account identifier.
         *
         * @return account identifier
         */
        public long getAccountId() {
            return accountId;
        }

        /**
         * Returns the movement date.
         *
         * @return movement date
         */
        public java.time.LocalDate getMovementDate() {
            return movementDate;
        }

        /**
         * Returns the movement type.
         *
         * @return movement type
         */
        public String getMovementType() {
            return movementType;
        }

        /**
         * Returns the definitive movement amount.
         *
         * @return amount
         */
        public BigDecimal getAmount() {
            return amount;
        }

        /**
         * Returns the movement currency.
         *
         * @return currency
         */
        public String getCurrency() {
            return currency;
        }

        /**
         * Returns the movement reference.
         *
         * @return reference
         */
        public String getReference() {
            return reference;
        }
    }
}