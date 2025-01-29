WITH breakdown_by_workflow AS (
  SELECT 
    analytics_metadata.workflowId as workflow_id,
    workflowName as workflow_name,
    SUM(CASE WHEN type IN ('success', 'failure') THEN count ELSE 0 END) as total_executions,
    SUM(CASE WHEN type = 'failure' THEN count ELSE 0 END) as total_failures,
    ROUND(CAST(SUM(CASE WHEN type = 'failure' THEN count ELSE 0 END) AS FLOAT) / 
      SUM(CASE WHEN type IN ('success', 'failure') THEN count ELSE 0 END), 2) as failure_rate,
    SUM(CASE WHEN type = 'time_saved_min' THEN count ELSE 0 END) as time_saved_min,
    CAST(AVG(CASE WHEN type = 'runtime_ms' THEN count ELSE NULL END) AS INTEGER) as avg_runtime_ms,
    projectId as project_id,
    projectName as project_name
  FROM analytics_metadata
  LEFT JOIN analytics_by_period ON analytics_metadata.workflowId = analytics_by_period.workflowId
  WHERE analytics_by_period.periodStart >= DATETIME('now', :window)
  -- AND projectId = COALESCE(:project_id, projectId)
  GROUP BY analytics_metadata.workflowId
  HAVING total_executions > 0
)
SELECT *
FROM breakdown_by_workflow
ORDER BY total_executions DESC
LIMIT :limit
OFFSET :offset;
