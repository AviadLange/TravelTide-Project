/*
Question #1: 
Calculate the proportion of sessions abandoned in summer months 
(June, July, August) and compare it to the proportion of sessions abandoned 
in non-summer months. Round the output to 3 decimal places.

Expected column names: summer_abandon_rate, other_abandon_rate
*/

-- q1 solution:

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

/*
Question #2: 
Bin customers according to their place in the session abandonment distribution as follows: 

1. number of abandonments greater than one standard deviation more than the mean. Call these customers “gt”.
2. number of abandonments fewer than one standard deviation less than the mean. Call these customers “lt”.
3. everyone else (the middle of the distribution). Call these customers “middle”.

calculate the number of customers in each group, the mean number of abandonments in each group, and the range of abandonments in each group.

Expected column names: distribution_loc, abandon_n, abandon_avg, abandon_range

*/

-- q2 solution:

--Gets each user's count of abandoned sessions. 
WITH 
  totals AS(
	SELECT user_id, COUNT(session_id) AS total_ab
	FROM sessions
  WHERE trip_id IS NULL
	GROUP BY user_id),

--Divides the users to three groups based on their abandons number.
ab_groups AS (SELECT *,
	CASE WHEN total_ab > (SELECT (AVG(total_ab)+STDDEV(total_ab)) FROM totals)
		THEN 'gt'
    WHEN total_ab < (SELECT (AVG(total_ab)-STDDEV(total_ab)) FROM totals)
    THEN 'lt'
    ELSE 'middle' END AS distribution_loc
FROM totals)

--Calculates the number, mean and range for these three groups.
SELECT distribution_loc,
	COUNT(*) AS abandon_n,
  ROUND(AVG(total_ab),3) AS abandon_avg,
  MAX(total_ab)-MIN(total_ab) AS abandon_range
FROM ab_groups
GROUP BY distribution_loc;

/*
Question #3: 
Calculate the total number of abandoned sessions and the total number of sessions 
that resulted in a booking per day, but only for customers who reside in one of the 
top 5 cities (top 5 in terms of total number of users from city). 
Also calculate the ratio of booked to abandoned for each day. 
Return only the 5 most recent days in the dataset.

Expected column names: session_date, abandoned,booked, book_abandon_ratio

*/

-- q3 solution:

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

/*
Question #4: 
Densely rank users from Saskatoon based on their ratio of successful bookings to abandoned bookings. 
then count how many users share each rank, with the most common ranks listed first.

note: if the ratio of bookings to abandons is null for a user, 
use the average bookings/abandons ratio of all Saskatoon users.

Expected column names: ba_rank, rank_count
*/

-- q4 solution:

--Gets the sessions count for Saskatoon people.
WITH saskatoon_users AS(
	SELECT user_id, COUNT(*) AS total_ab_sessions
	FROM users
	INNER JOIN sessions
	USING(user_id)
	WHERE home_city = 'saskatoon'
	GROUP BY user_id),

/*Calculates the abandoned and booked (cancellation excluded this time)
numbers for Saskatoon people.*/
book_or_abandon AS(
  SELECT user_id,
  	SUM(CASE WHEN trip_id IS NOT NULL AND cancellation IS FALSE THEN 1 ELSE 0 END) AS trips_booked,
  	SUM(CASE WHEN trip_id IS NULL THEN 1 ELSE 0 END) AS trips_abandoned
  FROM sessions
  INNER JOIN saskatoon_users
  USING(user_id)
	GROUP BY user_id),

/*Calculates the abandoned/booked ratio for Saskatoon people,
avoiding division by zero*/
ratio AS(SELECT
	CASE WHEN trips_abandoned = 0 THEN
  	(SELECT ROUND(AVG(trips_booked::DECIMAL/trips_abandoned),3)
    FROM book_or_abandon
    INNER JOIN saskatoon_users
  	USING(user_id)
    WHERE trips_abandoned <> 0)
	ELSE ROUND((trips_booked::DECIMAL/trips_abandoned),3) END AS ab_ratio
FROM book_or_abandon)

--Gets each ratio's rank and count of users with this ratio.
SELECT RANK() OVER (ORDER BY ab_ratio DESC) AS ba_rank, COUNT(*) AS rank_count
FROM ratio
GROUP BY ab_ratio
ORDER BY rank_count DESC;
