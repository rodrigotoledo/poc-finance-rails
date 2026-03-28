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