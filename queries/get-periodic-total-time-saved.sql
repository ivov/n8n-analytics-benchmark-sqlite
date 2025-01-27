SELECT 
  periodStart,
  SUM(value) as time_saved_minutes
FROM analytics_by_period
WHERE
  workflowId = COALESCE(:workflow_id, workflowId)
  AND type = 'time_saved_min'
  AND periodUnit = :unit 
  AND periodStart >= DATETIME('now', :window)
GROUP BY periodStart
ORDER BY periodStart;
