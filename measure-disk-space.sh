#!/bin/bash

db_file="$1"
db_copy="${db_file}.copy"

cp "$db_file" "$db_copy"

compaction_version=$(sqlite3 "$db_copy" "SELECT value FROM settings WHERE key = 'compaction_version';")

# Drop non-analytics tables
tables=$(sqlite3 "$db_copy" ".tables" | tr ' ' '\n' | grep -vE "^(sqlite_sequence|analytics|analytics_by_period|analytics_metadata)$")
for table in $tables; do
  sqlite3 "$db_copy" "DROP TABLE $table;"
done

get_file_size() {
    local file="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f%z "$file"
    else
        stat -c%s "$file"
    fi
}

pre_vacuum_size=$(get_file_size "$db_copy")
sqlite3 "$db_copy" "VACUUM;"
post_vacuum_size=$(get_file_size "$db_copy")

total_analytics=$(sqlite3 "$db_copy" "SELECT COUNT(*) FROM analytics;")
total_analytics_by_period=$(sqlite3 "$db_copy" "SELECT COUNT(*) FROM analytics_by_period;")
total_analytics_metadata=$(sqlite3 "$db_copy" "SELECT COUNT(*) FROM analytics_metadata;")
total_rows=$((total_analytics + total_analytics_by_period + total_analytics_metadata))

pre_vacuum_avg_row_size=$((pre_vacuum_size / total_rows))
post_vacuum_avg_row_size=$((post_vacuum_size / total_rows))
pre_vacuum_mib=$(printf "%.2f" "$(echo "$pre_vacuum_size / 1048576" | bc -l)")
post_vacuum_mib=$(printf "%.2f" "$(echo "$post_vacuum_size / 1048576" | bc -l)")

printf "Compaction version: %s\n\n" "$compaction_version"

printf "Pre-VACUUM\n"
printf "  DB size: %'d bytes (%.2f MiB)\n" "$pre_vacuum_size" "$pre_vacuum_mib"
printf "  Avg row size: %'d bytes\n\n" "$pre_vacuum_avg_row_size"

printf "Post-VACUUM\n"
printf "  DB size: %'d bytes (%.2f MiB)\n" "$post_vacuum_size" "$post_vacuum_mib"
printf "  Avg row size: %'d bytes\n\n" "$post_vacuum_avg_row_size"

printf "Total rows: %'d\n" "$total_rows"
printf "  analytics: %'d\n" "$total_analytics"
printf "  analytics_by_period: %'d\n" "$total_analytics_by_period"
printf "  analytics_metadata: %'d\n" "$total_analytics_metadata"

rm "$db_copy"
