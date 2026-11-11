import { NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { guard } from "@/lib/auth";
import { linkPart } from "@/lib/neo4j";

export async function POST(req, { params }) {
  const g = await guard(["Admin", "Technician"]);
  if (g.error) return g.error;
  const { id } = await params;
  const { part_id, qty } = await req.json();
  try {
    await pool.query("CALL sp_use_part(?, ?, ?)", [id, part_id, qty]);
  } catch (e) {
    return NextResponse.json({ error: e.sqlMessage || e.message }, { status: 400 });
  }
  const [[p]] = await pool.query("SELECT Part_id, Part_name FROM PART WHERE Part_id = ?", [part_id]);
  await linkPart(id, { id: p.Part_id, name: p.Part_name }, qty).catch((e) => console.error("Neo4j sync failed:", e.message));
  return NextResponse.json({ ok: true });
}
