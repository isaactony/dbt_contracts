
    

    create  table
      "dev"."main"."downstream_order_metrics__dbt_tmp"
  
    
    as (
      -- Owned by the Analytics team, a completely different team from the
-- one that owns stg_orders. This model has no visibility into the
-- Orders team's source system, only into the contracted shape of
-- stg_orders. If that shape changes without the contract catching it,
-- this model breaks (or worse, silently returns wrong numbers) with
-- no warning to the Analytics team.

select
    order_status,
    count(*) as order_count,
    sum(amount) as total_amount
from "dev"."main"."stg_orders"
group by order_status
    );
    
  