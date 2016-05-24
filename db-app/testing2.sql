--update home bay stored procedure
--------------------------------------------------------
CREATE OR REPLACE FUNCTION updateHomebay(e_mail VARCHAR,bname VARCHAR)
RETURNS VARCHAR
AS $$
DECLARE
bid INT;
bn VARCHAR;
BEGIN
  bid:=(SELECT bayid FROM CarSharing.Carbay WHERE name =bname) ;
  UPDATE CarSharing.Member SET homebay = bid  
  WHERE email = e_mail;
  bn := (SELECT name FROM CarSharing.Carbay WHERE bayid=bid);
  RETURN bn;
END;
$$LANGUAGE 'plpgsql';

------creat booking stored procedure-----------------

CREATE OR REPLACE FUNCTION makeBooking(car_rego VARCHAR,e_mail VARCHAR,date VARCHAR,hour INT,duration INT)
RETURNS BOOLEAN 
SECURITY DEFINER
AS $$
DECLARE
member INT;
stime TIMESTAMP;
etime TIMESTAMP;
BEGIN 
  stime := (SELECT to_timestamp(date,'YYYY-MM-DD') + hour *interval'1 hour');
  --add starttime checking constraINT in table to forbid member book Car in the past
  IF(stime>now()) THEN
    etime := (stime + duration *interval '1 hour');
    member := (SELECT memberno FROM CarSharing.Member WHERE email=e_mail);
    INSERT INTO CarSharing.Booking(Car,madeby,whenbooked,starttime,endtime)
    VALUES (Car_rego,member,now(),stime,etime);
  ELSE
    RAISE EXCEPTION 'No booking made in past';
  END IF;
  RETURN TRUE;
END;
$$LANGUAGE 'plpgsql';

-------------check overlapping booking tigger-----------------
CREATE OR REPLACE
FUNCTION OverlappingTime()
RETURNS TRIGGER AS $$
DECLARE
rec RECORD;
BEGIN
    --refresh my view everytime I need to insert my table.
    REFRESH MATERIALIZED VIEW CONCURRENTLY CarSharing.reservation;
    --refactor this CarSharing.booking to my materialised view reservation
    FOR rec IN SELECT starttime,endtime FROM CarSharing.Reservation WHERE car = NEW.car
    LOOP
        IF (rec.starttime, rec.endtime) OVERLAPS (NEW.starttime, NEW.endtime) THEN
            RAISE EXCEPTION 'Overlapping booking';
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

------------triger check overlap TRIGGER ----------------------
CREATE TRIGGER CheckOverlappingTime
BEFORE INSERT OR UPDATE ON CarSharing.Booking
FOR EACH ROW
EXECUTE PROCEDURE OverlappingTime();

CREATE OR REPLACE FUNCTION incrementNumberOfBooking()
RETURNS TRIGGER AS $$
DECLARE
nrb INT ;
BEGIN
    ------------refresh the materialised view to update current booking---------------
    REFRESH MATERIALIZED VIEW CONCURRENTLY CarSharing.reservation;
    nrb := (SELECT stat_nrofbookings FROM CarSharing.Member WHERE memberno = NEW.madeby);
    UPDATE CarSharing.Member SET stat_nrofbookings=nrb+1 WHERE memberno = NEW.madeby;
    RETURN old;
END;
$$ LANGUAGE plpgsql;

------------triger update member statistic number of booking---------------
CREATE TRIGGER updateMemberStatOfBooking
AFTER INSERT ON CarSharing.Booking
FOR EACH ROW
EXECUTE PROCEDURE incrementNumberOfBooking();

------------get all cars in by home bay's name ----------------------------------

CREATE OR REPLACE FUNCTION getCarsInBay(bname VARCHAR)
RETURNS TABLE(reg REGOTYPE,cn VARCHAR)
AS $$
BEGIN
 REFRESH MATERIALIZED VIEW CONCURRENTLY CarSharing.reservation;
 RETURN QUERY SELECT regno, name 
 FROM CarSharing.Car 
 WHERE parkedat = ( 
  SELECT bayid 
  FROM CarSharing.Carbay 
  WHERE name = bname)
  AND regno NOT IN (
  SELECT car 
  from CarSharing.Reservation
  WHERE (starttime < NOW() AND NOW() <endtime)
 );  
END;
$$LANGUAGE 'plpgsql';

----------------get all the books of the member with that email----------------------------
CREATE OR REPLACE FUNCTION getAllBooking(e_mail VARCHAR)
RETURNS table(Car REGOTYPE,name VARCHAR,date DATE,hour INT,stime TIMESTAMP) 
AS $$
BEGIN
  RETURN QUERY
  SELECT b.Car AS Car, c.name AS name , 
  CAST(b.starttime AS date) 
  AS date ,
  CAST(EXTRACT(EPOCH FROM endtime-starttime) AS int)/3600 AS duration ,b.starttime
  FROM CarSharing.Booking AS b join CarSharing.Car As C ON b.Car = regno 
  WHERE b.madeby = (SELECT memberno FROM CarSharing.Member WHERE email=e_mail)
  ORDER BY b.starttime DESC;
END;
$$  
LANGUAGE 'plpgsql';

----------------fetch car bays with specific keyword----------------------------

CREATE OR REPLACE FUNCTION fetchBays(searchTerm TEXT)
RETURNS TABLE(name VARCHAR, address VARCHAR, nrOfCar BIGINT)
AS $$
BEGIN
  searchTerm := '%'||searchTerm||'%';
  RETURN QUERY SELECT b.name , b.address, 
  COUNT(c.regno) FROM CarSharing.Carbay AS b JOIN CarSharing.Car AS c
  ON b.bayid = c.parkedat WHERE b.name ILIKE searchTerm OR 
  b.address ILIKE searchTerm
  GROUP BY bayid ;
 END;
 $$LANGUAGE 'plpgsql';

---------------fetch the home bay detail by car bay's name-----------------------
CREATE OR REPLACE FUNCTION getBay(n VARCHAR)
RETURNS TABLE( bname VARCHAR, descr TEXT,
 addr VARCHAR,gpsLat FLOAT,gpsLong FLOAT,walkscore INT) AS $$
BEGIN
 RETURN QUERY 
 SELECT name ,description,address,gps_lat,gps_long, cb.walkscore
 FROM Carbay cb WhERE cb.name =n;
 END;
$$LANGUAGE 'plpgsql';

----------------get all the home bays in database system---------------------------
CREATE OR REPLACE FUNCTION getAllBays()
RETURNS TABLE(name VARCHAR,address VARCHAR, nrOfCar BIGINT)
AS $$
BEGIN
  RETURN QUERY SELECT CarSharing.Carbay.name , CarSharing.Carbay.address, 
  COUNT(CarSharing.Car.regno) 
  FROM CarSharing.Carbay  JOIN CarSharing.Car 
  ON bayid = parkedat GROUP BY bayid;
 END;
 $$LANGUAGE 'plpgsql';

-----------------fetch car detail by its regno---------------------------------------
CREATE OR REPLACE FUNCTION getCarDetail(rego VARCHAR)
RETURNS TABLE(regno regotype,name VARCHAR,make VARCHAR,
model VARCHAR,year INT,transmission VARCHAR,category VARCHAR,
capacity INT,bay VARCHAR,walkscore INT,mapurl VARCHAR)
AS $$
BEGIN
  RETURN QUERY SELECT c.regno,c.name, c.make, c.model, c.year,c.transmission, 
  m.category,m.capacity, b.name, b.walkscore,b.mapurl 
  FROM CarSharing.Car AS c NATURAL JOIN CarSharing.Carmodel AS m
  JOIN CarSharing.Carbay AS b ON parkedat=bayid WHERE c.regno = rego;
 END;
 $$LANGUAGE 'plpgsql';



----------------get the availabilities of car with the regno----------------------
CREATE OR REPLACE FUNCTION getCarAvailability(rego VARCHAR)
RETURNS TABLE(hour INT,Duration INT)
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY CarSharing.reservation;
  RETURN QUERY SELECT CAST(EXTRACT(HOUR FROM r.starttime) AS int) AS hour ,
    CAST(EXTRACT(EPOCH FROM r.endtime-r.starttime) AS int)/3600 AS duration
  FROM CarSharing.Reservation AS r
  WHERE r.car=rego and CAST(r.starttime AS date)=CAST(now() AS date);
END;
 $$LANGUAGE 'plpgsql';

----------------fetch the booking by the car and date time--------------------------
CREATE OR REPLACE FUNCTION fetchbooking(b_car CHAR(6),b_date DATE,b_hour INT)
RETURNS TABLE ( mname TEXT, car regotype, cname VARCHAR, date DATE,
  hour INT,duration INT,madeday TEXT,bay VARCHAR,cost FLOAT)
AS $$
BEGIN
  RETURN QUERY 
 SELECT m.namegiven||' '||m.namefamily, b.Car, c.name, 
    CAST(b.starttime AS date) AS date, 
    CAST(EXTRACT(HOUR FROM starttime) AS int) AS hour ,
    CAST(EXTRACT(EPOCH FROM endtime-starttime) AS int)/3600 AS duration,
    to_char(b.whenbooked,'DD-MM-YYYY')  AS madeday , cb.name AS bay 
    , CAST(EXTRACT(EPOCH FROM endtime-starttime) AS FLOAT)/3600*(
      SELECT hourly_rate FROM CarSharing.Membershipplan
      WHERE title =m.subscribed 
    ) AS cost
    FROM CarSharing.booking AS b 
      JOIN CarSharing.Car AS C ON b.Car=regno 
      JOIN CarSharing.Member AS m ON b.madeby= m.Memberno 
      JOIN CarSharing.Carbay AS cb ON c.parkedat=cb.bayid 
    WHERE b.Car=b_Car AND CAST(b.starttime AS date) =b_date
      AND CAST(EXTRACT(EPOCH FROM endtime-starttime) AS int)/3600  = b_hour;
END;
$$ LANGUAGE 'plpgsql';

-----------extension 1 materialised reservation view----------

CREATE MATERIALIZED VIEW CarSharing.Reservation
AS
  SELECT Car,starttime,endtime
  FROM CarSharing.booking
  WHERE starttime >= (NOW()-interval '1 day')
  ORDER BY starttime DESC
WITH DATA;

CREATE UNIQUE INDEX DATE_TIME ON RESERVATION (Car,starttime);

------------extension 4 member analysis flat table------------
 
alter table carsharing.member alter column password type varchar(100);
alter table carsharing.member add column stat_weekendBookings integer default 0;
alter table carsharing.member add column stat_mostRecentBooking timestamp;
update table carsharing.member set password = '$2b$12$5ZWJceUuQewWJA3iPQWyteM9mEZ0PWb4OGSM4Hg.ViGKjnHV8FUPG'; 

create or replace view carsharing.frat_table as
select nameGiven || ' ' || nameFamily as name,
       ntile(5) over (order by stat_nrOfBookings asc) as freq,
       ntile(5) over (order by stat_mostRecentBooking asc) as recent,
       ntile(5) over (order by stat_sumPayments asc) as pay,
       CASE
       WHEN stat_weekendBookings < (stat_nrOfBookings - stat_weekendBookings) THEN 'weekday'
       ELSE 'weekend'
       END as type
from carsharing.member
order by freq desc, recent desc, pay desc;


-----------Dynamic update Member statistic----------------------
 
CREATE OR REPLACE FUNCTION incrementStats()
RETURNS TRIGGER AS $$
DECLARE
nrb INTEGER;
wkend INTEGER;
dayofweek INTEGER;
BEGIN
    nrb := (SELECT stat_nrOfBookings FROM carsharing.member WHERE memberno = NEW.madeby);
    wkend := (SELECT stat_weekendBookings FROM carsharing.member WHERE memberno = NEW.madeby);
    dayofweek := EXTRACT(dow FROM NEW.starttime);
    IF (dayofweek = 0 OR dayofweek = 6) THEN
        wkend := wkend + 1;
    END IF;
    UPDATE carsharing.member 
    SET stat_nrOfBookings = nrb + 1, 
        stat_weekendBookings = wkend, 
        stat_mostRecentBooking = NEW.whenbooked
    WHERE memberno = NEW.madeby;
    RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER updateMemberStatOfBooking ON carsharing.Booking;

CREATE TRIGGER updateMemberStatOfBooking
AFTER INSERT ON carsharing.Booking
FOR EACH ROW
EXECUTE PROCEDURE incrementStats();

