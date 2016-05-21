CREATE TABLE carsharing.reservation(
  regno REGOTYPE,
  bookdate TIMESTAMP,
  Availability BIT(24),
  PRIMARY KEY (regno,bookdate)
);

CREATE INDEX bookdate_index ON  carsharing.reservation (bookdate);

CREATE OR REPLACE FUNCTION 1stTimeGenerateReservation()
RETURN VOID AS $$
DECLARE
re RECORD
BEGIN
  --get a record from booking
  FOR re IN (SELECT car,starttime FROM carsharing.booking) LOOP
	--check if it is in reservation table
    IF()	
  END LOOP;
  

  --if it is in, get the availability from reservation
  
	  -- generate a bit string from the record of booking eg.cast(-44 as bit(12)) 
	  
	  -- concatinate the bit string with availability

	  -- update the availability
  --else insert a new record

 END;
 $$ LANGUAGE 'PLPGSQL'

CREATE OR REPLACE FUNCTION insertReservation() RETURN tigger AS $$

BEGIN
  INSERT INTO carsharing.reservation VALUES()
 
 END;
 $$ LANGUAGE 'PLPGSQL'
  SELECT ((SELECT car,starttime FROM carsharing.booking) > 0)