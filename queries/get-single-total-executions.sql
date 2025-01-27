SELECT SUM(count)
FROM analytics_by_period
WHERE
  workflowId = COALESCE(:workflow_id, workflowId)
  AND type IN ('success', 'failure')
  AND periodUnit = :unit
  AND periodStart >= DATETIME('now', :window)
