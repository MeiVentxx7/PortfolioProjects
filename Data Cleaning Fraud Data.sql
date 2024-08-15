/*

Cleaning Data in SQL Queries

Skills used: Aggregate functions, date functions, CASE expression, window functions, CTE, 
*/


select top 10 * from DataCleaningProject.dbo.fraud_data


---------------------------------------------------------------------------

-- Extract the date data from trans_date_trans_time column

select trans_date_trans_time, cast(trans_date_trans_time as date) as trans_date
from DataCleaningProject.dbo.fraud_data

 -- Add a new column [trans_date]
 Alter table dbo.fraud_data
 add trans_date DATE

 update dbo.fraud_data
 set trans_date = cast(trans_date_trans_time as date)



 ---------------------------------------------------------------------------

 -- Extract Year and Month and make each column

 -- YEAR
 alter table DataCleaningProject.dbo.fraud_data
 add trans_year int

 update DataCleaningProject.dbo.fraud_data
 set trans_year = YEAR(trans_date_trans_time)

 -- MONTH
 alter table DataCleaningProject.dbo.fraud_data
 add trans_month int

 update DataCleaningProject.dbo.fraud_data
 set trans_month = MONTH(trans_date_trans_time)


---------------------------------------------------------------------------

-- Remove " And update merchant column

UPDATE DataCleaningProject.dbo.fraud_data
SET merchant = REPLACE(merchant, '"', '')


select merchant from DataCleaningProject.dbo.fraud_data


---------------------------------------------------------------------------

-- Round the amount [amt]

select amt, round(amt, 2) 
from DataCleaningProject.dbo.fraud_data

-- update the column [amt]

update dbo.fraud_data
set amt = round(amt, 2) 


---------------------------------------------------------------------------


-- Extract age and make a new column [age]

select datediff(YEAR, dob, cast(trans_date_trans_time as date)) as age 
from DataCleaningProject.dbo.fraud_data


-- Create a new column [age]
 
alter table dbo.fraud_data
add age int

update dbo.fraud_data
set age = datediff(YEAR, dob, cast(trans_date_trans_time as date))



---------------------------------------------------------------------------

-- Remove " from the job column

update dbo.fraud_data
set job = replace(job, '"', '')

select * from DataCleaningProject.dbo.fraud_data


---------------------------------------------------------------------------

-- Change 1 and 0 to Yes and No [is_fraud]

-- Check distinct values in [is_fraud]

select distinct(is_fraud)
from DataCleaningProject.dbo.fraud_data

select count(*)
from DataCleaningProject.dbo.fraud_data
where is_fraud is null


-- Since there are only 2 null values, delete those rows with the null values.

delete from dbo.fraud_data
where is_fraud is null


-- Now, let's change 1 and 0 to Yes and No [is_fraud]

select is_fraud,
  case when is_fraud = 1 then 'Yes'
	else 'No'
	end
from DataCleaningProject.dbo.fraud_data


-- Change the data type

alter table dbo.fraud_data
alter column is_fraud nvarchar(20)

-- Update the column 

update dbo.fraud_data
set is_fraud =
 case when is_fraud = 1 then 'Yes'
	else 'No'
	end


---------------------------------------------------------------------------

-- Remove Duplicates

-- Assign a number for each row in a new column

select *, 
		ROW_NUMBER() OVER (
		PARTITION BY trans_date_trans_time,
						merchant,
						category,
						amt,
						is_fraud
						order by trans_date_trans_time
						) as row_num
from DataCleaningProject.dbo.fraud_data
order by trans_date_trans_time


-- Put the above in a CTE and delete duplicates

WITH RowNumCTE as (
select *, 
		ROW_NUMBER() OVER (
		PARTITION BY trans_date_trans_time,
						merchant,
						category,
						amt,
						is_fraud
						order by trans_date_trans_time
					) as row_num
from DataCleaningProject.dbo.fraud_data
-- order by trans_date_trans_time
)

DELETE FROM RowNumCTE 
where row_num > 1



---------------------------------------------------------------------------

-- Delete unused columns

select * from DataCleaningProject.dbo.fraud_data

alter table DataCleaningProject.dbo.fraud_data
drop column lat, long, trans_num, merch_lat, merch_long




---------------------------------------------------------------------------



/*

EDA and queries for Tableau dashboard

Skills used: Aggregate functions, date functions, CASE expression

*/



-- Q1. Which state have the highest fraudulent transaction percentage?

SELECT state, count(*) as total_trans, 
sum(case when is_fraud = 'Yes' then 1 else 0 end) as total_fraud_trans,
(sum(case when is_fraud = 'Yes' then 1 else 0 end)*100 / count(*)) as fraud_percentage
from DataCleaningProject.dbo.fraud_data
group by state
order by 4 desc

-- AK has the highest percentage 
-- However, fraudulent transactions were made in CA the most


---------------------------------------------------------------------------

 -- Q2. Are older people more likely to be targeted? 
 -- Is there a correlation between age and occurence of fraud transactions?

 select age, sum(amt) as total_amt, count(trans_date_trans_time)
 from DataCleaningProject.dbo.fraud_data
 where is_fraud = 'Yes'
 group by age
 order by 1 desc

 -- There is no big difference between younger people and older people

 ---------------------------------------------------------------------------

 -- Q3. In which month fruadulent transactions were made the most?
 
SELECT trans_month, count(is_fraud) as fraud_trans_count
from DataCleaningProject.dbo.fraud_data
where is_fraud = 'Yes'
group by trans_month
order by 2 desc

-- The total of fraud transactions are about the same for all months


---------------------------------------------------------------------------

-- Q4. Did the fraud transaction rate get lower over the year?
-- Let's see the percentage of fraud transaction commpare to the entire transaction per year.

select trans_year, count(*) as total_trans, 
sum(case when is_fraud = 'Yes' then 1 else 0 end) as total_fraud_trans,
(sum(case when is_fraud = 'Yes' then 1 else 0 end)*100 / count(*)) as fraud_percentage
from DataCleaningProject.dbo.fraud_data
group by trans_year
order by trans_year


-- It's only 1% lower 


---------------------------------------------------------------------------

-- Q5. Is there a correlation between transaction hours and occurence?

select DATEPART(HOUR, trans_date_trans_time) as trans_hour, count(is_fraud) as fraud_count
from DataCleaningProject.dbo.fraud_data
where is_fraud = 'Yes'
group by DATEPART(HOUR, trans_date_trans_time)
order by 2 desc


-- Most fraud transactions occured around midnight.


---------------------------------------------------------------------------

-- Q6. Which categories have the higher percentage of fraud transactions compare to total transactions?

select category, count(*) as total_trans,
sum(case when is_fraud = 'Yes' then 1 else 0 end) as fraud_trans,
(sum(case when is_fraud = 'Yes' then 1 else 0 end) * 100 / count(*)) as fraud_percentage
from DataCleaningProject.dbo.fraud_data
group by category
order by 4 desc


-- Top 5 category: grocery_pos, shopping net, misc_net, shopping_pos, gas_transport


---------------------------------------------------------------------------

-- Q7. Which cities have the higher percentage of fradulent transactions compared to the total?

select city, count(*) as total_trans,
sum(case when is_fraud = 'Yes' then 1 else 0 end) as fraud_trans,
(sum(case when is_fraud = 'Yes' then 1 else 0 end) * 100 / count(*)) as fraud_percentage
from DataCleaningProject.dbo.fraud_data
group by city
order by 4 desc


-- Some cities have 100% of fraud transaction rate
-- Not enough data to see the correlation between cities and occurence.


---------------------------------------------------------------------------
-- Use Q1, Q2, Q4, Q5, Q6, Q7 for Tableau visualization


