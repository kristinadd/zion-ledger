# Zion Ledger Service

A double-entry bookkeeping ledger service built with Rails 8.1 and PostgreSQL, designed for financial accuracy, immutability, and audit compliance.

## System Requirements

- **Ruby**: 3.3+ (check with `ruby -v`)
- **PostgreSQL**: 18 (check with `psql --version`)
- **Rails**: 8.1.1+

## Architecture Overview

This is an API-only Rails application designed as a microservice for managing financial ledgers with:

- **Double-entry bookkeeping** - Every transaction affects at least two accounts
- **Immutable ledger entries** - Financial records are never deleted or modified
- **ACID compliance** - PostgreSQL ensures transaction integrity
- **Audit trail** - Complete history of all financial operations
- **Precision arithmetic** - Uses PostgreSQL `decimal` type for money values
