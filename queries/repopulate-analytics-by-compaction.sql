-- Naive compaction for the `analytics` table, i.e. process all history in one go:
-- * for past 30 days, make hourly summaries
-- * from 30 to 90 days, make daily summaries
-- * from 90 days onwards, make weekly summaries
--
-- More realistically we will run regular compaction cycles that process data as it ages: 
-- * for data in past hour, create new hourly summary (insert hourly)
-- * for data older than 30 days, convert hourly to daily summaries (insert daily, delete hourly)
-- * for data older than 90 days, convert daily to weekly summaries (insert weekly, delete daily)

BEGIN TRANSACTION;

INSERT INTO analytics_by_period (workflowId, type, count, periodUnit, periodStart)
SELECT 
    workflowId,
    type,
    CASE
        WHEN type IN ('success', 'failure') THEN COUNT(*)
        WHEN type = 'time_saved_min' THEN SUM(value)
        WHEN type = 'runtime_ms' THEN ROUND(AVG(value))
    END as count,
    'hour' as periodUnit,
    strftime('%Y-%m-%d %H:00:00', timestamp) as periodStart
FROM analytics
WHERE timestamp >= datetime('now', '-30 days')
GROUP BY workflowId, type, strftime('%Y-%m-%d %H:00:00', timestamp);

INSERT INTO analytics_by_period (workflowId, type, count, periodUnit, periodStart)
SELECT 
    workflowId,
    type,
    CASE
        WHEN type IN ('success', 'failure') THEN COUNT(*)
        WHEN type = 'time_saved_min' THEN SUM(value)
        WHEN type = 'runtime_ms' THEN ROUND(AVG(value))
    END as count,
    'day' as periodUnit,
    date(timestamp) as periodStart
FROM analytics
WHERE timestamp < datetime('now', '-30 days') 
AND timestamp >= datetime('now', '-90 days')
GROUP BY workflowId, type, date(timestamp);

INSERT INTO analytics_by_period (workflowId, type, count, periodUnit, periodStart)
SELECT 
    workflowId,
    type,
    CASE
        WHEN type IN ('success', 'failure') THEN COUNT(*)
        WHEN type = 'time_saved_min' THEN SUM(value)
        WHEN type = 'runtime_ms' THEN ROUND(AVG(value))
    END as count,
    'week' as periodUnit,
    date(timestamp, 'weekday 0', '-7 days') as periodStart
FROM analytics
WHERE timestamp < datetime('now', '-90 days')
GROUP BY workflowId, type, date(timestamp, 'weekday 0', '-7 days');

DELETE FROM analytics;

COMMIT;
