      *****************************************************************
      * COPYBOOK: FINMOVERR
      * Error layout for rejected input records.
      *****************************************************************
       01  FINMOVERR-REC.
           05 ERR-TRANSACTION-ID       PIC X(20).
           05 ERR-ERROR-CODE           PIC X(06).
           05 ERR-ERROR-DESCRIPTION    PIC X(60).
           05 ERR-RECORD-RAW           PIC X(200).
           05 ERR-TIMESTAMP            PIC X(26).
