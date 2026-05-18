       IDENTIFICATION DIVISION.
      *****************************************************************
      * PROGRAM NAME : FINVLD01
      * AUTHOR       : Jorge Caballero Diaz
      * PURPOSE      : Validation and staging load of financial
      *                movement records received from batch input files.
      *
      * DESCRIPTION  :
      * - Reads financial movement input file
      * - Validates mandatory fields and business rules
      * - Writes valid records into staging file
      * - Writes invalid records into error file
      * - Generates processing counters and control information
      *
      * EXECUTION    :
      * Executed in batch mode through JCL procedure.
      *
      * ENVIRONMENT  :
      * Financial / Banking batch processing environment
      *****************************************************************
       PROGRAM-ID. FINVLD01.
       AUTHOR. OPENAI.
       DATE-WRITTEN. 2026-05-18.
       REMARKS. VALIDACION Y CARGA DE MOVIMIENTOS DE ENTRADA.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-MOVEMENT-FILE ASSIGN TO INFILE
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT STG-MOVEMENT-FILE ASSIGN TO STGFILE
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT ERR-MOVEMENT-FILE ASSIGN TO ERRFILE
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

      *****************************************************************
      * INPUT FINANCIAL MOVEMENT RECORD
      * This file contains the raw movement records received from the
      * external source. Each record is validated before being accepted
      * into the staging area.
      *****************************************************************
       FD  IN-MOVEMENT-FILE.
       01  FD-IN-MOVEMENT-REC.
           05 IN-RECORD-TYPE           PIC X(01).
           05 IN-TRANSACTION-ID        PIC X(20).
           05 IN-TRANSACTION-DATE      PIC 9(08).
           05 IN-ACCOUNT-NUMBER        PIC X(20).
           05 IN-TRANSACTION-TYPE      PIC X(02).
           05 IN-AMOUNT                PIC 9(11)V99.
           05 IN-CURRENCY              PIC X(03).
           05 IN-REFERENCE             PIC X(35).
           05 IN-CHANNEL               PIC X(10).

      *****************************************************************
      * VALIDATED STAGING RECORD
      * This file contains only records that passed validation and are
      * ready for downstream reconciliation or database loading.
      *****************************************************************
       FD  STG-MOVEMENT-FILE.
       01  FD-STG-MOVEMENT-REC.
           05 STG-TRANSACTION-ID       PIC X(20).
           05 STG-TRANSACTION-DATE     PIC 9(08).
           05 STG-ACCOUNT-NUMBER       PIC X(20).
           05 STG-TRANSACTION-TYPE     PIC X(02).
           05 STG-AMOUNT               PIC 9(11)V99.
           05 STG-CURRENCY             PIC X(03).
           05 STG-REFERENCE            PIC X(35).
           05 STG-CHANNEL              PIC X(10).
           05 STG-LOAD-TIMESTAMP       PIC X(26).

      *****************************************************************
      * ERROR MOVEMENT RECORD
      * This file contains rejected records together with the error code,
      * description and the raw source data for traceability.
      *****************************************************************
       FD  ERR-MOVEMENT-FILE.
       01  FD-ERR-MOVEMENT-REC.
           05 ERR-TRANSACTION-ID       PIC X(20).
           05 ERR-ERROR-CODE           PIC X(06).
           05 ERR-ERROR-DESCRIPTION    PIC X(60).
           05 ERR-RECORD-RAW           PIC X(200).
           05 ERR-TIMESTAMP            PIC X(26).

       WORKING-STORAGE SECTION.

      *****************************************************************
      * PROCESS CONTROL VARIABLES
      * These variables control the flow of the batch process, counters,
      * validation status and error management.
      *****************************************************************
       01  WS-CONTROL.
           05 WS-EOF-SW                PIC X(01) VALUE 'N'.
              88 EOF-YES                           VALUE 'Y'.
              88 EOF-NO                            VALUE 'N'.
           05 WS-VALID-SW              PIC X(01) VALUE 'Y'.
              88 RECORD-VALID                      VALUE 'Y'.
              88 RECORD-NOT-VALID                  VALUE 'N'.
           05 WS-RECORD-COUNT          PIC 9(09) VALUE 0.
           05 WS-VALID-COUNT           PIC 9(09) VALUE 0.
           05 WS-ERROR-COUNT           PIC 9(09) VALUE 0.
           05 WS-ERROR-CODE            PIC X(06) VALUE SPACES.
           05 WS-ERROR-DESC            PIC X(60) VALUE SPACES.
           05 WS-TRANSACTION-DATE-NUM  PIC 9(08) VALUE 0.
           05 WS-AMOUNT-NUM            PIC 9(11)V99 VALUE 0.
           05 WS-LOAD-TIMESTAMP        PIC X(26) VALUE SPACES.
           05 WS-CURRENT-DATE          PIC X(08) VALUE SPACES.
           05 WS-CURRENT-TIME          PIC X(08) VALUE SPACES.
           05 WS-RAW-RECORD            PIC X(200) VALUE SPACES.

      *****************************************************************
      * AUXILIARY VARIABLES
      * These fields support date validation, auxiliary conversions and
      * business rule checks during record processing.
      *****************************************************************
       01  WS-AUXILIARY.
           05 WS-MONTH                 PIC 9(02) VALUE 0.
           05 WS-DAY                   PIC 9(02) VALUE 0.
           05 WS-YEAR                  PIC 9(04) VALUE 0.
           05 WS-TEMP-DATE             PIC 9(08) VALUE 0.
           05 WS-TRANSACTION-TYPE-TBL.
              10 FILLER PIC X(02) VALUE 'CR'.
              10 FILLER PIC X(02) VALUE 'DB'.
              10 FILLER PIC X(02) VALUE 'TR'.
           05 WS-TRANSACTION-TYPE-OK   PIC X(01) VALUE 'N'.

       PROCEDURE DIVISION.

      *****************************************************************
      * MAIN PROCESS
      * Main entry point of the program. It initializes the execution,
      * processes each input record and finalizes the batch job.
      *****************************************************************
       MAIN-PROCESS.
           PERFORM 0000-INIT
           PERFORM 1000-READ-INPUT UNTIL EOF-YES
           PERFORM 9000-FINALIZE
           GOBACK.

      *****************************************************************
      * PROGRAM INITIALIZATION
      * Opens input and output files, initializes counters, switches and
      * execution timestamp used in valid and error records.
      *****************************************************************
       0000-INIT.
           OPEN INPUT  IN-MOVEMENT-FILE
                OUTPUT STG-MOVEMENT-FILE
                       ERR-MOVEMENT-FILE
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-CURRENT-DATE
           MOVE FUNCTION CURRENT-DATE(9:8) TO WS-CURRENT-TIME
           STRING WS-CURRENT-DATE DELIMITED BY SIZE
                  WS-CURRENT-TIME DELIMITED BY SIZE
                  INTO WS-LOAD-TIMESTAMP
           END-STRING
           MOVE 'N' TO WS-EOF-SW
           MOVE ZERO TO WS-RECORD-COUNT WS-VALID-COUNT WS-ERROR-COUNT
           .

      *****************************************************************
      * READ INPUT RECORD
      * Reads the next movement record from the input file. When a record
      * is available, it is validated and routed to the corresponding
      * valid or error output path.
      *****************************************************************
       1000-READ-INPUT.
           READ IN-MOVEMENT-FILE
               AT END
                   SET EOF-YES TO TRUE
               NOT AT END
                   ADD 1 TO WS-RECORD-COUNT
                   MOVE FD-IN-MOVEMENT-REC TO WS-RAW-RECORD
                   PERFORM 1100-VALIDATE-RECORD
                   IF RECORD-VALID
                       PERFORM 1200-BUILD-STAGING-RECORD
                       PERFORM 1300-WRITE-VALID-RECORD
                   ELSE
                       PERFORM 1400-WRITE-ERROR-RECORD
                   END-IF
           END-READ.

      *****************************************************************
      * VALIDATE INPUT RECORD
      * Performs mandatory field checks, date validation, amount control
      * and transaction-type validation. If any rule fails, an error code
      * and description are assigned for traceability.
      *****************************************************************
       1100-VALIDATE-RECORD.
           MOVE 'Y' TO WS-VALID-SW
           MOVE SPACES TO WS-ERROR-CODE WS-ERROR-DESC
           MOVE ZERO TO WS-TRANSACTION-DATE-NUM WS-AMOUNT-NUM

           IF IN-RECORD-TYPE NOT = 'M'
               MOVE 'E001' TO WS-ERROR-CODE
               MOVE 'INVALID RECORD TYPE' TO WS-ERROR-DESC
               MOVE 'N' TO WS-VALID-SW
           END-IF

           IF RECORD-VALID AND IN-TRANSACTION-ID = SPACES
               MOVE 'E002' TO WS-ERROR-CODE
               MOVE 'MISSING TRANSACTION ID' TO WS-ERROR-DESC
               MOVE 'N' TO WS-VALID-SW
           END-IF

           IF RECORD-VALID AND IN-ACCOUNT-NUMBER = SPACES
               MOVE 'E003' TO WS-ERROR-CODE
               MOVE 'MISSING ACCOUNT NUMBER' TO WS-ERROR-DESC
               MOVE 'N' TO WS-VALID-SW
           END-IF

           IF RECORD-VALID AND IN-TRANSACTION-DATE NOT NUMERIC
               MOVE 'E004' TO WS-ERROR-CODE
               MOVE 'INVALID TRANSACTION DATE' TO WS-ERROR-DESC
               MOVE 'N' TO WS-VALID-SW
           END-IF

           IF RECORD-VALID
               MOVE IN-TRANSACTION-DATE TO WS-TRANSACTION-DATE-NUM
               MOVE WS-TRANSACTION-DATE-NUM TO WS-TEMP-DATE
               IF WS-TEMP-DATE(5:2) < 1 OR WS-TEMP-DATE(5:2) > 12
                   MOVE 'E005' TO WS-ERROR-CODE
                   MOVE 'INVALID DATE MONTH' TO WS-ERROR-DESC
                   MOVE 'N' TO WS-VALID-SW
               END-IF
           END-IF

           IF RECORD-VALID AND IN-AMOUNT NOT NUMERIC
               MOVE 'E006' TO WS-ERROR-CODE
               MOVE 'INVALID AMOUNT' TO WS-ERROR-DESC
               MOVE 'N' TO WS-VALID-SW
           END-IF

           IF RECORD-VALID
               MOVE IN-AMOUNT TO WS-AMOUNT-NUM
               IF WS-AMOUNT-NUM <= ZERO
                   MOVE 'E007' TO WS-ERROR-CODE
                   MOVE 'AMOUNT MUST BE GREATER THAN ZERO' TO WS-ERROR-DESC
                   MOVE 'N' TO WS-VALID-SW
               END-IF
           END-IF

           IF RECORD-VALID
               MOVE 'N' TO WS-TRANSACTION-TYPE-OK
               IF IN-TRANSACTION-TYPE = 'CR'
                   MOVE 'Y' TO WS-TRANSACTION-TYPE-OK
               END-IF
               IF IN-TRANSACTION-TYPE = 'DB'
                   MOVE 'Y' TO WS-TRANSACTION-TYPE-OK
               END-IF
               IF IN-TRANSACTION-TYPE = 'TR'
                   MOVE 'Y' TO WS-TRANSACTION-TYPE-OK
               END-IF
               IF WS-TRANSACTION-TYPE-OK = 'N'
                   MOVE 'E008' TO WS-ERROR-CODE
                   MOVE 'INVALID TRANSACTION TYPE' TO WS-ERROR-DESC
                   MOVE 'N' TO WS-VALID-SW
               END-IF
           END-IF

           IF RECORD-VALID AND IN-CURRENCY = SPACES
               MOVE 'E009' TO WS-ERROR-CODE
               MOVE 'MISSING CURRENCY' TO WS-ERROR-DESC
               MOVE 'N' TO WS-VALID-SW
           END-IF

           IF RECORD-VALID AND IN-CURRENCY NOT = 'EUR'
                               AND IN-CURRENCY NOT = 'USD'
                               AND IN-CURRENCY NOT = 'GBP'
               MOVE 'E010' TO WS-ERROR-CODE
               MOVE 'UNSUPPORTED CURRENCY' TO WS-ERROR-DESC
               MOVE 'N' TO WS-VALID-SW
           END-IF

           IF RECORD-VALID
               ADD 1 TO WS-VALID-COUNT
           END-IF
           .

      *****************************************************************
      * BUILD STAGING RECORD
      * Copies the validated input values into the staging record layout
      * used by downstream reconciliation and control processes.
      *****************************************************************
       1200-BUILD-STAGING-RECORD.
           MOVE IN-TRANSACTION-ID   TO STG-TRANSACTION-ID
           MOVE IN-TRANSACTION-DATE TO STG-TRANSACTION-DATE
           MOVE IN-ACCOUNT-NUMBER   TO STG-ACCOUNT-NUMBER
           MOVE IN-TRANSACTION-TYPE TO STG-TRANSACTION-TYPE
           MOVE IN-AMOUNT           TO STG-AMOUNT
           MOVE IN-CURRENCY         TO STG-CURRENCY
           MOVE IN-REFERENCE        TO STG-REFERENCE
           MOVE IN-CHANNEL          TO STG-CHANNEL
           MOVE WS-LOAD-TIMESTAMP   TO STG-LOAD-TIMESTAMP
           .

      *****************************************************************
      * WRITE VALID RECORD
      * Persists the validated movement into the staging file so it can
      * be consumed by subsequent reconciliation or loading processes.
      *****************************************************************
       1300-WRITE-VALID-RECORD.
           WRITE FD-STG-MOVEMENT-REC
           .

      *****************************************************************
      * WRITE ERROR RECORD
      * Builds and writes a rejected-record trace containing the original
      * data, error code and description for audit and troubleshooting.
      *****************************************************************
       1400-WRITE-ERROR-RECORD.
           ADD 1 TO WS-ERROR-COUNT
           MOVE IN-TRANSACTION-ID TO ERR-TRANSACTION-ID
           MOVE WS-ERROR-CODE     TO ERR-ERROR-CODE
           MOVE WS-ERROR-DESC     TO ERR-ERROR-DESCRIPTION
           MOVE WS-RAW-RECORD     TO ERR-RECORD-RAW
           MOVE WS-LOAD-TIMESTAMP TO ERR-TIMESTAMP
           WRITE FD-ERR-MOVEMENT-REC
           .

      *****************************************************************
      * FINALIZATION
      * Closes all files and terminates program execution cleanly after
      * processing all available input records.
      *****************************************************************
       9000-FINALIZE.
           CLOSE IN-MOVEMENT-FILE
                 STG-MOVEMENT-FILE
                 ERR-MOVEMENT-FILE
           STOP RUN.
