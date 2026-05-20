      //TESTRUN  JOB (ACCT),'FIN TEST RUN',
      //             CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
      //*---------------------------------------------------------------*
      //* TESTRUN: sample execution job using test datasets.
      //*---------------------------------------------------------------*
      //STEP01   EXEC PGM=FINVLD01
      //STEPLIB  DD  DISP=SHR,DSN=FIN.LOADLIB
      //INFILE   DD  DISP=SHR,DSN=FIN.TEST.INPUT
      //STGFILE  DD  DISP=SHR,DSN=FIN.TEST.STAGE
      //ERRFILE  DD  DISP=SHR,DSN=FIN.TEST.ERROR
      //SYSPRINT DD  SYSOUT=*
      //SYSOUT   DD  SYSOUT=*
      //
      //STEP02   EXEC PGM=FINREC02
      //STEPLIB  DD  DISP=SHR,DSN=FIN.LOADLIB
      //STGFILE  DD  DISP=SHR,DSN=FIN.TEST.STAGE
      //CTRLFILE DD  DISP=SHR,DSN=FIN.TEST.CONTROL
      //DISCFILE DD  DISP=SHR,DSN=FIN.TEST.DISC
      //SYSPRINT DD  SYSOUT=*
      //SYSOUT   DD  SYSOUT=*
      //
      //STEP03   EXEC PGM=FINRPT03
      //STEPLIB  DD  DISP=SHR,DSN=FIN.LOADLIB
      //CTRLFILE DD  DISP=SHR,DSN=FIN.TEST.CONTROL
      //DISCFILE DD  DISP=SHR,DSN=FIN.TEST.DISC
      //RPTFILE  DD  DISP=SHR,DSN=FIN.TEST.REPORT
      //EXCFILE  DD  DISP=SHR,DSN=FIN.TEST.EXCEPTIONS
      //SYSPRINT DD  SYSOUT=*
      //SYSOUT   DD  SYSOUT=*
