-- PostgreSQL initialization script for financial application
-- Enable useful extensions for performance and monitoring

-- For query statistics and performance monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- For advanced indexing and search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- For UUID support (common in Rails apps)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- For better random data generation if needed
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- For table partitioning if needed in the future
-- CREATE EXTENSION IF NOT EXISTS pg_partman;  -- Uncomment if using partitioning

-- Add any additional initial SQL commands here

-- Ensure Rails databases exist (dev + test).
-- (The Postgres image creates POSTGRES_DB only; we create the remaining ones explicitly.)
SELECT 'CREATE DATABASE credito_poc_development'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'credito_poc_development')\gexec

SELECT 'CREATE DATABASE credito_poc_test'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'credito_poc_test')\gexec