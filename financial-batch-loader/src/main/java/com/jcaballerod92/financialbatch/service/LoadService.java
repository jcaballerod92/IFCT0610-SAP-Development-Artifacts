package com.jcaballerod92.financialbatch.service;

import com.jcaballerod92.financialbatch.model.FinancialTransaction;
import com.jcaballerod92.financialbatch.repository.LoadRepository;

/**
 * Service layer that coordinates the load operation.
 * It delegates persistence to the repository layer.
 */
public final class LoadService {

    private final LoadRepository loadRepository;

    /**
     * Creates the load service with the required repository dependency.
     *
     * @param loadRepository persistence repository
     */
    public LoadService(LoadRepository loadRepository) {
        this.loadRepository = loadRepository;
    }

    /**
     * Loads one validated transaction into the persistence layer.
     *
     * @param transaction validated financial movement
     */
    public void load(FinancialTransaction transaction) {
        loadRepository.insertTransaction(transaction);
    }
}