
    
      
    

    create  table
      "dev"."main"."stg_orders__dbt_tmp"
  
  (
    order_id integer not null,
    customer_id integer not null,
    order_status varchar,
    amount double,
    order_date date
    
    )
 ;
    
    
    insert into "dev"."main"."stg_orders__dbt_tmp" 
  (
    
      
      order_id ,
    
      
      customer_id ,
    
      
      order_status ,
    
      
      amount ,
    
      
      order_date 
    
  )
 (
      
    select order_id, customer_id, order_status, amount, order_date
    from (
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
from "dev"."main"."raw_orders"
    ) as model_subq
    );
  