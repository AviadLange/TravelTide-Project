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