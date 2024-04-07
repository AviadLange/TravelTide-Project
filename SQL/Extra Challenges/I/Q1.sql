--Gets the month from the session_start timestamp.
WITH months AS(
	SELECT session_id, trip_id,
		EXTRACT(MONTH FROM session_start) AS month_number
	FROM sessions),

--Gets the number of summer sessions. (the key will be used in a future join.)
total_summer AS (SELECT 1 AS a_key, COUNT(*) AS total_sessions
	FROM months
	WHERE month_number IN (6, 7, 8)),

--Gets the number of none summer sessions.
total_not_summer AS (SELECT 1 AS a_key, COUNT(*) AS total_sessions
	FROM months
	WHERE month_number NOT IN (6, 7, 8)),

--Gets the number of abandoned sessions in the summer.
ab_summer AS (SELECT 1 AS a_key, COUNT(*) AS number_of_abandoned
	FROM months
	WHERE month_number IN (6, 7, 8)
  AND trip_id IS NULL),

--Gets the number of abandoned sessions in the rest of the year.
ab_not_summer AS (SELECT 1 AS a_key, COUNT(*) AS number_of_abandoned
	FROM months
	WHERE month_number NOT IN (6, 7, 8)
  AND trip_id IS NULL),
  
--Calculates the summer abandonment rate.
summer_rate AS(SELECT 1 AS b_key,
	ROUND((number_of_abandoned::DECIMAL/total_sessions),3) AS summer_abandon_rate
FROM ab_summer
INNER JOIN total_summer
USING(a_key)),

--Calculates the none-summer abandonment rate.
other_rate AS(SELECT 1 AS b_key,
	ROUND((number_of_abandoned::DECIMAL/total_sessions),3) AS other_abandon_rate
FROM ab_not_summer
INNER JOIN total_not_summer
USING(a_key))

--Joins the two metrics together.
SELECT summer_abandon_rate, other_abandon_rate
FROM summer_rate
INNER JOIN other_rate
USING(b_key);
