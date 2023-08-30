--This script gathers a lot of metrics, in order to feed the 'Machine Learning' code.
/*I didn't remove the outliers nor scaled the data,
as the algorithm should figure it out by iself*/

--Filtering the data based on Elena's criterias, and aggragetes raw metrics.
WITH filtered_data AS(SELECT user_id,
	SUM(checked_bags) AS bags, 
--The following 'SUM(CASE...) fields basically give back the number of sessions which hold the condition. 
  SUM(CASE WHEN trip_id IS NOT NULL THEN 1 ELSE 0 END)::FLOAT AS trips_booked,
  SUM(CASE WHEN flight_booked = true THEN 1 ELSE 0 END)::FLOAT AS flights_booked,
  SUM(CASE WHEN return_flight_booked = true THEN 1 ELSE 0 END)::FLOAT AS return_booked,
  SUM(CASE WHEN hotel_booked = true THEN 1 ELSE 0 END)::FLOAT AS hotels_booked,
  SUM(CASE WHEN flight_booked = true AND hotel_booked = true THEN 1
  	ELSE 0 END)::FLOAT AS packages_booked, --User booked both hotel and flight
  SUM(CASE WHEN cancellation = true THEN 1 ELSE 0 END)::FLOAT AS cancellations,
  --The user was offered a flight discount.
  SUM(CASE WHEN flight_discount = true THEN 1 ELSE 0 END)::FLOAT AS f_discount,
  --The user was offered a room discount.
  SUM(CASE WHEN hotel_discount = true THEN 1 ELSE 0 END)::FLOAT AS h_discount,
  COUNT(session_id) AS total_sessions,
  ROUND(AVG(hotel_per_room_usd),2) AS avg_room_price,
  ROUND(AVG(base_fare_usd),2) AS avg_flight_price,
  ROUND(AVG(base_fare_usd*flight_discount_amount),2) AS avg_flight_discount,
  ROUND(AVG(hotel_per_room_usd*hotel_discount_amount),2) AS avg_room_discount,
	AVG(flight_discount_amount) AS f_discount_per,
  AVG(hotel_discount_amount) AS h_discount_per,
  ROUND(AVG(page_clicks),2) AS avg_clicks,
  AVG(CAST(SPLIT_PART(TO_CHAR(session_end-session_start + INTERVAL '0.5 second',
    'HH24:MI:SS.MS'), ':', 2) AS INTEGER) * 60 + --Minutes x 60 = seconds
		CAST(SPLIT_PART(SPLIT_PART(TO_CHAR(session_end-session_start + INTERVAL '0.5 second',
    'HH24:MI:SS.MS'), ':', 3), '.', 1) AS INTEGER) + --Adds the seconds to the minutes
		CASE WHEN CAST(SPLIT_PART(TO_CHAR(session_end-session_start + INTERVAL '0.5 second',
    'HH24:MI:SS.MS'), '.', -1) AS INTEGER) <= 500 THEN 0 --Rounds the centiseconds
		ELSE 1 END)::FLOAT AS session_in_seconds,
  ROUND(AVG(haversine_distance(home_airport_lat,
    home_airport_lon, destination_airport_lat, destination_airport_lon))) AS avg_distance
FROM sessions
INNER JOIN users --Obtains only sessions for the desired users
USING(user_id)
LEFT JOIN flights --Obtains also sessions with no flights data
USING(trip_id)
LEFT JOIN hotels --Obtains also sessions with no hotels data
USING(trip_id)
WHERE session_start >= '2023-01-04'
GROUP BY user_id
HAVING COUNT(session_id) > 7)

--This section gets new calculated fields based on the fields created in the previous section.
SELECT *,
	ROUND((trips_booked/total_sessions)::NUMERIC,2) AS trips_ratio,
  ROUND((trips_booked/avg_clicks)::NUMERIC,2) AS trips_per_click,
   ROUND((avg_clicks/total_sessions)::NUMERIC,2) AS clicks_per_session,                     
  ROUND((cancellations/total_sessions)::NUMERIC,2) AS cancellations_ratio,
  ROUND((flights_booked/total_sessions)::NUMERIC,2) AS flights_ratio,
  ROUND((hotels_booked/total_sessions)::NUMERIC,2) AS hotels_ratio,
  ROUND((packages_booked/total_sessions)::NUMERIC,2) AS packages_per_session,
	--Actual price paid.
  ROUND(avg_flight_price - (avg_flight_price*f_discount_per)::NUMERIC,2) AS f_discounted_price,
  --Actual price paid.
  ROUND(avg_room_price - (avg_room_price*h_discount_per)::NUMERIC,2) AS h_discounted_price,                  
  CASE WHEN flights_booked = 0 THEN NULL --Avoids the 'division by zero' potential error.
  	ELSE ROUND((return_booked/flights_booked)::NUMERIC,2) END AS return_ratio,
  ROUND((f_discount/total_sessions)::NUMERIC,2) AS f_discount_ratio,
  ROUND((h_discount/total_sessions)::NUMERIC,2) AS h_discount_ratio,
   CASE WHEN trips_booked = 0 THEN NULL --Avoids the 'division by zero' potential error.
   	ELSE ROUND((packages_booked/trips_booked)::NUMERIC,2) END AS package_per_trip,
   CASE WHEN flights_booked = 0 THEN NULL --Avoids the 'division by zero' potential error.
  	ELSE ROUND((bags/flights_booked)::NUMERIC,2) END AS bags_per_flight,
   avg_flight_price/avg_distance AS price_per_km,
   avg_flight_discount/avg_distance AS discount_per_km
FROM filtered_data;

/*There are almost endless calculated fields possibilities,
but these above are the ones I elected to create.*/
--This script is in further use here: 'Machine Learning.py'.