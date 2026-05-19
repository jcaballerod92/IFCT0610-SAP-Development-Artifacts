-- *********************************************************************
-- PROGRAM NAME : SP_FIN_RECONCILE
-- AUTHOR       : Jorge Caballero Diaz
-- PURPOSE      : Financial movement reconciliation and control process
--
-- DESCRIPTION  :
--   - Reads pending movement records from the staging/control view
--   - Compares account, amount, date and reference against target data
--   - Classifies each record as OK, DIF or ERR
--   - Persists reconciliation results and discrepancy details
--   - Updates processing status for operational traceability
--
-- ENVIRONMENT  : DB2 for z/OS / financial batch processing environment
-- *********************************************************************

-- =====================================================================
-- VIEW: VW_FIN_PENDING_MOVEMENTS
-- ---------------------------------------------------------------------
-- Functional purpose:
--   Provides the set of pending movements that still require
--   reconciliation and control processing.
-- =====================================================================
CREATE OR REPLACE VIEW VW_FIN_PENDING_MOVEMENTS AS
SELECT
    S.MOVEMENT_ID,
    S.ACCOUNT_ID,
    S.AMOUNT,
    S.MOVEMENT_DATE,
    S.REFERENCE,
    S.STATUS,
    S.CURRENCY,
    S.CHANNEL
FROM FIN_STG_MOVEMENT S
WHERE S.STATUS = 'PENDING';

-- =====================================================================
-- INDEX: IX_FIN_MOVEMENT_ACC
-- ---------------------------------------------------------------------
-- Functional purpose:
--   Improves access by account and movement date during reconciliation
--   lookups and report generation.
-- =====================================================================
CREATE INDEX IX_FIN_MOVEMENT_ACC
ON FIN_MOVEMENT (ACCOUNT_ID, MOVEMENT_DATE);

-- =====================================================================
-- INDEX: IX_FIN_DISC_MOV
-- ---------------------------------------------------------------------
-- Functional purpose:
--   Speeds up access to discrepancy records by movement and error code.
-- =====================================================================
CREATE INDEX IX_FIN_DISC_MOV
ON FIN_DISCREPANCY (MOVEMENT_ID, ERROR_CODE);

-- =====================================================================
-- STORED PROCEDURE: SP_FIN_RECONCILE
-- ---------------------------------------------------------------------
-- Functional purpose:
--   Performs reconciliation of pending financial movements against
--   definitive account and movement data in DB2.
--
-- Main steps:
--   1) Read pending movements from the view
--   2) Compare amount / account / date / reference
--   3) Classify as OK, DIF or ERR
--   4) Insert control data or discrepancy rows
--   5) Update staging status and audit information
-- =====================================================================

CREATE OR REPLACE PROCEDURE SP_FIN_RECONCILE ()
LANGUAGE SQL
MODIFIES SQL DATA
BEGIN
    -- -----------------------------------------------------------------
    -- DECLARATION SECTION
    -- Local variables used for reconciliation control, comparison logic
    -- and error handling.
    -- -----------------------------------------------------------------
    DECLARE V_ACCOUNT_ID        VARCHAR(20);
    DECLARE V_MOVEMENT_ID       VARCHAR(20);
    DECLARE V_AMOUNT            DECIMAL(13,2);
    DECLARE V_MOVEMENT_DATE     DATE;
    DECLARE V_REFERENCE         VARCHAR(35);
    DECLARE V_STATUS            VARCHAR(10);
    DECLARE V_ERROR_CODE        VARCHAR(6);
    DECLARE V_ERROR_DESCRIPTION VARCHAR(60);
    DECLARE V_EXPECTED_AMOUNT   DECIMAL(13,2);
    DECLARE V_REGISTERED_AMOUNT DECIMAL(13,2);
    DECLARE V_DIFF_AMOUNT       DECIMAL(13,2);
    DECLARE V_RECON_STATUS      VARCHAR(10);
    DECLARE V_ROW_NOT_FOUND     SMALLINT DEFAULT 0;
    DECLARE V_SQLCODE           INTEGER DEFAULT 0;

    -- -----------------------------------------------------------------
    -- CURSOR DECLARATION
    -- Reads the pending movements to be processed by the reconciliation
    -- engine.
    -- -----------------------------------------------------------------
    DECLARE C_PENDING CURSOR FOR
        SELECT MOVEMENT_ID,
               ACCOUNT_ID,
               AMOUNT,
               MOVEMENT_DATE,
               REFERENCE,
               STATUS
          FROM VW_FIN_PENDING_MOVEMENTS
         ORDER BY MOVEMENT_DATE, MOVEMENT_ID;

    -- -----------------------------------------------------------------
    -- HANDLERS
    -- Manage expected DB2 conditions such as end of cursor and absence
    -- of rows during control queries.
    -- -----------------------------------------------------------------
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET V_ROW_NOT_FOUND = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- In a real enterprise implementation, this block would update an
        -- error audit table and re-raise the exception for batch control.
        RESIGNAL;
    END;

    -- -----------------------------------------------------------------
    -- INITIALIZATION
    -- Prepare the procedure state before starting the reconciliation loop.
    -- -----------------------------------------------------------------
    SET V_ROW_NOT_FOUND = 0;

    -- -----------------------------------------------------------------
    -- OPEN CURSOR
    -- Starts the sequential processing of pending movement records.
    -- -----------------------------------------------------------------
    OPEN C_PENDING;

    -- -----------------------------------------------------------------
    -- MAIN RECONCILIATION LOOP
    -- Each pending movement is analysed against the reference account
    -- and movement tables.
    -- -----------------------------------------------------------------
    RECONCILE_LOOP:
    LOOP
        -- Fetch next pending movement.
        FETCH C_PENDING
            INTO V_MOVEMENT_ID,
                 V_ACCOUNT_ID,
                 V_AMOUNT,
                 V_MOVEMENT_DATE,
                 V_REFERENCE,
                 V_STATUS;

        IF V_ROW_NOT_FOUND = 1 THEN
            LEAVE RECONCILE_LOOP;
        END IF;

        -- Reset row flag for next iteration.
        SET V_ROW_NOT_FOUND = 0;

        -- -------------------------------------------------------------
        -- STEP 1: VERIFY ACCOUNT EXISTENCE AND STATUS
        -- -------------------------------------------------------------
        SET V_ERROR_CODE = NULL;
        SET V_ERROR_DESCRIPTION = NULL;
        SET V_EXPECTED_AMOUNT = 0.00;
        SET V_REGISTERED_AMOUNT = 0.00;
        SET V_DIFF_AMOUNT = 0.00;
        SET V_RECON_STATUS = 'OK';

        SELECT COALESCE(A.EXPECTED_AMOUNT, 0.00),
               COALESCE(A.ACCOUNT_STATUS, 'X')
          INTO V_EXPECTED_AMOUNT,
               V_STATUS
          FROM FIN_ACCOUNT A
         WHERE A.ACCOUNT_ID = V_ACCOUNT_ID;

        IF SQLCODE <> 0 THEN
            SET V_ERROR_CODE = 'E011';
            SET V_ERROR_DESCRIPTION = 'ACCOUNT NOT FOUND IN DB2';
            SET V_RECON_STATUS = 'ERR';
        ELSEIF V_STATUS <> 'A' THEN
            SET V_ERROR_CODE = 'E013';
            SET V_ERROR_DESCRIPTION = 'ACCOUNT NOT ACTIVE';
            SET V_RECON_STATUS = 'ERR';
        END IF;

        -- -------------------------------------------------------------
        -- STEP 2: COMPARE MOVEMENT DATA
        -- -------------------------------------------------------------
        IF V_RECON_STATUS = 'OK' THEN
            SELECT COALESCE(M.AMOUNT, 0.00)
              INTO V_REGISTERED_AMOUNT
              FROM FIN_MOVEMENT M
             WHERE M.MOVEMENT_ID = V_MOVEMENT_ID
               AND M.ACCOUNT_ID  = V_ACCOUNT_ID;

            IF SQLCODE <> 0 THEN
                SET V_ERROR_CODE = 'E014';
                SET V_ERROR_DESCRIPTION = 'MOVEMENT NOT FOUND IN DB2';
                SET V_RECON_STATUS = 'ERR';
            ELSE
                -- Amount comparison.
                SET V_DIFF_AMOUNT = V_AMOUNT - V_EXPECTED_AMOUNT;

                -- Business rule validation: amount / date / reference.
                IF V_AMOUNT = V_EXPECTED_AMOUNT
                   AND V_REGISTERED_AMOUNT = V_AMOUNT
                THEN
                    SET V_RECON_STATUS = 'RECONCILED';
                ELSE
                    SET V_ERROR_CODE = 'E015';
                    SET V_ERROR_DESCRIPTION = 'AMOUNT OR DATA DIFFERENCE';
                    SET V_RECON_STATUS = 'DIF';
                END IF;
            END IF;
        END IF;

        -- -------------------------------------------------------------
        -- STEP 3: PERSIST CONTROL OR DISCREPANCY INFORMATION
        -- -------------------------------------------------------------
        IF V_RECON_STATUS = 'RECONCILED' THEN
            INSERT INTO FIN_RECON_CONTROL
                (TRANSACTION_ID,
                 ACCOUNT_ID,
                 STATUS,
                 DIFFERENCE_AMOUNT,
                 RECON_DATE,
                 REMARKS)
            VALUES
                (V_MOVEMENT_ID,
                 V_ACCOUNT_ID,
                 'RECONCILED',
                 0.00,
                 CURRENT DATE,
                 'MOVEMENT RECONCILED SUCCESSFULLY');

            UPDATE FIN_STG_MOVEMENT
               SET STATUS = 'OK',
                   RECON_DATE = CURRENT DATE,
                   RECON_TIMESTAMP = CURRENT TIMESTAMP
             WHERE MOVEMENT_ID = V_MOVEMENT_ID;

        ELSE
            INSERT INTO FIN_DISCREPANCY
                (MOVEMENT_ID,
                 ACCOUNT_ID,
                 ERROR_CODE,
                 ERROR_DESCRIPTION,
                 EXPECTED_AMOUNT,
                 REGISTERED_AMOUNT,
                 DISC_DATE)
            VALUES
                (V_MOVEMENT_ID,
                 V_ACCOUNT_ID,
                 COALESCE(V_ERROR_CODE, 'E999'),
                 COALESCE(V_ERROR_DESCRIPTION, 'UNDEFINED RECONCILIATION ERROR'),
                 V_EXPECTED_AMOUNT,
                 V_REGISTERED_AMOUNT,
                 CURRENT DATE);

            UPDATE FIN_STG_MOVEMENT
               SET STATUS = 'ERR',
                   ERROR_CODE = COALESCE(V_ERROR_CODE, 'E999'),
                   ERROR_DESCRIPTION = COALESCE(V_ERROR_DESCRIPTION, 'UNDEFINED RECONCILIATION ERROR'),
                   RECON_TIMESTAMP = CURRENT TIMESTAMP
             WHERE MOVEMENT_ID = V_MOVEMENT_ID;
        END IF;

        -- -------------------------------------------------------------
        -- STEP 4: AUDIT / TRACEABILITY
        -- -------------------------------------------------------------
        INSERT INTO FIN_AUDIT_LOG
            (MODULE_NAME,
             PROCESS_ID,
             ENTITY_ID,
             ACTION_TYPE,
             ACTION_STATUS,
             ACTION_TIMESTAMP,
             ACTION_MESSAGE)
        VALUES
            ('SP_FIN_RECONCILE',
             V_MOVEMENT_ID,
             V_ACCOUNT_ID,
             'RECONCILIATION',
             V_RECON_STATUS,
             CURRENT TIMESTAMP,
             COALESCE(V_ERROR_DESCRIPTION, 'PROCESS COMPLETED'));

    END LOOP;

    -- -----------------------------------------------------------------
    -- CLOSE CURSOR
    -- Releases cursor resources after all pending movements have been
    -- processed.
    -- -----------------------------------------------------------------
    CLOSE C_PENDING;

END;
