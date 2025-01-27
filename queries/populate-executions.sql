WITH RECURSIVE sequence AS (
    SELECT 1 as i 
    UNION ALL
    SELECT i + 1 FROM sequence WHERE i < :num_executions
)
INSERT INTO execution_entity 
SELECT 
    i,
    (SELECT id FROM workflow_entity ORDER BY RANDOM() LIMIT 1),
    ABS(RANDOM() % 2),
    CASE (ABS(RANDOM()) % 9)
        WHEN 0 THEN 'cli' WHEN 1 THEN 'error' WHEN 2 THEN 'integrated'
        WHEN 3 THEN 'internal' WHEN 4 THEN 'manual' WHEN 5 THEN 'retry'
        WHEN 6 THEN 'trigger' WHEN 7 THEN 'webhook' ELSE 'evaluation' END, -- mode
    CASE WHEN RANDOM() % 5 = 0 THEN CAST(ABS(RANDOM() % 5) AS TEXT) END,
    CASE WHEN RANDOM() % 5 = 0 THEN CAST(ABS(RANDOM() % i) AS TEXT) END,
    datetime('now', '-' || ABS(RANDOM() % 24) || ' hours'),
    CASE WHEN ABS(RANDOM() % 2) THEN datetime('now', '-' || ABS(RANDOM() % 12) || ' hours') END,
    CASE WHEN ABS(RANDOM() % 8) = 7 THEN datetime('now', '+' || ABS(RANDOM() % 60) || ' minutes') END,
    CASE (ABS(RANDOM()) % 8)
        WHEN 0 THEN 'canceled' WHEN 1 THEN 'crashed' WHEN 2 THEN 'error'
        WHEN 3 THEN 'new' WHEN 4 THEN 'running' WHEN 5 THEN 'success'
        WHEN 6 THEN 'unknown' ELSE 'waiting' END,
    NULL,
    DATETIME('now', '-' || ABS(RANDOM() % 24) || ' hours')
FROM sequence;

INSERT INTO execution_data (executionId, workflowData, data)
SELECT DISTINCT id, '{}', '[]'
FROM execution_entity
ORDER BY RANDOM()
LIMIT 100000;
