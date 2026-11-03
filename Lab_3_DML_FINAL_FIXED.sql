-- LABORATORY WORK 3: DML
-- Airport database | PostgreSQL / pgAdmin 4
-- This corrected script is for the Airport database created in Lab 2.
-- IMPORTANT: It clears the current contents of the 10 Lab 2 tables first,
-- then rebuilds clean sample data and performs all 15 tasks.
-- Use this only if Airport contains your practice data, not real data.
-- Run this script ONCE.

-- RESET practice tables so IDs and foreign keys are predictable.
TRUNCATE TABLE
    security_check, boarding_pass, baggage_check, baggage,
    booking_flight, booking, flights, passengers, airport, airline
RESTART IDENTITY CASCADE;

-- Task 1: Generate and insert 200 random passengers.
INSERT INTO passengers
    (passenger_id, first_name, last_name, date_of_birth, gender,
     country_of_citizenship, country_of_residence, passport_number)
SELECT
    n,
    'Passenger' || n,
    'Surname' || n,
    DATE '1975-01-01' + (random() * 15000)::int,
    CASE WHEN random() < 0.5 THEN 'Male' ELSE 'Female' END,
    (ARRAY['Kazakhstan', 'France', 'Turkey', 'United Kingdom'])[1 + (n % 4)],
    (ARRAY['Kazakhstan', 'France', 'Turkey', 'United Kingdom'])[1 + (n % 4)],
    'PASS' || LPAD(n::text, 6, '0')
FROM generate_series(1, 200) AS n;

-- Create four base airlines. Explicit IDs make the exercise reproducible.
INSERT INTO airline (airline_id, airline_code, airline_name, airline_country)
VALUES
    (1, 'BASE1', 'North Star Air', 'Kazakhstan'),
    (2, 'BASE2', 'Blue Sky Airlines', 'France'),
    (3, 'BASE3', 'Eastern Wings', 'Brazil'),
    (4, 'BASE4', 'Pacific Air', 'Poland');

-- Allow NULL in state because Task 10 explicitly asks for missing states.
ALTER TABLE airport ALTER COLUMN state DROP NOT NULL;

-- Airports used by flights and Tasks 10 and 14.
INSERT INTO airport (airport_id, airport_name, country, state, city)
VALUES
    (1, 'Almaty International Airport', 'Kazakhstan', 'Almaty Region', 'Almaty'),
    (2, 'Astana International Airport', 'Kazakhstan', 'Astana Region', 'Astana'),
    (3, 'Charles de Gaulle Airport', 'France', 'Ile-de-France', 'Paris'),
    (4, 'Heathrow Airport', 'United Kingdom', 'England', 'London'),
    (5, 'Haneda Airport', 'Japan', 'Tokyo Prefecture', 'Tokyo'),
    (6, 'Mlawe Regional Airport', 'Exampleland', NULL, 'Mlawe'),
    (7, 'Kepuh Regional Airport', 'Exampleland', NULL, 'Kepuh');

-- Create 200 flights. Flights 1-30 arrive in 2024; 31-200 arrive in 2023.
INSERT INTO flights
    (flight_id, sch_departure_time, sch_arrival_time,
     departing_airport_id, arriving_airport_id, departing_gate,
     arriving_gate, airline_id, act_departure_time, act_arrival_time)
SELECT
    n,
    CASE WHEN n <= 30
         THEN TIMESTAMP '2024-01-01 08:00:00' + n * INTERVAL '5 days'
         ELSE TIMESTAMP '2023-01-01 08:00:00' + (n - 31) * INTERVAL '1 day'
    END,
    CASE WHEN n <= 30
         THEN TIMESTAMP '2024-01-01 11:00:00' + n * INTERVAL '5 days'
         ELSE TIMESTAMP '2023-01-01 11:00:00' + (n - 31) * INTERVAL '1 day'
    END,
    1 + (n % 4),
    1 + ((n + 1) % 5),
    'Gate-' || (1 + (n % 10)),
    'Gate-' || (1 + (n % 10)),
    1 + (n % 4),
    CASE WHEN n <= 30
         THEN TIMESTAMP '2024-01-01 08:05:00' + n * INTERVAL '5 days'
         ELSE TIMESTAMP '2023-01-01 08:05:00' + (n - 31) * INTERVAL '1 day'
    END,
    CASE WHEN n <= 30
         THEN TIMESTAMP '2024-01-01 11:10:00' + n * INTERVAL '5 days'
         ELSE TIMESTAMP '2023-01-01 11:10:00' + (n - 31) * INTERVAL '1 day'
    END
FROM generate_series(1, 200) AS n;

-- Add 170 bookings for flights 31-200 (no bookings on 2024 flights).
INSERT INTO booking
    (booking_id, flight_id, passenger_id, booking_platform,
     created_at, updated_at, status, ticket_price)
SELECT
    n - 30,
    n,
    n,
    (ARRAY['Website', 'Mobile App', 'Travel Agency'])[1 + (n % 3)],
    CASE WHEN n % 20 = 0
         THEN TIMESTAMP '2024-03-10 10:00:00'
         ELSE TIMESTAMP '2023-01-01 10:00:00' + n * INTERVAL '2 days'
    END,
    CURRENT_TIMESTAMP,
    'Confirmed',
    CASE WHEN n % 25 = 0 THEN 8000.00 ELSE (15000 + n * 100)::decimal(7,2) END
FROM generate_series(31, 200) AS n;

INSERT INTO booking_flight (booking_id, flight_id)
SELECT booking_id, flight_id FROM booking;

INSERT INTO baggage (weight_in_kg, booking_id)
SELECT (5 + (booking_id % 30))::decimal(4,2), booking_id FROM booking;

-- Baggage checks include old and March 2024 Not checked rows.
INSERT INTO baggage_check (check_result, created_at, updated_at, booking_id, passenger_id)
SELECT
    CASE WHEN b.booking_id % 3 = 0 THEN 'Not checked'
         WHEN b.booking_id % 3 = 1 THEN 'Checked'
         ELSE 'Pending' END,
    CASE WHEN b.booking_id % 10 = 0
         THEN TIMESTAMP '2023-05-15 09:00:00'
         WHEN b.booking_id % 10 = 1
         THEN TIMESTAMP '2024-03-15 09:00:00'
         ELSE TIMESTAMP '2024-06-15 09:00:00' + b.booking_id * INTERVAL '1 day'
    END,
    CURRENT_TIMESTAMP,
    b.booking_id,
    b.passenger_id
FROM booking b;

INSERT INTO boarding_pass (booking_id, seat, boarding_time)
SELECT booking_id, '12A', CURRENT_TIMESTAMP FROM booking;

INSERT INTO security_check (check_result, passenger_id)
SELECT 'Passed', passenger_id FROM passengers;

-- Task 2: Add KazAir based in Kazakhstan. It receives airline_id = 5.
INSERT INTO airline (airline_id, airline_code, airline_name, airline_country)
VALUES (5, 'KAZ', 'KazAir', 'Kazakhstan');

-- Task 3: Update KazAir country to Turkey.
UPDATE airline
SET airline_country = 'Turkey', updated_at = CURRENT_TIMESTAMP
WHERE airline_name = 'KazAir';

-- Task 4: Add three airlines at once.
INSERT INTO airline (airline_id, airline_code, airline_name, airline_country)
VALUES
    (6, 'EASY', 'AirEasy', 'France'),
    (7, 'FLYH', 'FlyHigh', 'Brazil'),
    (8, 'FLYF', 'FlyFly', 'Poland');

-- Task 5: Delete all flights whose scheduled arrival was in 2024.
DELETE FROM flights
WHERE sch_arrival_time >= TIMESTAMP '2024-01-01'
  AND sch_arrival_time < TIMESTAMP '2025-01-01';

-- Task 6: Increase all ticket prices by 15%.
UPDATE booking
SET ticket_price = ROUND(ticket_price * 1.15, 2),
    updated_at = CURRENT_TIMESTAMP;

-- Task 7: Delete tickets with price less than 10000.
-- Delete dependent rows first to respect foreign keys.
DELETE FROM baggage_check
WHERE booking_id IN (SELECT booking_id FROM booking WHERE ticket_price < 10000);
DELETE FROM baggage
WHERE booking_id IN (SELECT booking_id FROM booking WHERE ticket_price < 10000);
DELETE FROM boarding_pass
WHERE booking_id IN (SELECT booking_id FROM booking WHERE ticket_price < 10000);
DELETE FROM booking_flight
WHERE booking_id IN (SELECT booking_id FROM booking WHERE ticket_price < 10000);
DELETE FROM booking
WHERE ticket_price < 10000;

-- Task 8: Replace missing airline codes with UNK.
-- Lab 2 made airline_code NOT NULL; relax it for this task.
ALTER TABLE airline ALTER COLUMN airline_code DROP NOT NULL;
UPDATE airline
SET airline_code = 'UNK', updated_at = CURRENT_TIMESTAMP
WHERE airline_code IS NULL;

-- Task 9: Delete baggage checks before June 1, 2023 still marked Not checked.
DELETE FROM baggage_check
WHERE created_at < TIMESTAMP '2023-06-01'
  AND check_result = 'Not checked';

-- Task 10: Delete airports with NULL state in Mlawe or Kepuh.
DELETE FROM airport
WHERE state IS NULL
  AND city IN ('Mlawe', 'Kepuh');

-- Task 11: Insert a new unchecked baggage check and return its ID and timestamp.
INSERT INTO baggage_check (check_result, booking_id, passenger_id)
SELECT 'Not checked', booking_id, passenger_id
FROM booking
ORDER BY booking_id
LIMIT 1
RETURNING baggage_check_id, created_at;

-- Task 12: Convert all airline country names to uppercase.
UPDATE airline
SET airline_country = UPPER(airline_country),
    updated_at = CURRENT_TIMESTAMP;

-- Task 13: Update airline_id = 5.
UPDATE airline
SET airline_name = 'Global Airways',
    airline_country = 'United Kingdom',
    updated_at = CURRENT_TIMESTAMP
WHERE airline_id = 5;

-- Task 14: Set state for airports in Astana, London and Tokyo.
UPDATE airport
SET state = 'Capital District',
    updated_at = CURRENT_TIMESTAMP
WHERE city IN ('Astana', 'London', 'Tokyo');

-- Task 15: Mark March 2024 Not checked baggage checks as Checked.
UPDATE baggage_check
SET check_result = 'Checked',
    updated_at = CURRENT_TIMESTAMP
WHERE created_at >= TIMESTAMP '2024-03-01'
  AND created_at < TIMESTAMP '2024-04-01'
  AND check_result = 'Not checked';

-- Synchronize identity sequences after using explicit IDs.
SELECT setval(pg_get_serial_sequence('passengers', 'passenger_id'), 200, true);
SELECT setval(pg_get_serial_sequence('airline', 'airline_id'), 8, true);
SELECT setval(pg_get_serial_sequence('airport', 'airport_id'), 7, true);
SELECT setval(pg_get_serial_sequence('flights', 'flight_id'), 200, true);
SELECT setval(pg_get_serial_sequence('booking', 'booking_id'),
              GREATEST((SELECT COALESCE(MAX(booking_id), 1) FROM booking), 1), true);

-- FINAL VERIFICATION
SELECT 'passengers' AS table_name, COUNT(*) AS rows_count FROM passengers
UNION ALL SELECT 'airline', COUNT(*) FROM airline
UNION ALL SELECT 'airport', COUNT(*) FROM airport
UNION ALL SELECT 'flights', COUNT(*) FROM flights
UNION ALL SELECT 'booking', COUNT(*) FROM booking
UNION ALL SELECT 'baggage_check', COUNT(*) FROM baggage_check
ORDER BY table_name;

SELECT airline_id, airline_name, airline_country, airline_code
FROM airline
ORDER BY airline_id;

SELECT city, state
FROM airport
ORDER BY city;
