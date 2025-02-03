-- Version 2 of compaction logic for `analytics` table
-- * for past 90 days, make hourly summaries
-- * from 90 to 180 days, make daily summaries
-- * from 180 days onwards, make weekly summaries

BEGIN TRANSACTION;

INSERT INTO analytics_by_period (metaId, type, count, periodUnit, periodStart)
SELECT 
  metaId,
  type,
  SUM(value) as count,
  0 as periodUnit,
  unixepoch(strftime('%Y-%m-%d %H:00:00', timestamp)) as periodStart
FROM analytics
WHERE timestamp >= datetime('now', '-90 days')
GROUP BY metaId, type, strftime('%Y-%m-%d %H:00:00', timestamp);

INSERT INTO analytics_by_period (metaId, type, count, periodUnit, periodStart)
SELECT 
  metaId,
  type,
  SUM(value) as count,
  1 as periodUnit,
  unixepoch(date(timestamp)) as periodStart
FROM analytics
WHERE timestamp < datetime('now', '-90 days') 
AND timestamp >= datetime('now', '-180 days')
GROUP BY metaId, type, date(timestamp);

INSERT INTO analytics_by_period (metaId, type, count, periodUnit, periodStart)
SELECT 
  metaId,
  type,
  SUM(value) as count,
  2 as periodUnit,
  unixepoch(date(timestamp, 'weekday 0', '-180 days')) as periodStart
FROM analytics
WHERE timestamp < datetime('now', '-90 days')
GROUP BY metaId, type, date(timestamp, 'weekday 0', '-7 days');

DELETE FROM analytics;

INSERT INTO settings (key, value, loadOnStartup)
VALUES ('compaction_version', '2', 0);

COMMIT;
