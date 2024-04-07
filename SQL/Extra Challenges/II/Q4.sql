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