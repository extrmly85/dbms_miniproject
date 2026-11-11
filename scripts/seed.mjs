import { pool } from "../lib/db.js";
import { hashPassword } from "../lib/password.js";
import { embed } from "../lib/embed.js";
import { setupGraph, upsertWorkOrder, linkPart } from "../lib/neo4j.js";

const { SEED_ADMIN_PASSWORD, SEED_TECH_PASSWORD } = process.env;
if (!SEED_ADMIN_PASSWORD || !SEED_TECH_PASSWORD) throw new Error("Set SEED_ADMIN_PASSWORD and SEED_TECH_PASSWORD in .env.local");

for (const [username, pw, role, tech] of [
  ["admin", SEED_ADMIN_PASSWORD, "Admin", null],
  ["technician", SEED_TECH_PASSWORD, "Technician", 1],
]) {
  await pool.query(
    `INSERT INTO APP_USER (Username, Password_hash, Role, Technician_id) VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE Password_hash = VALUES(Password_hash), Role = VALUES(Role)`,
    [username, hashPassword(pw), role, tech]
  );
}
console.log("Users ready: admin, technician");

await setupGraph();
const [orders] = await pool.query(
  `SELECT w.Work_order_id, w.Asset_id, a.Asset_name, w.Issue_description, w.Priority, w.Status,
          w.Labor_cost, w.Technician_id, t.Technician_name
   FROM WORK_ORDER w JOIN ASSET a ON w.Asset_id = a.Asset_id
   LEFT JOIN TECHNICIAN t ON w.Technician_id = t.Technician_id`
);
for (const o of orders) {
  await upsertWorkOrder(
    { id: o.Work_order_id, assetId: o.Asset_id, assetName: o.Asset_name, issue: o.Issue_description,
      priority: o.Priority, status: o.Status, laborCost: o.Labor_cost,
      technicianId: o.Technician_id, technicianName: o.Technician_name },
    await embed(o.Issue_description)
  );
}
const [uses] = await pool.query(
  `SELECT wp.Work_order_id, wp.Quantity_used, p.Part_id, p.Part_name
   FROM WORK_ORDER_PART wp JOIN PART p ON wp.Part_id = p.Part_id`
);
for (const u of uses) await linkPart(u.Work_order_id, { id: u.Part_id, name: u.Part_name }, u.Quantity_used, true);
console.log(`Graph ready: ${orders.length} work orders, ${uses.length} part links`);
process.exit(0);
