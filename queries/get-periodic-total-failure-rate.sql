SELECT 
  p.periodStart,
  CAST(COALESCE(f.failures, 0) AS FLOAT) / COALESCE(t.total, 1) as failure_rate
FROM (
  SELECT DISTINCT periodStart
  FROM analytics_by_period 
  WHERE periodUnit = :unit
  AND periodStart >= datetime('now', :window)
) p
LEFT JOIN (
  SELECT periodStart, SUM(count) as failures
  FROM analytics_by_period
  WHERE 
    workflowId = COALESCE(:workflow_id, workflowId)
    AND type = 'failure'
    AND periodUnit = :unit
    AND periodStart >= datetime('now', :window)
    GROUP BY periodStart
) f ON p.periodStart = f.periodStart
LEFT JOIN (
  SELECT periodStart, SUM(count) as total
  FROM analytics_by_period
  WHERE 
    workflowId = COALESCE(:workflow_id, workflowId)
    AND type IN ('success', 'failure')
    AND periodUnit = :unit
    AND periodStart >= datetime('now', :window)
    GROUP BY periodStart
) t ON p.periodStart = t.periodStart
ORDER BY p.periodStart;
