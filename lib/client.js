"use client";
import { useEffect, useState } from "react";

export async function api(url, opts = {}) {
  const r = await fetch(url, { headers: { "Content-Type": "application/json" }, ...opts });
  if (r.status === 401 && location.pathname !== "/login") location.href = "/login";
  return r;
}

export function useMe() {
  const [me, setMe] = useState(null);
  useEffect(() => {
    api("/api/auth/me").then((r) => r.ok && r.json()).then((d) => d && setMe(d));
  }, []);
  return me;
}
