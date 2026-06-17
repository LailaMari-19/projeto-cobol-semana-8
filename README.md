# 🏦 Sistema de Contas Bancárias - Processamento Batch (COBOL/DB2)

<p align="center">
  <img src="https://img.shields.io/badge/Language-COBOL-blue" alt="COBOL">
  <img src="https://img.shields.io/badge/Database-DB2-brightgreen" alt="DB2">
</p>

## 📖 Sobre o Projeto
Este projeto implementa uma rotina de processamento **Batch** para o setor bancário. O sistema processa arquivos sequenciais de clientes e transações, realiza validações de regras de negócio e garante a integridade dos dados através de integração com **DB2** e **controle transacional (COMMIT/ROLLBACK)**.

## ⚙️ Arquitetura e Funcionalidades
- **Ordenação (SORT)**: Garante que os dados de entrada sejam processados na ordem correta.
- **Validações**: Lógica robusta para Débito/Crédito com verificação de saldo disponível.
- **Integridade**: Tratamento de erros persistido em tabela de logs (`ERROS_PROCESSAMENTO`).
- **Performance**: Processamento otimizado com commits configurados a cada 100 registros.

## 📂 Estrutura do Repositório
```text
├── COPY/               # Copybooks (Layouts de registros)
├── Inputs/             # Dados de entrada (.TXT)
├── PROCBANC.CBL        # Lógica central (COBOL + SQL)
├── PROCBANC.JCL        # JCL de execução e ordenação
└── README.md           # Documentação do projeto
