--This data served me for the 'Vincenty Distance' calculation. 

--Filters first the data based on Elena's criterias.
WITH filtered_data AS(
	SELECT user_id, COUNT(session_id) AS number_of_sessions
	FROM sessions
	WHERE session_start >= '2023-01-04'
	GROUP BY user_id
	HAVING COUNT(session_id) > 7)

--Selects only the unique home and destination combinations.
SELECT DISTINCT
	home_airport_lat, home_airport_lon, destination_airport_lat,
  destination_airport_lon, home_city, destination,
--I added the haversine distance, so in the end it could be compared to vincenty distance. 
  haversine_distance(home_airport_lat, home_airport_lon,
  	destination_airport_lat, destination_airport_lon) AS haversine_distance
FROM filtered_data
INNER JOIN sessions
USING(user_id)
INNER JOIN users
USING(user_id)
INNER JOIN flights --'INNER JOIN' this time, to filter out the sessions without flights
USING(trip_id);

--This script is in further use here: 'Vincenty Distance.py'.