SELECT 
  periodStart,
  SUM(count) as total_executions
FROM analytics_by_period a
JOIN analytics_metadata m ON a.workflowId = m.workflowId
WHERE
  m.projectId = :project_id
  AND type IN ('success', 'failure')
  AND periodUnit = :unit
  AND periodStart >= DATETIME('now', :window)
GROUP BY periodStart
ORDER BY periodStart;
