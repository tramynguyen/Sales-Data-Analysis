-- Inspecting data
select * 
from salesproject.dbo.sales_data_sample


--checking unique values
select distinct status from salesproject.dbo.sales_data_sample -- Nice one to plot
select distinct year_id from salesproject.dbo.sales_data_sample
select distinct PRODUCTLINE from salesproject.dbo.sales_data_sample -- Nice to plot
select distinct COUNTRY from salesproject.dbo.sales_data_sample    -- Nice to plot
select distinct DEALSIZE from salesproject.dbo.sales_data_sample    -- Nice to plot
select distinct TERRITORY from salesproject.dbo.sales_data_sample    -- Nice to plot

select distinct MONTH_ID from salesproject.dbo.sales_data_sample
where year_id = 2003

--ANALYSIS
---Let's start by grouping sales by productline

Select PRODUCTLINE, sum(SALES) as Revenue
from salesproject.dbo.sales_data_sample
group by PRODUCTLINE
order by 2 desc

select year_id, sum(SALES) as Revenue
from salesproject.dbo.sales_data_sample
group by year_id
order by 2 desc

select DEALSIZE, sum(SALES) as Revenue
from salesproject.dbo.sales_data_sample
group by DEALSIZE
order by 2 desc

---What was the best month for sales in a specific year? How much was earned that month?
select MONTH_ID, sum(SALES) Revenue, count(ORDERNUMBER) Frequency
from salesproject.dbo.sales_data_sample
where year_id = 2005
group by MONTH_ID
order by 2 desc

---November seems to be the best month, what product do they sell in November
select MONTH_ID, PRODUCTLINE, sum(SALES) Revenue, count(ORDERNUMBER) Frequency
from salesproject.dbo.sales_data_sample
where year_id = 2004 and MONTH_ID = 11
group by MONTH_ID, PRODUCTLINE
order by 3 desc

---Who is our best customer
Drop TABLE if EXISTS #rfm;
with rfm as
(
select 
CUSTOMERNAME,
sum(SALES) MonetaryValue,
avg(SALES) AvgMonetaryValue,
count(ORDERNUMBER) Frequency,
max(ORDERDATE) last_order_date,
(select max(ORDERDATE) from salesproject.dbo.sales_data_sample) max_order_date,
DATEDIFF(DD, max(ORDERDATE),(select max(ORDERDATE) from salesproject.dbo.sales_data_sample)) Recency
from salesproject.dbo.sales_data_sample
group by CUSTOMERNAME
),
rfm_calc as
(
select r. *,
NTILE(4) OVER (order by Recency desc) rfm_recency,
NTILE(4) OVER (order by Frequency) rfm_frequency,
NTILE(4) OVER (order by AvgMonetaryValue) rfm_monetary
from rfm r
)
select *, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME,
rfm_recency, rfm_frequency , rfm_monetary,
case 
	when rfm_cell_string in (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) then 'lost customers'
	when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344) then 'slipping away, cant lose'
	when rfm_cell_string in (311, 411, 331) then 'new customer'
	when rfm_cell_string in (222, 223, 233, 322) then 'potential chunners'
	when rfm_cell_string in (323, 333, 321, 422, 332, 432) then 'active'
	when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

---what products are most often sold together?
---select * from salesproject.dbo.sales_data_sample where ORDERNUMBER = '10411'


select distinct OrderNumber,  stuff(

	(select ',' + PRODUCTCODE
from salesproject.dbo.sales_data_sample p
where ORDERNUMBER in
(
select ORDERNUMBER 
from
(
select ORDERNUMBER, count(*) rn
from salesproject.dbo.sales_data_sample 
WHERE STATUS = 'Shipped'
group by ORDERNUMBER
)m
where rn = 2
)
and p.ORDERNUMBER = s.ORDERNUMBER
for xml path ('')), 1, 1, '') ProductCodes
from salesproject.dbo.sales_data_sample s
order by 2 desc