"use client";
import { useEffect, useState } from "react";
import { api, useMe } from "@/lib/client";

const inr = (v) => "₹" + Number(v).toLocaleString("en-IN");
const blank = { asset_id: "", issue: "", priority: "Medium", labor_cost: "" };

export default function WorkOrders() {
  const me = useMe();
  const [orders, setOrders] = useState([]);
  const [assets, setAssets] = useState([]);
  const [parts, setParts] = useState([]);
  const [form, setForm] = useState(blank);
  const [use, setUse] = useState({ wo: "", part: "", qty: 1 });
  const [q, setQ] = useState("");
  const [hits, setHits] = useState([]);
  const [msg, setMsg] = useState("");

  const load = async () => {
    setOrders(await (await api("/api/work-orders")).json());
    setAssets(await (await api("/api/assets")).json());
    setParts(await (await api("/api/parts")).json());
  };
  useEffect(() => { load(); }, []);

  const create = async () => {
    const r = await api("/api/work-orders", { method: "POST", body: JSON.stringify(form) });
    const d = await r.json();
    if (!r.ok) return setMsg(d.error);
    setMsg(d.graphSynced ? "Work order created" : "Work order created (graph sync failed)");
    setForm(blank);
    load();
  };
  const setStatus = async (id, status) => { await api(`/api/work-orders/${id}`, { method: "PATCH", body: JSON.stringify({ status }) }); load(); };
  const remove = async (id) => { if (confirm(`Delete work order ${id}?`)) { await api(`/api/work-orders/${id}`, { method: "DELETE" }); load(); } };
  const addPart = async () => {
    const r = await api(`/api/work-orders/${use.wo}/parts`, { method: "POST", body: JSON.stringify({ part_id: use.part, qty: Number(use.qty) }) });
    setMsg(r.ok ? "Part recorded" : (await r.json()).error);
    load();
  };
  const search = async () => {
    const r = await api(`/api/similar?q=${encodeURIComponent(q)}`);
    const d = await r.json();
    if (r.ok) setHits(d); else setMsg(d.error);
  };

  const open = orders.filter((o) => o.Status !== "Closed");
  return (
    <>
      <h1>Work Orders</h1>
      {msg && <div className="card">{msg}</div>}
      <div className="card">
        <div className="row">
          <select value={form.asset_id} onChange={(e) => setForm({ ...form, asset_id: e.target.value })}>
            <option value="">Select asset</option>
            {assets.map((a) => <option key={a.Asset_id} value={a.Asset_id}>{a.Asset_name}</option>)}
          </select>
          <input style={{ flex: 1 }} placeholder="Issue description" value={form.issue} onChange={(e) => setForm({ ...form, issue: e.target.value })} />
          <select value={form.priority} onChange={(e) => setForm({ ...form, priority: e.target.value })}>
            <option>High</option><option>Medium</option><option>Low</option>
          </select>
          <input type="number" placeholder="Labor cost" value={form.labor_cost} onChange={(e) => setForm({ ...form, labor_cost: e.target.value })} />
          <button onClick={create}>Create</button>
        </div>
        <div className="row">
          <select value={use.wo} onChange={(e) => setUse({ ...use, wo: e.target.value })}>
            <option value="">Work order</option>
            {open.map((o) => <option key={o.Work_order_id} value={o.Work_order_id}>#{o.Work_order_id} {o.Asset_name}</option>)}
          </select>
          <select value={use.part} onChange={(e) => setUse({ ...use, part: e.target.value })}>
            <option value="">Part</option>
            {parts.map((p) => <option key={p.Part_id} value={p.Part_id}>{p.Part_name} (stock {p.Stock_qty})</option>)}
          </select>
          <input type="number" min="1" style={{ width: 70 }} value={use.qty} onChange={(e) => setUse({ ...use, qty: e.target.value })} />
          <button className="alt" onClick={addPart}>Use part</button>
        </div>
      </div>
      <table>
        <thead><tr><th>ID</th><th>Asset</th><th>Issue</th><th>Priority</th><th>Status</th><th>Technician</th><th>Total cost</th><th></th></tr></thead>
        <tbody>
          {orders.map((o) => (
            <tr key={o.Work_order_id}>
              <td>{o.Work_order_id}</td><td>{o.Asset_name}</td><td>{o.Issue_description}</td>
              <td>{o.Priority}</td><td><span className="tag">{o.Status}</span></td>
              <td>{o.Technician_name || "-"}</td><td>{inr(o.Total_cost)}</td>
              <td>
                {o.Status !== "Closed" && <button className="alt" onClick={() => setStatus(o.Work_order_id, "Closed")}>Close</button>}{" "}
                {me?.role === "Admin" && <button className="alt" onClick={() => remove(o.Work_order_id)}>Delete</button>}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <div className="card">
        <b>Find similar past issues (Neo4j vector search)</b>
        <div className="row">
          <input style={{ flex: 1 }} placeholder="e.g. overheating cooling problem" value={q} onChange={(e) => setQ(e.target.value)} onKeyDown={(e) => e.key === "Enter" && search()} />
          <button onClick={search}>Search</button>
        </div>
        {hits.map((h) => (
          <div key={h.id} style={{ padding: "6px 0", borderTop: "1px solid #30363d" }}>
            WO #{h.id} · {h.asset} · {h.issue} <span className="tag">{h.status}</span> <span className="tag">similarity {h.score.toFixed(2)}</span>
            {h.parts.length > 0 && <div style={{ color: "#8b949e", fontSize: 13 }}>Parts used: {h.parts.join(", ")}</div>}
          </div>
        ))}
      </div>
    </>
  );
}
