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