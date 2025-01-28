WITH breakdown_by_workflow AS (
  SELECT 
    w.id,
    w.name as workflow_name,
    SUM(CASE WHEN type IN ('success', 'failure') THEN count ELSE 0 END) as total_executions,
    SUM(CASE WHEN type = 'failure' THEN count ELSE 0 END) as total_failures,
    ROUND(CAST(SUM(CASE WHEN type = 'failure' THEN count ELSE 0 END) AS FLOAT) / 
      SUM(CASE WHEN type IN ('success', 'failure') THEN count ELSE 0 END), 2) as failure_rate,
    SUM(CASE WHEN type = 'time_saved_min' THEN count ELSE 0 END) as time_saved_min,
    CAST(AVG(CASE WHEN type = 'runtime_ms' THEN count ELSE NULL END) AS INTEGER) as avg_runtime_ms,
    w.updatedAt as last_updated_at
  FROM workflow_entity w
  LEFT JOIN analytics_by_period a ON w.id = a.workflowId
  WHERE a.periodStart >= DATETIME('now', :window)
  GROUP BY w.id
  HAVING total_executions > 0
)
SELECT *
FROM breakdown_by_workflow
ORDER BY total_executions DESC
LIMIT :limit
OFFSET :offset;
