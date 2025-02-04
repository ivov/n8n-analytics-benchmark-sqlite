CREATE TABLE analytics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  metaId INTEGER REFERENCES analytics_metadata(metaId) ON DELETE CASCADE,
  -- 0: time_saved_min
  -- 1: runtime_ms
  -- 2: success
  -- 3: failure
  type INTEGER NOT NULL, -- 0: time_saved_min, 1: runtime_ms, 2: success, 3: failure
  value INTEGER, -- integer for minutes, integer for milliseconds, always 1, always 1
  timestamp DATETIME NOT NULL DEFAULT 'now'
);

CREATE index idx_analytics_by_timestamp ON analytics(timestamp);

WITH RECURSIVE generate_rows AS (
  SELECT 1 as counter
  UNION ALL
  SELECT counter + 1 FROM generate_rows WHERE counter < :num_events
)
INSERT INTO analytics (metaId, type, value, timestamp)
SELECT 
  NULL,
  ABS(RANDOM() % 4),
  1,
  datetime('now', '-' || ABS(RANDOM() % 31536000) || ' seconds')
FROM generate_rows;

WITH max_id AS ( SELECT metaId from analytics_metadata ORDER BY metaId DESC LIMIT 1 )
UPDATE analytics
SET metaId = (ABS(RANDOM()) % (SELECT metaId FROM max_id)) + 1;

UPDATE analytics
SET value = ABS(RANDOM() % 300000) + 1 -- 1 ms to 300,000 ms (5 minutes) runtime
WHERE type = 1;

UPDATE analytics
SET value = (ABS(RANDOM() % 240) + 1) -- 1 minute to 240 minutes (4 hours)
WHERE type = 0;

CREATE TABLE analytics_by_period (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  metaId INTEGER REFERENCES analytics_metadata(metaId) ON DELETE CASCADE,
  -- preserve analytics on workflow deletion
  -- TODO: try int2
  type INTEGER NOT NULL, -- see analytics.type
  -- TODO: rename to value
  count INTEGER NOT NULL, -- count of events within aggregation period
  -- 0: hour
  -- 1: day
  -- 2: week
  -- TODO: consider VARCHAR(1) or INTEGER
  periodUnit INTEGER NOT NULL, -- unit of aggregation period: hour, day, week 
  periodStart DATETIME NOT NULL DEFAULT 'now'
);

CREATE INDEX idx_analytics_by_period_composite ON analytics_by_period(metaId, type, periodUnit, periodStart);
