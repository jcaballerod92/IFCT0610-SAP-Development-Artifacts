package com.jcaballerod92.financialbatch.service;

import com.jcaballerod92.financialbatch.model.FinancialTransaction;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

/**
 * Service responsible for reading the input file and converting
 * each CSV record into a domain transaction object.
 */
public final class FileReaderService {

    /**
     * Reads a CSV file and returns the parsed transaction list.
     *
     * @param fileName input file path
     * @return list of parsed financial transactions
     * @throws IOException if the file cannot be opened or read
     */
    public List<FinancialTransaction> read(String fileName) throws IOException {
        List<FinancialTransaction> records = new ArrayList<FinancialTransaction>();

        try (BufferedReader reader = Files.newBufferedReader(Paths.get(fileName), StandardCharsets.UTF_8)) {
            String line;
            boolean firstLine = true;

            while ((line = reader.readLine()) != null) {
                String trimmed = line.trim();

                if (trimmed.isEmpty()) {
                    continue;
                }

                // Skip CSV header if present
                if (firstLine && trimmed.toLowerCase().contains("transactionid")) {
                    firstLine = false;
                    continue;
                }

                firstLine = false;
                records.add(FinancialTransaction.fromCsvLine(trimmed));
            }
        }

        return records;
    }
}