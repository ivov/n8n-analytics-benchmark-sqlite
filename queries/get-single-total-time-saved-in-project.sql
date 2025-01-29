SELECT SUM(count)
FROM analytics_by_period a
JOIN analytics_metadata m ON a.workflowId = m.workflowId
WHERE
 a.workflowId = COALESCE(:workflow_id, a.workflowId)
 AND m.projectId = COALESCE(:project_id, m.projectId)
 AND type = 'time_saved_min'
 AND periodUnit = :unit 
 AND periodStart >= DATETIME('now', :window);
