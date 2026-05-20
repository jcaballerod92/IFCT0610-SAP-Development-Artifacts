package com.jcaballerod92.financialbatch.model;

import java.time.LocalDateTime;

/**
 * Business error or technical rejection record.
 * This object is used to keep traceability of rejected transactions
 * or reconciliation incidents.
 */
public final class ErrorRecord {

    private final String transactionId;
    private final String accountNumber;
    private final String errorCode;
    private final String errorDescription;
    private final String rawRecord;
    private final LocalDateTime errorTimestamp;

    /**
     * Creates a new error record.
     *
     * @param transactionId related transaction identifier
     * @param accountNumber related account number
     * @param errorCode business or technical error code
     * @param errorDescription human-readable error description
     * @param rawRecord original raw record or context text
     * @param errorTimestamp timestamp of the error generation
     */
    public ErrorRecord(
            String transactionId,
            String accountNumber,
            String errorCode,
            String errorDescription,
            String rawRecord,
            LocalDateTime errorTimestamp) {
        this.transactionId = transactionId;
        this.accountNumber = accountNumber;
        this.errorCode = errorCode;
        this.errorDescription = errorDescription;
        this.rawRecord = rawRecord;
        this.errorTimestamp = errorTimestamp;
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
     * Returns the account number associated with the error.
     *
     * @return account number
     */
    public String getAccountNumber() {
        return accountNumber;
    }

    /**
     * Returns the error code.
     *
     * @return error code
     */
    public String getErrorCode() {
        return errorCode;
    }

    /**
     * Returns the error description.
     *
     * @return error description
     */
    public String getErrorDescription() {
        return errorDescription;
    }

    /**
     * Returns the original raw record or contextual text.
     *
     * @return raw record
     */
    public String getRawRecord() {
        return rawRecord;
    }

    /**
     * Returns the timestamp of the error generation.
     *
     * @return error timestamp
     */
    public LocalDateTime getErrorTimestamp() {
        return errorTimestamp;
    }

    @Override
    public String toString() {
        return "ErrorRecord{" +
                "transactionId='" + transactionId + '\'' +
                ", accountNumber='" + accountNumber + '\'' +
                ", errorCode='" + errorCode + '\'' +
                ", errorDescription='" + errorDescription + '\'' +
                ", rawRecord='" + rawRecord + '\'' +
                ", errorTimestamp=" + errorTimestamp +
                '}';
    }
}