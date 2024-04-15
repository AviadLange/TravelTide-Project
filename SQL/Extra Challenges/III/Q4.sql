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