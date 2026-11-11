# Enterprise Physical Asset Depreciation & Work-Order Manager

Next.js app on MySQL (relational data) and Neo4j (graph and vector search).

## Prerequisites
- Node.js 20.6 or newer
- MySQL with `asset_db` created from the SQL files, run in this order: DDL, DML, Upgrade
- A Neo4j 5.x database (Neo4j Aura Free works) for the graph and vector index

## Setup
1. `npm install`
2. Copy `.env.local.example` to `.env.local` and fill in every value
3. `npm run seed` creates the `admin` and `technician` logins and loads the graph with embeddings (the first run downloads the embedding model, about 25 MB)
4. `npm run dev` and open http://localhost:3000

## Roles
- Admin: everything, including posting depreciation and deleting work orders
- Technician: view data, create and close work orders, record parts used

## Structure
- `app/api` route handlers (auth, assets, work orders, parts, summary, similar search)
- `lib` database, auth, embedding and Neo4j helpers
- `scripts/seed.mjs` users and graph loader

## Database features
MySQL: triggers, stored procedure and function, transaction with rollback, views, indexes, full-text search.
Neo4j: constraints, vector index (cosine, 384 dimensions), aggregation, graph traversal, similarity search.
