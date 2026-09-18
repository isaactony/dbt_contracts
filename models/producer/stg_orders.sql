-- Owned by the Orders team.
-- This is the producer-side model. Its column names and types are locked
-- in by the contract declared in producer.yml. Any change here that
-- doesn't match that contract fails the dbt build, in CI, before merge.

select
    order_id,
    customer_id,
    order_status,
    amount,
    order_date
from {{ ref('raw_orders') }}
