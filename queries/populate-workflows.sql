WITH RECURSIVE counter(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM counter WHERE n < :num_workflows
)
INSERT INTO workflow_entity (
    id, name, active, nodes, connections, createdAt, updatedAt, settings, staticData, pinData, versionId, triggerCount, meta
)
SELECT 
    HEX(RANDOMBLOB(16)), -- id
    'Workflow_' || n, -- name
    ABS(RANDOM() % 2), -- active
    '[{"parameters":{"rule":{"interval":[{}]}},"type":"n8n-nodes-base.scheduleTrigger","typeVersion":1.2,"position":[0,0],"id":"' || hex(randomblob(16)) || '"}]',
    '{"Schedule Trigger":{"main":[]}}', -- connections
    DATETIME('now', '-' || ABS(RANDOM() % 365) || ' days'), -- createdAt
    DATETIME('now', '-' || ABS(RANDOM() % 30) || ' days'), -- updatedAt
    '{"executionOrder":"v1"}', -- settings
    CASE (ABS(RANDOM() % 2)) WHEN 0 THEN NULL ELSE '{"lastExecution":"2024-01-20"}' END, -- staticData
    NULL, -- pinData
    HEX(RANDOMBLOB(16)), -- versionId
    ABS(RANDOM() % 200), -- triggerCount
    CASE (ABS(RANDOM() % 2)) WHEN 0 THEN NULL ELSE '{"templateCredsSetupCompleted":true}' END -- meta
FROM counter;
