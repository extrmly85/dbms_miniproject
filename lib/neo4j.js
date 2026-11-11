import neo4j from "neo4j-driver";

const driver = (globalThis._neo4j ??= neo4j.driver(
  process.env.NEO4J_URI || "bolt://localhost:7687",
  neo4j.auth.basic(process.env.NEO4J_USER || "neo4j", process.env.NEO4J_PASSWORD || "")
));

const num = (v) => (neo4j.isInt(v) ? v.toNumber() : v);

async function run(query, params = {}) {
  const session = driver.session();
  try {
    return await session.run(query, params);
  } finally {
    await session.close();
  }
}

export async function setupGraph() {
  await run("CREATE CONSTRAINT asset_id IF NOT EXISTS FOR (a:Asset) REQUIRE a.id IS UNIQUE");
  await run("CREATE CONSTRAINT wo_id IF NOT EXISTS FOR (w:WorkOrder) REQUIRE w.id IS UNIQUE");
  await run("CREATE CONSTRAINT part_id IF NOT EXISTS FOR (p:Part) REQUIRE p.id IS UNIQUE");
  await run("CREATE CONSTRAINT tech_id IF NOT EXISTS FOR (t:Technician) REQUIRE t.id IS UNIQUE");
  await run(
    `CREATE VECTOR INDEX workorder_embedding IF NOT EXISTS
     FOR (w:WorkOrder) ON (w.embedding)
     OPTIONS { indexConfig: { \`vector.dimensions\`: 384, \`vector.similarity_function\`: 'cosine' } }`
  );
}

export async function upsertWorkOrder(w, embedding) {
  await run(
    `MERGE (a:Asset {id: $assetId}) SET a.name = $assetName
     MERGE (w:WorkOrder {id: $id})
     SET w.issue = $issue, w.priority = $priority, w.status = $status,
         w.laborCost = $laborCost, w.embedding = $embedding
     MERGE (a)-[:HAS_WORK_ORDER]->(w)`,
    {
      id: neo4j.int(w.id), assetId: neo4j.int(w.assetId), assetName: w.assetName,
      issue: w.issue, priority: w.priority, status: w.status,
      laborCost: Number(w.laborCost || 0), embedding,
    }
  );
  if (w.technicianId)
    await run(
      `MATCH (w:WorkOrder {id: $id})
       MERGE (t:Technician {id: $tid}) SET t.name = $tname
       MERGE (w)-[:ASSIGNED_TO]->(t)`,
      { id: neo4j.int(w.id), tid: neo4j.int(w.technicianId), tname: w.technicianName }
    );
}

export async function setStatus(id, status) {
  await run("MATCH (w:WorkOrder {id: $id}) SET w.status = $status", { id: neo4j.int(id), status });
}

export async function removeWorkOrder(id) {
  await run("MATCH (w:WorkOrder {id: $id}) DETACH DELETE w", { id: neo4j.int(id) });
}

export async function linkPart(woId, part, qty, replace = false) {
  await run(
    `MATCH (w:WorkOrder {id: $wo})
     MERGE (p:Part {id: $pid}) SET p.name = $pname
     MERGE (w)-[u:USED]->(p)
     SET u.qty = CASE WHEN $replace THEN $qty ELSE coalesce(u.qty, 0) + $qty END`,
    { wo: neo4j.int(woId), pid: neo4j.int(part.id), pname: part.name, qty: neo4j.int(qty), replace }
  );
}

export async function similarWorkOrders(embedding, k = 5) {
  const r = await run(
    `CALL db.index.vector.queryNodes('workorder_embedding', $k, $embedding) YIELD node AS w, score
     MATCH (a:Asset)-[:HAS_WORK_ORDER]->(w)
     OPTIONAL MATCH (w)-[u:USED]->(p:Part)
     RETURN w.id AS id, w.issue AS issue, w.status AS status, a.name AS asset, score,
            collect(p.name + ' x' + toString(u.qty)) AS parts
     ORDER BY score DESC`,
    { k: neo4j.int(k), embedding }
  );
  return r.records.map((x) => ({
    id: num(x.get("id")), issue: x.get("issue"), status: x.get("status"),
    asset: x.get("asset"), score: x.get("score"), parts: x.get("parts"),
  }));
}
