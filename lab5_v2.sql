-- =====================================================================
-- Laboratory work 5: constraints (CHECK, UNIQUE, DEFAULT)
-- Run each task separately (select the block -> F5) and take a screenshot.
-- NOTE: CHECK constraints are added with NOT VALID, so they apply to new
-- and updated rows and do not fail on old rows that already exist.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Task 1. Passengers must be at least 10 years old
-- ---------------------------------------------------------------------
ALTER TABLE passengers
ADD CONSTRAINT chk_passengers_min_age_10
CHECK (date_of_birth <= (CURRENT_DATE - INTERVAL '10 years')) NOT VALID;

SELECT conname, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conname = 'chk_passengers_min_age_10';


-- ---------------------------------------------------------------------
-- Task 2. Booking price: from 0 to 50000 tg
-- ---------------------------------------------------------------------
ALTER TABLE booking
ADD CONSTRAINT chk_booking_ticket_price_range
CHECK (ticket_price >= 0 AND ticket_price <= 50000) NOT VALID;

SELECT conname, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conname = 'chk_booking_ticket_price_range';


-- ---------------------------------------------------------------------
-- Task 3. Luggage weight between 1 and 23 kg
-- ---------------------------------------------------------------------
ALTER TABLE baggage
ADD CONSTRAINT chk_baggage_weight_1_23
CHECK (weight_in_kg BETWEEN 1 AND 23) NOT VALID;

SELECT conname, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conname = 'chk_baggage_weight_1_23';


-- ---------------------------------------------------------------------
-- Task 4. airport_name must have at least 10 characters
-- ---------------------------------------------------------------------
ALTER TABLE airport
ADD CONSTRAINT chk_airport_name_min_length
CHECK (CHAR_LENGTH(airport_name) >= 10) NOT VALID;

SELECT conname, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conname = 'chk_airport_name_min_length';


-- ---------------------------------------------------------------------
-- Task 5. UNIQUE constraints on some columns in each table
-- ---------------------------------------------------------------------
ALTER TABLE airline
ADD CONSTRAINT uq_airline_code UNIQUE (airline_code);

ALTER TABLE airport
ADD CONSTRAINT uq_airport_name_city UNIQUE (airport_name, city);

ALTER TABLE baggage
ADD CONSTRAINT uq_baggage_id_booking UNIQUE (baggage_id, booking_id);

ALTER TABLE baggage_check
ADD CONSTRAINT uq_baggage_check_id_passenger UNIQUE (baggage_check_id, passenger_id);

ALTER TABLE boarding_pass
ADD CONSTRAINT uq_boarding_pass_booking_seat UNIQUE (booking_id, seat);

ALTER TABLE booking
ADD CONSTRAINT uq_booking_id_flight_passenger UNIQUE (booking_id, flight_id, passenger_id);

ALTER TABLE booking_flight
ADD CONSTRAINT uq_booking_flight_booking_flight UNIQUE (booking_id, flight_id);

ALTER TABLE flights
ADD CONSTRAINT uq_flights_route_time
UNIQUE (airline_id, departing_airport_id, arriving_airport_id, sch_departure_time);

ALTER TABLE passengers
ADD CONSTRAINT uq_passengers_passport UNIQUE (passport_number);

ALTER TABLE security_check
ADD CONSTRAINT uq_security_check_id_passenger UNIQUE (security_check_id, passenger_id);

SELECT conrelid::regclass AS table_name,
       conname,
       pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE contype = 'u'
  AND conname LIKE 'uq\_%'
ORDER BY conrelid::regclass::text;


-- ---------------------------------------------------------------------
-- Task 6. Male passengers: at least 18 years old,
--         female passengers: at least 19 years old
-- (works for values like 'Male'/'Female' and 'M'/'F')
-- ---------------------------------------------------------------------
ALTER TABLE passengers
ADD CONSTRAINT chk_passengers_gender_age
CHECK (
    (UPPER(LEFT(gender, 1)) = 'M' AND date_of_birth <= (CURRENT_DATE - INTERVAL '18 years'))
    OR (UPPER(LEFT(gender, 1)) = 'F' AND date_of_birth <= (CURRENT_DATE - INTERVAL '19 years'))
    OR UPPER(LEFT(gender, 1)) NOT IN ('M', 'F')
) NOT VALID;

SELECT conname, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conname = 'chk_passengers_gender_age';


-- ---------------------------------------------------------------------
-- Task 7. Minimum age by country_of_citizenship:
--         Kazakhstan - 18, France - 17, other countries - 19
-- ---------------------------------------------------------------------
ALTER TABLE passengers
ADD CONSTRAINT chk_passengers_country_age
CHECK (
    CASE
        WHEN country_of_citizenship = 'Kazakhstan'
            THEN date_of_birth <= (CURRENT_DATE - INTERVAL '18 years')
        WHEN country_of_citizenship = 'France'
            THEN date_of_birth <= (CURRENT_DATE - INTERVAL '17 years')
        ELSE date_of_birth <= (CURRENT_DATE - INTERVAL '19 years')
    END
) NOT VALID;

SELECT conname, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conname = 'chk_passengers_country_age';


-- ---------------------------------------------------------------------
-- Task 8. ticket_discount column + CHECK
--         5% discount for tickets created on/after 2024-01-01,
--         10% discount for tickets created before 2024-01-01
-- ---------------------------------------------------------------------
ALTER TABLE booking
ADD COLUMN ticket_discount NUMERIC(12, 2);

UPDATE booking
SET ticket_discount = CASE
        WHEN created_at >= TIMESTAMP '2024-01-01' THEN ROUND(ticket_price * 0.05, 2)
        ELSE ROUND(ticket_price * 0.10, 2)
    END;

ALTER TABLE booking
ADD CONSTRAINT chk_booking_ticket_discount
CHECK (
    ticket_discount IS NULL
    OR ticket_discount = CASE
        WHEN created_at >= TIMESTAMP '2024-01-01' THEN ROUND(ticket_price * 0.05, 2)
        ELSE ROUND(ticket_price * 0.10, 2)
    END
);

SELECT booking_id, ticket_price, created_at, ticket_discount
FROM booking
ORDER BY booking_id
LIMIT 10;


-- ---------------------------------------------------------------------
-- Task 9. Default value 'Confirmed' for booking status,
--         then insert a booking without specifying status
-- ---------------------------------------------------------------------
ALTER TABLE booking
ALTER COLUMN status SET DEFAULT 'Confirmed';

INSERT INTO booking (booking_id, flight_id, passenger_id, booking_platform, ticket_price, ticket_discount)
OVERRIDING SYSTEM VALUE
SELECT (SELECT COALESCE(MAX(booking_id), 0) + 1 FROM booking),
       (SELECT MIN(flight_id) FROM flights),
       (SELECT MIN(passenger_id) FROM passengers),
       'Website',
       15000,
       750.00;

SELECT *
FROM booking
ORDER BY booking_id DESC
LIMIT 1;


-- ---------------------------------------------------------------------
-- Task 10. Date column is set automatically to the current date
--          (booking.created_at)
-- ---------------------------------------------------------------------
ALTER TABLE booking
ALTER COLUMN created_at SET DEFAULT CURRENT_DATE;

SELECT column_name, column_default
FROM information_schema.columns
WHERE table_name = 'booking' AND column_name = 'created_at';

-- test: insert without created_at
INSERT INTO booking (booking_id, flight_id, passenger_id, booking_platform, ticket_price, ticket_discount)
OVERRIDING SYSTEM VALUE
SELECT (SELECT COALESCE(MAX(booking_id), 0) + 1 FROM booking),
       (SELECT MIN(flight_id) FROM flights),
       (SELECT MIN(passenger_id) FROM passengers),
       'Mobile App',
       20000,
       1000.00;

SELECT booking_id, booking_platform, status, created_at
FROM booking
ORDER BY booking_id DESC
LIMIT 1;
