--regno c.name make model year

SELECT regno, name from carsharing.car


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
BEFORE INSERT OR UPDATE ON carsharing.Booking
FOR EACH ROW
EXECUTE PROCEDURE OverlappingTime();


(
SELECT carsharing.carbay.name , address, count(regno) 
FROM carsharing.carbay  JOIN carsharing.car ON bayid = parkedat 
WHERE carsharing.carbay.name ILIKE '%KELLY%' or address LIKE '%KELLY%'
GROUP BY bayid
)union(
SELECT carsharing.carbay.name , address, count(regno) 
FROM carsharing.carbay  JOIN carsharing.car ON bayid = parkedat 
WHERE address LIKE '%Kelly%'
GROUP BY bayid
)


SELECT carsharing.carbay.name , address, count(regno) 
FROM carsharing.carbay  JOIN carsharing.car ON bayid = parkedat 
GROUP BY bayid



SELECT cb.name ,description, address,gps_lat,gps_long
FROM carsharing.carbay AS cb JOIN carsharing.car AS c ON bayid = parkedat 
WhERE cb.name = 'Darlinghurst - Crown Street'


SELECT regno, name 
FROM carsharing.car 
where parkedat = (
	SELECT bayid from carsharing.carbay
	WhERE name = 'Darlinghurst - Crown Street'
	)



SELECT nickname, nametitle, namegiven , namefamily, c.address, 
cb.name,since, subscribed,stat_nrofbookings
FROM carsharing.Member as c join carsharing.carbay as cb on homebay = bayid


SELECT regno, make, model, year,transmission, category,
capacity, b.name , walkscore,mapurl
FROM carsharing.car 
  NATURAL JOIN carsharing.carmodel 
  JOIN carsharing.carbay AS b ON parkedat=bayid






/*SELECT m.namegiven||' '||m.namefamily, b.car, c.name,
 to_char(b.starttime,'DD-MM-YYYY') AS date , 
 EXTRACT(HOUR FROM starttime) as hour ,
 endtime-starttime AS duration,
 to_char(b.whenbooked,'DD-MM-YYYY') AS bookeddate , 
 cb.name
FROM carsharing.booking AS b JOIN carsharing.car AS C ON car=regno
 JOIN carsharing.member AS m ON b.madeby= m.memberno
 JOIN carsharing.carbay as cb ON c.parkedat=cb.bayid
WHERE b.car='BB63AC' AND to_char(b.starttime,'DD-MM-YYYY') = '28-05-2016' AND 
EXTRACT(HOUR FROM starttime) = 9
*/

SELECT m.namegiven||' '||m.namefamily, b.car, c.name, to_char(b.starttime,'DD-MM-YYYY') AS date, EXTRACT(HOUR FROM starttime) as hour ,EXTRACT( hour FROM endtime-starttime) AS duration , to_char(b.whenbooked,'DD-MM-YYYY') AS bookeddate , cb.name
        FROM carsharing.booking AS b JOIN carsharing.car AS C ON car=regno JOIN carsharing.member AS m ON b.madeby= m.memberno JOIN carsharing.carbay as cb ON c.parkedat=cb.bayid
        WHERE b.car='BB63AC' AND to_char(b.starttime,'DD-MM-YYYY') = '28-05-2016' AND 
EXTRACT(HOUR FROM starttime) = 9


Select email, bayid, name from carsharing.member join carsharing.carbay on homebay = bayid


Update carsharing.member 

set homebay = (Select bayid from carsharing.carbay where name = 'Erskineville - Erskineville Road')

where email ='Msmystiquedarkholm@gmail.com'

Update carsharing.member 

set homebay = ( Select bayid from carsharing.carbay where name = 'Newtown - Camperdown Memorial Park')

where email ='Msmystiquedarkholm@gmail.com'