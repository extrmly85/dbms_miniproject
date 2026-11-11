import { NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { guard } from "@/lib/auth";

export async function POST(req) {
  const g = await guard(["Admin"]);
  if (g.error) return g.error;
  const { asset_id, period } = await req.json();
  try {
    await pool.query("CALL sp_post_depreciation(?, ?)", [asset_id, period]);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: e.message }, { status: 400 });
  }
}
