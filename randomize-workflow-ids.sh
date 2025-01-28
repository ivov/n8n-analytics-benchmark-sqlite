#!/bin/bash

# Populate `analytics.workflowId` with random valid workflow IDs
#
# Sample generated SQL:
#
# UPDATE analytics SET workflowId = CASE
# WHEN (ABS(RANDOM()) % 3) = 0 THEN '764235F571D643D5C2D5F2E6A0714FFB'
# WHEN (ABS(RANDOM()) % 3) = 1 THEN 'EA0DCE4C3C286872839B006AE83C3896'
# WHEN (ABS(RANDOM()) % 3) = 2 THEN '6FCA09155DC50A0E14C4858512638611'
# ELSE '764235F571D643D5C2D5F2E6A0714FFB' END;

DB_PATH=$1

IFS=$'\n' read -d '' -r -a workflow_ids < <(sqlite3 "$DB_PATH" "SELECT id FROM workflow_entity;")

if [ ${#workflow_ids[@]} -eq 0 ]; then
  echo "No workflow IDs found"
  exit 1
fi

sql_stmt="UPDATE analytics SET workflowId = CASE"
for i in "${!workflow_ids[@]}"; do
    sql_stmt+=" WHEN (ABS(RANDOM()) % ${#workflow_ids[@]}) = $i THEN '${workflow_ids[$i]}'"
done
sql_stmt+=" ELSE '${workflow_ids[0]}' END;"

sqlite3 "$DB_PATH" "$sql_stmt"