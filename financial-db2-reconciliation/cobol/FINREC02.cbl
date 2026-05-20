       IDENTIFICATION DIVISION.
      *****************************************************************
      * PROGRAM NAME : FINREC02
      * PURPOSE      : Reconcile staged movements against DB2 reference.
      * DESCRIPTION  : Reads staging records, checks account and movement
      *                data, writes control and discrepancy outputs.
      *****************************************************************
       PROGRAM-ID. FINREC02.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT STG-MOVEMENT-FILE ASSIGN TO STGFILE.
           SELECT CTRL-RECON-FILE ASSIGN TO CTRLFILE.
           SELECT DISC-FILE ASSIGN TO DISCFILE.

       DATA DIVISION.
       FILE SECTION.

      *****************************************************************
      * STAGING INPUT LAYOUT
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

      *****************************************************************
      * CONTROL OUTPUT LAYOUT
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
      * DISCREPANCY OUTPUT LAYOUT
      *****************************************************************
       FD  DISC-FILE.
       01  FD-DISC-REC.
           05 DISC-TRANSACTION-ID      PIC X(20).
           05 DISC-ACCOUNT-NUMBER      PIC X(20).
           05 DISC-ERROR-CODE          PIC X(06).
           05 DISC-ERROR-DESCRIPTION   PIC X(60).
           05 DISC-EXPECTED-AMOUNT     PIC 9(11)V99.
           05 DISC-REGISTERED-AMOUNT   PIC 9(11)V99.

       WORKING-STORAGE SECTION.

      *****************************************************************
      * CONTROL VARIABLES
      *****************************************************************
       01  WS-CONTROL.
           05 WS-EOF-SW                PIC X(01) VALUE 'N'.
              88 EOF-YES                           VALUE 'Y'.
           05 WS-ERROR-SW              PIC X(01) VALUE 'N'.
              88 ERROR-YES                         VALUE 'Y'.
           05 WS-RECON-STATUS          PIC X(10) VALUE SPACES.
           05 WS-ACCOUNT-STATUS        PIC X(01) VALUE SPACES.
           05 WS-DB2-AMOUNT            PIC 9(11)V99 VALUE 0.
           05 WS-DIFF-AMOUNT           PIC 9(11)V99 VALUE 0.
           05 WS-RECON-DATE            PIC 9(08) VALUE 0.
           05 WS-ERROR-CODE            PIC X(06) VALUE SPACES.
           05 WS-ERROR-DESC            PIC X(60) VALUE SPACES.

       PROCEDURE DIVISION.

      *****************************************************************
      * MAIN PROCESS
      * Coordinates reconciliation and routing to outputs.
      *****************************************************************
       MAIN-PROCESS.
           PERFORM 0000-INIT
           PERFORM 1000-READ-STAGING UNTIL EOF-YES
           PERFORM 9000-FINALIZE
           GOBACK.

      *****************************************************************
      * INITIALIZATION
      * Opens files and prepares working values.
      *****************************************************************
       0000-INIT.
           OPEN INPUT  STG-MOVEMENT-FILE
                OUTPUT CTRL-RECON-FILE
                       DISC-FILE
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-RECON-DATE
           .

      *****************************************************************
      * READ STAGING
      * Reads each staged record and performs DB2-style reconciliation.
      *****************************************************************
       1000-READ-STAGING.
           READ STG-MOVEMENT-FILE
               AT END
                   SET EOF-YES TO TRUE
               NOT AT END
                   PERFORM 1100-SELECT-DB2-CHECK
                   IF WS-ERROR-SW = 'N'
                       PERFORM 1200-COMPARE-AMOUNTS
                       IF WS-RECON-STATUS = 'RECONCILED'
                           PERFORM 1300-POST-RECORD
                       ELSE
                           PERFORM 1400-WRITE-DISCREPANCY
                       END-IF
                   ELSE
                       PERFORM 1400-WRITE-DISCREPANCY
                   END-IF
                   PERFORM 1500-UPDATE-CONTROL
           END-READ.

      *****************************************************************
      * SELECT DB2 CHECK
      * In a real environment this would read reference data from DB2.
      * Here it prepares the working values used for comparison.
      *****************************************************************
       1100-SELECT-DB2-CHECK.
           MOVE 'N' TO WS-ERROR-SW
           MOVE ZERO TO WS-DB2-AMOUNT
           MOVE SPACES TO WS-ACCOUNT-STATUS

           IF STG-ACCOUNT-NUMBER = '9999999999'
               MOVE 'E011' TO WS-ERROR-CODE
               MOVE 'ACCOUNT NOT FOUND IN DB2' TO WS-ERROR-DESC
               MOVE 'Y' TO WS-ERROR-SW
           ELSE
               MOVE 'A' TO WS-ACCOUNT-STATUS
               MOVE STG-AMOUNT TO WS-DB2-AMOUNT
           END-IF
           .

      *****************************************************************
      * COMPARE AMOUNTS
      * Compares staged amount with reference amount.
      *****************************************************************
       1200-COMPARE-AMOUNTS.
           IF STG-AMOUNT = WS-DB2-AMOUNT
               MOVE 'RECONCILED' TO WS-RECON-STATUS
               MOVE ZERO TO WS-DIFF-AMOUNT
           ELSE
               MOVE 'DIF' TO WS-RECON-STATUS
               COMPUTE WS-DIFF-AMOUNT = STG-AMOUNT - WS-DB2-AMOUNT
               MOVE 'E015' TO WS-ERROR-CODE
               MOVE 'AMOUNT OR DATA DIFFERENCE' TO WS-ERROR-DESC
           END-IF
           .

      *****************************************************************
      * POST RECORD
      * Writes the reconciled record into the control file.
      *****************************************************************
       1300-POST-RECORD.
           MOVE STG-TRANSACTION-ID TO CTRL-TRANSACTION-ID
           MOVE STG-ACCOUNT-NUMBER TO CTRL-ACCOUNT-NUMBER
           MOVE WS-RECON-STATUS    TO CTRL-STATUS
           MOVE ZERO                TO CTRL-DIFFERENCE-AMOUNT
           MOVE WS-RECON-DATE      TO CTRL-RECON-DATE
           MOVE 'MOVEMENT RECONCILED SUCCESSFULLY' TO CTRL-REMARKS
           WRITE FD-CTRL-RECON-REC
           .

      *****************************************************************
      * WRITE DISCREPANCY
      * Writes the discrepancy record into the exception output.
      *****************************************************************
       1400-WRITE-DISCREPANCY.
           MOVE STG-TRANSACTION-ID TO DISC-TRANSACTION-ID
           MOVE STG-ACCOUNT-NUMBER TO DISC-ACCOUNT-NUMBER
           MOVE WS-ERROR-CODE      TO DISC-ERROR-CODE
           MOVE WS-ERROR-DESC      TO DISC-ERROR-DESCRIPTION
           MOVE WS-DB2-AMOUNT      TO DISC-EXPECTED-AMOUNT
           MOVE STG-AMOUNT         TO DISC-REGISTERED-AMOUNT
           WRITE FD-DISC-REC
           .

      *****************************************************************
      * UPDATE CONTROL
      * Keeps the control flow ready for the next record.
      *****************************************************************
       1500-UPDATE-CONTROL.
           CONTINUE.

      *****************************************************************
      * FINALIZATION
      * Closes all files and ends execution.
      *****************************************************************
       9000-FINALIZE.
           CLOSE STG-MOVEMENT-FILE
                 CTRL-RECON-FILE
                 DISC-FILE
           STOP RUN.
