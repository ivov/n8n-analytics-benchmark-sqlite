CREATE TABLE analytics_metadata (
  workflowId VARCHAR(16) PRIMARY KEY REFERENCES workflow_entity(id),
  workflowName VARCHAR(128)
);

INSERT INTO analytics_metadata (workflowId, workflowName)
SELECT DISTINCT
    a.workflowId,
    w.name as workflowName
FROM analytics a
JOIN workflow_entity w ON a.workflowId = w.id
WHERE a.workflowId IS NOT NULL;

