﻿BEGIN TRANSACTION;
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
DROP DOMAIN IF EXISTS MemberName_type;
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

--Create domain for certain type of data using several entity,but for title 
--Or transimiss we only use once, we put the check inside create table

--This applys to all payment method related entities
CREATE DOMAIN Pref INTEGER CHECK (VALUE IN (1,2,3));

--This applys to member's email and paypal's email
CREATE DOMAIN Email VARCHAR(254) 
CHECK (VALUE SIMILAR TO '[\w.]+@[\w]+\.[A-Za-z]{2,}');

--This applys to member firstname and lastname
CREATE DOMAIN MemberName_type AS VARCHAR(50) CONSTRAINT 
CheckPeople_name CHECK ( VALUE SIMILAR TO '[A-Z][a-z]*');
--Only alphabet can use in first name and last name

--THIS APPLY TO CAR BAY, LOCATION, CAR THEIR NAME 
CREATE DOMAIN Name_type AS VARCHAR(50) 
CONSTRAINT Check_name CHECK ( VALUE SIMILAR TO '[a-zA-Z0-9\s]{2,}'); 
--min 3 charactors not allowed symbol in the name.

CREATE TABLE CarHireDB.Address(
    addr_id SERIAL,
    building_no VARCHAR(25),
    street_no VARCHAR(25) NOT NULL,
    street_name VARCHAR(25) NOT NULL,
    suburb VARCHAR(25) NOT NULL,
    state VARCHAR(5) NOT NULL,
    zip CHAR(4) NOT NULL,
    PRIMARY KEY (addr_id)
);

CREATE TABLE CarHireDB.Location(
    id SERIAL,
    name Name_type NOT NULL,
    loc_type VARCHAR(25) DEFAULT 'N/A',
    part_of INTEGER,
    PRIMARY KEY (id),
    FOREIGN KEY (part_of) REFERENCES CarHireDB.Location,
    CONSTRAINT Location_type CHECK (loc_type in ('City','Suburb','District','N/A'))
);

CREATE TABLE CarHireDB.Car_bay(
    name Name_type,
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
    name Name_type NOT NULL,
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
    first_name MemberName_type NOT NULL,
    last_name MemberName_type NOT NULL,
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
    duration INTEGER NOT NULL ,
    book_date DATE DEFAULT NOW()NOT NULL,
    PRIMARY KEY (booking_no),
    FOREIGN KEY (member_id) REFERENCES CarHireDB.Member,
    FOREIGN KEY (regno) REFERENCES CarHireDB.Car ON UPDATE CASCADE,
    CONSTRAINT Booking_positive CHECK (duration > 0),
    CONSTRAINT Booking_start CHECK (start_time > NOW()),
    CONSTRAINT Booking_made CHECK (book_date <= NOW())

    
);

CREATE TABLE CarHireDB.Member_phone( 
    id INTEGER NOT NULL,
    phone VARCHAR(20) NOT NULL,
    PRIMARY KEY (id, phone),
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
    name VARCHAR(50) NOT NULL,
    bsb CHAR(6) NOT NULL,
    account CHAR(16) NOT NULL,
    PRIMARY KEY (member_id, num),
    FOREIGN KEY (member_id, num) REFERENCES CarHireDB.Payment_method ON DELETE CASCADE,
    CONSTRAINT Bank_name CHECK (name SIMILAR TO '[A-Z\.\s]*'), --Only allow capital and space and dot
    CONSTRAINT Bank_bsb CHECK (bsb SIMILAR TO '[0-9]*') --Only allow 6 digits 
);

CREATE TABLE CarHireDB.Credit_card(
    member_id INTEGER NOT NULL,
    num Pref NOT NULL,
    expire DATE NOT NULL,
    name VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    card_no VARCHAR(16) NOT NULL,
    PRIMARY KEY (member_id, num),
    FOREIGN KEY (member_id, num) REFERENCES CarHireDB.Payment_method ON DELETE CASCADE,
    CONSTRAINT Cc_expiry CHECK (expire > NOW()),
    CONSTRAINT Cc_name CHECK (name SIMILAR TO '[A-Z]{3,}\s[A-Z]{3,}'),--minimum 3 charactors of first_name and last name and only 1 space allowed
    CONSTRAINT Cc_no CHECK (card_no SIMILAR TO '[0-9]*')-- only allow numbers
);


--Add all the deferable constraint to group the member create in one transaction.
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

--Fire after insert to member's payment method to prevent overlap in paypal or bank_card or credit_card table
--enforce the disjoin constraint 

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


--Fire before detele prefer_method from payment_method.
CREATE OR REPLACE
FUNCTION DelPay()
RETURNS trigger AS $$
BEGIN
    IF EXISTS(SELECT id , prefer_method FROM CarHireDB.Member WHERE id = OLD.member_id and prefer_method = OLD.num) THEN
        RAISE EXCEPTION 'Cannot delete preferred payment method';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER RemovePaymentMethod
BEFORE DELETE ON CarHireDB.Payment_method
FOR EACH ROW
EXECUTE PROCEDURE DelPay();


--Fire after we create an empty car bay
CREATE OR REPLACE
FUNCTION NewBay()
RETURNS trigger AS $$
DECLARE
BEGIN
    IF NOT EXISTS(SELECT * FROM CarHireDB.Car WHERE bay = NEW.name) THEN
        RAISE EXCEPTION 'Cannot create car bay without a car';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER MakeBay
AFTER INSERT ON CarHireDB.Car_bay
FOR EACH ROW
EXECUTE PROCEDURE NewBay();

--To be triggered before delete, update
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

--To be triggered after insertion
--booking can't be inserted or updated if there is overlap
CREATE OR REPLACE
FUNCTION OverlappingTime()
RETURNS trigger AS $$
DECLARE
rec RECORD;
BEGIN
    
    FOR rec IN SELECT start_time, start_time+(duration*interval '1 hour') as end_time FROM CarHireDB.Booking WHERE regno = NEW.regno
    LOOP
        IF (rec.start_time, rec.end_time) OVERLAPS (NEW.start_time, NEW.start_time+(NEW.duration*interval '1 hour')) THEN
            RAISE EXCEPTION 'Overlapping booking';
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER CheckOverlappingTime
BEFORE INSERT OR UPDATE ON CarHireDB.Booking
FOR EACH ROW
EXECUTE PROCEDURE OverlappingTime();


--Fire when people update book_date of booking
CREATE OR REPLACE
FUNCTION VerifyUpdateBooking()
RETURNS trigger AS $$
DECLARE
BEGIN
    IF NEW.book_date<> OLD.book_date THEN
        RAISE EXCEPTION 'CAN NOT CHANGE THE BOOKING MAKE DATE';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER CheckBookingUpdate
BEFORE UPDATE ON CarHireDB.Booking
FOR EACH ROW
EXECUTE PROCEDURE VerifyUpdateBooking();
----------
COMMIT;

--Create some base information to create cars and car bays.

BEGIN TRANSACTION;
    INSERT INTO CarHireDB.Location(name)
    VALUES('Big Blue');
    INSERT INTO CarHireDB.Address(street_no,street_name,suburb,state,zip)
    VALUES('10','Woerdens Road','RAYMOND TERRACE EAST','NSW','2324'); 
    INSERT INTO CarHireDB.Address(building_no,street_no,street_name,suburb,state,zip)
    VALUES('Unit45','66','Peninsula Drive','KURNELL','NSW','2231'); 
COMMIT;
--Create 2 car(we can not create a car bay without a car 
--So we aggregate these 2 creations in 1 transaction)
BEGIN TRANSACTION;
    INSERT INTO CarHireDB.Car_model
    VALUES('MG','ZR','Blue',5);
    INSERT INTO CarHireDB.Car(regno,bay,name,make,model,transmission)
    VALUES('NSW080','Ultimo','little blue','MG','ZR','auto');
    INSERT INTO CarHireDB.Location(name,loc_type,part_of)
    VALUES('Darling harbor','City',1);
    INSERT INTO CarHireDB.Car_bay
    VALUES('Ultimo',1,'close to central station',324.34,19.02,1);
COMMIT;

BEGIN TRANSACTION;
    INSERT INTO CarHireDB.Car_model
    VALUES('Ford','LTD04','Limo',5);
    INSERT INTO CarHireDB.Car(regno,bay,name,make,model,year,transmission)
    VALUES('QSA800','Redfern','our limo','Ford','LTD04','2004-01-01','auto');
    INSERT INTO CarHireDB.Location (name,loc_type,part_of)
    VALUES('Little Fern','Suburb',1);
    INSERT INTO CarHireDB.Car_bay
    VALUES('Redfern',2,'near usyd',19.02,324.34,2);
COMMIT;


--Create members
BEGIN TRANSACTION;
    INSERT INTO CarHireDB.Member(prefer_method,title,first_name,last_name,nick_name,address,email,since,dob,password,subscription,license_no) 
    VALUES (1,'Ms','Samantha','Huffer','SH123',3,'SamanthaHuffer@inbound.plus',now()-interval'4 months','24-06-1986','asdsadf','silver','abc1234');
    INSERT INTO CarHireDB.Address
    VALUES(3,null,'5','Fergusson Street','SHANNON BROOK','NSW','2470');
    INSERT INTO CarHireDB.Member_phone
    VALUES(1,'67513893');
    INSERT INTO CarHireDB.Member_phone
    VALUES(1,'40399312');
    INSERT INTO CarHireDB.Payment_method
    VALUES(1,1);
    INSERT INTO CarHireDB.Paypal
    VALUES(1,1,'SamanthaHuffer@inbound.plus');
    INSERT INTO CarHireDB.Payment_method
    VALUES(1,2);
    INSERT INTO CarHireDB.Bank_account
    VALUES(1,2,'COMMBANK','128128','87493632145615');
    INSERT INTO CarHireDB.Membership_plan
    VALUES('silver');
    INSERT INTO CarHireDB.Payment_method
    VALUES(1,3);
    INSERT INTO CarHireDB.Credit_card
    VALUES(1,3,'01-04-2018','SAMANTHA HUFFER','MasterCard','5293118974927399');
COMMIT;

BEGIN TRANSACTION;
    INSERT INTO CarHireDB.Member(prefer_method,title,first_name,last_name,nick_name,address,email,homebay,since,dob,password,subscription,license_no) 
    VALUES (2,'Mr','Cameron','Boswell','cb852',4,'CameronBoswell@gmail.com','Ultimo',now()-interval'9 years','02-07-1983','yw45y35','gold','ty95236');
    INSERT INTO CarHireDB.Address
    VALUES(4,null,'55','Settlement Road','PARADISE BEACH','VIC','3851');
    INSERT INTO CarHireDB.Member_phone
    VALUES(2,'67513893');
    INSERT INTO CarHireDB.Member_phone
    VALUES(2,'40399312');
    INSERT INTO CarHireDB.Payment_method
    VALUES(2,2);
    INSERT INTO CarHireDB.Bank_account
    VALUES(2,2,'ST. GEORGE','113113','15936874321456');
    INSERT INTO CarHireDB.Payment_method
    VALUES(2,3);
    INSERT INTO CarHireDB.Paypal
    VALUES(2,3,'CameronBoswell@gmail.com');
    INSERT INTO CarHireDB.Membership_plan
    VALUES('gold');
    INSERT INTO CarHireDB.Payment_method
    VALUES(2,1);
    INSERT INTO CarHireDB.Paypal
    VALUES(2,1,'BellaHopwood@hotmail.com');   
COMMIT;

BEGIN TRANSACTION;
    INSERT INTO CarHireDB.Member (prefer_method,title,first_name,last_name,nick_name,address,email,homebay,since,dob,password,subscription,license_no) 
    VALUES (1,'Miss','Bella','Hopwood','BH52',5,'BellaHopwood@hotmail.com','Redfern',now()-interval'5 years','04-02-1968','yERT565','pearl','er243235');
    INSERT INTO CarHireDB.Address
    VALUES(5,null,'61','Sale Street','HUNTLEY','NSW','2800');
    INSERT INTO CarHireDB.Membership_plan
    VALUES('pearl');
    INSERT INTO CarHireDB.Member_phone
    VALUES(3,'67513893');
    INSERT INTO CarHireDB.Member_phone
    VALUES(3,'40399312');
    INSERT INTO CarHireDB.Member_phone
    VALUES(3,'53191344');	
    INSERT INTO CarHireDB.Payment_method
    VALUES(3,1);
    INSERT INTO CarHireDB.Payment_method
    VALUES(3,2);
    INSERT INTO CarHireDB.Payment_method
    VALUES(3,3);   
    INSERT INTO CarHireDB.Bank_account
    VALUES(3,1,'WESTPAC','113128','87432145615936');
    INSERT INTO CarHireDB.Credit_card
    VALUES(3,2,'31-07-2019','BELLA HOPWOOD','VISA','4556568618806083');
    INSERT INTO CarHireDB.Paypal
    VALUES(3,3,'BellaHopwood@hotmail.com');
COMMIT;
	--Create 3rd car
BEGIN TRANSACTION;
    INSERT INTO CarHireDB.Car(regno,bay,name,make,model,transmission)
    VALUES('JB007','Ultimo','limo2','Ford','LTD04','auto');
COMMIT;

	--Miss create a car with a wrong carbay
BEGIN TRANSACTION;
    INSERT INTO CarHireDB.Car_model
    VALUES('Fiat','Multipla','your bond',15);
    INSERT INTO CarHireDB.Car(regno,bay,name,make,model,year,transmission)
    VALUES('ATS800','Redfern','James Bond','Fiat','Multipla','2000-01-01','manual');
    INSERT INTO CarHireDB.Car_bay
    VALUES('Lovely Darling',1,'near usyd',109.02,32.34,1);
COMMIT;

	--Update Membership plan of data
UPDATE CarHireDB.Membership_plan SET monthly_fee=300,hourly_rate=8.5 WHERE title='gold';
UPDATE CarHireDB.Membership_plan SET monthly_fee=200,hourly_rate=10,km_rate=8.5 WHERE title='silver';
UPDATE CarHireDB.Membership_plan SET monthly_fee=100,hourly_rate=15,km_rate=10,daily_rate=8.5 WHERE title='pearl';

	--CREATE BOOKING
INSERT INTO CarHireDB.Booking(member_id,regno,start_time,duration,book_date)
VALUES (1,'NSW080',now()+interval '9 hours',5,now());
INSERT INTO CarHireDB.Booking(member_id,regno,start_time,duration)
VALUES (1,'JB007',now()+interval '9 days',5);
INSERT INTO CarHireDB.Booking(member_id,regno,start_time,duration)
VALUES (2,'JB007',now()+interval '7 days',4);

select * from carhiredb.booking
delete from carhiredb.booking

	--Trigger rejection overlap booking
INSERT INTO CarHireDB.Booking(member_id,regno,start_time,duration) VALUES (1,'JB007',now()+interval '9 days',3); 

	--Cascade delete payment method
SELECT * FROM CarHireDB.Member JOIN CarHireDB.Payment_method on id=member_id WHERE id =3;
DELETE FROM CarHireDB.Member WHERE id =3;


	--Trigger rejection update book_date of Booking
UPDATE CarHireDB.Booking SET book_date=now()+interval '25 days' where regno = 'NSW080';
UPDATE CarHireDB.Booking SET book_date=now()-interval '35 days' where regno = 'JB007';

	--Trigger rejection update overlap booking
UPDATE CarHireDB.Booking SET start_time=now()+interval '7 days' ,duration =5 
WHERE regno='JB007' and member_id = 2

	
	--Trigger rejection last car deletion 
DELETE FROM CarHireDB.Car where regno='QSA800';

	--Trigger enforece payment method disjoint constraint
	--Allow to delete non-prefer method
    DELETE FROM CarHireDB.Payment_method WHERE member_id =2 AND num =1
	--Trigger rejection delete prefer method
    DELETE FROM CarHireDB.Payment_method WHERE member_id =2 AND num =2
	--Trigger rejection voilate disjoin constraint
    INSERT INTO CarHireDB.Payment_method 
    VALUES(2,1);
	--Forbid overlap in paypal/credit car/ bank account
    INSERT INTO CarHireDB.Credit_card 
    VALUES(2,1,'01-03-2020','CAMERON BOSWELL','MasterCard','5229136636292407');
	
    INSERT INTO CarHireDB.Paypal
    VALUES(2,1,'BellaHopwood@hotmail.com');

    INSERT INTO CarHireDB.Bank_account
    VALUES(2,1,'WESTPAC','113128','87432145615936');