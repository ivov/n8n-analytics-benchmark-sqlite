SELECT 
  periodStart,
  CAST(SUM(CASE WHEN type = 'failure' THEN count ELSE 0 END) AS FLOAT) /
    SUM(count) as failure_rate
FROM analytics_by_period ap
WHERE 
  type IN ('success', 'failure')
  AND periodStart >= datetime('now', :window)
  AND periodUnit = :unit
  AND workflowId = COALESCE(:workflow_id, workflowId)
GROUP BY periodStart
ORDER BY periodStart;
