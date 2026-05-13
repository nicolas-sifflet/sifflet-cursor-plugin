---
name: sifflet-quality-as-code
description: Draft and refine Sifflet monitor and workspace YAML using the Sifflet MCP server plus the official Monitors as Code schema. Use when the user wants monitor YAML, workspace.yaml, dataset resolution, monitor-as-code guidance, or Sifflet CLI apply steps.
---

# Sifflet Quality as Code (Monitors as Code)

## Use this for

- `workspace.yaml` authoring or updates
- Monitor YAML creation or review
- Dataset, URN, owner, or lineage discovery before writing YAML
- Converting monitor ideas into schema-valid Monitor v2 files
- Planning `sifflet code workspace plan` and `sifflet code workspace apply`

## Workflow

### Source of truth

The official **[Monitor schema](https://docs.siffletdata.com/docs/monitor-schema)** is mandatory context whenever drafting or reviewing monitor YAML. Use it as the source of truth for top-level fields, required fields, monitor identity (`id` vs `friendlyId`), dataset references, notifications, tags, terms, schedules, and destructive-change behavior. Use **[Parameters per monitor type](https://docs.siffletdata.com/docs/parameters-per-monitor-type)** only for the `parameters` payload after the monitor type is chosen.

### 1) Discover inputs with MCP

Use the **Sifflet** MCP server when available to resolve real catalog objects before writing YAML:

- Use `search_asset` or `asset_by_urn` to resolve dataset IDs, URIs, owners, and tags.
- Use `get_monitor_details_by_id` when the user wants to copy or adapt an existing monitor.
- Use `get_downstream_assets_of_asset` when change impact matters.
- If MCP is unavailable, ask the user for the dataset reference that the official schema accepts: `uri`, `id`, unambiguous `name`, or `name` plus datasource context.

### 2) Choose monitor type and ask only what the docs require

Before calling `get_monitor_code_by_description` or hand-writing `parameters`, fix **`parameters.kind`** from the user goal, then **ask the user** for any missing inputs below. Skip questions already answered or obvious from the dataset (e.g. time column from schema). Authoritative shapes live in **[Parameters per monitor type](https://docs.siffletdata.com/docs/parameters-per-monitor-type)** and **[Monitor schema](https://docs.siffletdata.com/docs/monitor-schema)**.

| `parameters.kind` | Ask when needed (non-exhaustive; extend from docs) |
|---------------------|------------------------------------------------------|
| **Volume** | Static vs dynamic threshold? If static: min/max, comparison mode (absolute vs relative %)? **Time window**: timestamp field name (or `auto`), `frequency`, `firstRun`, `offsetPeriods`? **Partition** (e.g. BigQuery ingestion)? **WHERE** / **groupBy** slice? |
| **Freshness** | Same threshold/time-window style as Volume where applicable; confirm incremental expectations vs defaults. |
| **MetadataFreshness** | **Static threshold only** supports `comparisonMode: Absolute` per docs—max gap in **seconds**? (Supported sources: BigQuery, Databricks, MySQL, Oracle, Snowflake.) |
| **RowDuplicates** / **Duplicates** (row-level) | Accept default sensitivity or specify static threshold (e.g. max duplicate rate)? **Time window** + **partition** if incremental/partitioned table? |
| **SchemaChange** | Usually minimal—confirm single target dataset. |
| **Metrics** | **Field name** (required). **Aggregation** (`Average`, `Sum`, `Quantile` + quantile value, …)? **Threshold** static/dynamic and bounds? **Time window** field / `firstRun` / `frequency`? **WHERE** / **groupBy** / **partition**? |
| **CustomMetrics** | Full **SQL**; confirm result columns match docs (numeric metric, optional time column, optional group-by dimension—no invented alias for dimension). Threshold bounds, **timeWindow** `offsetPeriods`, **partition**? |
| **FieldNulls** | **Field** name. **valueMode**: `Count` vs `Percentage`? Static max nulls / max %? Time window + WHERE + groupBy + partition if not simple? |
| **FieldDuplicates** | Same pattern as **FieldNulls** but for duplicate values on a field. |
| **Distribution** | **Field** (categorical). Static vs dynamic threshold? **Reference**: fixed date vs rolling delay? `onAddedCategory` / `onRemovedCategory`? **Time window** `duration` (days) and `offsetPeriods`? |
| **FieldInList** | **Field** + explicit `values` list (required). Optional WHERE / groupBy / timeWindow / partition. |
| **FieldFormat** | **Field** + **format** (`Email`, `Phone`, `UUID`, `Regex` + pattern). Regex not on MS SQL per docs. |
| **Sql** | Full **SQL**; monitor fails when the query returns one or more rows—confirm that matches intent. **Partition** if needed? |
| **CorrelatedMetrics** | Exactly **two** metrics (one per dataset); field + aggregation each; joint **threshold**; **timeWindow**. |
| **Conditional** | Full **condition** tree (`equals`, `andGroup`, …); **threshold** (e.g. max failing rows). Multi-dataset field refs need `dataset.id` disambiguation per docs. |

Then pass resolved answers into a natural-language **`description`** plus **`dataset_ids`** for `get_monitor_code_by_description`, or encode directly in YAML and validate with **`sifflet code workspace plan`**.

### 3) Draft YAML carefully

- `get_monitor_code_by_description` is a drafting helper only.
- Validate every draft against the official docs before treating it as final:
  - [Monitor schema](https://docs.siffletdata.com/docs/monitor-schema) (mandatory source of truth)
  - [Workspace schema](https://docs.siffletdata.com/docs/workspace-schema)
  - [Parameters per monitor type](https://docs.siffletdata.com/docs/parameters-per-monitor-type)
- Monitors must use `kind: Monitor` and `version: 2`; Monitor v1 is deprecated.
- Monitors require `name`, `incident.severity`, at least one dataset, and `parameters.kind`.
- Prefer stable dataset references: `uri`, `id`, or datasource-qualified names when ambiguity is possible.
- Explain `id` vs `friendlyId` trade-offs if the user is choosing monitor identity strategy. Changing `id`, or changing datasets behind a `friendlyId`, can recreate monitors and affect history.

### 4) Keep workspace layout simple

For a new workspace, prefer the official CLI init flow when the user has the Sifflet CLI available:

```bash
sifflet code workspace init --file workspace.yaml --name "<workspace name>"
sifflet code monitor init --file monitors/<monitor-name>.yaml --name "<monitor name>"
```

If creating files manually, keep the repository shape easy to review:

```text
quality/
├── workspace.yaml
└── monitors/
    ├── monitor-a.yaml
    └── monitor-b.yaml
```

- Keep monitor files small and focused.
- Use multi-document YAML only if the team explicitly wants it.
- Keep workspace `include` and `exclude` globs easy to reason about.

### 5) Apply safely

- Prefer:
  1. `sifflet code workspace plan --file workspace.yaml`
  2. Review output
  3. `sifflet code workspace apply --file workspace.yaml`
- For CI/CD, use `sifflet code workspace apply --file workspace.yaml --auto-approve` only after the workspace is reviewed.
- Mention destructive implications when monitor files are removed or monitor IDs change. Deleting a monitor file, or changing an existing monitor `id`, can delete the previous monitor and associated data.
- Remind users that workspace-managed monitors become read-only in the UI.
