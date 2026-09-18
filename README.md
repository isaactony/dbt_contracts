# Data contract demo: catching a breaking schema change before it merges

A minimal, real, runnable dbt project demonstrating the scenario from the
article outline: a producer team renames a column, and instead of that
break surfacing three days later in a downstream team's dashboard, it
fails the pull request itself.

Everything here actually ran. The command output below is copied straight
from a real `dbt build`, not written up from memory.

## Structure

```
seeds/raw_orders.csv                        raw data, as if landed from a source system
models/producer/stg_orders.sql               producer-owned model, contract-enforced
models/producer/producer.yml                 the contract: exact column names + types
models/consumer/downstream_order_metrics.sql  a different team's model, built on stg_orders
.github/workflows/dbt-contract-check.yml      the CI job that enforces the contract on every PR
```

No warehouse, no credentials. It runs on DuckDB against a local file, so
`dbt build` works the same on a laptop as it would in CI.

## Running it

```bash
pip install dbt-core dbt-duckdb
export DBT_PROFILES_DIR=$(pwd)/dbt_profile
dbt build
```

Real output on a clean build:

```
2 of 3 START sql table model main.stg_orders ................ [RUN]
2 of 3 OK created sql table model main.stg_orders ............ [OK in 0.11s]
3 of 3 START sql table model main.downstream_order_metrics ... [RUN]
3 of 3 OK created sql table model main.downstream_order_metrics [OK in 0.02s]

Done. PASS=3 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=3
```

## Reproducing the break

Open `models/producer/stg_orders.sql` and change:

```sql
amount,
```

to:

```sql
amount as order_amount,
```

Then run `dbt build` again. This is the real error it produces, no
downstream model even attempts to run:

```
2 of 3 ERROR creating sql table model main.stg_orders ........ [ERROR in 0.08s]
3 of 3 SKIP relation main.downstream_order_metrics ........... [SKIP]

Compilation Error in model stg_orders (models/producer/stg_orders.sql)
  This model has an enforced contract that failed.
  Please ensure the name, data_type, and number of columns in your
  contract match the columns in your model's definition.

  | column_name  | definition_type | contract_type | mismatch_reason       |
  | ------------- | --------------- | ------------- | --------------------- |
  | amount        |                 | DOUBLE        | missing in definition |
  | order_amount  | DOUBLE          |               | missing in contract   |
```

That's the whole demo. `stg_orders` fails to build, `downstream_order_metrics`
never even attempts to run against a shape that changed underneath it, and
in the GitHub Actions workflow in this repo, that failure is exactly what
would show up as a red X on the pull request, before anything merges.

## A real thing this surfaced while building it

The contract was written with `order_id` and `customer_id` as `bigint` on
the first attempt, and DuckDB's own CSV type inference actually assigned
them 32-bit `integer`. The very first `dbt build` failed on that mismatch,
which is a genuine, small demonstration of how exactly contracts check,
strict enough to catch even an integer-width mismatch that would never
show up as a bug anyone would notice by eye.

## What this does and doesn't protect against

It catches structural breaks: a renamed column, a changed type, a column
that disappears. It does not catch semantic drift: the same column, same
name, same type, but the business logic upstream quietly changed what a
value means. That's a real limitation worth stating plainly rather than
implying contracts solve data quality end to end. For that layer, this
project would need to be paired with something like Great Expectations
or dbt's own data tests (not just contract enforcement) checking value
ranges and distributions, not just shape.
