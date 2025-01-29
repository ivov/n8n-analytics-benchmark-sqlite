BEGIN TRANSACTION;

WITH RECURSIVE generate_rows AS (
  SELECT 1 as counter
  UNION ALL
  SELECT counter + 1 FROM generate_rows WHERE counter < :num_projects
)
INSERT INTO project (
  id,
  name,
  type,
  createdAt,
  updatedAt,
  icon
)
SELECT 
  HEX(RANDOMBLOB(16)), -- id
  'Project_' || counter, -- name
  'team', -- type
  DATETIME('now', '-' || ABS(RANDOM() % 365) || ' days'), -- createdAt
  DATETIME('now', '-' || ABS(RANDOM() % 30) || ' days'), -- updatedAt
  CASE (ABS(RANDOM() % 2))
    WHEN 0 THEN NULL
    ELSE '💼'
  END -- icon
FROM generate_rows;

INSERT INTO project_relation (
  projectId,
  userId,
  role,
  createdAt,
  updatedAt
)
SELECT 
  id as projectId,
  (SELECT id FROM user LIMIT 1) as userId, -- instance owner is admin of all created team projects
  'project:admin' as role,
  p.createdAt,
  p.updatedAt
FROM project p
WHERE p.id NOT IN (SELECT projectId FROM project_relation);

INSERT INTO shared_workflow (workflowId, projectId, role, createdAt, updatedAt)
SELECT 
  w.id as workflowId,
  (SELECT id FROM project ORDER BY RANDOM() LIMIT 1) as projectId,
  'workflow:owner' as role,
  w.createdAt,
  w.updatedAt
FROM workflow_entity w;

UPDATE shared_workflow
SET projectId = (
  SELECT id FROM project
  WHERE shared_workflow.projectId = shared_workflow.projectId -- correlated query to force re-evaluation
  ORDER BY RANDOM()
  LIMIT 1
);

COMMIT;
