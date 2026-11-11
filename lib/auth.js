import { SignJWT, jwtVerify } from "jose";
import { cookies } from "next/headers";
import { NextResponse } from "next/server";

const key = () => new TextEncoder().encode(process.env.SESSION_SECRET);

export async function createSession(user) {
  const token = await new SignJWT({ uid: user.User_id, username: user.Username, role: user.Role })
    .setProtectedHeader({ alg: "HS256" })
    .setExpirationTime("8h")
    .sign(key());
  (await cookies()).set("session", token, { httpOnly: true, sameSite: "lax", path: "/", maxAge: 8 * 3600 });
}

export async function getSession() {
  const token = (await cookies()).get("session")?.value;
  if (!token) return null;
  try {
    return (await jwtVerify(token, key())).payload;
  } catch {
    return null;
  }
}

export async function guard(roles) {
  const session = await getSession();
  if (!session) return { error: NextResponse.json({ error: "Not logged in" }, { status: 401 }) };
  if (roles && !roles.includes(session.role))
    return { error: NextResponse.json({ error: "Forbidden for your role" }, { status: 403 }) };
  return { session };
}
