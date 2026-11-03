-- =====================================================================
-- Laboratory work 6: JOIN
-- Run each task separately (select the query -> F5) and take a screenshot.
-- Notes:
--  * The flights table has no "flight number" column, so flight_id is
--    used as the flight number.
--  * "A specific airline / flight / country" is chosen automatically with
--    a subquery, so the result is never empty. To use your own value,
--    replace the subquery with a literal, e.g.  a.airline_id = 3
--    or  ap.country = 'Kazakhstan'.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Task 1. All flights of a specific airline
-- ---------------------------------------------------------------------
SELECT f.flight_id,
       a.airline_name,
       f.sch_departure_time,
       f.sch_arrival_time
FROM flights f
JOIN airline a ON a.airline_id = f.airline_id
WHERE a.airline_id = (SELECT MIN(airline_id) FROM flights)
ORDER BY f.sch_departure_time;


-- ---------------------------------------------------------------------
-- Task 2. All flights with the names of departure airports
-- ---------------------------------------------------------------------
SELECT f.flight_id,
       ap.airport_name AS departure_airport,
       f.sch_departure_time
FROM flights f
JOIN airport ap ON ap.airport_id = f.departing_airport_id
ORDER BY f.flight_id;


-- ---------------------------------------------------------------------
-- Task 3. Airlines that have no flights scheduled for the next month
-- (LEFT JOIN + IS NULL; the date condition is in ON, not in WHERE)
-- ---------------------------------------------------------------------
SELECT a.airline_id,
       a.airline_name
FROM airline a
LEFT JOIN flights f
       ON f.airline_id = a.airline_id
      AND f.sch_departure_time >= date_trunc('month', CURRENT_DATE) + INTERVAL '1 month'
      AND f.sch_departure_time <  date_trunc('month', CURRENT_DATE) + INTERVAL '2 months'
WHERE f.flight_id IS NULL
ORDER BY a.airline_id;


-- ---------------------------------------------------------------------
-- Task 4. List of passengers on a specific flight
-- ---------------------------------------------------------------------
SELECT b.flight_id,
       p.passenger_id,
       p.first_name,
       p.last_name,
       p.passport_number
FROM booking b
JOIN passengers p ON p.passenger_id = b.passenger_id
WHERE b.flight_id = (SELECT MIN(flight_id) FROM booking)
ORDER BY p.last_name;


-- ---------------------------------------------------------------------
-- Task 5. Average, total, maximum and minimum ticket price for each flight
-- ---------------------------------------------------------------------
SELECT f.flight_id,
       ROUND(AVG(b.ticket_price), 2) AS avg_price,
       SUM(b.ticket_price)           AS total_price,
       MAX(b.ticket_price)           AS max_price,
       MIN(b.ticket_price)           AS min_price
FROM flights f
JOIN booking b ON b.flight_id = f.flight_id
GROUP BY f.flight_id
ORDER BY f.flight_id;


-- ---------------------------------------------------------------------
-- Task 6. All flights to a specific country
-- (flights + airport (arrival) + airline, condition on country name)
-- ---------------------------------------------------------------------
SELECT f.flight_id,
       a.airline_name,
       ap.airport_name AS arrival_airport,
       ap.country      AS arrival_country,
       f.sch_arrival_time
FROM flights f
JOIN airport ap ON ap.airport_id = f.arriving_airport_id
JOIN airline a  ON a.airline_id  = f.airline_id
WHERE ap.country = (SELECT MIN(ap2.country)
                    FROM airport ap2
                    JOIN flights f2 ON f2.arriving_airport_id = ap2.airport_id)
ORDER BY f.flight_id;


-- ---------------------------------------------------------------------
-- Task 7. Minor passengers (under 18) and their arrival destination
-- ---------------------------------------------------------------------
SELECT p.first_name || ' ' || p.last_name AS full_name,
       p.date_of_birth,
       ap.city    AS destination_city,
       ap.country AS destination_country
FROM passengers p
JOIN booking b  ON b.passenger_id = p.passenger_id
JOIN flights f  ON f.flight_id    = b.flight_id
JOIN airport ap ON ap.airport_id  = f.arriving_airport_id
WHERE p.date_of_birth > CURRENT_DATE - INTERVAL '18 years'
ORDER BY p.date_of_birth DESC;
-- If this returns no rows, the table has no minors today. Alternative:
-- check age on the day of the flight, replace the WHERE line with:
-- WHERE p.date_of_birth > f.sch_departure_time::date - INTERVAL '18 years'


-- ---------------------------------------------------------------------
-- Task 8. Passenger full name, passport number and arrival time
--         at the destination (actual arrival time of the flight)
-- ---------------------------------------------------------------------
SELECT p.first_name || ' ' || p.last_name AS full_name,
       p.passport_number,
       f.act_arrival_time AS arrival_time
FROM passengers p
JOIN booking b ON b.passenger_id = p.passenger_id
JOIN flights f ON f.flight_id    = b.flight_id
ORDER BY full_name;


-- ---------------------------------------------------------------------
-- Task 9. Flights where the airline's home country equals the origin
--         (departure airport) country, grouped by the airport country
-- ---------------------------------------------------------------------
SELECT dep.country AS airport_country,
       COUNT(f.flight_id) AS flights_count,
       STRING_AGG(f.flight_id::text, ', ' ORDER BY f.flight_id) AS flight_ids
FROM flights f
JOIN airline a   ON a.airline_id   = f.airline_id
JOIN airport dep ON dep.airport_id = f.departing_airport_id
WHERE a.airline_country = dep.country
GROUP BY dep.country
ORDER BY dep.country;


-- ---------------------------------------------------------------------
-- Task 10. Flight number, airline name, departure airport, arrival airport
-- ---------------------------------------------------------------------
SELECT f.flight_id AS flight_number,
       a.airline_name,
       dep.airport_name AS departure_airport,
       arr.airport_name AS arrival_airport
FROM flights f
JOIN airline a   ON a.airline_id   = f.airline_id
JOIN airport dep ON dep.airport_id = f.departing_airport_id
JOIN airport arr ON arr.airport_id = f.arriving_airport_id
ORDER BY f.flight_id;


-- ---------------------------------------------------------------------
-- Task 11. Passengers who booked flights of a specific airline
--          (full name and flight number)
-- ---------------------------------------------------------------------
SELECT p.first_name || ' ' || p.last_name AS full_name,
       f.flight_id AS flight_number,
       a.airline_name
FROM passengers p
JOIN booking b ON b.passenger_id = p.passenger_id
JOIN flights f ON f.flight_id    = b.flight_id
JOIN airline a ON a.airline_id   = f.airline_id
WHERE a.airline_id = (SELECT MIN(f2.airline_id)
                      FROM flights f2
                      JOIN booking b2 ON b2.flight_id = f2.flight_id)
ORDER BY full_name;


-- ---------------------------------------------------------------------
-- Task 12. Each flight's number, destination country and number of
--          booked passengers (flights with no bookings are included)
-- ---------------------------------------------------------------------
SELECT f.flight_id AS flight_number,
       arr.country AS destination_country,
       COUNT(DISTINCT b.passenger_id) AS passengers_count
FROM flights f
JOIN airport arr   ON arr.airport_id = f.arriving_airport_id
LEFT JOIN booking b ON b.flight_id   = f.flight_id
GROUP BY f.flight_id, arr.country
ORDER BY f.flight_id;


-- ---------------------------------------------------------------------
-- Task 13. Passengers who have not booked any tickets
-- (LEFT JOIN + IS NULL)
-- ---------------------------------------------------------------------
SELECT p.passenger_id,
       p.first_name,
       p.last_name,
       p.passport_number
FROM passengers p
LEFT JOIN booking b ON b.passenger_id = p.passenger_id
WHERE b.booking_id IS NULL
ORDER BY p.passenger_id;


-- ---------------------------------------------------------------------
-- Task 14. Each airline and the total number of its flights
--          (airlines without flights are included)
-- ---------------------------------------------------------------------
SELECT a.airline_id,
       a.airline_name,
       COUNT(f.flight_id) AS flights_count
FROM airline a
LEFT JOIN flights f ON f.airline_id = a.airline_id
GROUP BY a.airline_id, a.airline_name
ORDER BY flights_count DESC, a.airline_name;


-- ---------------------------------------------------------------------
-- Task 15. Flights departing from airports of a specified country:
--          airline name, flight number, departure airport city
-- ---------------------------------------------------------------------
SELECT a.airline_name,
       f.flight_id AS flight_number,
       dep.city    AS departure_city,
       dep.country AS departure_country
FROM flights f
JOIN airline a   ON a.airline_id   = f.airline_id
JOIN airport dep ON dep.airport_id = f.departing_airport_id
WHERE dep.country = (SELECT MIN(ap2.country)
                     FROM airport ap2
                     JOIN flights f2 ON f2.departing_airport_id = ap2.airport_id)
ORDER BY f.flight_id;
