# Financial DB2 Reconciliation

<!-- Project overview -->
This repository contains a mainframe-style financial batch flow designed to demonstrate COBOL, JCL and DB2 skills in a banking context.

<!-- Scope -->
The project is organized around three COBOL programs, supporting copybooks, batch jobs and DB2 scripts:
- FINVLD01: validates and stages input movements
- FINREC02: reconciles staged movements against DB2 reference data
- FINRPT03: generates control and exception reports

<!-- Execution model -->
The repository is intentionally structured to look like a professional enterprise batch solution. The COBOL source, JCL orchestration, DB2 model and functional documentation are separated by responsibility so the flow is easy to understand.

<!-- How to read the project -->
Start with the README, then review the COBOL programs in execution order:
1. FINVLD01
2. FINREC02
3. FINRPT03

Then review the DB2 scripts, the batch jobs and the functional documents.
