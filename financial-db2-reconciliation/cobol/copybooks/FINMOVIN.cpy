      *****************************************************************
      * COPYBOOK: FINMOVIN
      * Input layout for raw movement records.
      *****************************************************************
       01  FINMOVIN-REC.
           05 IN-RECORD-TYPE           PIC X(01).
           05 IN-TRANSACTION-ID        PIC X(20).
           05 IN-TRANSACTION-DATE      PIC 9(08).
           05 IN-ACCOUNT-NUMBER        PIC X(20).
           05 IN-TRANSACTION-TYPE      PIC X(02).
           05 IN-AMOUNT                PIC 9(11)V99.
           05 IN-CURRENCY              PIC X(03).
           05 IN-REFERENCE             PIC X(35).
           05 IN-CHANNEL               PIC X(10).
