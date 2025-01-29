SELECT SUM(count)
FROM analytics_by_period a
JOIN analytics_metadata m ON a.workflowId = m.workflowId
WHERE
 m.projectId = :project_id
 AND type = 'time_saved_min'
 AND periodUnit = :unit 
 AND periodStart >= DATETIME('now', :window);
