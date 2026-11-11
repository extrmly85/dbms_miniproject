import { NextResponse } from "next/server";
import { getSession } from "@/lib/auth";

export async function GET() {
  const s = await getSession();
  return s ? NextResponse.json({ username: s.username, role: s.role }) : NextResponse.json({ error: "Not logged in" }, { status: 401 });
}
