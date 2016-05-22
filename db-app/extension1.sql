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
re RECORD;
h INT;
BEGIN
  --get a record from booking
  FOR re IN (SELECT car,starttime FROM carsharing.booking) LOOP
	--check if it is in reservation table
    IF (SELECT * FROM carsharing.reservation WHERE regno = re.car AND bookdate=re.starttime)<0 THEN
      h := cast( EXTRACT(HOUR FROM starttime) as int );
      INSERT INTO carsharing.reservation VALUES (re.car,re.starttime,)		
  END LOOP;
  

  --if it is in, get the availability from reservation
  
	  -- generate a bit string from the record of booking eg.cast(-44 as bit(12)) 
	  
	  -- concatinate the bit string with availability

	  -- update the availability
  --else insert a new record

 END;
 
CREATE FUNCTION tobits(a integer, b integer)
  RETURNS bitstring
AS $$
  if
    return None
  if a > b:
    return a
  return b
 
$$ LANGUAGE plpythonu;

 
select cast(17 as bit(24));

select ;

CREATE OR REPLACE FUNCTION insertReservation() RETURN tigger AS $$

BEGIN
  INSERT INTO carsharing.reservation VALUES()
 
 END;
 $$ LANGUAGE 'PLPGSQL'
  SELECT ((SELECT car,starttime FROM carsharing.booking) > 0)