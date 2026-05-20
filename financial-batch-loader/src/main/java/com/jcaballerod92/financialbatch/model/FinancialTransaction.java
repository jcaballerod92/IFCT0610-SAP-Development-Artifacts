package com.jcaballerod92.financialbatch.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

/**
 * Domain object that represents one financial movement from the input file.
 * It stores the business fields used during validation and loading.
 */
public final class FinancialTransaction {

    private final String transactionId;
    private final LocalDate transactionDate;
    private final String accountNumber;
    private final String transactionType;
    private final BigDecimal amount;
    private final String currency;
    private final String reference;

    /**
     * Creates a new financial transaction object.
     *
     * @param transactionId business identifier of the movement
     * @param transactionDate movement date
     * @param accountNumber account number
     * @param transactionType movement type
     * @param amount movement amount
     * @param currency currency code
     * @param reference external reference
     */
    public FinancialTransaction(
            String transactionId,
            LocalDate transactionDate,
            String accountNumber,
            String transactionType,
            BigDecimal amount,
            String currency,
            String reference) {
        this.transactionId = transactionId;
        this.transactionDate = transactionDate;
        this.accountNumber = accountNumber;
        this.transactionType = transactionType;
        this.amount = amount;
        this.currency = currency;
        this.reference = reference;
    }

    /**
     * Builds a transaction object from one CSV line.
     * Expected order:
     * transactionId, transactionDate, accountNumber, transactionType, amount, currency, reference
     *
     * @param line raw CSV line
     * @return parsed financial transaction
     */
    public static FinancialTransaction fromCsvLine(String line) {
        if (line == null || line.trim().isEmpty()) {
            throw new IllegalArgumentException("Empty CSV line");
        }

        String[] parts = line.split(",", -1);
        if (parts.length < 7) {
            throw new IllegalArgumentException("Invalid CSV format. Expected 7 columns.");
        }

        try {
            return new FinancialTransaction(
                    parts[0].trim(),
                    LocalDate.parse(parts[1].trim()),
                    parts[2].trim(),
                    parts[3].trim(),
                    new BigDecimal(parts[4].trim()),
                    parts[5].trim(),
                    parts[6].trim()
            );
        } catch (DateTimeParseException ex) {
            throw new IllegalArgumentException("Invalid transaction date: " + parts[1].trim(), ex);
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("Invalid amount: " + parts[4].trim(), ex);
        }
    }

    /**
     * Returns the transaction identifier.
     *
     * @return transaction id
     */
    public String getTransactionId() {
        return transactionId;
    }

    /**
     * Returns the transaction date.
     *
     * @return transaction date
     */
    public LocalDate getTransactionDate() {
        return transactionDate;
    }

    /**
     * Returns the account number.
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
     * Returns the movement amount.
     *
     * @return amount
     */
    public BigDecimal getAmount() {
        return amount;
    }

    /**
     * Returns the movement currency.
     *
     * @return currency code
     */
    public String getCurrency() {
        return currency;
    }

    /**
     * Returns the external reference.
     *
     * @return reference text
     */
    public String getReference() {
        return reference;
    }

    @Override
    public String toString() {
        return "FinancialTransaction{" +
                "transactionId='" + transactionId + '\'' +
                ", transactionDate=" + transactionDate +
                ", accountNumber='" + accountNumber + '\'' +
                ", transactionType='" + transactionType + '\'' +
                ", amount=" + amount +
                ", currency='" + currency + '\'' +
                ", reference='" + reference + '\'' +
                '}';
    }
}