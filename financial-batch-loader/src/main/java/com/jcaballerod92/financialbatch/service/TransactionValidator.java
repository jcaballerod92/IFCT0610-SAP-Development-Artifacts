package com.jcaballerod92.financialbatch.service;

import com.jcaballerod92.financialbatch.model.FinancialTransaction;

import java.math.BigDecimal;

/**
 * Validates the business rules of each financial movement before loading.
 */
public final class TransactionValidator {

    /**
     * Validates one transaction record.
     *
     * @param record transaction to validate
     * @return validation result
     */
    public ValidationResult validate(FinancialTransaction record) {
        if (record == null) {
            return ValidationResult.error("E001", "Record is null");
        }
        if (isBlank(record.getTransactionId())) {
            return ValidationResult.error("E002", "Missing transaction identifier");
        }
        if (record.getTransactionDate() == null) {
            return ValidationResult.error("E003", "Missing transaction date");
        }
        if (isBlank(record.getAccountNumber())) {
            return ValidationResult.error("E004", "Missing account number");
        }
        if (isBlank(record.getTransactionType())
                || !("CR".equalsIgnoreCase(record.getTransactionType())
                || "DB".equalsIgnoreCase(record.getTransactionType())
                || "TR".equalsIgnoreCase(record.getTransactionType()))) {
            return ValidationResult.error("E005", "Invalid transaction type");
        }
        if (record.getAmount() == null || record.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            return ValidationResult.error("E006", "Amount must be greater than zero");
        }
        if (isBlank(record.getCurrency())
                || !("EUR".equalsIgnoreCase(record.getCurrency())
                || "USD".equalsIgnoreCase(record.getCurrency())
                || "GBP".equalsIgnoreCase(record.getCurrency()))) {
            return ValidationResult.error("E007", "Unsupported currency");
        }
        if (isBlank(record.getReference())) {
            return ValidationResult.error("E008", "Missing reference");
        }

        return ValidationResult.ok();
    }

    /**
     * Checks whether a string is null, empty or only whitespace.
     *
     * @param value text to check
     * @return true if blank
     */
    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    /**
     * Validation result object used by the batch process.
     */
    public static final class ValidationResult {
        private final boolean valid;
        private final String errorCode;
        private final String errorDescription;

        private ValidationResult(boolean valid, String errorCode, String errorDescription) {
            this.valid = valid;
            this.errorCode = errorCode;
            this.errorDescription = errorDescription;
        }

        /**
         * Builds a successful validation result.
         *
         * @return valid result
         */
        public static ValidationResult ok() {
            return new ValidationResult(true, null, null);
        }

        /**
         * Builds a failed validation result.
         *
         * @param errorCode validation error code
         * @param errorDescription validation error message
         * @return invalid result
         */
        public static ValidationResult error(String errorCode, String errorDescription) {
            return new ValidationResult(false, errorCode, errorDescription);
        }

        /**
         * Returns whether validation was successful.
         *
         * @return true if valid
         */
        public boolean isValid() {
            return valid;
        }

        /**
         * Returns the validation error code.
         *
         * @return error code
         */
        public String getErrorCode() {
            return errorCode;
        }

        /**
         * Returns the validation error description.
         *
         * @return error description
         */
        public String getErrorDescription() {
            return errorDescription;
        }
    }
}