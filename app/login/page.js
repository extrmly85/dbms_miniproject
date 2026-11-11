"use client";
import { useState } from "react";

export default function Login() {
  const [f, setF] = useState({ username: "", password: "" });
  const [err, setErr] = useState("");

  const submit = async (e) => {
    e.preventDefault();
    const r = await fetch("/api/auth/login", {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(f),
    });
    if (r.ok) location.href = "/";
    else setErr((await r.json()).error);
  };

  return (
    <div className="card" style={{ maxWidth: 360, margin: "60px auto" }}>
      <h1>Sign in</h1>
      <div className="row" style={{ flexDirection: "column" }}>
        <input placeholder="Username" value={f.username} onChange={(e) => setF({ ...f, username: e.target.value })} />
        <input type="password" placeholder="Password" value={f.password} onChange={(e) => setF({ ...f, password: e.target.value })}
          onKeyDown={(e) => e.key === "Enter" && submit(e)} />
        <button onClick={submit}>Login</button>
        {err && <span style={{ color: "#f85149" }}>{err}</span>}
      </div>
    </div>
  );
}
