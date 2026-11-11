import { NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { guard } from "@/lib/auth";

export async function GET() {
  const g = await guard();
  if (g.error) return g.error;
  const [rows] = await pool.query("SELECT Part_id, Part_name, Unit_cost, Stock_qty FROM PART ORDER BY Part_name");
  return NextResponse.json(rows);
}
