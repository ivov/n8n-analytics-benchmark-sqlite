SELECT SUM(count)
FROM analytics_by_period ap
WHERE
  ap.metaId = COALESCE((SELECT metaId from analytics_metadata WHERE workflowId = :workflow_id), ap.metaId)
  AND type = 3
  AND periodUnit = :unit
  AND periodStart >= unixepoch(datetime('now', :window));
