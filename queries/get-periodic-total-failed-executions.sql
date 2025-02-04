SELECT 
  periodStart,
  SUM(count) as failures
FROM analytics_by_period ap
JOIN analytics_metadata am ON ap.metaId = am.metaId
WHERE
  workflowId = COALESCE(:workflow_id, workflowId)
  AND type = 3
  AND periodUnit = :unit
  AND periodStart >= unixepoch(datetime('now', :window))
GROUP BY periodStart
ORDER BY periodStart;
