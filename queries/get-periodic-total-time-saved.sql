SELECT 
  periodStart,
  SUM(count) as time_saved_minutes
FROM analytics_by_period ap
WHERE
  ap.metaId = COALESCE((SELECT metaId from analytics_metadata WHERE workflowId = :workflow_id), ap.metaId)
  AND type = 0
  AND periodUnit = :unit 
  AND periodStart >= unixepoch(datetime('now', :window))
GROUP BY periodStart
ORDER BY periodStart;
