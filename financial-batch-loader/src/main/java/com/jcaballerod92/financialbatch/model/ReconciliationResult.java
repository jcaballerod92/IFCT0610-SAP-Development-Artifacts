package com.jcaballerod92.financialbatch.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Summary result generated after reconciliation processing.
 * It contains the batch counters, final status and the list of incidents.
 */
public final class ReconciliationResult {

    private final int processedRecords;
    private final int reconciledRecords;
    private final int discrepancyRecords;
    private final int errorRecords;
    private final String finalStatus;
    private final LocalDateTime generatedAt;
    private final List<ErrorRecord> errorDetails;

    /**
     * Creates a reconciliation result object.
     *
     * @param processedRecords total records processed
     * @param reconciledRecords records reconciled successfully
     * @param discrepancyRecords records with differences
     * @param errorRecords records with technical or business errors
     * @param finalStatus final batch status
     * @param generatedAt timestamp of the summary generation
     * @param errorDetails detailed error list
     */
    public ReconciliationResult(
            int processedRecords,
            int reconciledRecords,
            int discrepancyRecords,
            int errorRecords,
            String finalStatus,
            LocalDateTime generatedAt,
            List<ErrorRecord> errorDetails) {
        this.processedRecords = processedRecords;
        this.reconciledRecords = reconciledRecords;
        this.discrepancyRecords = discrepancyRecords;
        this.errorRecords = errorRecords;
        this.finalStatus = finalStatus;
        this.generatedAt = generatedAt;
        this.errorDetails = Collections.unmodifiableList(new ArrayList<ErrorRecord>(errorDetails));
    }

    /**
     * Returns the total number of processed records.
     *
     * @return processed count
     */
    public int getProcessedRecords() {
        return processedRecords;
    }

    /**
     * Returns the number of successfully reconciled records.
     *
     * @return reconciled count
     */
    public int getReconciledRecords() {
        return reconciledRecords;
    }

    /**
     * Returns the number of discrepancy records.
     *
     * @return discrepancy count
     */
    public int getDiscrepancyRecords() {
        return discrepancyRecords;
    }

    /**
     * Returns the number of error records.
     *
     * @return error count
     */
    public int getErrorRecords() {
        return errorRecords;
    }

    /**
     * Returns the final status of the reconciliation batch.
     *
     * @return final status
     */
    public String getFinalStatus() {
        return finalStatus;
    }

    /**
     * Returns the timestamp when the result was generated.
     *
     * @return generated timestamp
     */
    public LocalDateTime getGeneratedAt() {
        return generatedAt;
    }

    /**
     * Returns the detailed list of errors.
     *
     * @return error list
     */
    public List<ErrorRecord> getErrorDetails() {
        return errorDetails;
    }

    @Override
    public String toString() {
        return "ReconciliationResult{" +
                "processedRecords=" + processedRecords +
                ", reconciledRecords=" + reconciledRecords +
                ", discrepancyRecords=" + discrepancyRecords +
                ", errorRecords=" + errorRecords +
                ", finalStatus='" + finalStatus + '\'' +
                ", generatedAt=" + generatedAt +
                ", errorDetails=" + errorDetails +
                '}';
    }
}