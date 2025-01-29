-- Version 2 of compaction logic for `analytics` table
-- * for past 90 days, make hourly summaries
-- * from 90 to 180 days, make daily summaries
-- * from 180 days onwards, make weekly summaries

BEGIN TRANSACTION;

INSERT INTO analytics_by_period (workflowId, type, count, periodUnit, periodStart)
SELECT 
  workflowId,
  type,
  CASE
    WHEN type IN ('success', 'failure') THEN COUNT(*)
    WHEN type = 'time_saved_min' THEN SUM(value)
    WHEN type = 'runtime_ms' THEN SUM(value)
  END as count,
  'hour' as periodUnit,
  strftime('%Y-%m-%d %H:00:00', timestamp) as periodStart
FROM analytics
WHERE timestamp >= datetime('now', '-90 days')
GROUP BY workflowId, type, strftime('%Y-%m-%d %H:00:00', timestamp);

INSERT INTO analytics_by_period (workflowId, type, count, periodUnit, periodStart)
SELECT 
  workflowId,
  type,
  CASE
    WHEN type IN ('success', 'failure') THEN COUNT(*)
    WHEN type = 'time_saved_min' THEN SUM(value)
    WHEN type = 'runtime_ms' THEN SUM(value)
  END as count,
  'day' as periodUnit,
  date(timestamp) as periodStart
FROM analytics
WHERE timestamp < datetime('now', '-90 days') 
AND timestamp >= datetime('now', '-180 days')
GROUP BY workflowId, type, date(timestamp);

INSERT INTO analytics_by_period (workflowId, type, count, periodUnit, periodStart)
SELECT 
  workflowId,
  type,
  CASE
    WHEN type IN ('success', 'failure') THEN COUNT(*)
    WHEN type = 'time_saved_min' THEN SUM(value)
    WHEN type = 'runtime_ms' THEN SUM(value)
  END as count,
  'week' as periodUnit,
  date(timestamp, 'weekday 0', '-180 days') as periodStart
FROM analytics
WHERE timestamp < datetime('now', '-90 days')
GROUP BY workflowId, type, date(timestamp, 'weekday 0', '-7 days');

DELETE FROM analytics;

INSERT INTO settings (key, value, loadOnStartup)
VALUES ('compaction_version', '2', 0);

COMMIT;
