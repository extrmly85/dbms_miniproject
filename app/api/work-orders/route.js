import { NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { guard } from "@/lib/auth";
import { embed } from "@/lib/embed";
import { upsertWorkOrder } from "@/lib/neo4j";

export async function GET() {
  const g = await guard();
  if (g.error) return g.error;
  const [rows] = await pool.query(
    `SELECT w.Work_order_id, a.Asset_name, w.Issue_description, w.Priority, w.Status,
            w.Created_date, t.Technician_name, fn_work_order_cost(w.Work_order_id) AS Total_cost
     FROM WORK_ORDER w
     JOIN ASSET a ON w.Asset_id = a.Asset_id
     LEFT JOIN TECHNICIAN t ON w.Technician_id = t.Technician_id
     ORDER BY w.Work_order_id DESC`
  );
  return NextResponse.json(rows);
}

export async function POST(req) {
  const g = await guard(["Admin", "Technician"]);
  if (g.error) return g.error;
  const { asset_id, issue, priority, labor_cost } = await req.json();
  try {
    const [r] = await pool.query(
      `INSERT INTO WORK_ORDER (Asset_id, Issue_description, Priority, Status, Created_date, Labor_cost)
       VALUES (?, ?, ?, 'Open', CURDATE(), ?)`,
      [asset_id, issue, priority, labor_cost || 0]
    );
    let graph = true;
    try {
      const [[a]] = await pool.query("SELECT Asset_name FROM ASSET WHERE Asset_id = ?", [asset_id]);
      await upsertWorkOrder(
        { id: r.insertId, assetId: asset_id, assetName: a.Asset_name, issue, priority, status: "Open", laborCost: labor_cost },
        await embed(issue)
      );
    } catch (e) {
      console.error("Neo4j sync failed:", e.message);
      graph = false;
    }
    return NextResponse.json({ id: r.insertId, graphSynced: graph });
  } catch (e) {
    return NextResponse.json({ error: e.message }, { status: 400 });
  }
}
