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