/*
Question #1:
return users who have booked and completed at least 10 flights, ordered by user_id.

Expected column names: `user_id`
*/

-- q1 solution:

-- This query selects users who have completed at least 10 flights.
SELECT user_id
FROM sessions
WHERE cancellation = FALSE
AND flight_booked = TRUE
GROUP BY user_id
HAVING COUNT(*) > 9
ORDER BY user_id;

/*

Question #2: 
Write a solution to report the trip_id of sessions where:

1. session resulted in a booked flight
2. booking occurred in May, 2022
3. booking has the maximum flight discount on that respective day.

If in one day there are multiple such transactions, return all of them.

Expected column names: `trip_id`

*/

-- q2 solution:

-- This part finds the max discount for every day in May 2022.
WITH date_creator AS(
	SELECT *,
  	MAX(flight_discount_amount) OVER(PARTITION BY DATE(session_end)) AS max_discount
  FROM sessions
	WHERE flight_booked = TRUE
  	AND session_end BETWEEN '2022-05-01' AND '2022-06-01')

-- This part returns only the trip_ids with the highest discount for the day.
SELECT trip_id
FROM date_creator
WHERE max_discount = flight_discount_amount
ORDER BY trip_id;

/*
Question #3: 
Write a solution that will, for each user_id of users with greater than 10 flights, 
find out the largest window of days between 
the departure time of a flight and the departure time 
of the next departing flight taken by the user.

Expected column names: `user_id`, `biggest_window`

*/

-- q3 solution:

-- This part filters for users who booked at least 11 flights.
WITH users_filter AS(
	SELECT user_id, COUNT(*) AS flights
	FROM sessions
	WHERE flight_booked = TRUE
	GROUP BY user_id
	HAVING  COUNT(*) > 10),

-- This part calculates the days difference between each flight.
differences AS(
	SELECT user_id,
		(DATE(departure_time)) - LAG(DATE(departure_time))
  		OVER(PARTITION BY user_id ORDER BY DATE(departure_time)) AS days_diff
	FROM sessions
	INNER JOIN users_filter
	USING(user_id)
	INNER JOIN flights
	USING(trip_id))

-- This part gets the biggest gap between flights for each user.
SELECT user_id, MAX(days_diff) AS biggest_window
FROM differences
GROUP BY user_id;

/*
Question #4: 
Find the user_id’s of people whose origin airport is Boston (BOS) 
and whose first and last flight were to the same destination. 
Only include people who have flown out of Boston at least twice.

Expected column names: user_id
*/

-- q4 solution:

-- This part filters for boston residents.
WITH boston_users AS(
	SELECT user_id, destination_airport, departure_time	
	FROM users
	INNER JOIN sessions
	USING(user_id)
	INNER JOIN flights
	USING(trip_id)
	WHERE home_airport = 'BOS'
		AND cancellation = FALSE),

-- This part gets the first and last flight for each user.
dates_tracker AS(
	SELECT *,
		MAX(departure_time) OVER(PARTITION BY user_id) AS last_dep,
  	MIN(departure_time) OVER(PARTITION BY user_id) AS first_dep
	FROM boston_users),

-- This part filters for only first and last flights.
airports_checker AS(
	SELECT *, LAG(destination_airport) OVER(PARTITION BY user_id) AS first_dep_airport
	FROM dates_tracker
	WHERE (departure_time = first_dep OR departure_time = last_dep)) -- Records of first and last only.

-- This part gets the user who flew to the same destination.
SELECT user_id
FROM airports_checker
WHERE first_dep_airport = destination_airport;
