CREATE TABLE analytics_metadata (
  metaId INTEGER PRIMARY KEY AUTOINCREMENT,
  workflowId VARCHAR(16) REFERENCES workflow_entity(id) ON DELETE SET NULL,
  workflowName VARCHAR(128) NOT NULL,
  projectId VARCHAR(36) REFERENCES project(id) ON DELETE SET NULL,
  projectName VARCHAR(255) NOT NULL
);

CREATE INDEX idx_analytics_metadata_project_id ON analytics_metadata(projectId);

INSERT INTO analytics_metadata (workflowId, workflowName, projectId, projectName)
SELECT wf.id, wf.name, p.id, p.name
FROM workflow_entity wf
JOIN shared_workflow swf ON wf.id = swf.workflowId
JOIN project p ON swf.projectId = p.id;



