#!/bin/bash

DB_PATH=$1

analytics_count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM analytics;")
analytics_by_period_count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM analytics_by_period;")

if [ "$analytics_count" -gt 0 ] || [ "$analytics_by_period_count" -eq 0 ]; then
  echo "Error: The analytics table must be empty and analytics_by_period must have rows."
  echo "Please run 'make compact' before benchmarking."
  exit 1
fi

UNIT="hour" # TODO: Decide on unit for all runs
WINDOW="-7 days" # TODO: Decide on window for all runs

# TODO: Surface which compaction logic this report corresponds to
# TODO: Make results parseable? Send results to Google Sheet?

RANDOM_WORKFLOW_ID=$(sqlite3 "$DB_PATH" "SELECT id FROM workflow_entity LIMIT 1;")
# TODO: Project ID param

benchmark_query() {
  local query_name=$1
  local query_description=$2
  local cli_command=$3
  
  echo "Benchmarking: $query_description"
  hyperfine --warmup 1 --runs 3 "$cli_command" # TODO: Decide on warmups and iterations
  echo "----------------------------------------"
}

# query that does not accept workflow ID
benchmark_query "get-breakdown-by-workflow" \
  "Breakdown by workflow" \
  "make run query=get-breakdown-by-workflow window='$WINDOW'"

# queries that accept optional workflow ID
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
  # without workflow ID
  benchmark_query "$query" \
    "$query (all workflows)" \
    "make run query=$query unit='$UNIT' window='$WINDOW'"
  
  # with workflow ID
  benchmark_query "$query" \
    "$query (specific workflow)" \
    "make run query=$query unit='$UNIT' window='$WINDOW' workflow=$RANDOM_WORKFLOW_ID"
done
