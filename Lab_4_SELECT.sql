-- AIRPORT DATABASE - LABORATORY WORK 4
-- SELECT queries
-- Run in pgAdmin Query Tool while connected to the Airport database.
-- This file only reads data. It does not INSERT, UPDATE or DELETE anything.
-- flight_id is used as the flight number because the Lab 2 schema has no
-- separate flight_number column.

-- 1. Display airline names in uppercase.
SELECT UPPER(airline_name) AS airline_name_upper
FROM airline;

-- 2. Replace 'Air' with 'Aero' in airline names.
SELECT airline_name,
       REPLACE(airline_name, 'Air', 'Aero') AS modified_airline_name
FROM airline;

-- 3. Find flights operated by airline 1 or airline 2.
SELECT flight_id, airline_id
FROM flights
WHERE airline_id IN (1, 2)
ORDER BY flight_id;

-- 4. Find airports whose names contain 'Regional' or 'Air'.
SELECT airport_id, airport_name, city
FROM airport
WHERE airport_name ILIKE '%Regional%'
   OR airport_name ILIKE '%Air%'
ORDER BY airport_name;

-- 5. Show passenger names and date of birth in Month DD, YYYY format.
SELECT first_name, last_name,
       TO_CHAR(date_of_birth, 'FMMonth DD, YYYY') AS date_of_birth
FROM passengers
ORDER BY last_name, first_name;

-- 6. Find flight IDs where actual arrival was later than scheduled arrival.
SELECT flight_id, sch_arrival_time, act_arrival_time
FROM flights
WHERE act_arrival_time > sch_arrival_time
ORDER BY flight_id;

-- 7. Show late flights with their scheduled and actual arrival times.
SELECT flight_id, airline_id, sch_arrival_time, act_arrival_time,
       act_arrival_time - sch_arrival_time AS arrival_delay
FROM flights
WHERE act_arrival_time > sch_arrival_time
ORDER BY arrival_delay DESC;

-- 8. Find airlines from France, Portugal or Poland created
-- between November 1, 2023 and March 31, 2024 (inclusive).
SELECT airline_id, airline_name, airline_country, created_at
FROM airline
WHERE airline_country IN ('France', 'Portugal', 'Poland')
  AND created_at >= TIMESTAMP '2023-11-01'
  AND created_at < TIMESTAMP '2024-04-01'
ORDER BY created_at;

-- 9. Show the 3 heaviest baggage records above 25 kg.
SELECT baggage_id, booking_id, weight_in_kg
FROM baggage
WHERE weight_in_kg > 25
ORDER BY weight_in_kg DESC
LIMIT 3;

-- 10. Find the youngest passenger (or passengers if there is a tie).
SELECT first_name, last_name, date_of_birth
FROM passengers
WHERE date_of_birth = (SELECT MAX(date_of_birth) FROM passengers);

-- 11. Find the cheapest ticket price on each booking platform.
SELECT booking_platform, MIN(ticket_price) AS cheapest_ticket_price
FROM booking
GROUP BY booking_platform
ORDER BY booking_platform;

-- 12. Find airlines whose airline_code contains at least one digit.
SELECT airline_id, airline_name, airline_code
FROM airline
WHERE airline_code ~ '[0-9]';

-- 13. Show the 5 most recently created airlines.
SELECT airline_id, airline_name, airline_country, created_at
FROM airline
ORDER BY created_at DESC
LIMIT 5;

-- 14. Find baggage checks for booking IDs from 200 to 300,
-- excluding records whose result is 'Checked'.
SELECT booking_id, baggage_check_id, check_result
FROM baggage_check
WHERE booking_id BETWEEN 200 AND 300
  AND check_result <> 'Checked'
ORDER BY booking_id;

-- 15. Find baggage checks updated earlier than they were created,
-- but in the same calendar month and year.
SELECT baggage_check_id, created_at, updated_at, check_result
FROM baggage_check
WHERE updated_at < created_at
  AND DATE_TRUNC('month', updated_at) = DATE_TRUNC('month', created_at)
ORDER BY created_at;

