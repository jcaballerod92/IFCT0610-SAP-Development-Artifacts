package com.jcaballerod92.financialbatch;

import com.jcaballerod92.financialbatch.database.DatabaseInitializer;
import com.jcaballerod92.financialbatch.model.FinancialTransaction;
import com.jcaballerod92.financialbatch.model.LoadResultDto;
import com.jcaballerod92.financialbatch.repository.LoadRepository;
import com.jcaballerod92.financialbatch.service.FileReaderService;
import com.jcaballerod92.financialbatch.service.LoadService;
import com.jcaballerod92.financialbatch.service.TransactionValidator;
import com.jcaballerod92.financialbatch.service.TransactionValidator.ValidationResult;

import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

/**
 * Main batch application entry point.
 * Responsible for coordinating initialization, file reading,
 * validation, persistence and final batch result creation.
 */
public final class FinancialBatchLoaderApplication {

    /**
     * Main entry point used by the JVM.
     * Launches the batch execution and prints the final result.
     *
     * @param args optional command-line arguments
     */
    public static void main(String[] args) {
        FinancialBatchLoaderApplication application = new FinancialBatchLoaderApplication();
        LoadResultDto result = application.execute();
        System.out.println(result);
    }

    /**
     * Executes the complete batch flow.
     * This method orchestrates:
     * - properties loading
     * - database initialization
     * - CSV reading
     * - business validation
     * - JDBC persistence
     * - batch summary creation
     *
     * @return final execution result DTO
     */
    public LoadResultDto execute() {
        Properties properties = loadProperties();

        String inputFile = properties.getProperty("app.input-file", "sample-files/financial_movements.csv");
        String dbUrl = properties.getProperty("db.url", "jdbc:h2:file:./data/fin_db;AUTO_SERVER=TRUE;MODE=LEGACY");
        String dbUser = properties.getProperty("db.user", "sa");
        String dbPassword = properties.getProperty("db.password", "");

        List<String> errorMessages = new ArrayList<String>();
        int processedRecords = 0;
        int validRecords = 0;
        int rejectedRecords = 0;
        String loadStatus = "SUCCESS";
        LocalDateTime loadTimestamp = LocalDateTime.now();

        try {
            java.nio.file.Files.createDirectories(java.nio.file.Paths.get("data"));

            DatabaseInitializer databaseInitializer = new DatabaseInitializer(dbUrl, dbUser, dbPassword);
            databaseInitializer.initialize();

            FileReaderService fileReaderService = new FileReaderService();
            TransactionValidator validator = new TransactionValidator();
            LoadRepository loadRepository = new LoadRepository(dbUrl, dbUser, dbPassword);
            LoadService loadService = new LoadService(loadRepository);

            List<FinancialTransaction> records = fileReaderService.read(inputFile);
            processedRecords = records.size();

            for (FinancialTransaction record : records) {
                ValidationResult validation = validator.validate(record);

                if (validation.isValid()) {
                    try {
                        loadService.load(record);
                        validRecords++;
                    } catch (RuntimeException ex) {
                        rejectedRecords++;
                        loadStatus = "WITH_ERRORS";
                        errorMessages.add(buildError(record.getTransactionId(), "E900",
                                "Database load error: " + ex.getMessage()));
                    }
                } else {
                    rejectedRecords++;
                    loadStatus = "WITH_ERRORS";
                    errorMessages.add(buildError(record.getTransactionId(),
                            validation.getErrorCode(),
                            validation.getErrorDescription()));
                }
            }
        } catch (IOException ex) {
            loadStatus = "TECHNICAL_ERROR";
            errorMessages.add(buildError(null, "E901", "File error: " + ex.getMessage()));
        } catch (RuntimeException ex) {
            loadStatus = "TECHNICAL_ERROR";
            errorMessages.add(buildError(null, "E999", "Unexpected error: " + ex.getMessage()));
        }

        if (rejectedRecords > 0 && "SUCCESS".equals(loadStatus)) {
            loadStatus = "WITH_ERRORS";
        }

        return new LoadResultDto(
                processedRecords,
                validRecords,
                rejectedRecords,
                loadStatus,
                loadTimestamp,
                errorMessages
        );
    }

    /**
     * Loads application properties from the classpath.
     * If the file is not available, default values will be used.
     *
     * @return properties object loaded from resources
     */
    private Properties loadProperties() {
        Properties properties = new Properties();

        InputStream inputStream = FinancialBatchLoaderApplication.class
                .getClassLoader()
                .getResourceAsStream("application.properties");

        if (inputStream == null) {
            return properties;
        }

        try {
            properties.load(inputStream);
        } catch (IOException ignored) {
            // Default values will be used if properties cannot be loaded.
        }

        return properties;
    }

    /**
     * Builds a standardized error text for console output or log use.
     *
     * @param transactionId related transaction identifier
     * @param errorCode technical/business error code
     * @param description error explanation
     * @return formatted error message
     */
    private String buildError(String transactionId, String errorCode, String description) {
        return "transactionId=" + transactionId
                + " | errorCode=" + errorCode
                + " | errorDescription=" + description;
    }
}