/*
DATABASE — LABORATORY WORK 7: INDEXES
Database: Airport Database (PostgreSQL / pgAdmin 4)

IMPORTANT: This script is adapted to the schema used in your previous labs.
Known column-name differences from the worksheet:
  flights.actual_departure       -> flights.act_departure_time
  flights.scheduled_departure    -> flights.sch_departure_time
  flights.departure_airport_id   -> flights.departing_airport_id
  flights.arrival_airport_id     -> flights.arriving_airport_id
  booking.price                 -> booking.ticket_price
  flights.flight_no / flights.status were NOT present in the schema recorded
  from your previous labs. The script uses flight_id as the flight number
  in the JOIN task and includes checks/instructions for the missing status column.
Run sections one by one and take a full-page screenshot of each task's SQL + output.
*/

-- ============================================================
-- 0. CHECK THE CURRENT TABLE STRUCTURE
-- ============================================================
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN
      ('flights', 'passengers', 'booking', 'booking_flight',
       'baggage', 'airport', 'airline')
ORDER BY table_name, ordinal_position;


-- ============================================================
-- 1. INDEX ON ACTUAL DEPARTURE
-- Worksheet: actual_departure; in our schema: act_departure_time
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_flights_act_departure_time
ON flights (act_departure_time);

-- Unique index for flight number + scheduled departure.
-- Our flights table has no flight_no column in the known schema.
-- flight_id is already the primary key, so do NOT create a fake flight_no.
-- The equivalent uniqueness check on the available scheduled time is:
-- (This may fail if two flights share the same scheduled departure time.)
-- CREATE UNIQUE INDEX idx_flights_flight_id_sch_departure
-- ON flights (flight_id, sch_departure_time);


-- ============================================================
-- 2. COMPOSITE INDEX ON DEPARTURE + ARRIVAL AIRPORT
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_flights_departing_arriving_airports
ON flights (departing_airport_id, arriving_airport_id);

ANALYZE flights;

-- ============================================================
-- 3. COMPARE PERFORMANCE WITH AND WITHOUT THE AIRPORT INDEX
-- First temporarily disable index/bitmap scans to observe a sequential
-- scan, then allow the planner to choose the index.
-- EXPLAIN ANALYZE actually executes the SELECT.
-- ============================================================
SET enable_indexscan = OFF;
SET enable_bitmapscan = OFF;

EXPLAIN ANALYZE
SELECT *
FROM flights
WHERE departing_airport_id = 1
  AND arriving_airport_id = 2;

RESET enable_indexscan;
RESET enable_bitmapscan;

EXPLAIN ANALYZE
SELECT *
FROM flights
WHERE departing_airport_id = 1
  AND arriving_airport_id = 2;


-- ============================================================
-- 4. CHECK INDEX USAGE WITH EXPLAIN ANALYZE
-- ============================================================
EXPLAIN ANALYZE
SELECT *
FROM flights
WHERE departing_airport_id = 1
  AND arriving_airport_id = 2;


-- ============================================================
-- 5. UNIQUE INDEX ON PASSENGERS.PASSPORT_NUMBER
-- Check duplicates first. If this query returns rows, the unique
-- index cannot be created until duplicate passport numbers are fixed.
-- ============================================================
SELECT passport_number, COUNT(*) AS copies
FROM passengers
GROUP BY passport_number
HAVING COUNT(*) > 1;

-- Create the unique index (run after confirming there are no duplicates).
CREATE UNIQUE INDEX IF NOT EXISTS idx_passengers_passport_number_unique
ON passengers (passport_number);

-- Insert two new passengers, only if these passport numbers do not exist.
-- Change the values if your teacher requires specific passenger details.
INSERT INTO passengers
    (first_name, last_name, date_of_birth, gender,
     country_of_citizenship, country_of_residence, passport_number)
SELECT 'Alex', 'Morgan', DATE '1990-05-12', 'Male',
       'USA', 'USA', 'LAB7PASS0001'
WHERE NOT EXISTS (
    SELECT 1 FROM passengers WHERE passport_number = 'LAB7PASS0001'
);

INSERT INTO passengers
    (first_name, last_name, date_of_birth, gender,
     country_of_citizenship, country_of_residence, passport_number)
SELECT 'Maria', 'Santos', DATE '1992-08-21', 'Female',
       'Philippines', 'Philippines', 'LAB7PASS0002'
WHERE NOT EXISTS (
    SELECT 1 FROM passengers WHERE passport_number = 'LAB7PASS0002'
);

-- Try to insert a duplicate passport number.
-- Expected result: ERROR because the UNIQUE index prevents duplicates.
-- Run this statement separately to capture the error for the explanation.
-- INSERT INTO passengers
--     (first_name, last_name, date_of_birth, gender,
--      country_of_citizenship, country_of_residence, passport_number)
-- VALUES ('Test', 'Duplicate', DATE '1995-01-01', 'Male',
--         'USA', 'USA', 'LAB7PASS0001');

SELECT passenger_id, first_name, last_name, passport_number
FROM passengers
WHERE passport_number IN ('LAB7PASS0001', 'LAB7PASS0002');


-- ============================================================
-- 6. COMPOSITE INDEX ON PASSENGER NAME, DOB AND CITIZENSHIP
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_passengers_name_dob_citizenship
ON passengers (first_name, last_name, date_of_birth, country_of_citizenship);

ANALYZE passengers;

-- Worksheet asks for Philippines + birth year 1984.
-- This query filters by citizenship and date of birth. The composite
-- index starts with first_name, so PostgreSQL may not use it efficiently
-- for this query (leftmost-prefix rule).
EXPLAIN ANALYZE
SELECT *
FROM passengers
WHERE country_of_citizenship = 'Philippines'
  AND date_of_birth >= DATE '1984-01-01'
  AND date_of_birth <  DATE '1985-01-01';

-- A query using the leading columns can use the composite index:
EXPLAIN ANALYZE
SELECT *
FROM passengers
WHERE first_name = 'Maria'
  AND last_name = 'Santos'
  AND date_of_birth = DATE '1992-08-21'
  AND country_of_citizenship = 'Philippines';


-- ============================================================
-- 7. LIST INDEXES FOR PASSENGERS, THEN DROP CREATED INDEXES
-- Keep the passport unique index for the later duplicate test only if
-- you want it to remain. The DROP statements below remove Lab 7 indexes.
-- ============================================================
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'passengers'
ORDER BY indexname;

-- Drop indexes created in this lab for the Passengers table.
DROP INDEX IF EXISTS idx_passengers_name_dob_citizenship;
DROP INDEX IF EXISTS idx_passengers_passport_number_unique;


-- ============================================================
-- 8. INDEX ON BOOKING.PASSENGER_ID — BEFORE AND AFTER
-- ============================================================
ANALYZE booking;

-- BEFORE creating the index:
EXPLAIN ANALYZE
SELECT *
FROM booking
WHERE passenger_id = 100;

CREATE INDEX IF NOT EXISTS idx_booking_passenger_id
ON booking (passenger_id);

ANALYZE booking;

-- AFTER creating the index:
EXPLAIN ANALYZE
SELECT *
FROM booking
WHERE passenger_id = 100;


-- ============================================================
-- 9. COMPOSITE INDEX ON BOOKING_FLIGHT (BOOKING_ID, FLIGHT_ID)
-- JOIN query: our schema uses ticket_price, and flight_id is shown
-- as flight_no because no flight_no column exists in the known schema.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_booking_flight_booking_flight
ON booking_flight (booking_id, flight_id);

ANALYZE booking_flight;
ANALYZE booking;
ANALYZE flights;

EXPLAIN ANALYZE
SELECT
    f.flight_id AS flight_no,
    b.ticket_price AS price
FROM booking AS b
JOIN booking_flight AS bf
    ON bf.booking_id = b.booking_id
JOIN flights AS f
    ON f.flight_id = bf.flight_id
WHERE b.ticket_price > 9000;


-- ============================================================
-- 10. INDEX ON FLIGHTS.STATUS — COLUMN CHECK
-- The flights table structure recorded from your earlier labs did not
-- contain a status column. Run the check below.
-- If it returns no row, do not run the two EXPLAIN queries until your
-- instructor's version of the table has a flights.status column.
-- ============================================================
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'flights'
  AND column_name = 'status';

-- If flights.status exists in your actual database, uncomment and run:
-- CREATE INDEX IF NOT EXISTS idx_flights_status ON flights (status);
-- ANALYZE flights;
-- EXPLAIN ANALYZE SELECT * FROM flights WHERE status = 'Departed';
-- EXPLAIN ANALYZE SELECT * FROM flights WHERE status = 'Boarding';


-- ============================================================
-- 11. INDEX ON BAGGAGE.WEIGHT_IN_KG — RANGE QUERIES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_baggage_weight_in_kg
ON baggage (weight_in_kg);

ANALYZE baggage;

EXPLAIN ANALYZE
SELECT *
FROM baggage
WHERE weight_in_kg > 49;

EXPLAIN ANALYZE
SELECT *
FROM baggage
WHERE weight_in_kg > 5;


-- ============================================================
-- 12. INDEX ON AIRPORT_NAME — LIKE PATTERNS
-- A normal B-tree index may support LIKE 'A%' under suitable collation/
-- operator-class conditions, but normally cannot support LIKE '%Airport'.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_airport_airport_name
ON airport (airport_name);

ANALYZE airport;

EXPLAIN ANALYZE
SELECT *
FROM airport
WHERE airport_name LIKE 'A%';

EXPLAIN ANALYZE
SELECT *
FROM airport
WHERE airport_name LIKE '%Airport';


-- ============================================================
-- 13. COMPOSITE INDEX ON AIRPORT(COUNTRY, CITY)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_airport_country_city
ON airport (country, city);

ANALYZE airport;

-- First column only: can use the composite index.
EXPLAIN ANALYZE
SELECT *
FROM airport
WHERE country = 'Philippines';

-- Second column only: generally cannot use the (country, city) index
-- efficiently because the leading country column is not constrained.
EXPLAIN ANALYZE
SELECT *
FROM airport
WHERE city = 'Manila';

-- Both columns: can use the composite index.
EXPLAIN ANALYZE
SELECT *
FROM airport
WHERE country = 'Philippines'
  AND city = 'Manila';


-- ============================================================
-- 14. EXPRESSION INDEX ON LOWER(PASSENGERS.LAST_NAME)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_passengers_lower_last_name
ON passengers (LOWER(last_name));

ANALYZE passengers;

-- This expression matches the index:
EXPLAIN ANALYZE
SELECT *
FROM passengers
WHERE LOWER(last_name) = 'irnis';

-- This condition does not match the expression index:
EXPLAIN ANALYZE
SELECT *
FROM passengers
WHERE last_name = 'Irnis';


-- ============================================================
-- 15. COVERING INDEX ON BOOKING(PASSENGER_ID, TICKET_PRICE)
-- PostgreSQL syntax: INCLUDE makes ticket_price available in the index
-- without making it a search key.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_booking_passenger_price_cover
ON booking (passenger_id)
INCLUDE (ticket_price);

ANALYZE booking;

EXPLAIN ANALYZE
SELECT ticket_price
FROM booking
WHERE passenger_id = 100;


-- ============================================================
-- 16. UNIQUE INDEX ON AIRLINE.AIRLINE_CODE
-- First find duplicate non-NULL values. NULLs do not conflict under
-- a normal PostgreSQL UNIQUE index (multiple NULLs are allowed).
-- ============================================================
SELECT airline_code, COUNT(*) AS copies
FROM airline
WHERE airline_code IS NOT NULL
GROUP BY airline_code
HAVING COUNT(*) > 1;

-- If the duplicate query returns no rows, create the unique index:
CREATE UNIQUE INDEX IF NOT EXISTS idx_airline_airline_code_unique
ON airline (airline_code);

-- If creation fails because duplicates exist, inspect the conflicting rows:
-- SELECT *
-- FROM airline
-- WHERE airline_code IN (
--     SELECT airline_code
--     FROM airline
--     WHERE airline_code IS NOT NULL
--     GROUP BY airline_code
--     HAVING COUNT(*) > 1
-- )
-- ORDER BY airline_code;

-- Do not delete or change airline records without checking with your
-- instructor. After correcting duplicate values, run CREATE UNIQUE INDEX
-- again.


-- ============================================================
-- OPTIONAL: SHOW ALL INDEXES CREATED FOR THIS LAB
-- ============================================================
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;
