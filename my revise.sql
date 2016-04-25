BEGIN TRANSACTION;
DROP TABLE IF EXISTS CarHireDB.Address CASCADE;
DROP TABLE IF EXISTS CarHireDB.Location CASCADE;
DROP TABLE IF EXISTS CarHireDB.Car_bay CASCADE;
DROP TABLE IF EXISTS CarHireDB.Car_model CASCADE;
DROP TABLE IF EXISTS CarHireDB.Car CASCADE;
DROP TABLE IF EXISTS CarHireDB.Member CASCADE;
DROP TABLE IF EXISTS CarHireDB.Booking CASCADE;
DROP TABLE IF EXISTS CarHireDB.Member_phone CASCADE;
DROP TABLE IF EXISTS CarHireDB.License CASCADE;
DROP TABLE IF EXISTS CarHireDB.Membership_plan CASCADE;
DROP TABLE IF EXISTS CarHireDB.Payment_method CASCADE;
DROP TABLE IF EXISTS CarHireDB.Paypal CASCADE;
DROP TABLE IF EXISTS CarHireDB.Bank_account CASCADE;
DROP TABLE IF EXISTS CarHireDB.Credit_card CASCADE;
DROP SCHEMA IF EXISTS CarHireDB CASCADE;  
DROP DOMAIN IF EXISTS Pref;
DROP DOMAIN IF EXISTS Email;
DROP DOMAIN IF EXISTS Title;
DROP DOMAIN IF EXISTS Transimission;
DROP DOMAIN IF EXISTS Location_type;
DROP DOMAIN IF EXISTS Name_type;
--DROP FUNCTION IF EXISTS BayCheck();
--DROP TRIGGER IF EXISTS BayMaintenance;
--DROP FUNCTION IF EXISTS OverlappingTime();
--DROP TRIGGER IF EXISTS CheckOverlappingTime;
--DROP FUNCTION IF EXISTS ToPaypal();
--DROP FUNCTION IF EXISTS ToBank();
--DROP FUNCTION IF EXISTS ToCc();
--DROP TRIGGER IF EXISTS IntoPaypal;
--DROP TRIGGER IF EXISTS IntoBank;
--DROP TRIGGER IF EXISTS IntoCc;
--DROP FUNCTION IF EXISTS DelPay();
--DROP TRIGGER IF EXISTS RemovePaymentMethod;
--DROP FUNCTION IF EXISTS NewBay();
--DROP TRIGGER IF EXISTS MakeBay;
COMMIT;

BEGIN TRANSACTION;
----------
CREATE SCHEMA CarHireDB;

CREATE DOMAIN Pref INTEGER CHECK (VALUE IN (1,2,3));
CREATE DOMAIN Email VARCHAR(254) CHECK (VALUE SIMILAR TO '[\w.]+@[\w]+\.[A-Za-z]{2,}');
CREATE DOMAIN Name_type AS VARCHAR(50) CONSTRAINT Check_name CHECK ( VALUE SIMILAR TO '[A-Z][a-z]*');
--CREATE DOMAIN Name_type AS VARCHAR(50) CONSTRAINT Check_name CHECK ( VALUE SIMILAR TO '^[A-Z][a-z]+$'); THIS APPLY TO CAR BAY, LOCATION, CAR THEIR NAME

CREATE TABLE CarHireDB.Address(
    addr_id SERIAL,
    building_no INTEGER,
    street_no VARCHAR(25) NOT NULL,
    street_name VARCHAR(25) NOT NULL,
    suburb VARCHAR(25) NOT NULL,
    state VARCHAR(5) NOT NULL,
    zip CHAR(4) NOT NULL,
    PRIMARY KEY (addr_id)
);

CREATE TABLE CarHireDB.Location(
    id SERIAL,
    name VARCHAR(50) NOT NULL,
    loc_type VARCHAR(25) DEFAULT 'N/A',
    part_of INTEGER,
    PRIMARY KEY (id),
    FOREIGN KEY (part_of) REFERENCES CarHireDB.Location,
    CONSTRAINT Location_type CHECK (loc_type in ('City','Suburb','District','N/A'))
);

CREATE TABLE CarHireDB.Car_bay(
    name VARCHAR(50),-- If we create the domain name type, we can apply it to every name
    addr_id INTEGER NOT NULL,
    description VARCHAR(254),
    pos_latitude FLOAT NOT NULL,
    pos_longitude FLOAT NOT NULL,
    location_id INTEGER,
    PRIMARY KEY (name),
    FOREIGN KEY (addr_id) REFERENCES CarHireDB.Address,
    FOREIGN KEY (location_id) REFERENCES CarHireDB.Location,
    UNIQUE (pos_latitude, pos_longitude)
);

CREATE TABLE CarHireDB.Car_model(
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    category VARCHAR(25),
    capacity INTEGER,
    PRIMARY KEY (make, model)
);

CREATE TABLE CarHireDB.Car(
    regno CHAR(8),
    bay VARCHAR(50) NOT NULL,
    name VARCHAR(50) NOT NULL,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year DATE,
    transmission VARCHAR(15),
    PRIMARY KEY (regno),
    FOREIGN KEY (bay) REFERENCES CarHireDB.Car_bay ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED,
    FOREIGN KEY (make,model) REFERENCES CarHireDB.Car_model ON UPDATE CASCADE,
    UNIQUE (name),
    CONSTRAINT Car_transmission CHECK (transmission IN ('auto','manual'))
);

CREATE TABLE CarHireDB.Member(
    id SERIAL,
    prefer_method Pref NOT NULL,
    title CHAR(10) DEFAULT 'N/A' ,
    first_name Name_type NOT NULL,
    last_name Name_type NOT NULL,
    nick_name VARCHAR(50),
    address INTEGER NOT NULL,
    email Email NOT NULL,
    homebay VARCHAR(50),
    since DATE NOT NULL,
    dob DATE NOT NULL,
    password VARCHAR(255) NOT NULL,
    subscription VARCHAR(25),
    license_no VARCHAR(20) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (nick_name),
    UNIQUE (email),
    CONSTRAINT Member_title CHECK (title IN ('Mr','Mrs','Ms','Dr','Miss','Mdm','N/A')),
    CONSTRAINT Member_nickname CHECK (nick_name SIMILAR TO '[A-Za-z][[:alnum:]]{2,}'),
    CONSTRAINT Member_since CHECK (since <= NOW()),
    CONSTRAINT Member_dob CHECK (AGE(dob) >= interval '18 years')
);

CREATE TABLE CarHireDB.Booking(
    booking_no SERIAL,
    member_id INTEGER NOT NULL,
    regno CHAR(8) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    duration INTEGER NOT NULL DEFAULT 1,
    book_date DATE NOT NULL,
    PRIMARY KEY (booking_no),
    FOREIGN KEY (member_id) REFERENCES CarHireDB.Member,
    FOREIGN KEY (regno) REFERENCES CarHireDB.Car ON UPDATE CASCADE,
    CONSTRAINT Booking_positive CHECK (duration > 0),
    CONSTRAINT Booking_start CHECK (start_time > NOW()),
    CONSTRAINT Booking_made CHECK (book_date <= NOW())
    --CONSTRAINT Booking_dur CHECK (EXTRACT(EPOCH FROM (end_time - start_time)) = duration*60*60)--WHY?
    
);

CREATE TABLE CarHireDB.Member_phone(
    id INTEGER NOT NULL,
    phone_no VARCHAR(20) NOT NULL,
    PRIMARY KEY (id, phone_no),
    FOREIGN KEY (id) REFERENCES CarHireDB.Member ON DELETE CASCADE
);

CREATE TABLE CarHireDB.License(
    license_no VARCHAR(20),
    exp_date DATE NOT NULL,
    PRIMARY KEY (license_no),
    CONSTRAINT License_exp CHECK (exp_date > NOW())
);

CREATE TABLE CarHireDB.Membership_plan(
    title VARCHAR(25),
    monthly_fee MONEY,
    hourly_rate MONEY,
    km_rate MONEY,
    daily_rate MONEY,
    daily_km_rate MONEY,
    daily_km_included MONEY,
    PRIMARY KEY (title)
);

CREATE TABLE CarHireDB.Payment_method(
    member_id INTEGER NOT NULL,
    num Pref NOT NULL,
    PRIMARY KEY (member_id, num),
    FOREIGN KEY (member_id) REFERENCES CarHireDB.Member ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE CarHireDB.Paypal(
    member_id INTEGER NOT NULL,
    num Pref NOT NULL,
    email Email NOT NULL,
    PRIMARY KEY (member_id, num),
    FOREIGN KEY (member_id, num) REFERENCES CarHireDB.Payment_method ON DELETE CASCADE
);

CREATE TABLE CarHireDB.Bank_account(
    member_id INTEGER NOT NULL,
    num Pref NOT NULL,
    name VARCHAR(50) NOT NULL,-- DOMAIN NAME
    bsb CHAR(7) NOT NULL,
    account CHAR(16) NOT NULL,
    PRIMARY KEY (member_id, num),
    FOREIGN KEY (member_id, num) REFERENCES CarHireDB.Payment_method ON DELETE CASCADE,
    CONSTRAINT Bank_name CHECK (name SIMILAR TO '^[A-Z]+\s[A-Z]+$'),
    CONSTRAINT Bank_bsb CHECK (bsb SIMILAR TO '[0-9]*')
);

CREATE TABLE CarHireDB.Credit_card(
    member_id INTEGER NOT NULL,
    num Pref NOT NULL,
    expire DATE NOT NULL,
    name VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    card_no CHAR(16) NOT NULL,
    PRIMARY KEY (member_id, num),
    FOREIGN KEY (member_id, num) REFERENCES CarHireDB.Payment_method ON DELETE CASCADE,
    CONSTRAINT Cc_expiry CHECK (expire > NOW()),
    CONSTRAINT Cc_name CHECK (name SIMILAR TO '^[A-Z]+\s[A-Z]+$'),
    CONSTRAINT Cc_no CHECK (card_no SIMILAR TO '[0-9]*')
);

ALTER TABLE CarHireDB.Member
ADD FOREIGN KEY (id, prefer_method)
REFERENCES CarHireDB.Payment_method
DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE CarHireDB.Member
ADD FOREIGN KEY (address)
REFERENCES CarHireDB.Address
DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE CarHireDB.Member
ADD FOREIGN KEY (homebay)
REFERENCES CarHireDB.Car_bay
ON DELETE SET NULL
ON UPDATE CASCADE;

ALTER TABLE CarHireDB.Member
ADD FOREIGN KEY (subscription)
REFERENCES CarHireDB.Membership_plan
ON UPDATE CASCADE
DEFERRABLE INITIALLY DEFERRED;

--to be triggered before delete, update
--NB: bay cannot be deleted if cars exist in bay
CREATE OR REPLACE
FUNCTION BayCheck()
RETURNS trigger AS $$
DECLARE
rem INTEGER;
BEGIN
    SELECT COUNT(*) FROM CarHireDB.Car WHERE bay = OLD.bay INTO rem;
    IF rem < 1 THEN
        RAISE EXCEPTION 'Cannot remove last car from bay';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER BayMaintenance
AFTER DELETE OR UPDATE ON CarHireDB.Car
FOR EACH ROW
EXECUTE PROCEDURE BayCheck();
/*
--to be triggered after insertion START +DURATION AS END_TIME
CREATE OR REPLACE
FUNCTION OverlappingTime()
RETURNS trigger AS $$
DECLARE
rec RECORD;
end_time TIMESTAMP;
BEGIN
    
    FOR rec IN SELECT start_time, duration FROM CarHireDB.Booking WHERE regno = NEW.regno
    LOOP
        end_time := rec.start_time + rec.duration;
        IF (rec.start_time, rec.end_time) OVERLAPS (NEW.start_time, NEW.end_time) THEN
            RAISE EXCEPTION 'Overlapping booking';
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER CheckOverlappingTime
AFTER INSERT ON CarHireDB.Booking
FOR EACH ROW
EXECUTE PROCEDURE OverlappingTime();*/

CREATE OR REPLACE
FUNCTION ToPaypal()
RETURNS trigger AS $$
BEGIN
    IF EXISTS(SELECT num FROM CarHireDB.Bank_account WHERE member_id = NEW.member_id and num = NEW.num) THEN
        RAISE EXCEPTION 'Overlapping payment method';
    END IF;
    IF EXISTS(SELECT num FROM CarHireDB.Credit_card WHERE member_id = NEW.member_id and num = NEW.num) THEN
        RAISE EXCEPTION 'Overlapping payment method';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE
FUNCTION ToBank()
RETURNS trigger AS $$
BEGIN
    IF EXISTS(SELECT num FROM CarHireDB.Paypal WHERE member_id = NEW.member_id and num = NEW.num) THEN
        RAISE EXCEPTION 'Overlapping payment method';
    END IF;
    IF EXISTS(SELECT num FROM CarHireDB.Credit_card WHERE member_id = NEW.member_id and num = NEW.num) THEN
        RAISE EXCEPTION 'Overlapping payment method';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE
FUNCTION ToCc()
RETURNS trigger AS $$
BEGIN
    IF EXISTS(SELECT num FROM CarHireDB.Bank_account WHERE member_id = NEW.member_id and num = NEW.num) THEN
        RAISE EXCEPTION 'Overlapping payment method';
    END IF;
    IF EXISTS(SELECT num FROM CarHireDB.Paypal WHERE member_id = NEW.member_id and num = NEW.num) THEN
        RAISE EXCEPTION 'Overlapping payment method';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER IntoPaypal
AFTER INSERT ON CarHireDB.Paypal
FOR EACH ROW
EXECUTE PROCEDURE ToPaypal();

CREATE TRIGGER IntoBank
AFTER INSERT ON CarHireDB.Bank_account
FOR EACH ROW
EXECUTE PROCEDURE ToBank();

CREATE TRIGGER IntoCc
AFTER INSERT ON CarHireDB.Credit_card
FOR EACH ROW
EXECUTE PROCEDURE ToCc();

CREATE OR REPLACE
FUNCTION DelPay()
RETURNS trigger AS $$
BEGIN
    IF EXISTS(SELECT prefer_method FROM CarHireDB.Member WHERE id = OLD.member_id and num = OLD.num) THEN
        RAISE EXCEPTION 'Cannot delete preferred payment method';
    ELSE
        DELETE FROM CarHireDB.Payment_method WHERE member_id = OLD.member_id and num = OLD.num;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER RemovePaymentMethod
BEFORE DELETE ON CarHireDB.Payment_method
FOR EACH ROW
EXECUTE PROCEDURE DelPay();

CREATE OR REPLACE
FUNCTION NewBay()
RETURNS trigger AS $$
DECLARE
BEGIN
    IF NOT EXISTS(SELECT * FROM CarHireDB.Car WHERE bay = NEW.name) THEN
        RAISE EXCEPTION 'No cars in bay';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER MakeBay
AFTER INSERT ON CarHireDB.Car_bay
FOR EACH ROW
EXECUTE PROCEDURE NewBay();

CREATE OR REPLACE
FUNCTION VerifyBooking()
RETURNS trigger AS $$
DECLARE
BEGIN
    IF NEW.book_date<> OLD.book_date THEN
        RAISE EXCEPTION 'CAN NOT CHANGE THE BOOKING MAKE DATE';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER VerifyUpdateBooking
BEFORE UPDATE ON CarHireDB.Booking
FOR EACH ROW
EXECUTE PROCEDURE VerifyBooking();
----------
COMMIT;


--create member

BEGIN TRANSACTION;
    INSERT INTO CarHireDB.Member 
    VALUES (0,1,'Ms','Samantha','Huffer','SH123',1,'SamanthaHuffer@inbound.plus',null,now()-interval'4 months',now()-interval'38 years','asdsadf','silver','abc1234');
    INSERT INTO CarHireDB.Address
    VALUES(1,null,'5','Fergusson Street','SHANNON BROOK','NSW','2470'); 
    INSERT INTO CarHireDB.Payment_method
    VALUES(0,1);
    INSERT INTO CarHireDB.Paypal
    VALUES(0,1,'SamanthaHuffer@inbound.plus');
    INSERT INTO CarHireDB.Membership_plan
    VALUES('silver');
COMMIT;

--create car
BEGIN TRANSACTION;
    INSERT INTO CarHireDB.Car_model
    VALUES('Ford','LTD04','Limo',5);
    INSERT INTO CarHireDB.Car
    VALUES('QSA800','in','our limo','Ford','LTD04',NULL,'auto');
    INSERT INTO CarHireDB.Car_bay
    VALUES('in',1,null,19.02,324.34,null);
COMMIT;
BEGIN TRANSACTION;
    
    INSERT INTO CarHireDB.Car
    VALUES('AS800','in','limo2','Ford','LTD04',NULL,'auto');
   
COMMIT;
--delete car
BEGIN TRANSACTION;
    --DELETE FROM CarHireDB.Car where regno='QSA800';
COMMIT;

--CREATE BOOKING
BEGIN TRANSACTION;
    INSERT INTO CarHireDB.Booking
    VALUES (1,0,'QSA800',now()+interval '9 hours',5,now());
COMMIT;

UPDATE CarHireDB.BOoking SET book_date=now() where regno = 'QSA800'