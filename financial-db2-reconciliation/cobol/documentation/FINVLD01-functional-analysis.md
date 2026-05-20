# FINVLD01 Functional Analysis

<!-- Purpose -->
FINVLD01 validates raw movement input records and moves only the accepted ones into the staging file.

<!-- Input -->
The program receives a flat file or batch input with transaction identifier, account number, date, amount, currency, reference and channel.

<!-- Output -->
Valid records are written to staging. Invalid records are written to the error file together with an error code and a short description.

<!-- Control -->
The execution flow is intentionally simple and sequential so it resembles a classic banking batch validation step.
