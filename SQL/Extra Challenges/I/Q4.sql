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