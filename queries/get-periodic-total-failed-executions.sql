SELECT 
  periodStart,
  SUM(count) as failures
FROM analytics_by_period
WHERE
  workflowId = COALESCE(:workflow_id, workflowId)
  AND type = 'failure' 
  AND periodUnit = :unit
  AND periodStart >= DATETIME('now', :window)
GROUP BY periodStart
ORDER BY periodStart;
