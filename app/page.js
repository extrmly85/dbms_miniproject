"use client";
import { useEffect, useState } from "react";
import { api, useMe } from "@/lib/client";

const inr = (v) => "₹" + Number(v).toLocaleString("en-IN");

export default function Assets() {
  const me = useMe();
  const [assets, setAssets] = useState([]);
  const [summary, setSummary] = useState([]);
  const [period, setPeriod] = useState(new Date().toISOString().slice(0, 10));

  const load = async () => {
    setAssets(await (await api("/api/assets")).json());
    setSummary(await (await api("/api/summary")).json());
  };
  useEffect(() => { load(); }, []);

  const post = async (asset_id) => {
    const r = await api("/api/depreciation", { method: "POST", body: JSON.stringify({ asset_id, period }) });
    if (!r.ok) alert((await r.json()).error);
    load();
  };

  const isAdmin = me?.role === "Admin";
  return (
    <>
      <h1>Book value by category</h1>
      <table>
        <thead><tr><th>Category</th><th>Assets</th><th>Purchase cost</th><th>Book value</th></tr></thead>
        <tbody>
          {summary.map((s) => (
            <tr key={s.Category_name}><td>{s.Category_name}</td><td>{s.Assets}</td><td>{inr(s.Total_cost)}</td><td>{inr(s.Total_book_value)}</td></tr>
          ))}
        </tbody>
      </table>
      <h1>Assets</h1>
      {isAdmin && (
        <div className="row">
          <label>Depreciation period date <input type="date" value={period} onChange={(e) => setPeriod(e.target.value)} /></label>
        </div>
      )}
      <table>
        <thead><tr><th>ID</th><th>Asset</th><th>Category</th><th>Location</th><th>Purchase</th><th>Book value</th><th>Status</th><th></th></tr></thead>
        <tbody>
          {assets.map((a) => (
            <tr key={a.Asset_id}>
              <td>{a.Asset_id}</td><td>{a.Asset_name}</td><td>{a.Category_name}</td>
              <td>{a.Building}, F{a.Floor}</td><td>{inr(a.Purchase_cost)}</td><td>{inr(a.Current_book_value)}</td>
              <td><span className="tag">{a.Status}</span></td>
              <td>{isAdmin && <button onClick={() => post(a.Asset_id)}>Post depreciation</button>}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}
