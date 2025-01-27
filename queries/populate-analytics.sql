CREATE TABLE analytics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    workflowId VARCHAR(16) NOT NULL REFERENCES workflow_entity(id),
    type TEXT NOT NULL, -- time_saved_min, runtime_ms, success, failure
    value INTEGER, -- integer for minutes, integer for milliseconds, always 1, always 1
    timestamp TEXT NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
);

WITH RECURSIVE generate_rows AS (
    SELECT 1 as counter
    UNION ALL
    SELECT counter + 1 FROM generate_rows WHERE counter < :num_events
)
INSERT INTO analytics (workflowId, type, value, timestamp)
SELECT 
    (SELECT id FROM workflow_entity ORDER BY RANDOM() LIMIT 1),
    CASE RANDOM() % 4
        WHEN 0 THEN 'time_saved_min'
        WHEN 1 THEN 'runtime_ms'
        WHEN 2 THEN 'success'
        ELSE 'failure' END,
    1,
    datetime('now', '-' || ABS(RANDOM() % 31536000) || ' seconds')
FROM generate_rows;

UPDATE analytics
SET value = ABS(RANDOM() % 300000) + 1 -- 1 ms to 300,000 ms (5 minutes) runtime
WHERE type = 'runtime_ms';

UPDATE analytics
SET value = (ABS(RANDOM() % 240) + 1) -- 1 minute to 240 minutes (4 hours)
WHERE type = 'time_saved_min';

CREATE TABLE analytics_by_period (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    workflowId VARCHAR(16) NOT NULL REFERENCES workflow_entity(id),
    type TEXT NOT NULL, -- see analytics.type
    count INTEGER NOT NULL, -- count of events within aggregation period
    periodUnit TEXT NOT NULL, -- unit of aggregation period: hour, day, week 
    periodStart TEXT NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')) -- start of aggregation period
);

CREATE INDEX idx_analytics_by_period_composite ON analytics_by_period(workflowId, type, periodUnit, periodStart);

