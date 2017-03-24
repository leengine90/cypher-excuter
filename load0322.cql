// Create US Product Node
CREATE (:Product {id: 1, name: "KMU"});
CREATE (:Product {id: 2, name: "DKY"});
CREATE (:Product {id: 3, name: "EDP"});
CREATE (:Product {id: 4, name: "EBS"});
CREATE (:Product {id: 5, name: "SLV"});

CREATE CONSTRAINT ON (c:Curriculum) ASSERT c.id IS UNIQUE;
CREATE CONSTRAINT ON (c:Chapter) ASSERT c.id IS UNIQUE;

// Create & link Chapter and Curriculum Nodes
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/yr9x3udlnifsth0/chapters.csv?dl=1" AS row
MATCH (prod:Product {id: 1})
CREATE (chap:Chapter {id: TOINT(row.id), name: row.name})
MERGE (curr:Curriculum {id: TOINT(row.curriculum_id), name: row.curriculum})
MERGE (prod)-[r:has_curriculum]->(curr)
CREATE (curr)-[rc:has_chapter]->(chap)
SET r.seq = TOINT(row.curr_seq)
SET rc.seq = TOINT(row.seq)
;

// Create & link Lesson nodes
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/awbrq8jyh0x31i2/lessons.csv?dl=1" AS row
MATCH (chap:Chapter {id: TOINT(row.chapter_id)})
CREATE (lesson:Lesson {id: TOINT(row.id), name: row.name, t_no: TOINT(row.t_no), old_id: TOINT(row.old)})
CREATE (chap)-[r:has_lesson]->(lesson)
SET r.seq = TOINT(row.seq)
;

// Create & link Cartoon nodes
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/awbrq8jyh0x31i2/lessons.csv?dl=1" AS row
WITH row.cartoon as cartoon, row
WHERE cartoon <> '' AND cartoon <> 'NULL'
MATCH (lesson:Lesson {id: TOINT(row.id)})
CREATE (c:Cartoon {id: TOINT(row.id), name: cartoon, title: row.cartoon_title})
CREATE (lesson)-[:uses_cartoon]->(c)
;

// Create Video Nodes
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/mfi5l9e1e4x9h61/videos.csv?dl=1" AS row
CREATE (:Video {name: row.video});

// Create Unit Nodes
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/2gsyygd86dubplu/modules.csv?dl=1" AS row
CREATE (m:Unit {id: TOINT(row.id), name: row.name})
WITH m, CASE WHEN row.af <> "1" THEN [1] ELSE [] END AS deactive, CASE WHEN row.af = "1" THEN [1] ELSE [] END AS active
FOREACH (x IN deactive | SET m:DEACTIVE)
FOREACH (y IN active | SET m:ACTIVE)
;


CREATE CONSTRAINT ON (u:Unit) ASSERT u.id IS UNIQUE;
CREATE INDEX ON :Video(name);
CREATE INDEX ON :Lesson(old_id);

// Video Links
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "https://www.dropbox.com/s/2gsyygd86dubplu/modules.csv?dl=1" AS row
with row.video as video,row
WHERE video <> '' AND video <> 'NULL'
MATCH (unit:Unit {id: TOINT(row.id)})
MATCH (vid:Video {name: row.video})
MERGE (unit)-[:has_video]->(vid)
;

// Create Data Nodes
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/mi5wkdpg7fv1mjy/data.csv?dl=1" AS row
CREATE (val:Data {id: TOINT(row.id)})
;

// Create Level 1 Problems
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/s7rxenc7qswfrdd/problems_lev1.csv?dl=1" AS row
CREATE (p:Problem {id: TOINT(row.id)})
WITH p, CASE WHEN row.af <> "1" THEN [1] ELSE [] END AS deactive, CASE WHEN row.af = "1" THEN [1] ELSE [] END AS active
FOREACH (x IN deactive | SET p:DEACTIVE)
FOREACH (y IN active | SET p:ACTIVE)
;

// Create All Sub Problems
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/io5td1n0ev5yvea/problems_lev2-all.csv?dl=1" AS row
CREATE (p:Problem {id: TOINT(row.id)})
WITH p, CASE WHEN row.af <> "1" THEN [1] ELSE [] END AS deactive, CASE WHEN row.af = "1" THEN [1] ELSE [] END AS active
FOREACH (x IN deactive | SET p:DEACTIVE)
FOREACH (y IN active | SET p:ACTIVE)
;

CREATE CONSTRAINT ON (d:Data) ASSERT d.id IS UNIQUE;
CREATE CONSTRAINT ON (p:Problem) ASSERT p.id IS UNIQUE;

// Lesson to Unit Relationship
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "https://www.dropbox.com/s/mxwb57qi7ksgs8n/tbc_relation.csv?dl=1" AS row
with row.media as media, row.chain as chain,row
WHERE media = '1' AND chain = '1'
MATCH (unit:Unit {id: TOINT(row.module)})
MATCH (lesson:Lesson {old_id: TOINT(row.lesson_id)})
MERGE (lesson)-[r:has_unit]->(unit)
SET r.seq = TOINT(row.seq)
SET r.type = "unit"
;

// Lesson to Chain Relationship
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "https://www.dropbox.com/s/uqb1st1qnmlzwz8/tbc_relation.csv?dl=1" AS row
with row.media as media, row.chain as chain,row
WHERE media = '1' AND chain = '2'
MATCH (unit:Unit {id: TOINT(row.module)})
MATCH (lesson:Lesson {old_id: TOINT(row.lesson_id)})
MERGE (lesson)-[r:has_unit]->(unit)
SET r.seq = TOINT(row.seq)
SET r.type = "chain"
;

// Lesson to Video Relationship
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "https://www.dropbox.com/s/uqb1st1qnmlzwz8/tbc_relation.csv?dl=1" AS row
with row.media as media,row
WHERE media = '2'
MATCH (vid:Video {name: row.module})
MATCH (lesson:Lesson {old_id: TOINT(row.lesson_id)})
MERGE (lesson)-[r:has_video]->(vid)
SET r.seq = TOINT(row.seq)
;

// Unit to Data Relationship
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "https://www.dropbox.com/s/mi5wkdpg7fv1mjy/data.csv?dl=1" AS row
MATCH (data:Data {id: TOINT(row.id)})
MATCH (unit:Unit {id: TOINT(row.module)})
MERGE (unit)-[:has]->(data)
;

// Data to Problem Relationship
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "https://www.dropbox.com/s/s7rxenc7qswfrdd/problems_lev1.csv?dl=1" AS row
MATCH (data:Data {id: TOINT(row.data)})
MATCH (problem:Problem {id: TOINT(row.id)})
MERGE (data)-[:makes]->(problem)
;

// Sub Problem Relationships
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/io5td1n0ev5yvea/problems_lev2-all.csv?dl=1" AS row
MATCH (parent:Problem {id: TOINT(row.id_parent)})
MATCH (problem:Problem {id: TOINT(row.id)})
MERGE (parent)-[:substep]->(problem)
;

// Sub Problem Calls to Units
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/io5td1n0ev5yvea/problems_lev2-all.csv?dl=1" AS row
MATCH (problem:Problem {id: TOINT(row.id)})
MATCH (unit:Unit {id: TOINT(row.module)})
MERGE (problem)-[:calls]->(unit)
;

// connect level 2 children
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/io5td1n0ev5yvea/problems_lev2-all.csv?dl=1" AS row
WITH TOINT(row.level) as lev, row
MATCH (unit:Unit {id: TOINT(row.module)})
MATCH (parent:Unit {id: TOINT(row.module_parent)})
MERGE (unit)-[:child_of]->(parent)
;

// connect non-tier units to lessons
USING PERIODIC COMMIT	
LOAD CSV WITH HEADERS 
FROM "https://www.dropbox.com/s/io5td1n0ev5yvea/problems_lev2-all.csv?dl=1" AS row
MATCH (unit:Unit {id: TOINT(row.module)})
MATCH (parent:Unit {id: TOINT(row.data)})
MATCH (lesson:Lesson)-[:has_unit]->(parent)
MERGE (unit)-[l:used_in]->(lesson)
SET l.problem = TOINT(row.id)
SET l.module_parent = parent.id
;

// Cleanup
MATCH (l:Lesson) remove l.old_id return l;

MATCH (n:Lesson)-[has_unit]->(u:Unit)-[r:used_in]->(n)
DELETE r 
;

