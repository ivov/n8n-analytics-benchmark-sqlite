SELECT CAST(f.failures AS FLOAT) / t.total as failure_rate
FROM (
  SELECT SUM(count) as failures 
  FROM analytics_by_period 
  WHERE
    workflowId = COALESCE(:workflow_id, workflowId)
    AND type = 'failure'
    AND periodUnit = :unit
    AND periodStart >= datetime('now', :window)
) f,
(
  SELECT SUM(count) as total 
  FROM analytics_by_period 
  WHERE
    workflowId = COALESCE(:workflow_id, workflowId)
    AND type IN ('success', 'failure')
    AND periodUnit = :unit
    AND periodStart >= datetime('now', :window)
) t;
