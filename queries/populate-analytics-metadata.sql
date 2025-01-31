-- TODO: Should all columns be NOT NULL?
CREATE TABLE analytics_metadata (
  workflowId VARCHAR(16) PRIMARY KEY REFERENCES analytics_by_period (workflowId) ON DELETE CASCADE,
  workflowName VARCHAR(128) NOT NULL,
  projectId VARCHAR(36),
  projectName VARCHAR(255)
);

CREATE INDEX idx_analytics_metadata_project_id ON analytics_metadata(projectId);

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

