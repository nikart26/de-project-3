-- Delete
-- DELETE from mart.f_customer_retention 

Truncate table mart.f_customer_retention;

-- Update
insert into mart.f_customer_retention (period_id,
                                       new_customers_count, 
                                       returning_customers_count, 
                                       refunded_customer_count, 
                                       period_name, item_id, 
                                       new_customers_revenue, 
                                       returning_customers_revenue,
                                       customers_refunded)
with q as (
 select distinct
 	q1.period_id as period_id,
 	q1.customer_id as customer_id,
 	case when q1.status='shipped' and q1.cust_events_count = 1 then 'Y' else 'N' end as is_new_cust,
 	case when q1.status='refunded' then 'Y' end as is_refunded
 from 
	 	(select 
			(extract ('Year' from to_date(to_char(date_id, '99999999'), 'YYYYMMDD'))::text||extract ('week' from to_date(to_char(date_id, '99999999'), 'YYYYMMDD'))::text)::int4 as period_id,
			customer_id as customer_id,
			status as status,
			count (id) as cust_events_count
		from mart.f_sales 
		group by period_id, customer_id, status) q1),
	sq as (
	select 
		(extract ('Year' from to_date(to_char(date_id, '99999999'), 'YYYYMMDD'))::text||extract ('week' from to_date(to_char(date_id, '99999999'), 'YYYYMMDD'))::text)::int4 as period_id,
		customer_id as customer_id,
		status as status,
		item_id as item_id,
		count (id) as cust_events_count,
		sum(payment_amount) as revenue
	from mart.f_sales
	group by period_id, customer_id, status, item_id
		)		
			select 
			 	sq.period_id as period_id,
			 	count(case when sq.status='shipped' and q.is_new_cust = 'Y'  then 1 end) as new_customers_count,
			 	count(case when sq.status='shipped' and q.is_new_cust = 'N'  then 1 end) as returning_customers_count,
			 	count(case when sq.status='refunded' and q.is_refunded = 'Y' then 1 end) as refunded_customer_count,
			 	('weekly') as period_name,
			 	sq.item_id as item_id,
			 	sum (case when q.is_new_cust = 'Y' then sq.revenue end) as new_customers_revenue,
			 	sum (case when q.is_new_cust = 'N' then sq.revenue end) as returning_customers_revenue,
			 	sum (case when sq.status = 'refunded' then sq.cust_events_count end) as customers_refunded
		 	from sq left join q on q.period_id = sq.period_id and q.customer_id = sq.customer_id
		 	group by sq.period_id, sq.item_id
		;
