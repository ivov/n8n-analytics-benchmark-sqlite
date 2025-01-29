-- TODO: Should all columns be NOT NULL?
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

UPDATE analytics_metadata SET
  projectId = sw.projectId,
  projectName = p.name
FROM shared_workflow sw
JOIN project p ON sw.projectId = p.id
WHERE analytics_metadata.workflowId = sw.workflowId;
