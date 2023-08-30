--This data served me for the 'Distribution and Outliers' visualizations. 

--Filters first the data based on Elena's criterias.
WITH filtered_data AS(
	SELECT user_id, COUNT(session_id) AS number_of_sessions
	FROM sessions
	WHERE session_start >= '2023-01-04'
	GROUP BY user_id
	HAVING COUNT(session_id) > 7)

--Selects and creates the relevant fields with the highest 'Outliers Concern'.
SELECT session_id, user_id, page_clicks, 
	hotel_per_room_usd AS room_price,
  nights,
  base_fare_usd AS flight_price,
	haversine_distance(home_airport_lat,
    home_airport_lon, destination_airport_lat, destination_airport_lon) AS distance,
    TO_CHAR(session_end-session_start + INTERVAL '0.5 second',
    'HH24:MI:SS.MS') AS session_duration,
  CAST(SPLIT_PART(TO_CHAR(session_end-session_start + INTERVAL '0.5 second',
    'HH24:MI:SS.MS'), ':', 2) AS INTEGER) * 60 + 
CAST(SPLIT_PART(SPLIT_PART(TO_CHAR(session_end-session_start + INTERVAL '0.5 second',
    'HH24:MI:SS.MS'), ':', 3), '.', 1) AS INTEGER) +
CASE WHEN CAST(SPLIT_PART(TO_CHAR(session_end-session_start + INTERVAL '0.5 second',
    'HH24:MI:SS.MS'), '.', -1) AS INTEGER) <= 500 THEN 0
	ELSE 1 END::FLOAT AS session_in_seconds
FROM filtered_data
INNER JOIN sessions
USING(user_id)
INNER JOIN users
USING(user_id)
LEFT JOIN flights
USING(trip_id)
LEFT JOIN hotels
USING(trip_id);