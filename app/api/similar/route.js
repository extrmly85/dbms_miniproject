import { NextResponse } from "next/server";
import { guard } from "@/lib/auth";
import { embed } from "@/lib/embed";
import { similarWorkOrders } from "@/lib/neo4j";

export async function GET(req) {
  const g = await guard();
  if (g.error) return g.error;
  const q = new URL(req.url).searchParams.get("q") || "";
  if (!q) return NextResponse.json([]);
  try {
    return NextResponse.json(await similarWorkOrders(await embed(q)));
  } catch (e) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}
