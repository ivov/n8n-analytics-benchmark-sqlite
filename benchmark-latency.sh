#!/bin/bash

# TODO: Decide on 
# - unit for all runs
# - window for all runs
# - warmups for all runs
# - iterations for all runs

DB_FILEPATH=$1
UNIT="hour" 
WINDOW="-7 days"
RANDOM_WORKFLOW_ID=$(sqlite3 "$DB_FILEPATH" "SELECT id FROM workflow_entity LIMIT 1;")
RANDOM_PROJECT_ID=$(sqlite3 "$DB_FILEPATH" "SELECT id FROM project LIMIT 1;")

check_analytics_tables() {
  analytics_count=$(sqlite3 "$DB_FILEPATH" "SELECT COUNT(*) FROM analytics;")
  analytics_by_period_count=$(sqlite3 "$DB_FILEPATH" "SELECT COUNT(*) FROM analytics_by_period;")
  analytics_metadata_count=$(sqlite3 "$DB_FILEPATH" "SELECT COUNT(*) FROM analytics_metadata;")

  if [ "$analytics_count" -gt 0 ] || [ "$analytics_by_period_count" -eq 0 ] || [ "$analytics_metadata_count" -eq 0 ]; then
    echo "Please run 'make compact version=n' before benchmarking"
    exit 1
  fi
}

benchmark_query() {
  local query_description=$2
  local query_command=$3
  
  echo "$query_description"
  hyperfine --warmup 2 --runs 5 "$query_command" # TODO: Decide on warmups and iterations
}

benchmark_all_queries() {
 # query that accepts optional project ID
  benchmark_query "get-breakdown-by-workflow" \
  "Breakdown by workflow (all projects)" \
  "make run query=get-breakdown-by-workflow window='$WINDOW'"

  benchmark_query "get-breakdown-by-workflow" \
  "Breakdown by workflow (specific project)" \
  "make run query=get-breakdown-by-workflow window='$WINDOW' project_id=$RANDOM_PROJECT_ID"

 # queries that accept optional workflow ID or optional project ID
  queries=(
    "get-periodic-total-executions"
    "get-periodic-total-failed-executions" 
    "get-periodic-total-failure-rate"
    "get-periodic-total-time-saved"
    "get-single-total-executions"
    "get-single-total-failed-executions"
    "get-single-total-failure-rate"
    "get-single-total-time-saved"
  )

  for query in "${queries[@]}"; do
    benchmark_query "$query" \
    "$query (all workflows)" \
    "make run query=$query unit='$UNIT' window='$WINDOW'"
   
    benchmark_query "$query" \
    "$query (specific workflow)" \
    "make run query=$query unit='$UNIT' window='$WINDOW' workflow_id=$RANDOM_WORKFLOW_ID"

    benchmark_query "$query-in-project" \
    "$query (specific project)" \
    "make run query=$query-in-project unit='$UNIT' window='$WINDOW' project_id=$RANDOM_PROJECT_ID"
  done
}

check_analytics_tables
benchmark_all_queries