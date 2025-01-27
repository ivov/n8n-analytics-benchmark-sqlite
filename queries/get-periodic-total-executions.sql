SELECT 
  periodStart,
  SUM(count) as total_executions
FROM analytics_by_period
WHERE
  workflowId = COALESCE(:workflow_id, workflowId)
  AND type IN ('success', 'failure')
  AND periodUnit = :unit
  AND periodStart >= DATETIME('now', :window)
GROUP BY periodStart
ORDER BY periodStart;
