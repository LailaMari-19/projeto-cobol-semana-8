IDENTIFICATION DIVISION.
       PROGRAM-ID. PROCBANC.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-CLI ASSIGN TO CLIENTES.
           SELECT ARQ-TRX ASSIGN TO TRANSACOES.
           SELECT ARQ-REL ASSIGN TO RELATORIO.
           SELECT ARQ-ERR ASSIGN TO ERROS.

       DATA DIVISION.
       FILE SECTION.
       FD  ARQ-CLI.
       COPY 'COPY/CLI.CPY'.
       
       FD  ARQ-TRX.
       COPY 'COPY/TRX.CPY'.

       FD  ARQ-REL.
       01  REG-REL       PIC X(80).

       FD  ARQ-ERR.
       01  REG-ERR       PIC X(80).

       WORKING-STORAGE SECTION.
       EXEC SQL INCLUDE SQLCA END-EXEC.

       01 WS-EOF              PIC X(01) VALUE 'N'.
       01 WS-CONT-PROCESS     PIC 9(05) VALUE 0.
       01 WS-TOT-LIDOS        PIC 9(05) VALUE 0.
       01 WS-TOT-OK           PIC 9(05) VALUE 0.
       01 WS-TOT-ERRO         PIC 9(05) VALUE 0.

       PROCEDURE DIVISION.
       000-MAIN.
           EXEC SQL CONNECT TO 'BANCO-DB2' END-EXEC.

           OPEN INPUT ARQ-CLI.
           READ ARQ-CLI AT END MOVE 'Y' TO WS-EOF.
           PERFORM UNTIL WS-EOF = 'Y'
               ADD 1 TO WS-TOT-LIDOS
               EXEC SQL
                   SELECT CLI_ID INTO :CLI-ID
                   FROM CLIENTES WHERE CLI_ID = :CLI-ID
               END-EXEC
               IF SQLCODE = 0
                   EXEC SQL
                       UPDATE CLIENTES 
                       SET CLI_NOME = :CLI-NOME, CLI_SALDO = :CLI-SALDO 
                       WHERE CLI_ID = :CLI-ID
                   END-EXEC
                   ADD 1 TO WS-TOT-OK
               ELSE
                   EXEC SQL
                       INSERT INTO CLIENTES (CLI_ID, CLI_NOME, CLI_SALDO)
                       VALUES (:CLI-ID, :CLI-NOME, :CLI-SALDO)
                   END-EXEC
                   ADD 1 TO WS-TOT-OK
               END-IF
               ADD 1 TO WS-CONT-PROCESS
               IF FUNCTION MOD(WS-CONT-PROCESS, 100) = 0
                   EXEC SQL COMMIT END-EXEC
               END-IF
               READ ARQ-CLI AT END MOVE 'Y' TO WS-EOF
           END-PERFORM.
           CLOSE ARQ-CLI.

           MOVE 'N' TO WS-EOF.
           OPEN INPUT ARQ-TRX.
           READ ARQ-TRX AT END MOVE 'Y' TO WS-EOF.
           PERFORM UNTIL WS-EOF = 'Y'
               EXEC SQL
                   SELECT CLI_SALDO INTO :CLI-SALDO
                   FROM CLIENTES WHERE CLI_ID = :TRX-CLI-ID
               END-EXEC
               IF SQLCODE = 0
                   IF TRX-TIPO = 'D' AND CLI-SALDO >= TRX-VALOR
                       EXEC SQL
                           UPDATE CLIENTES SET CLI_SALDO = CLI_SALDO - :TRX-VALOR
                           WHERE CLI_ID = :TRX-CLI-ID
                       END-EXEC
                       ADD 1 TO WS-TOT-OK
                   ELSE
                       IF TRX-TIPO = 'C'
                           EXEC SQL
                               UPDATE CLIENTES SET CLI_SALDO = CLI_SALDO + :TRX-VALOR
                               WHERE CLI_ID = :TRX-CLI-ID
                           END-EXEC
                           ADD 1 TO WS-TOT-OK
                       ELSE
                           ADD 1 TO WS-TOT-ERRO
                       END-IF
                   END-IF
               ELSE
                   EXEC SQL
                       INSERT INTO ERROS_PROCESSAMENTO (CLI_ID, DESCRICAO_ERRO)
                       VALUES (:TRX-CLI-ID, 'CLIENTE INEXISTENTE')
                   END-EXEC
                   ADD 1 TO WS-TOT-ERRO
               END-IF
               READ ARQ-TRX AT END MOVE 'Y' TO WS-EOF
           END-PERFORM.
           CLOSE ARQ-TRX.

           OPEN OUTPUT ARQ-REL.
           MOVE "--- RELATORIO FINAL ---" TO REG-REL.
           WRITE REG-REL.
           MOVE "TOTAL LIDOS: " TO REG-REL(1:13).
           MOVE WS-TOT-LIDOS TO REG-REL(14:05).
           WRITE REG-REL.
           MOVE "TOTAL OK:    " TO REG-REL(1:13).
           MOVE WS-TOT-OK TO REG-REL(14:05).
           WRITE REG-REL.
           MOVE "TOTAL ERRO:  " TO REG-REL(1:13).
           MOVE WS-TOT-ERRO TO REG-REL(14:05).
           WRITE REG-REL.
           CLOSE ARQ-REL.

           EXEC SQL DISCONNECT CURRENT END-EXEC.
           GOBACK.