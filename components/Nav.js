"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useMe } from "@/lib/client";

export default function Nav() {
  const me = useMe();
  const path = usePathname();
  const logout = async () => {
    await fetch("/api/auth/logout", { method: "POST" });
    location.href = "/login";
  };
  return (
    <nav>
      <b>Asset Manager</b>
      {path !== "/login" && (
        <>
          <Link href="/">Assets</Link>
          <Link href="/work-orders">Work Orders</Link>
        </>
      )}
      <span style={{ marginLeft: "auto" }}>
        {me && <>{me.username} <span className="tag">{me.role}</span> <button className="alt" onClick={logout}>Logout</button></>}
      </span>
    </nav>
  );
}
