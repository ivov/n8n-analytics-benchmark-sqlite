# n8n-analytics-benchmark-sqlite

```sh
make setup
make measure-disk-space
make benchmark-latency
make benchmark-throughput
```

Events per year assuming 10 events per execution, based on real user data points:

```
541,000 ex/day → 197,465,000 ex/year →   1,974,650,000 events/year
100,000 ex/day → 36,500,000 ex/year →      365,500,000 events/year
36,600 ex/day → 13,140,000 ex/year →       131,400,000 events/year
```

Test Result Napkin Math: 8 queries * 2 compaction schedule * 3 parameters (wf id, project id, nothing) = 48 sets of percentiles

## ToDo Until Monday

- [x] turn type into int
- [x] store dates as epoch maybe?
- [ ] run benchmark on cloud

## ToDo For Implementation
- [ ] evaluate if batching writes is worth it


