      *****************************************************************
      * COPYBOOK: FINDISC
      * Discrepancy layout for reconciliation exceptions.
      *****************************************************************
       01  FINDISC-REC.
           05 DISC-TRANSACTION-ID      PIC X(20).
           05 DISC-ACCOUNT-NUMBER      PIC X(20).
           05 DISC-ERROR-CODE          PIC X(06).
           05 DISC-ERROR-DESCRIPTION   PIC X(60).
           05 DISC-EXPECTED-AMOUNT     PIC 9(11)V99.
           05 DISC-REGISTERED-AMOUNT   PIC 9(11)V99.
