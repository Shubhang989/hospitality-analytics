----------------------------------------------------------------------------
-- SHOWDE HOSPITALITY PROJECT GROUP-5 
----------------------------------------------------------------------------

Create database showdehotels;
use showdehotels;
show tables;

-- DATA TYPE CHANGES (run first, so date joins below compare DATE to DATE)
ALTER TABLE showdehotels.dim_date ADD date_new DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE showdehotels.dim_date
SET date_new = STR_TO_DATE(date, '%d-%b-%y');
ALTER TABLE showdehotels.dim_date DROP date;
ALTER TABLE showdehotels.dim_date CHANGE date_new date DATE;

-- DATA COUNT VALIDATION
SELECT COUNT(*) FROM dim_hotels;         
SELECT COUNT(*) FROM dim_rooms;               
SELECT COUNT(*) FROM dim_date;                  
SELECT COUNT(*) FROM fact_bookings;              
SELECT COUNT(*) FROM fact_aggregated_bookings;    

-- DATA COMPLETENESS CHECK
SELECT * FROM fact_bookings WHERE property_id IS NULL OR check_in_date IS NULL OR room_category IS NULL;
SELECT * FROM fact_bookings WHERE booking_status NOT IN ('Checked Out','Cancelled','No Show');
SELECT COUNT(*) FROM fact_bookings WHERE ratings_given IS NULL AND booking_status = 'Checked Out';

-- DATA CONSISTENCY CHECK 
SELECT fb.property_id
FROM fact_bookings fb
LEFT JOIN dim_hotels dh ON fb.property_id = dh.property_id
WHERE dh.property_id IS NULL;
SELECT fb.room_category
FROM fact_bookings fb
LEFT JOIN dim_rooms dr ON fb.room_category = dr.room_id
WHERE dr.room_id IS NULL;
SELECT fb.check_in_date
FROM fact_bookings fb
LEFT JOIN dim_date dd ON fb.check_in_date = dd.date
WHERE dd.date IS NULL;

-- DUPLICATE RECORDS CHECK 
SELECT booking_id, COUNT(*)
FROM fact_bookings
GROUP BY booking_id
HAVING COUNT(*) > 1;
SELECT property_id, check_in_date, room_category, COUNT(*)
FROM fact_aggregated_bookings
GROUP BY property_id, check_in_date, room_category
HAVING COUNT(*) > 1;

-- DASHBOARD AGGREGATION CHECK
SELECT SUM(revenue_realized) FROM fact_bookings;                         
SELECT SUM(revenue_realized) / (SELECT SUM(successful_bookings) FROM fact_aggregated_bookings) FROM fact_bookings;  -- ADR       
SELECT SUM(successful_bookings)*100.0 / SUM(capacity) FROM fact_aggregated_bookings; 
SELECT COUNT(*)*100.0 / (SELECT COUNT(*) FROM fact_bookings)
  FROM fact_bookings WHERE booking_status = 'Cancelled';                  
SELECT SUM(revenue_realized) / (SELECT SUM(capacity) FROM fact_aggregated_bookings)
  FROM fact_bookings;  -- RevPAR (capacity summed once, from the aggregated table)
    
   
#---------------------KPI_ANALYSIS--------------#

#------------------------- Total Revenue---------------------------#
select sum(revenue_realized) as 'Total Revenue'
from fact_bookings;

#---------------- ADR- AVERAGE DAILY RATE--------#
-- ADR = room revenue / room-nights sold
select sum(revenue_realized)/(select sum(successful_bookings) from fact_aggregated_bookings) as ADR
from fact_bookings;

#----------------RevPAR-------------------#
select sum(revenue_realized)/(select sum(capacity) from fact_aggregated_bookings) as RevPAR
from fact_bookings;

#-------------------Revenue by City-------------------#
select h.city, sum(f.revenue_realized) as Revenue
from fact_bookings f 
JOIN dim_hotels h
ON f.property_id = h.property_id
GROUP BY h.city;

#--------------Revenue By Month-----------------#
SELECT 
    MONTHNAME(check_in_date) AS month,
    SUM(revenue_realized) AS Revenue
FROM showdehotels.fact_bookings
GROUP BY 
    MONTH(check_in_date),
    MONTHNAME(check_in_date)
ORDER BY 
    MONTH(check_in_date);

#-------------------Total Successful Bookings-------------------#
select  sum(successful_bookings) as Total_Successful_Bookings
from fact_aggregated_bookings;

#--------------------Total Cancelled Bookings------------------#
SELECT 
    COUNT(booking_id) AS `Total Cancelled Bookings`
FROM showdehotels.fact_bookings
WHERE booking_status = 'Cancelled';

#-------------------Total No Show Bookings---------------------#
select count(*) as `No Show Bookings`
from fact_bookings
where booking_status = 'No Show';

#-------------------Booking % By Room Class----------#
select r.room_class, count(*) * 100.0/(select count(*) from fact_bookings) as Booking_Rate
from fact_bookings f 
JOIN dim_rooms r
ON f.room_category = r.room_id
GROUP BY r.room_class;

#----------------------Total Capacity---------------#
select sum(capacity) as Total_Capacity
From fact_aggregated_bookings; 

#----------------------Occupancy %---------------#
select sum(successful_bookings)/sum(capacity)*100.0 as Occupancy_Percentage
From fact_aggregated_bookings;

#-----------------------Cancellation %--------#
select
sum(case 
    when booking_status= 'Cancelled' then 1 else 0 end) * 100.0/ count(*) as Cancellation_Percentage
From fact_bookings;

#--------------------No Show %--------#
select
sum(case
    when booking_status='No Show' then 1 else 0 end) * 100.0/count(*) as No_Show_Percentage
From fact_bookings;    

#-------------------Cancellation % By Booking Channel--------#
select booking_channel,
sum(case
    when booking_status = 'Cancelled' then 1 else 0 end) * 100.0/count(*) as Cancellation
from fact_bookings
GROUP BY booking_channel;    
                        
#------------------Checked-Out % (booking realization)------#
select sum(case
           when booking_status = 'Checked Out' then 1 else 0
           end)*100.0 /
       sum(case
           when booking_status IN('Checked Out','Cancelled','No Show') then 1 else 0
           end) as Checked_Out_Percentage
 From fact_bookings;

#------------------Revenue Realization % (matches Power BI)------#
select sum(revenue_realized)*100.0/sum(revenue_generated) as Revenue_Realization_Percentage
from fact_bookings;          
 
 ------------------------------ END-----------------------------------------------------------
                        







