import { NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { guard } from "@/lib/auth";

export async function GET() {
  const g = await guard();
  if (g.error) return g.error;
  const [rows] = await pool.query(
    `SELECT a.Asset_id, a.Asset_name, c.Category_name, l.Building, l.Floor, a.Purchase_cost,
            a.Current_book_value, a.Status
     FROM ASSET a
     JOIN ASSET_CATEGORY c ON a.Category_id = c.Category_id
     JOIN LOCATION l ON a.Location_id = l.Location_id
     ORDER BY a.Asset_id`
  );
  return NextResponse.json(rows);
}
