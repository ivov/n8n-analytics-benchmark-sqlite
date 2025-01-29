SELECT CAST(f.failures AS FLOAT) / t.total as failure_rate
FROM (
 SELECT SUM(count) as failures 
 FROM analytics_by_period a
 JOIN analytics_metadata m ON a.workflowId = m.workflowId
 WHERE
   a.workflowId = COALESCE(:workflow_id, a.workflowId)
   AND m.projectId = COALESCE(:project_id, m.projectId)
   AND type = 'failure'
   AND periodUnit = :unit
   AND periodStart >= datetime('now', :window)
) f,
(
 SELECT SUM(count) as total 
 FROM analytics_by_period a
 JOIN analytics_metadata m ON a.workflowId = m.workflowId
 WHERE
   a.workflowId = COALESCE(:workflow_id, a.workflowId)
   AND m.projectId = COALESCE(:project_id, m.projectId)
   AND type IN ('success', 'failure')
   AND periodUnit = :unit
   AND periodStart >= datetime('now', :window)
) t;