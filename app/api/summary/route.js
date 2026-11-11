import { NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { guard } from "@/lib/auth";

export async function GET() {
  const g = await guard();
  if (g.error) return g.error;
  const [rows] = await pool.query("SELECT * FROM vw_category_book_value");
  return NextResponse.json(rows);
}
