#!/bin/bash

db_file="$1"
db_copy="${db_file}.copy"

cp "$db_file" "$db_copy"

# Drop non-analytics tables
tables=$(sqlite3 "$db_copy" ".tables" | tr ' ' '\n' | grep -vE "^(sqlite_sequence|analytics|analytics_by_period)$")
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
total_rows=$((total_analytics + total_analytics_by_period))

pre_vacuum_avg_row_size=$((pre_vacuum_size / total_rows))
post_vacuum_avg_row_size=$((post_vacuum_size / total_rows))
pre_vacuum_mib=$(printf "%.2f" "$(echo "$pre_vacuum_size / 1048576" | bc -l)")
post_vacuum_mib=$(printf "%.2f" "$(echo "$post_vacuum_size / 1048576" | bc -l)")

printf "✅ Pre-VACUUM size of DB: %'d bytes → %s MiB\n" "$pre_vacuum_size" "$pre_vacuum_mib"
printf "✅ Post-VACUUM size of DB: %'d bytes → %s MiB\n" "$post_vacuum_size" "$post_vacuum_mib"
printf "✅ Total rows: %'d (%'d from \`analytics\` + %'d from \`analytics_by_period\`)\n" \
  "$total_rows" "$total_analytics" "$total_analytics_by_period"
printf "✅ Pre-VACUUM avg row size: %'d bytes\n" "$pre_vacuum_avg_row_size"
printf "✅ Post-VACUUM avg row size: %'d bytes\n" "$post_vacuum_avg_row_size"

rm "$db_copy"
