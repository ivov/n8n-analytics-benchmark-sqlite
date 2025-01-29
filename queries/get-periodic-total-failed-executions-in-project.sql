SELECT 
  periodStart,
  SUM(count) as failures
FROM analytics_by_period a
JOIN analytics_metadata m ON a.workflowId = m.workflowId
WHERE
  m.projectId = :project_id
  AND type = 'failure' 
  AND periodUnit = :unit
  AND periodStart >= DATETIME('now', :window)
GROUP BY periodStart
ORDER BY periodStart;
