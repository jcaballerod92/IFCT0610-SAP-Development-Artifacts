package com.jcaballerod92.financialbatch.service;

import com.jcaballerod92.financialbatch.model.ErrorRecord;
import com.jcaballerod92.financialbatch.model.ReconciliationResult;
import com.jcaballerod92.financialbatch.repository.ReconciliationRepository;
import com.jcaballerod92.financialbatch.repository.ReconciliationRepository.AccountReference;
import com.jcaballerod92.financialbatch.repository.ReconciliationRepository.MovementReference;
import com.jcaballerod92.financialbatch.repository.ReconciliationRepository.ReconciliationRow;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Service that performs reconciliation between staging and definitive data.
 * It coordinates repository calls, business comparisons and result creation.
 */
public final class ReconciliationService {

    private final ReconciliationRepository repository;

    /**
     * Creates the reconciliation service with the required repository.
     *
     * @param repository reconciliation repository
     */
    public ReconciliationService(ReconciliationRepository repository) {
        this.repository = repository;
    }

    /**
     * Executes the complete reconciliation flow for all pending movements.
     *
     * @return reconciliation summary result
     */
    public ReconciliationResult reconcile() {
        List<ReconciliationRow> pendingRows = repository.findPendingMovements();
        List<ErrorRecord> errorDetails = new ArrayList<ErrorRecord>();

        int processed = 0;
        int reconciled = 0;
        int discrepancies = 0;
        int errors = 0;

        for (ReconciliationRow row : pendingRows) {
            processed++;

            String status;
            String errorCode = null;
            String errorDescription = null;
            BigDecimal differenceAmount = BigDecimal.ZERO;
            BigDecimal expectedAmount = BigDecimal.ZERO;
            BigDecimal registeredAmount = row.getAmount();

            AccountReference accountReference = repository.findAccountReference(row.getAccountNumber());

            if (accountReference == null) {
                status = "ERR";
                errorCode = "E011";
                errorDescription = "ACCOUNT NOT FOUND IN DB2";
                errors++;
                errorDetails.add(buildError(row, errorCode, errorDescription));
            } else if (!"A".equals(accountReference.getAccountStatus())) {
                status = "ERR";
                errorCode = "E013";
                errorDescription = "ACCOUNT NOT ACTIVE";
                errors++;
                row.setAccountId(accountReference.getAccountId());
                errorDetails.add(buildError(row, errorCode, errorDescription));
            } else {
                row.setAccountId(accountReference.getAccountId());

                MovementReference movementReference =
                        repository.findMovementReference(row.getTransactionId(), accountReference.getAccountId());

                if (movementReference == null) {
                    status = "ERR";
                    errorCode = "E014";
                    errorDescription = "MOVEMENT NOT FOUND IN DB2";
                    errors++;
                    errorDetails.add(buildError(row, errorCode, errorDescription));
                } else {
                    expectedAmount = movementReference.getAmount();
                    differenceAmount = registeredAmount.subtract(expectedAmount);

                    boolean sameAmount = registeredAmount.compareTo(expectedAmount) == 0;
                    boolean sameDate = row.getTransactionDate().equals(movementReference.getMovementDate());
                    boolean sameType = equalsIgnoreCase(row.getTransactionType(), movementReference.getMovementType());
                    boolean sameCurrency = equalsIgnoreCase(row.getCurrency(), movementReference.getCurrency());
                    boolean sameReference = equalsText(row.getReference(), movementReference.getReference());

                    if (sameAmount && sameDate && sameType && sameCurrency && sameReference) {
                        status = "RECONCILED";
                        reconciled++;
                    } else {
                        status = "DIF";
                        errorCode = "E015";
                        errorDescription = "AMOUNT OR DATA DIFFERENCE";
                        discrepancies++;
                        errorDetails.add(buildError(row, errorCode, errorDescription));
                    }
                }
            }

            repository.saveControlRecord(
                    row,
                    status,
                    differenceAmount,
                    status.equals("RECONCILED") ? "MOVEMENT RECONCILED SUCCESSFULLY" : errorDescription
            );

            if (!"RECONCILED".equals(status)) {
                repository.saveDiscrepancy(
                        row,
                        errorCode == null ? "E999" : errorCode,
                        errorDescription == null ? "UNDEFINED RECONCILIATION ERROR" : errorDescription,
                        expectedAmount,
                        registeredAmount
                );
            }

            repository.updateStagingStatus(row, status, errorCode, errorDescription);

            repository.saveAudit(
                    "RECONCILIATION",
                    "SP_FIN_RECONCILE",
                    "FIN_STG_MOVEMENT",
                    String.valueOf(row.getStgId()),
                    "RECONCILIATION",
                    status,
                    status.equals("RECONCILED")
                            ? "ROW RECONCILED SUCCESSFULLY"
                            : errorDescription
            );
        }

        String finalStatus = (discrepancies == 0 && errors == 0) ? "SUCCESS" : "WITH_ERRORS";

        return new ReconciliationResult(
                processed,
                reconciled,
                discrepancies,
                errors,
                finalStatus,
                LocalDateTime.now(),
                errorDetails
        );
    }

    /**
     * Builds an error record for a rejected or discrepant row.
     *
     * @param row reconciliation row
     * @param errorCode error code
     * @param errorDescription error description
     * @return error record
     */
    private ErrorRecord buildError(ReconciliationRow row, String errorCode, String errorDescription) {
        return new ErrorRecord(
                row.getTransactionId(),
                row.getAccountNumber(),
                errorCode,
                errorDescription,
                row.toString(),
                LocalDateTime.now()
        );
    }

    /**
     * Compares two strings ignoring case and handling nulls.
     *
     * @param left first value
     * @param right second value
     * @return true if both values are equal
     */
    private boolean equalsIgnoreCase(String left, String right) {
        if (left == null && right == null) {
            return true;
        }
        if (left == null || right == null) {
            return false;
        }
        return left.equalsIgnoreCase(right);
    }

    /**
     * Compares two text values handling nulls and empty strings.
     *
     * @param left first text value
     * @param right second text value
     * @return true if both texts are equivalent
     */
    private boolean equalsText(String left, String right) {
        String normalizedLeft = left == null ? "" : left.trim();
        String normalizedRight = right == null ? "" : right.trim();
        return normalizedLeft.equals(normalizedRight);
    }
}