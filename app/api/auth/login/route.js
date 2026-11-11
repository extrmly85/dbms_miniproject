import { NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { createSession } from "@/lib/auth";
import { verifyPassword } from "@/lib/password";

export async function POST(req) {
  const { username, password } = await req.json();
  const [rows] = await pool.query("SELECT * FROM APP_USER WHERE Username = ?", [username || ""]);
  const user = rows[0];
  if (!user || !verifyPassword(password || "", user.Password_hash))
    return NextResponse.json({ error: "Invalid username or password" }, { status: 401 });
  await createSession(user);
  return NextResponse.json({ username: user.Username, role: user.Role });
}
