
CREATE OR REPLACE FUNCTION updateHomebay(e_mail VARCHAR,bname VARCHAR)
RETURNS VARCHAR
AS $$
DECLARE
bid INT;
bn VARCHAR;
BEGIN
  bid:=(SELECT bayid FROM carsharing.carbay WHERE name =bname) ;
  UPDATE carsharing.member SET homebay = bid  
  WHERE email = e_mail;
  bn := (SELECT name FROM carsharing.carbay WHERE bayid=bid);
  RETURN bn;
END;
$$LANGUAGE 'plpgsql';
DROP FUNCTION updatehomebay(character varying,character varying)
SELECT updateHomebay('MrajayBains@gmail.com','Darlinghurst - Crown Street')

--------------------------------------------------------

CREATE OR REPLACE FUNCTION makeBooking(car_rego VARCHAR,e_mail VARCHAR,date varchar,hour int,duration int)
RETURNS boolean 
AS $$
DECLARE
mnr INT;
stime TIMESTAMP;
etime TIMESTAMP;
BEGIN
  stime := (SELECT to_timestamp(date,'YYYY-MM-DD') + hour *interval'1 hour');
  etime := (stime + duration *interval '1 hour');
  mnr := (SELECT memberno FROM carsharing.member WHERE email=e_mail);
  INSERT INTO carsharing.Booking(car,madeby,whenbooked,starttime,endtime)
  VALUES (car_rego,mnr,now(),stime,etime);
  RETURN true;
END;
$$LANGUAGE 'plpgsql';


SELECT * from makebooking('AT61LA','MrajayBains@gmail.com','2015-05-20',17,4)

delete from carsharing.booking where car='AT61LA' and starttime = (SELECT to_timestamp('2061-05-20','YYYY-MM-DD') + 17 *interval'1 hour');

SELECT * from carsharing.booking where car='AT61LA'

SELECT (to_timestamp('2017-05-20','YYYY-MM-DD') + 17 *interval'1hour')

--------------------------------------------------------

CREATE OR REPLACE FUNCTION getCarsInBay(bname VARCHAR)
RETURNS TABLE(reg REGOTYPE,cn VARCHAR)
AS $$
BEGIN
 RETURN QUERY SELECT regno, name 
 FROM carsharing.car 
 WHERE parkedat = ( 
 SELECT bayid 
 FROM carsharing.carbay 
 WHERE name = bname);
END;
$$LANGUAGE 'plpgsql';


select * from getCarsInBay('Erskineville - Erskineville Road')

--------------------------------------------------------
CREATE OR REPLACE FUNCTION getAllBooking(e_mail varchar)
RETURNS table(car regotype,name varchar,date text,hour int,stime timestamp) 
AS $$
BEGIN
  Return QUERY SELECT b.car AS car, c.name AS name , 
  to_char(b.starttime,'DD-MM-YYYY') 
  AS date ,
  cast( EXTRACT(HOUR FROM starttime) as int )AS hour ,b.starttime
  FROM carsharing.Booking AS b join carsharing.Car As C ON b.car = regno 
            WHERE b.madeby = (SELECT memberno FROM carsharing.member WHERE email=e_mail)
  ORDER BY b.starttime DESC;
END;
$$  
LANGUAGE 'plpgsql'


drop function getAllBooking(varchar)
SELECT * from getAllBooking('MrajayBains@gmail.com') ;

--------------------------------------------------------
CREATE OR REPLACE FUNCTION fetchBays(searchTerm text)
RETURNS TABLE(name VARCHAR, address VARCHAR, nrOfCar BIGINT)
AS $$
BEGIN
  searchTerm := '%'||searchTerm||'%';
  RETURN QUERY SELECT b.name , b.address, 
  count(c.regno) FROM carsharing.carbay as b JOIN carsharing.car as c
  ON b.bayid = c.parkedat WHERE b.name ILIKE searchTerm or 
  b.address ILIKE searchTerm
  GROUP BY bayid ;
 END;
 $$LANGUAGE 'plpgsql';


SELECT * from fetchBays('Road') 


--------------------------------------------------------
CREATE OR REPLACE FUNCTION getBay(n VARCHAR)
RETURNS TABLE( bname VARCHAR, descr text,
 addr VARCHAR,gpsLat FLOAT,gpsLong FLOAT,walkscore INT) AS $$
BEGIN
 RETURN QUERY 
 SELECT name ,description,address,gps_lat,gps_long, walkscore
 FROM carbay cb WhERE cb.name =n;
 END;
 $$LANGUAGE 'plpgsql';

SELECT *from getBay('Erskineville - Erskineville Road') AS (name ,description, address,gps_lat,gps_long)

DROP FUNCTION getbay(character varying)


--------------------------------------------------------
CREATE OR REPLACE FUNCTION getAllBays()
RETURNS TABLE(name VARCHAR,address VARCHAR, nrOfCar BIGINT)
AS $$
BEGIN
  RETURN QUERY SELECT carsharing.carbay.name , carsharing.carbay.address, 
  count(carsharing.car.regno) FROM carsharing.carbay  JOIN carsharing.car 
  ON bayid = parkedat GROUP BY bayid;
 END;
 $$LANGUAGE 'plpgsql';

SELECT * FROM GETALLBAYS();



--------------------------------------------------------
CREATE OR REPLACE FUNCTION getCarDetail(rego varchar)
RETURNS TABLE(regno regotype,name varchar,make varchar,
model varchar,year int,transmission varchar,category varchar,
capacity int,bay varchar,walkscore int,mapurl varchar)
AS $$
BEGIN
  RETURN QUERY SELECT c.regno,c.name, c.make, c.model, c.year,c.transmission, 
  m.category,m.capacity, b.name, b.walkscore,b.mapurl 
  FROM carsharing.car AS c NATURAL JOIN carsharing.carmodel as m
  JOIN carsharing.carbay AS b ON parkedat=bayid WHERE c.regno = rego;
 END;
 $$LANGUAGE 'plpgsql';


Select * From getCarDetail('AN83WT');

--------------------------------------------------------
CREATE OR REPLACE FUNCTION fetchbooking(b_car char(6),b_date varchar,b_hour int)
RETURNS TABLE(mname text,car regotype,cname varchar,date text,hour int,duration int,madeday text,bay varchar)
AS $$

BEGIN
  RETURN QUERY SELECT m.namegiven||' '||m.namefamily, b.car, 
  c.name, to_char(b.starttime,'DD-MM-YYYY') AS date,
  cast(EXTRACT(HOUR FROM starttime) as int) as hour ,cast(EXTRACT( hour FROM endtime-starttime) as int) AS duration ,
  to_char(b.whenbooked,'DD-MM-YYYY')
  AS madeday , cb.name as bay 
  FROM carsharing.booking AS b JOIN carsharing.car AS C ON b.car=regno JOIN carsharing.member AS m ON b.madeby= m.memberno JOIN carsharing.carbay as cb ON c.parkedat=cb.bayid
  WHERE b.car=b_car AND to_char(b.starttime,'DD-MM-YYYY') = b_date AND EXTRACT(HOUR FROM starttime) = b_hour;

END;
$$ LANGUAGE 'plpgsql'

DROP FUNCTION fetchbooking(character,character varying,integer)

SELECT * FROM fetchbooking('AN83WT','22-03-2012',17) ;



