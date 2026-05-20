      *****************************************************************
      * COPYBOOK: FINRECON
      * Control layout for reconciliation result records.
      *****************************************************************
       01  FINRECON-REC.
           05 CTRL-TRANSACTION-ID      PIC X(20).
           05 CTRL-ACCOUNT-NUMBER      PIC X(20).
           05 CTRL-STATUS              PIC X(10).
           05 CTRL-DIFFERENCE-AMOUNT   PIC 9(11)V99.
           05 CTRL-RECON-DATE          PIC 9(08).
           05 CTRL-REMARKS             PIC X(60).
