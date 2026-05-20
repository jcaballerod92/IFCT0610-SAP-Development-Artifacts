       IDENTIFICATION DIVISION.
      *****************************************************************
      * PROGRAM NAME : FINRPT03
      * PURPOSE      : Generate control and exception reports.
      * DESCRIPTION  : Reads reconciliation and discrepancy outputs,
      *                accumulates totals and writes summary information.
      *****************************************************************
       PROGRAM-ID. FINRPT03.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CTRL-RECON-FILE ASSIGN TO CTRLFILE.
           SELECT DISC-FILE ASSIGN TO DISCFILE.
           SELECT RPT-SUMMARY-FILE ASSIGN TO RPTFILE.
           SELECT RPT-EXCEPTION-FILE ASSIGN TO EXCFILE.

       DATA DIVISION.
       FILE SECTION.

      *****************************************************************
      * RECONCILIATION CONTROL INPUT
      *****************************************************************
       FD  CTRL-RECON-FILE.
       01  FD-CTRL-RECON-REC.
           05 CTRL-TRANSACTION-ID      PIC X(20).
           05 CTRL-ACCOUNT-NUMBER      PIC X(20).
           05 CTRL-STATUS              PIC X(10).
           05 CTRL-DIFFERENCE-AMOUNT   PIC 9(11)V99.
           05 CTRL-RECON-DATE          PIC 9(08).
           05 CTRL-REMARKS             PIC X(60).

      *****************************************************************
      * DISCREPANCY INPUT
      *****************************************************************
       FD  DISC-FILE.
       01  FD-DISC-REC.
           05 DISC-TRANSACTION-ID      PIC X(20).
           05 DISC-ACCOUNT-NUMBER      PIC X(20).
           05 DISC-ERROR-CODE          PIC X(06).
           05 DISC-ERROR-DESCRIPTION   PIC X(60).
           05 DISC-EXPECTED-AMOUNT     PIC 9(11)V99.
           05 DISC-REGISTERED-AMOUNT   PIC 9(11)V99.

      *****************************************************************
      * SUMMARY REPORT OUTPUT
      *****************************************************************
       FD  RPT-SUMMARY-FILE.
       01  FD-RPT-SUMMARY-REC.
           05 RPT-RUN-ID               PIC X(20).
           05 RPT-TOTAL-READ           PIC 9(09).
           05 RPT-TOTAL-OK             PIC 9(09).
           05 RPT-TOTAL-ERROR          PIC 9(09).
           05 RPT-TOTAL-DISCREPANCIES  PIC 9(09).
           05 RPT-FINAL-STATUS         PIC X(10).

      *****************************************************************
      * EXCEPTION REPORT OUTPUT
      *****************************************************************
       FD  RPT-EXCEPTION-FILE.
       01  FD-RPT-EXCEPTION-REC.
           05 RPT-TRANSACTION-ID       PIC X(20).
           05 RPT-ACCOUNT-NUMBER       PIC X(20).
           05 RPT-ERROR-CODE           PIC X(06).
           05 RPT-ERROR-DESCRIPTION    PIC X(60).
           05 RPT-AMOUNT               PIC 9(11)V99.
           05 RPT-TIMESTAMP            PIC X(26).

       WORKING-STORAGE SECTION.

      *****************************************************************
      * CONTROL VARIABLES
      *****************************************************************
       01  WS-CONTROL.
           05 WS-EOF-CTRL-SW           PIC X(01) VALUE 'N'.
              88 CTRL-EOF-YES                     VALUE 'Y'.
           05 WS-EOF-DISC-SW           PIC X(01) VALUE 'N'.
              88 DISC-EOF-YES                     VALUE 'Y'.
           05 WS-TOTAL-READ            PIC 9(09) VALUE 0.
           05 WS-TOTAL-OK              PIC 9(09) VALUE 0.
           05 WS-TOTAL-ERROR           PIC 9(09) VALUE 0.
           05 WS-TOTAL-DISC            PIC 9(09) VALUE 0.
           05 WS-FINAL-STATUS          PIC X(10) VALUE SPACES.
           05 WS-RUN-ID                PIC X(20) VALUE SPACES.
           05 WS-WORK-TEXT             PIC X(80) VALUE SPACES.
           05 WS-TIMESTAMP             PIC X(26) VALUE SPACES.
           05 WS-CURRENT-DATE          PIC X(08) VALUE SPACES.
           05 WS-CURRENT-TIME          PIC X(08) VALUE SPACES.

       PROCEDURE DIVISION.

      *****************************************************************
      * MAIN PROCESS
      * Controls the report generation flow.
      *****************************************************************
       MAIN-PROCESS.
           PERFORM 0000-INIT
           PERFORM 1000-READ-CTRL UNTIL CTRL-EOF-YES AND DISC-EOF-YES
           PERFORM 1200-WRITE-SUMMARY
           PERFORM 1400-CALCULATE-FINAL-STATUS
           PERFORM 9000-FINALIZE
           GOBACK.

      *****************************************************************
      * INITIALIZATION
      * Opens files and prepares report counters.
      *****************************************************************
       0000-INIT.
           OPEN INPUT  CTRL-RECON-FILE
                       DISC-FILE
                OUTPUT RPT-SUMMARY-FILE
                       RPT-EXCEPTION-FILE
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-CURRENT-DATE
           MOVE FUNCTION CURRENT-DATE(9:8) TO WS-CURRENT-TIME
           STRING WS-CURRENT-DATE DELIMITED BY SIZE
                  WS-CURRENT-TIME DELIMITED BY SIZE
                  INTO WS-TIMESTAMP
           END-STRING
           MOVE WS-TIMESTAMP TO WS-RUN-ID
           MOVE ZERO TO WS-TOTAL-READ WS-TOTAL-OK WS-TOTAL-ERROR WS-TOTAL-DISC
           .

      *****************************************************************
      * READ CONTROL RECORDS
      * In a real implementation the control and discrepancy streams could
      * be processed separately. Here the logic is kept simple.
      *****************************************************************
       1000-READ-CTRL.
           READ CTRL-RECON-FILE
               AT END
                   SET CTRL-EOF-YES TO TRUE
               NOT AT END
                   ADD 1 TO WS-TOTAL-READ
                   IF CTRL-STATUS = 'RECONCILED'
                       ADD 1 TO WS-TOTAL-OK
                   ELSE
                       ADD 1 TO WS-TOTAL-ERROR
                   END-IF
           END-READ.

           READ DISC-FILE
               AT END
                   SET DISC-EOF-YES TO TRUE
               NOT AT END
                   ADD 1 TO WS-TOTAL-DISC
                   PERFORM 1300-WRITE-EXCEPTIONS
           END-READ.

      *****************************************************************
      * WRITE SUMMARY
      * Writes the batch summary report.
      *****************************************************************
       1200-WRITE-SUMMARY.
           MOVE WS-RUN-ID               TO RPT-RUN-ID
           MOVE WS-TOTAL-READ           TO RPT-TOTAL-READ
           MOVE WS-TOTAL-OK             TO RPT-TOTAL-OK
           MOVE WS-TOTAL-ERROR          TO RPT-TOTAL-ERROR
           MOVE WS-TOTAL-DISC           TO RPT-TOTAL-DISCREPANCIES
           IF WS-TOTAL-ERROR = 0 AND WS-TOTAL-DISC = 0
               MOVE 'SUCCESS' TO RPT-FINAL-STATUS
               MOVE 'SUCCESS' TO WS-FINAL-STATUS
           ELSE
               MOVE 'WITH ERRORS' TO RPT-FINAL-STATUS
               MOVE 'WITH ERRORS' TO WS-FINAL-STATUS
           END-IF
           WRITE FD-RPT-SUMMARY-REC
           .

      *****************************************************************
      * WRITE EXCEPTIONS
      * Writes discrepancy detail into the exception report.
      *****************************************************************
       1300-WRITE-EXCEPTIONS.
           MOVE DISC-TRANSACTION-ID     TO RPT-TRANSACTION-ID
           MOVE DISC-ACCOUNT-NUMBER     TO RPT-ACCOUNT-NUMBER
           MOVE DISC-ERROR-CODE         TO RPT-ERROR-CODE
           MOVE DISC-ERROR-DESCRIPTION  TO RPT-ERROR-DESCRIPTION
           MOVE DISC-REGISTERED-AMOUNT  TO RPT-AMOUNT
           MOVE WS-TIMESTAMP            TO RPT-TIMESTAMP
           WRITE FD-RPT-EXCEPTION-REC
           .

      *****************************************************************
      * CALCULATE FINAL STATUS
      * Final batch status control.
      *****************************************************************
       1400-CALCULATE-FINAL-STATUS.
           CONTINUE.

      *****************************************************************
      * FINALIZATION
      * Closes files and ends the program.
      *****************************************************************
       9000-FINALIZE.
           CLOSE CTRL-RECON-RECORD
                 DISC-FILE
                 RPT-SUMMARY-FILE
                 RPT-EXCEPTION-FILE
           STOP RUN.
