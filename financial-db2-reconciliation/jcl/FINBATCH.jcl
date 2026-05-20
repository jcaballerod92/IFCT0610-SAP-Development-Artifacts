      //FINBATCH  JOB (ACCT),'FIN BATCH',
      //             CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
      //*---------------------------------------------------------------*
      //* FINBATCH: main batch orchestration job.
      //* STEP01   : runs FINVLD01 to validate and stage input records.
      //* STEP02   : runs FINREC02 to reconcile staged records.
      //* STEP03   : runs FINRPT03 to generate summary and exceptions.
      //*---------------------------------------------------------------*
      //STEP01   EXEC PGM=FINVLD01
      //STEPLIB  DD  DISP=SHR,DSN=FIN.LOADLIB
      //INFILE   DD  DISP=SHR,DSN=FIN.INPUT.MOVEMENTS
      //STGFILE  DD  DISP=SHR,DSN=FIN.STAGE.MOVEMENTS
      //ERRFILE  DD  DISP=SHR,DSN=FIN.ERROR.MOVEMENTS
      //SYSPRINT DD  SYSOUT=*
      //SYSOUT   DD  SYSOUT=*
      //
      //STEP02   EXEC PGM=FINREC02
      //STEPLIB  DD  DISP=SHR,DSN=FIN.LOADLIB
      //STGFILE  DD  DISP=SHR,DSN=FIN.STAGE.MOVEMENTS
      //CTRLFILE DD  DISP=SHR,DSN=FIN.RECON.CONTROL
      //DISCFILE DD  DISP=SHR,DSN=FIN.DISCREPANCY
      //SYSPRINT DD  SYSOUT=*
      //SYSOUT   DD  SYSOUT=*
      //
      //STEP03   EXEC PGM=FINRPT03
      //STEPLIB  DD  DISP=SHR,DSN=FIN.LOADLIB
      //CTRLFILE DD  DISP=SHR,DSN=FIN.RECON.CONTROL
      //DISCFILE DD  DISP=SHR,DSN=FIN.DISCREPANCY
      //RPTFILE  DD  DISP=SHR,DSN=FIN.REPORT.SUMMARY
      //EXCFILE  DD  DISP=SHR,DSN=FIN.REPORT.EXCEPTIONS
      //SYSPRINT DD  SYSOUT=*
      //SYSOUT   DD  SYSOUT=*
