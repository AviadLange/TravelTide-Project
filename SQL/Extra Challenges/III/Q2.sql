--This part screens the users to inckude only desired ones.
WITH users_screener AS(
	SELECT user_id, AVG(hotel_discount_amount) AS avg_discount,
  	MAX(hotel_discount_amount) AS max_discount
	FROM sessions
	WHERE cancellation = FALSE
		AND hotel_discount = TRUE
  	AND (hotel_booked = TRUE OR flight_booked = TRUE) --A trip was booked.
	GROUP BY user_id
	HAVING COUNT(*) >=2)

--This part returns only the users with max discount greater than the overall max discount.
SELECT user_id
FROM users_screener
WHERE max_discount > (SELECT MAX(avg_discount) FROM users_screener);