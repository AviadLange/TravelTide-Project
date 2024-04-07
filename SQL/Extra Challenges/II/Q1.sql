-- This query selects users who have completed at least 10 flights.
SELECT user_id
FROM sessions
WHERE cancellation = FALSE
AND flight_booked = TRUE
GROUP BY user_id
HAVING COUNT(*) > 9
ORDER BY user_id;
