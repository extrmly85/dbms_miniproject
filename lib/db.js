import mysql from "mysql2/promise";

export const pool = (globalThis._pool ??= mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "asset_db",
  dateStrings: true,
  connectionLimit: 5,
}));
