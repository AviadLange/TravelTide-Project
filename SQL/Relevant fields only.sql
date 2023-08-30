/*This entire script has multiple 'WITH' statements as the interface I used (Beekeeper) does not allow
any creating of a 'VIEW'/TABLE'*/

--Filtering first the data based on Elena's criterias.
WITH filtered_data AS(
	SELECT user_id, COUNT(session_id) AS number_of_sessions
	FROM sessions
	WHERE session_start >= '2023-01-04'
	GROUP BY user_id
	HAVING COUNT(session_id) > 7),

--I joined the filtered_data to the given tables, in order to get data for every session made by the these filtered users.
--This section calculates each session's duration, and converts it to a numeric sum of seconds.
/*'TO_CHAR()' first converts the value type to a string, then, 'SPLIT_PART()' splits the string by ':'.
Finally, 'CAST()' converts the strings to a numeric value*/
time_adjusment AS (SELECT *,
  CAST(SPLIT_PART(TO_CHAR(session_end-session_start + INTERVAL '0.5 second',
    'HH24:MI:SS.MS'), ':', 2) AS INTEGER) * 60 + --Minutes x 60 = seconds
CAST(SPLIT_PART(SPLIT_PART(TO_CHAR(session_end-session_start + INTERVAL '0.5 second',
    'HH24:MI:SS.MS'), ':', 3), '.', 1) AS INTEGER) + --Adds the seconds to the minutes
CASE WHEN CAST(SPLIT_PART(TO_CHAR(session_end-session_start + INTERVAL '0.5 second',
    'HH24:MI:SS.MS'), '.', -1) AS INTEGER) <= 500 THEN 0 --Rounds the centiseconds
	ELSE 1 END::FLOAT AS session_in_seconds
FROM filtered_data
INNER JOIN sessions --Obtains only sessions for the desired users
USING(user_id)
INNER JOIN users --Obtains only sessions for the desired users
USING(user_id)
LEFT JOIN flights --Obtains also sessions with no flights data
USING(trip_id)
LEFT JOIN hotels --Obtains also sessions with no hotels data
USING(trip_id)),

--This section takes care of potential outliers in the data.
/*The following 'CASE' statements basically check if the value is greater than the field's mean + two standard deviations.
If it's indeed greater, it replaces it with 'NULL', and this value won't longer affect the calculations.*/
--'n_o_...' stands for no outliers.
outliers_removal AS (SELECT *,
--Page clicks without outliers.
	CASE WHEN page_clicks <= (SELECT AVG(page_clicks)+(STDDEV(page_clicks))*2 FROM sessions)
		THEN page_clicks ELSE NULL END AS n_o_page_clicks,
--Nights booked in a hotel without outliers.
	CASE WHEN nights <= (SELECT AVG(nights)+(STDDEV(nights))*2 FROM hotels)
		THEN nights ELSE NULL END AS n_o_nights,
--Session duration in seconds and without outliers.
	CASE WHEN session_in_seconds <= (SELECT AVG(session_in_seconds)
    +(STDDEV(session_in_seconds))*2 FROM time_adjusment)
		THEN session_in_seconds ELSE NULL END AS n_o_session_in_seconds, 
--Flight price without outliers.
  CASE WHEN base_fare_usd <= (SELECT AVG(base_fare_usd)+(STDDEV(base_fare_usd))*2 FROM flights)
		THEN base_fare_usd ELSE NULL END AS n_o_flight_price,
--Room price without outliers.
  CASE WHEN hotel_per_room_usd <= (SELECT AVG(hotel_per_room_usd)+(STDDEV(hotel_per_room_usd))*2
    FROM hotels)
		THEN hotel_per_room_usd ELSE NULL END AS n_o_room_price,
--Distance covered for each trip without ouliers.
/*I used the provided 'haversine_distance()' function,
which takes the 'lon' and 'lat' for two points and calculates their distance.*/
  CASE WHEN haversine_distance(home_airport_lat,
    home_airport_lon, destination_airport_lat, destination_airport_lon) <=
    (SELECT AVG(haversine_distance(home_airport_lat, --Subquery which avoids using aggregation function without 'GROUP BY'.
    	home_airport_lon, destination_airport_lat, destination_airport_lon))
     	+(STDDEV(haversine_distance(home_airport_lat,
    	home_airport_lon, destination_airport_lat, destination_airport_lon)))*2
    FROM sessions
		INNER JOIN users
		USING(user_id)
		LEFT JOIN flights
		USING(trip_id))
	THEN ROUND(haversine_distance(home_airport_lat,
    home_airport_lon, destination_airport_lat, destination_airport_lon)::NUMERIC,0) ELSE NULL END
  AS haversine_distance_km
FROM time_adjusment),

--This statement scales the relevant fields I'll as is. Other calculated fields will be scaled later.
--This scaling uses the 'max' and 'min' value of every session.
--It follows the scaling formula: (value-minimum value)/(maximum value-minimum value).
scaling AS (SELECT *,
  --Scales the session duration in seconds.
   (n_o_session_in_seconds-(SELECT MIN(n_o_session_in_seconds) FROM outliers_removal))/
    (SELECT (MAX(n_o_session_in_seconds)-MIN(n_o_session_in_seconds)) FROM outliers_removal)
    AS scaled_session_in_seconds,
  --Scales the room price for each hotel booking.
	(n_o_room_price-(SELECT MIN(n_o_room_price) FROM outliers_removal))/
    (SELECT (MAX(n_o_room_price)-MIN(n_o_room_price)) FROM outliers_removal)
    AS scaled_room_price,
   --Scales the number of nights for each hotel booking.
	(n_o_nights-(SELECT MIN(n_o_nights) FROM outliers_removal))/
    (SELECT (MAX(n_o_nights)-MIN(n_o_nights)) FROM outliers_removal)
    AS scaled_nights,
  --Scales the distance traveled by each user.
  (haversine_distance_km-(SELECT MIN(haversine_distance_km) FROM outliers_removal))/
    (SELECT (MAX(haversine_distance_km)-MIN(haversine_distance_km)) FROM outliers_removal)
    AS scaled_distance_km     
FROM outliers_removal),

/*This section groups back the data by user,
	and creates new calculated fields from the previous database created.*/
/*I refrained from rounding the fields with values on the 0-1 scale to avoid the
possibility of obtaining 0 values, which could potentially skew my findings.*/
first_aggregation AS (SELECT user_id, has_children,
--Calculates and segnents the user's age based on his/her birthdate.
	CASE WHEN birthdate < '1968-12-31' THEN '55+'
		WHEN birthdate BETWEEN '1969-01-01' AND '1982-12-31' THEN '41-55'
  	WHEN birthdate BETWEEN '1983-01-01' AND '1997-12-31' THEN '26-40'
		ELSE '17-25' END AS group_age,
	--The following 'SUM(CASE...) fields basically give back the number of sessions which hold the condition. 
  SUM(checked_bags) AS bags,
  SUM(CASE WHEN trip_id IS NOT NULL THEN 1 ELSE 0 END)::FLOAT AS trips_booked,
  SUM(CASE WHEN flight_booked = true THEN 1 ELSE 0 END)::FLOAT AS flights_booked,
  SUM(CASE WHEN return_flight_booked = true THEN 1 ELSE 0 END)::FLOAT AS return_booked,
  SUM(CASE WHEN hotel_booked = true THEN 1 ELSE 0 END)::FLOAT AS hotels_booked,
  SUM(CASE WHEN flight_booked = true AND hotel_booked = true THEN 1
  	ELSE 0 END)::FLOAT AS packages_booked,
  SUM(CASE WHEN cancellation = true THEN 1 ELSE 0 END)::FLOAT AS cancellations,
  SUM(CASE WHEN flight_discount = true THEN 1 ELSE 0 END)::FLOAT AS f_discount, --The user was offered a flight discount
	COUNT(session_id) AS total_sessions,
  AVG(scaled_nights) AS avg_scaled_nights,
  AVG(scaled_room_price) AS avg_scaled_room_price,
  ROUND(AVG(n_o_flight_price),2) AS avg_flight_price,
  AVG(flight_discount_amount) AS f_discount_per, --Mean discount percentage for flights
  AVG(n_o_page_clicks) AS avg_clicks,
  ROUND(AVG(haversine_distance_km),2) AS avg_distance,
  AVG(scaled_distance_km) AS avg_scaled_distance_km,
	AVG(scaled_session_in_seconds) AS avg_scaled_session_in_seconds
FROM scaling
GROUP BY user_id, has_children, group_age),

--This section uses the fields created in the previous section for further calculations.
/*Here I did round (to 2 decimal points) a field with 0-1 scale when it holds proportion,
as the range of the denominator doesn't exceed 12, and there is no risk of getting wrong 0 values*/
second_aggregation AS (SELECT *,
  ROUND((cancellations/total_sessions)::NUMERIC,2) AS cancellations_ratio,
  ROUND((flights_booked/total_sessions)::NUMERIC,2) AS flights_ratio,
  ROUND((avg_clicks/total_sessions)::NUMERIC,2) AS clicks_per_session,                     
  ROUND((hotels_booked/total_sessions)::NUMERIC,2) AS hotels_ratio,
  ROUND((packages_booked/total_sessions)::NUMERIC,2) AS packages_per_session,
  CASE WHEN flights_booked = 0 THEN NULL --Avoids the 'division by zero' potential error.
  	ELSE ROUND((return_booked/flights_booked)::NUMERIC,2) END AS return_ratio,
  ROUND((f_discount/total_sessions)::NUMERIC,2) AS f_discount_ratio,
   CASE WHEN flights_booked = 0 THEN NULL --Avoids the 'division by zero' potential error.
  	ELSE ROUND((bags/flights_booked)::NUMERIC,2) END AS bags_per_flight,
   avg_flight_price/avg_distance AS price_per_km
FROM first_aggregation)

/* This query selects only the fields I used in my final segmentation (16 fields),
   and scales the proportaion fields previously created.*/
/*It's important to notice that here the 'max' and 'min' values are actually the specific user
and not a specific session as earlier*/
SELECT user_id, has_children, group_age, avg_scaled_room_price,
	f_discount_per, f_discount_ratio, packages_per_session,
  flights_ratio, cancellations_ratio, hotels_ratio, avg_scaled_session_in_seconds,
  return_ratio, avg_scaled_distance_km, avg_scaled_nights,
	(bags_per_flight-(SELECT MIN(bags_per_flight) FROM second_aggregation))/
    (SELECT (MAX(bags_per_flight)-MIN(bags_per_flight)) FROM second_aggregation)
    AS scaled_bags_per_flight,
  (price_per_km-(SELECT MIN(price_per_km) FROM second_aggregation))/
    (SELECT (MAX(price_per_km)-MIN(price_per_km)) FROM second_aggregation)
    AS scaled_price_per_km,
  (clicks_per_session-(SELECT MIN(clicks_per_session) FROM second_aggregation))/
    (SELECT (MAX(clicks_per_session)-MIN(clicks_per_session)) FROM second_aggregation)
    AS scaled_clicks_per_session
FROM second_aggregation;