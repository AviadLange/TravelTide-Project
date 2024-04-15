--This query counts the number of flights during the week and weekend. 
SELECT 
  SUM(CASE WHEN EXTRACT(DOW FROM departure_time) NOT IN(0, 6) THEN 1 ELSE 0 END) AS working_cnt,
	SUM(CASE WHEN EXTRACT(DOW FROM departure_time) IN(0, 6) THEN 1 ELSE 0 END) AS weekend_cnt
FROM flights;
