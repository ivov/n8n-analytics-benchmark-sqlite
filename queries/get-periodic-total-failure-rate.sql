SELECT 
  periodStart, 
  periodUnit,
  -- INFO: uncomment to debug and check
  -- metaId,
  -- SUM(CASE WHEN type = 2 THEN count ELSE 0 END) successes,
  -- SUM(CASE WHEN type = 3 THEN count ELSE 0 END) failures,
  -- SUM(count) total,
  CAST(SUM(CASE WHEN type = 3 THEN count ELSE 0 END) AS FLOAT) / 
    SUM(count) failure_rate
FROM analytics_by_period ap
WHERE
	type IN (2, 3) AND
  periodUnit = :unit AND
  periodStart >= unixepoch(datetime('now', :window)) AND
  ap.metaId = COALESCE((SELECT metaId from analytics_metadata WHERE workflowId = :workflow_id), ap.metaId)
GROUP BY periodStart
ORDER BY periodStart;
