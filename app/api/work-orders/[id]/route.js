import { NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { guard } from "@/lib/auth";
import { setStatus, removeWorkOrder } from "@/lib/neo4j";

export async function PATCH(req, { params }) {
  const g = await guard(["Admin", "Technician"]);
  if (g.error) return g.error;
  const { id } = await params;
  const { status } = await req.json();
  await pool.query("UPDATE WORK_ORDER SET Status = ? WHERE Work_order_id = ?", [status, id]);
  await setStatus(id, status).catch((e) => console.error("Neo4j sync failed:", e.message));
  return NextResponse.json({ ok: true });
}

export async function DELETE(_req, { params }) {
  const g = await guard(["Admin"]);
  if (g.error) return g.error;
  const { id } = await params;
  await pool.query("DELETE FROM WORK_ORDER WHERE Work_order_id = ?", [id]);
  await removeWorkOrder(id).catch((e) => console.error("Neo4j sync failed:", e.message));
  return NextResponse.json({ ok: true });
}
