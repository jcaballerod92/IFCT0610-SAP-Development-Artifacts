       IDENTIFICATION DIVISION.
      *****************************************************************
      * PROGRAM NAME : FINVLD01
      * PURPOSE      : Validate and stage financial movement records.
      * DESCRIPTION  : Reads input movements, validates business rules,
      *                writes valid records to staging and invalid ones
      *                to the error file.
      *****************************************************************
       PROGRAM-ID. FINVLD01.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-MOVEMENT-FILE ASSIGN TO INFILE.
           SELECT STG-MOVEMENT-FILE ASSIGN TO STGFILE.
           SELECT ERR-MOVEMENT-FILE ASSIGN TO ERRFILE.

       DATA DIVISION.
       FILE SECTION.

      *****************************************************************
      * INPUT RECORD LAYOUT
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
      * STAGING RECORD LAYOUT
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
      * ERROR RECORD LAYOUT
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
      * CONTROL VARIABLES
      *****************************************************************
       01  WS-CONTROL.
           05 WS-EOF-SW                PIC X(01) VALUE 'N'.
              88 EOF-YES                           VALUE 'Y'.
           05 WS-VALID-SW              PIC X(01) VALUE 'Y'.
              88 RECORD-VALID                      VALUE 'Y'.
           05 WS-RECORD-COUNT          PIC 9(09) VALUE 0.
           05 WS-VALID-COUNT           PIC 9(09) VALUE 0.
           05 WS-ERROR-COUNT           PIC 9(09) VALUE 0.
           05 WS-ERROR-CODE            PIC X(06) VALUE SPACES.
           05 WS-ERROR-DESC            PIC X(60) VALUE SPACES.
           05 WS-LOAD-TIMESTAMP        PIC X(26) VALUE SPACES.
           05 WS-RAW-RECORD            PIC X(200) VALUE SPACES.

       PROCEDURE DIVISION.

      *****************************************************************
      * MAIN PROCESS
      * Coordinates the whole validation flow from initialization to
      * file closing.
      *****************************************************************
       MAIN-PROCESS.
           PERFORM 0000-INIT
           PERFORM 1000-READ-INPUT UNTIL EOF-YES
           PERFORM 9000-FINALIZE
           GOBACK.

      *****************************************************************
      * INITIALIZATION
      * Opens files and prepares counters and timestamps.
      *****************************************************************
       0000-INIT.
           OPEN INPUT  IN-MOVEMENT-FILE
                OUTPUT STG-MOVEMENT-FILE
                       ERR-MOVEMENT-FILE
           MOVE FUNCTION CURRENT-DATE TO WS-LOAD-TIMESTAMP
           MOVE ZERO TO WS-RECORD-COUNT WS-VALID-COUNT WS-ERROR-COUNT
           .

      *****************************************************************
      * READ INPUT
      * Reads each record and dispatches it to validation and routing.
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
      * VALIDATE RECORD
      * Applies mandatory field checks and business rules.
      *****************************************************************
       1100-VALIDATE-RECORD.
           MOVE 'Y' TO WS-VALID-SW
           MOVE SPACES TO WS-ERROR-CODE WS-ERROR-DESC

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

           IF RECORD-VALID AND IN-AMOUNT <= ZERO
               MOVE 'E006' TO WS-ERROR-CODE
               MOVE 'INVALID AMOUNT' TO WS-ERROR-DESC
               MOVE 'N' TO WS-VALID-SW
           END-IF

           IF RECORD-VALID
               ADD 1 TO WS-VALID-COUNT
           END-IF
           .

      *****************************************************************
      * BUILD STAGING RECORD
      * Copies validated source values into the staging layout.
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
      * Sends the validated record into the staging file.
      *****************************************************************
       1300-WRITE-VALID-RECORD.
           WRITE FD-STG-MOVEMENT-REC.

      *****************************************************************
      * WRITE ERROR RECORD
      * Persists the rejected input record together with the reason.
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
      * Closes all files and ends execution cleanly.
      *****************************************************************
       9000-FINALIZE.
           CLOSE IN-MOVEMENT-FILE
                 STG-MOVEMENT-FILE
                 ERR-MOVEMENT-FILE
           STOP RUN.
