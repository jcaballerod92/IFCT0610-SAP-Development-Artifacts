package com.jcaballerod92.financialbatch.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * DTO returned at the end of the batch execution.
 * It contains counters, final status and the list of errors.
 */
public final class LoadResultDto {

    private final int processedRecords;
    private final int validRecords;
    private final int rejectedRecords;
    private final String loadStatus;
    private final LocalDateTime loadTimestamp;
    private final List<String> errorMessages;

    /**
     * Creates a batch result object.
     *
     * @param processedRecords total records read from input
     * @param validRecords valid records successfully loaded
     * @param rejectedRecords rejected records
     * @param loadStatus final batch status
     * @param loadTimestamp batch execution timestamp
     * @param errorMessages list of validation/load errors
     */
    public LoadResultDto(
            int processedRecords,
            int validRecords,
            int rejectedRecords,
            String loadStatus,
            LocalDateTime loadTimestamp,
            List<String> errorMessages) {
        this.processedRecords = processedRecords;
        this.validRecords = validRecords;
        this.rejectedRecords = rejectedRecords;
        this.loadStatus = loadStatus;
        this.loadTimestamp = loadTimestamp;
        this.errorMessages = Collections.unmodifiableList(new ArrayList<String>(errorMessages));
    }

    /**
     * Returns total processed records.
     *
     * @return processed count
     */
    public int getProcessedRecords() {
        return processedRecords;
    }

    /**
     * Returns valid loaded records.
     *
     * @return valid count
     */
    public int getValidRecords() {
        return validRecords;
    }

    /**
     * Returns rejected records.
     *
     * @return rejected count
     */
    public int getRejectedRecords() {
        return rejectedRecords;
    }

    /**
     * Returns final batch status.
     *
     * @return status text
     */
    public String getLoadStatus() {
        return loadStatus;
    }

    /**
     * Returns the batch execution timestamp.
     *
     * @return timestamp
     */
    public LocalDateTime getLoadTimestamp() {
        return loadTimestamp;
    }

    /**
     * Returns the list of errors generated during the batch.
     *
     * @return error messages list
     */
    public List<String> getErrorMessages() {
        return errorMessages;
    }

    @Override
    public String toString() {
        return "LoadResultDto{" +
                "processedRecords=" + processedRecords +
                ", validRecords=" + validRecords +
                ", rejectedRecords=" + rejectedRecords +
                ", loadStatus='" + loadStatus + '\'' +
                ", loadTimestamp=" + loadTimestamp +
                ", errorMessages=" + errorMessages +
                '}';
    }
}