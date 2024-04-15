/*
Question #1:
Calculate the number of flights with a departure time during the work week (Monday through Friday) and the number of flights departing during the weekend (Saturday or Sunday).

Expected column names: working_cnt, weekend_cnt
*/

-- q1 solution:

--This query counts the number of flights during the week and weekend. 
SELECT 
  SUM(CASE WHEN EXTRACT(DOW FROM departure_time) NOT IN(0, 6) THEN 1 ELSE 0 END) AS working_cnt,
	SUM(CASE WHEN EXTRACT(DOW FROM departure_time) IN(0, 6) THEN 1 ELSE 0 END) AS weekend_cnt
FROM flights;

/*

Question #2: 
For users that have booked at least 2  trips with a hotel discount, it is possible to calculate their average hotel discount, and maximum hotel discount. write a solution to find users whose maximum hotel discount is strictly greater than the max average discount across all users.

Expected column names: user_id

*/

-- q2 solution:

--This part screens the users to inckude only desired ones.
WITH users_screener AS(
	SELECT user_id, AVG(hotel_discount_amount) AS avg_discount,
  	MAX(hotel_discount_amount) AS max_discount
	FROM sessions
	WHERE cancellation = FALSE
		AND hotel_discount = TRUE
  	AND (hotel_booked = TRUE OR flight_booked = TRUE) --A trip was booked.
	GROUP BY user_id
	HAVING COUNT(*) >=2)

--This part returns only the users with max discount greater than the overall max discount.
SELECT user_id
FROM users_screener
WHERE max_discount > (SELECT MAX(avg_discount) FROM users_screener);

/*
Question #3: 
when a customer passes through an airport we count this as one “service”.

for example:

suppose a group of 3 people book a flight from LAX to SFO with return flights. In this case the number of services for each airport is as follows:

3 services when the travelers depart from LAX

3 services when they arrive at SFO

3 services when they depart from SFO

3 services when they arrive home at LAX

for a total of 6 services each for LAX and SFO.

find the airport with the most services.

Expected column names: airport

*/

-- q3 solution:

--This part calculates the number of passengers on each trip (even for a round trip).
WITH passengers_calculator AS(
	SELECT origin_airport, destination_airport,
		CASE WHEN return_flight_booked = TRUE THEN seats*2
  		ELSE seats END AS both_trips
	FROM flights),

--This part calculates how many passengers traveled in each origin and destination airports.
sum_passengers AS(
	SELECT origin_airport AS airport, SUM(both_trips) AS total_passengers
	FROM passengers_calculator
	GROUP BY origin_airport
	UNION ALL --Keeps the duplicates because an airport is used for both departure and landing.
	SELECT destination_airport AS airport, SUM(both_trips) AS total_passengers
	FROM passengers_calculator
	GROUP BY destination_airport),

--This part adds the passengers that landed and departed for each airport.
united_airports AS(
	SELECT airport, SUM(total_passengers) AS total_services
	FROM sum_passengers
	GROUP BY airport)

--This part gets the airport with most "services".
SELECT airport
FROM united_airports
WHERE total_services = (SELECT MAX(total_services) FROM united_airports);

/*
Question #4: 
using the definition of “services” provided in the previous question, we will now rank airports by total number of services. 

write a solution to report the rank of each airport as a percentage, where the rank as a percentage is computed using the following formula: 

`percent_rank = (airport_rank - 1) * 100 / (the_number_of_airports - 1)`

The percent rank should be rounded to 1 decimal place. airport rank is ascending, such that the airport with the least services is rank 1. If two airports have the same number of services, they also get the same rank.

Return by ascending order of rank

E**xpected column names: airport, percent_rank**

Expected column names: airport, percent_rank
*/

-- q4 solution:

--This part calculates the number of passengers on each trip (even for a round trip).
WITH passengers_calculator AS(
	SELECT origin_airport, destination_airport,
		CASE WHEN return_flight_booked = TRUE THEN seats*2
  		ELSE seats END AS both_trips
	FROM flights),

--This part calculates how many passengers traveled in each origin and destination airports.
sum_passengers AS(
	SELECT origin_airport AS airport, SUM(both_trips) AS total_passengers
	FROM passengers_calculator
	GROUP BY origin_airport
	UNION ALL --Keeps the duplicates because an airport is used for both departure and landing.
	SELECT destination_airport AS airport, SUM(both_trips) AS total_passengers
	FROM passengers_calculator
	GROUP BY destination_airport),

--This part adds the passengers that landed and departed for each airport and ranks them.
sum_and_rank AS(
	SELECT airport, SUM(total_passengers) AS total_services,
  	RANK() OVER(ORDER BY SUM(total_passengers)) AS airport_rank
	FROM sum_passengers
	GROUP BY airport)

--This part gets the percent rank for each airport.
SELECT airport,
	ROUND((airport_rank-1)*100/((SELECT COUNT(*) FROM sum_and_rank) -1)::NUMERIC,1) AS percent_rank
FROM sum_and_rank;
