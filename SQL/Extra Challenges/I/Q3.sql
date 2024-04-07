--Gets the top five cities in terms of users number.
WITH top_cities AS(SELECT user_id
	FROM users
	WHERE home_city IN (
    SELECT home_city
    FROM users
    GROUP BY home_city
    ORDER BY COUNT(*) DESC
    LIMIT 5)),

/*Gets the abandoned sessions for the last five days in the DB
for users from the upper mentioned cities.*/
abandoned AS(
  SELECT DATE(session_start) AS day_session, COUNT(*) AS abandoned
	FROM sessions
	INNER JOIN top_cities
	USING(user_id)
	WHERE trip_id IS NULL 
	GROUP BY day_session
	ORDER BY day_session DESC
	LIMIT 5),

--Gets the booked sessions (including the cancelled sessions).
 booked AS(
  SELECT user_id, DATE(session_start) AS day_session
	FROM sessions
	INNER JOIN top_cities
	USING(user_id)
	WHERE trip_id IS NOT NULL),

--Combines the numbers for abandoned and booked sessions per day.
both_metrics AS(
  SELECT day_session, abandoned, COUNT(*) AS booked
	FROM booked
	INNER JOIN abandoned
	USING(day_session)
	GROUP BY day_session, abandoned)

--Adds the booked to abandoned ratio.
SELECT *, ROUND(booked::DECIMAL/abandoned,3) AS book_abandon_ratio
FROM both_metrics
ORDER BY day_session DESC;