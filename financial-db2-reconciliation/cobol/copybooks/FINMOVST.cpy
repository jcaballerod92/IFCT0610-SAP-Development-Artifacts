      *****************************************************************
      * COPYBOOK: FINMOVST
      * Staging layout for validated movement records.
      *****************************************************************
       01  FINMOVST-REC.
           05 STG-TRANSACTION-ID       PIC X(20).
           05 STG-TRANSACTION-DATE     PIC 9(08).
           05 STG-ACCOUNT-NUMBER       PIC X(20).
           05 STG-TRANSACTION-TYPE     PIC X(02).
           05 STG-AMOUNT               PIC 9(11)V99.
           05 STG-CURRENCY             PIC X(03).
           05 STG-REFERENCE            PIC X(35).
           05 STG-CHANNEL              PIC X(10).
           05 STG-LOAD-TIMESTAMP       PIC X(26).
