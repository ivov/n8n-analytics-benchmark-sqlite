CREATE TABLE analytics_metadata (
  workflowId VARCHAR(16) UNIQUE NOT NULL,
  workflowName VARCHAR(128),
  projectId VARCHAR(36), -- TODO: project table
  projectName VARCHAR(255)
);

INSERT INTO analytics_metadata (workflowId, workflowName)
SELECT DISTINCT
    a.workflowId,
    w.name as workflowName
FROM analytics a
JOIN workflow_entity w ON a.workflowId = w.id
WHERE a.workflowId IS NOT NULL;

