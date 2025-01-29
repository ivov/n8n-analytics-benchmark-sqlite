DB_FILEPATH := $(HOME)/.n8n/analytics-benchmark.sqlite
DB_FILENAME := $(notdir $(DB_FILEPATH))
N8N_VERSION := 1.75.2

setup: nuke create populate

# Remove the benchmark DB.
nuke:
	@rm $(DB_FILEPATH) || true

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

# Populate the benchmark DB with workflows and analytics events.
# Defaults: 500 workflows, 50 projects, 1m analytics events
# Example: 
#   make populate workflows=700 projects=100 analytics=500,000
populate:
	@make workflows n=$(if $(workflows),$(workflows),500)
	@make projects n=$(if $(projects),$(projects),50)
	@make analytics n=$(if $(analytics),$(analytics),1000000)

# Populate the `workflow_entity` table in the benchmark DB.
workflows:
	@sed 's/:num_workflows/$(shell echo $(n) | tr -d ',')/g' queries/populate-workflows.sql | sqlite3 $(DB_FILEPATH)
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM workflow_entity;"); \
	printf "✅ Total rows in \`workflow_entity\` table: %'d\n" $$total_rows

# Populate the `analytics` table in the benchmark DB.
analytics:
	@sed 's/:num_events/$(shell echo $(n) | tr -d ',')/g' queries/populate-analytics.sql | sqlite3 $(DB_FILEPATH)
	@chmod +x randomize-workflow-ids.sh && ./randomize-workflow-ids.sh $(DB_FILEPATH)
	@cat queries/populate-analytics-metadata.sql | sqlite3 $(DB_FILEPATH)
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM analytics;"); \
	printf "✅ Total pre-compaction rows in \`analytics\` table: %'d\n" $$total_rows
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM analytics_by_period;"); \
	printf "✅ Total pre-compaction rows in \`analytics_by_period\` table: %'d\n" $$total_rows

# Populate the `project` table with team projects in the benchmark DB.
projects:
	@sed 's/:num_projects/$(shell echo $(n) | tr -d ',')/g' queries/populate-projects.sql | sqlite3 $(DB_FILEPATH)

# Process all `analytics` rows into `analytics_by_period` summaries.
# Example: make compact version=2
compact:
	@if [ -z "$(version)" ]; then \
		echo "Error: version parameter required. Example: make compact version=1" >&2; \
		exit 1; \
	fi
	@sqlite3 $(DB_FILEPATH) < queries/compact-analytics-v$(version).sql
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM analytics;"); \
	printf "✅ Total post-compaction rows in \`analytics\` table: %'d\n" $$total_rows
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM analytics_by_period;"); \
	printf "✅ Total post-compaction rows in \`analytics_by_period\` table: %'d\n" $$total_rows

# Run a query against the `analytics_by_period` table.
# Examples: 
#    make run query=get-single-total-executions unit=hour window="-7 days"
#    make run query=get-single-total-executions unit=hour window="-7 days" workflow=832F64FEB2F71CDE686BB1EDDE88A4FB
#    make run query=get-breakdown-by-workflow window="-7 days" limit=35 offset=0
run:
	@sed "s/:unit/'$(unit)'/g; \
	s/:window/'$(window)'/g; \
	s/:workflow_id/$(if $(workflow),'$(workflow)',NULL)/g; \
	s/:limit/$(if $(limit),$(limit),15)/g; \
	s/:offset/$(if $(offset),$(offset),0)/g" \
	queries/$(query).sql | sqlite3 $(DB_FILEPATH)
