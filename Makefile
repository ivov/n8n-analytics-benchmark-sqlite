DB_FILEPATH := $(HOME)/.n8n/analytics-benchmark.sqlite
DB_FILENAME := $(notdir $(DB_FILEPATH))
N8N_VERSION := 1.75.2

setup: nuke create populate

# Remove the benchmark DB.
nuke:
	@rm $(DB_FILEPATH)

# Start n8n to create an empty sqlite DB with all migrations applied.
create:
	@docker run --rm --name n8n-$(N8N_VERSION) -p 5678:5678 \
	-v ~/.n8n:/home/node/.n8n \
	-e DB_SQLITE_DATABASE=/home/node/.n8n/$(DB_FILENAME) \
	n8nio/n8n:$(N8N_VERSION) > /dev/null & \
	while ! docker logs n8n-$(N8N_VERSION) 2>&1 | grep -q "Editor is now accessible"; do sleep 1; done && \
	docker stop n8n-$(N8N_VERSION) > /dev/null && \
	echo "✅ DB set up at: $(DB_FILEPATH)"

# Make a copy of the benchmark DB, reduce to only `analytics` and `analytics_by_period`
# tables, and report pre- and post-VACUUM sizes, total rows, and pre- and post-VACUUM
# average row sizes.
measure-disk-space:
	@chmod +x ./measure-disk-space.sh
	@./measure-disk-space.sh $(DB_FILEPATH)

# Populate the benchmark DB with workflows, executions and analytics events.
# Defaults: 500 workflows, 100k executions, 1m analytics events
# Example: `make populate workflows=700 executions=200,000 analytics=500,000`
populate:
	@make workflows n=$(or $(workflows),500)
	@make executions n=$(or $(executions),100000)
	@make analytics n=$(or $(analytics),1000000)

# Populate the `workflow_entity` table in the benchmark DB.
workflows:
	@sed 's/:num_workflows/$(shell echo $(n) | tr -d ',')/g' queries/populate-workflows.sql | sqlite3 $(DB_FILEPATH)
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM workflow_entity;"); \
	printf "✅ Total rows in \`workflow_entity\` table: %'d\n" $$total_rows

# Populate the `execution_entity` table in the benchmark DB.
executions:
	@sed 's/:num_executions/$(shell echo $(n) | tr -d ',')/g' queries/populate-executions.sql | sqlite3 $(DB_FILEPATH)
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM execution_entity;"); \
	printf "✅ Total rows in \`execution_entity\` table: %'d\n" $$total_rows

# Populate the `analytics` table in the benchmark DB.
analytics:
	@sed 's/:num_events/$(shell echo $(n) | tr -d ',')/g' queries/populate-analytics.sql | sqlite3 $(DB_FILEPATH)
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM analytics;"); \
	printf "✅ Total pre-compaction rows in \`analytics\` table: %'d\n" $$total_rows
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM analytics_by_period;"); \
	printf "✅ Total pre-compaction rows in \`analytics_by_period\` table: %'d\n" $$total_rows

# Process all `analytics` rows into `analytics_by_period` summaries.
compact:
	@sqlite3 $(DB_FILEPATH) < queries/repopulate-analytics-by-compaction.sql
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM analytics;"); \
	printf "✅ Total post-compaction rows in \`analytics\` table: %'d\n" $$total_rows
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM analytics_by_period;"); \
	printf "✅ Total post-compaction rows in \`analytics_by_period\` table: %'d\n" $$total_rows

# Run a query against the `analytics_by_period` table.
# Example: `make run query=get-single-total-executions unit=hour window="-7 days"`
# Example: `make run query=get-single-total-executions unit=hour window="-7 days" workflow=832F64FEB2F71CDE686BB1EDDE88A4FB`
run:
	@sed "s/:unit/'$(unit)'/g; s/:window/'$(window)'/g; s/:workflow_id/$(if $(workflow),'$(workflow)',NULL)/g" queries/$(query).sql | sqlite3 $(DB_FILEPATH)
