DB_FILEPATH := /data/benchmark-dbs/analytics-benchmark.sqlite
DB_FILENAME := $(notdir $(DB_FILEPATH))
# N8N_VERSION := 1.75.2
CONTAINER_NAME := $(shell openssl rand -base64 24 | tr -dc 'a-zA-Z0-9')

setup: nuke create populate

benchmark-baseline:
	hyperfine --warmup 2 --export-csv baseline.csv \
		'make run query=baseline'

benchmark-queries:
	hyperfine --warmup 2 --export-csv result-queries.csv \
		'make run query=get-breakdown-by-workflow' \
		'make run query=get-periodic-total-executions' \
		'make run query=get-periodic-total-failed-executions' \
		'make run query=get-periodic-total-failure-rate' \
		'make run query=get-periodic-total-time-saved' \
		'make run query=get-single-total-executions' \
		'make run query=get-single-total-failed-executions' \
		'make run query=get-single-total-failure-rate' \
		'make run query=get-single-total-time-saved'

setup-events-benchmark:
	@parallel 'make DB_FILEPATH=/data/benchmark-dbs/analytics-benchmark-events{1}-v{2}.sqlite setup analytics={1}000000 compact version={2}' \
	::: 1 2 4 8 16 \
	::: 1

benchmark-events:
	hyperfine --warmup 2 --export-csv result-events-${query}.csv \
		--parameter-list events 1,2,4,8,16 \
		--parameter-list version 1 \
		--command-name 'v{version} - events: {events}' \
		'make DB_FILEPATH=/data/benchmark-dbs/analytics-benchmark-events{events}-v{version}.sqlite run query=${query}'

setup-workflow-benchmark:
	@parallel 'make DB_FILEPATH=/data/benchmark-dbs/analytics-benchmark-wfs{1}-v{2}.sqlite setup workflows={1} compact version={2}' \
	::: 125 250 500 1000 \
	::: 1

benchmark-workflows:
	hyperfine --warmup 2 --export-csv result-workflows-${query}.csv \
		--parameter-list wfs 125,250,500,1000 \
		--parameter-list version 1 \
		--command-name 'v{version} - wfs: {wfs}' \
		'make DB_FILEPATH=/data/benchmark-dbs/analytics-benchmark-wfs{wfs}-v{version}.sqlite run query=${query}'

setup-projects-benchmark:
	@parallel 'make DB_FILEPATH=/data/benchmark-dbs/analytics-benchmark-projects{1}-v{2}.sqlite setup projects={1} compact version={2}' \
	::: 50 100 200 400 800 \
	::: 1

benchmark-projects:
	hyperfine --warmup 2 --export-csv result-projects-${query}.csv \
		--parameter-list projects 50,100,200,400,800 \
		--parameter-list version 1 \
		--command-name 'v{version} - projects: {projects}' \
		'make DB_FILEPATH=/data/benchmark-dbs/analytics-benchmark-projects{projects}-v{version}.sqlite run query=${query}'

# Remove the benchmark DB.
nuke:
	@rm $(DB_FILEPATH) || true

# Start n8n to create an empty sqlite DB with all migrations applied.
create:
	@cp /data/database.sqlite $(DB_FILEPATH)
# 	@docker run --rm --name '$(CONTAINER_NAME)' \
# 	-v ~/.n8n:/home/node/.n8n \
# 	-e DB_SQLITE_DATABASE=/home/node/.n8n/$(DB_FILENAME) \
# 	n8nio/n8n:$(N8N_VERSION) > /dev/null & \
# 	while ! docker logs '$(CONTAINER_NAME)' 2>&1 | grep -q "Editor is now accessible"; do sleep 1; done && \
# 	docker stop $(CONTAINER_NAME) > /dev/null && \
# 	echo "✅ DB set up at: $(DB_FILEPATH)"

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
	printf "✅ Total rows in \`workflow_entity\` table: %d\n" $$total_rows

# Populate the `analytics` table in the benchmark DB.
analytics:
	@echo 'Populate metadata'
	@cat queries/populate-analytics-metadata.sql | sqlite3 $(DB_FILEPATH)
	@echo 'Populate analytics'
	@sed 's/:num_events/$(shell echo $(n) | tr -d ',')/g' queries/populate-analytics.sql | sqlite3 $(DB_FILEPATH)
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM analytics;"); \
	printf "✅ Total pre-compaction rows in \`analytics\` table: %d\n" $$total_rows
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM analytics_by_period;"); \
	printf "✅ Total pre-compaction rows in \`analytics_by_period\` table: %d\n" $$total_rows

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
	printf "✅ Total post-compaction rows in \`analytics\` table: %d\n" $$total_rows
	@total_rows=$$(sqlite3 $(DB_FILEPATH) "SELECT COUNT(*) FROM analytics_by_period;"); \
	printf "✅ Total post-compaction rows in \`analytics_by_period\` table: %d\n" $$total_rows

# Run a query against the `analytics_by_period` table.
# Examples: 
#    make run query=get-single-total-executions unit=hour window="-7 days"
#    make run query=get-single-total-executions unit=hour window="-7 days" workflow_id=832F64FEB2F71CDE686BB1EDDE88A4FB
#    make run query=get-breakdown-by-workflow window="-7 days" project_id=E0E058A25F43D1640267B4963CC5FE7A
#    make run query=get-breakdown-by-workflow window="-7 days" limit=35 offset=0
run:
	sed "s/:unit/$(if $(unit),$(unit),0)/g; \
	s/:window/$(if $(window),'$(window)','-1 year')/g; \
	s/:workflow_id/$(if $(workflow_id),'$(workflow_id)',NULL)/g; \
	s/:project_id/$(if $(project_id),'$(project_id)',NULL)/g; \
	s/:limit/$(if $(limit),$(limit),15)/g; \
	s/:offset/$(if $(offset),$(offset),0)/g" \
	queries/$(query).sql | sqlite3 $(DB_FILEPATH)

benchmark-latency:
	@chmod +x ./benchmark-latency.sh && ./benchmark-latency.sh $(DB_FILEPATH)
