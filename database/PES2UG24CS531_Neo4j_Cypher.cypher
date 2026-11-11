// Task 1: Constraints and vector index
CREATE CONSTRAINT asset_id IF NOT EXISTS FOR (a:Asset) REQUIRE a.id IS UNIQUE;
CREATE CONSTRAINT wo_id IF NOT EXISTS FOR (w:WorkOrder) REQUIRE w.id IS UNIQUE;
CREATE CONSTRAINT part_id IF NOT EXISTS FOR (p:Part) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT tech_id IF NOT EXISTS FOR (t:Technician) REQUIRE t.id IS UNIQUE;

CREATE VECTOR INDEX workorder_embedding IF NOT EXISTS
FOR (w:WorkOrder) ON (w.embedding)
OPTIONS { indexConfig: { `vector.dimensions`: 384, `vector.similarity_function`: 'cosine' } };

// Task 2: Nodes
UNWIND [
  {id: 1, name: 'Dell PowerEdge Server', category: 'IT Equipment'},
  {id: 2, name: 'Hydraulic Press HP-200', category: 'Machinery'},
  {id: 3, name: 'Toyota Innova', category: 'Vehicles'},
  {id: 4, name: 'Conference Table Set', category: 'Furniture'},
  {id: 5, name: 'Central AC Unit', category: 'Machinery'},
  {id: 6, name: 'Laptop Fleet Lot-A', category: 'IT Equipment'}
] AS r
MERGE (a:Asset {id: r.id}) SET a.name = r.name, a.category = r.category;

UNWIND [
  {id: 1, name: 'Ravi Kumar'}, {id: 2, name: 'Anita Shetty'},
  {id: 3, name: 'Mohan Rao'}, {id: 4, name: 'Suresh Nayak'}
] AS r
MERGE (t:Technician {id: r.id}) SET t.name = r.name;

UNWIND [
  {id: 1, name: 'Thermal Sensor', cost: 450}, {id: 2, name: 'Compressor Belt', cost: 1200},
  {id: 3, name: 'Hydraulic Seal', cost: 800}, {id: 4, name: 'Cooling Fan', cost: 650},
  {id: 5, name: 'Power Supply Unit', cost: 2500}
] AS r
MERGE (p:Part {id: r.id}) SET p.name = r.name, p.unitCost = r.cost;

UNWIND [
  {id: 1, asset: 5, issue: 'AC compressor overheating and tripping breaker', priority: 'High', status: 'Open', labor: 3500, tech: 2},
  {id: 2, asset: 2, issue: 'Hydraulic leak near press cylinder', priority: 'High', status: 'In Progress', labor: 6000, tech: 3},
  {id: 3, asset: 1, issue: 'Server fan noise and thermal warnings', priority: 'Medium', status: 'Closed', labor: 1500, tech: 1},
  {id: 4, asset: 3, issue: 'Brake pad replacement and routine service', priority: 'Low', status: 'Closed', labor: 2500, tech: null},
  {id: 5, asset: 6, issue: 'Laptop battery swelling on three units', priority: 'Medium', status: 'Open', labor: 2000, tech: 1}
] AS r
MERGE (w:WorkOrder {id: r.id})
SET w.issue = r.issue, w.priority = r.priority, w.status = r.status, w.laborCost = r.labor
WITH w, r
MATCH (a:Asset {id: r.asset})
MERGE (a)-[:HAS_WORK_ORDER]->(w)
WITH w, r
OPTIONAL MATCH (t:Technician {id: r.tech})
FOREACH (_ IN CASE WHEN t IS NULL THEN [] ELSE [1] END | MERGE (w)-[:ASSIGNED_TO]->(t));

// Task 3: Relationships with properties
UNWIND [
  {wo: 1, part: 1, qty: 2}, {wo: 1, part: 4, qty: 1}, {wo: 2, part: 3, qty: 4},
  {wo: 3, part: 4, qty: 2}, {wo: 3, part: 1, qty: 1}, {wo: 5, part: 5, qty: 3}
] AS r
MATCH (w:WorkOrder {id: r.wo}), (p:Part {id: r.part})
MERGE (w)-[u:USED]->(p) SET u.qty = r.qty;

// Task 4: Aggregation queries
MATCH (a:Asset)-[:HAS_WORK_ORDER]->(w:WorkOrder)
RETURN a.name AS asset, count(w) AS work_orders, sum(w.laborCost) AS labor_cost
ORDER BY labor_cost DESC;

MATCH (:WorkOrder)-[u:USED]->(p:Part)
RETURN p.name AS part, sum(u.qty) AS total_used
ORDER BY total_used DESC;

MATCH (t:Technician)<-[:ASSIGNED_TO]-(w:WorkOrder)
RETURN t.name AS technician, count(w) AS assigned, collect(w.status) AS statuses;

// Task 5: Graph traversal (assets that needed the same parts)
MATCH (a1:Asset)-[:HAS_WORK_ORDER]->(:WorkOrder)-[:USED]->(p:Part)<-[:USED]-(:WorkOrder)<-[:HAS_WORK_ORDER]-(a2:Asset)
WHERE a1.id < a2.id
RETURN a1.name AS asset_1, a2.name AS asset_2, collect(DISTINCT p.name) AS shared_parts;

// Task 6: Vector similarity search ($queryVec is a 384-dimension embedding of the search text)
CALL db.index.vector.queryNodes('workorder_embedding', 3, $queryVec) YIELD node AS w, score
MATCH (a:Asset)-[:HAS_WORK_ORDER]->(w)
OPTIONAL MATCH (w)-[u:USED]->(p:Part)
RETURN w.id AS work_order, a.name AS asset, w.issue AS issue, score, collect(p.name) AS parts
ORDER BY score DESC;

// Task 7: Update and delete
MATCH (w:WorkOrder {id: 1}) SET w.status = 'Closed';
MATCH (w:WorkOrder {id: 4}) DETACH DELETE w;
