#!/usr/bin/env python3

from modules import pg8000
import configparser


# Define some useful variables
ERROR_CODE = 55929

#####################################################
##  Database Connect
#####################################################

def database_connect():
    # Read the config file
    config = configparser.ConfigParser()
    config.read('config.ini')

    # Create a connection to the database
    connection = None
    try:
        connection = pg8000.connect(database=config['DATABASE']['user'],
            user=config['DATABASE']['user'],
            password=config['DATABASE']['password'],
            host=config['DATABASE']['host'])
    except pg8000.OperationalError as e:
        print("""Error, you haven't updated your config.ini or you have a bad
        connection, please try again. (Update your files first, then check
        internet connection)
        """)
        print(e)
    #return the connection to use
    return connection

#####################################################
##  Login
#####################################################

def check_login(email, password):
    # Dummy data 
    #['Shadow', 'Mr', 'Evan', 'Nave', '123 Fake Street, Fakesuburb', 'SIT', '01-05-2016', 'Premium', '1']
    val = None
    #Ask for the database connection, and get the cursor set up
    conn = database_connect()
    if(conn is None):
        return ERROR_CODE
    cur = conn.cursor()
    try:
        #Try executing the SQL and get from the database
        sql = """SELECT  nickname, nametitle, namegiven , namefamily, c.address, cb.name,since, subscribed,stat_nrofbookings FROM carsharing.Member as c join carsharing.carbay as cb on homebay = bayid
            WHERE email = %s AND password = %s """
        cur.execute(sql , (email, password))
        val = cur.fetchone()
        if len(val)==0:
            val=None
    except:
        #If there were any errors, return a NULL row printing an error to the debug
        print("Error with Database")
    cur.close()             #Close the cursor
    conn.close()            #Close the connection to the db
    return val

#####################################################
##  Homebay
#####################################################
def update_homebay(email, bayname):
    #Ask for the database connection, and get the cursor set up
    isUpdated=False
    conn = database_connect()
    if(conn is None):
        return ERROR_CODE
    cur = conn.cursor()
    try:
        sql = """ UPDATE carsharing.member SET homebay = (SELECT bayid FROM carsharing.carbay WHERE name = %s) WHERE email = %s """
       
        cur.execute(sql , (bayname , email ))
        conn.commit()
        isUpdated = True
    except Exception as e:
        print(e)
        print("Error with update database")
    cur.close()
    conn.close()
    # Update the user's homebay
    return isUpdated
#####################################################
##  Booking (make, get all, get details)
#####################################################

def make_booking(email, car_rego, date, hour, duration):
    # TODO
    # Insert a new booking
    # Make sure to check for:(I think for this check, we can use some constraint check from assignment 2)
    #       - If the member already has booked at that time
    #       - If there is another booking that overlaps
    #       - Etc.
    # return False if booking was unsuccessful :)
    # We want to make sure we check this thoroughly
    return True


def get_all_bookings(email):
    # Get the database connection and set up the cursor
    conn = database_connect()
    if(conn is None):
        return ERROR_CODE
    cur = conn.cursor()
    rows =None
    try:
        #Try to get all the info return from the query
        sql = """ SELECT b.car , c.name , to_char(b.starttime,'DD-MM-YYYY') AS date , EXTRACT(HOUR FROM starttime) AS time FROM carsharing.Booking AS b join carsharing.Car As C ON car = regno 
            WHERE b.madeby = 
                (SELECT memberno FROM carsharing.member 
                 WHERE email=%s) """
        cur.execute(sql, (email, ))
        rows = cur.fetchall()
        if len(rows)==0:
           rows=None
        else:
            for row in rows:
                row[3] = int(row[3])
    except:
        print("Error fetching from database")
    cur.close()
    conn.close()
    return rows

def get_booking(b_date, b_hour, car):
   # val = ['Shadow', '66XY99', 'Ice the Cube', '01-05-2016', '1', '4', '29-04-2016', 'SIT']
    #return val
    
    conn = database_connect()
    if(conn is None):
        return ERROR_CODE
    cur = conn.cursor()
    row = None
    try:
        sql = """ SELECT m.namegiven||' '||m.namefamily, b.car, c.name, to_char(b.starttime,'DD-MM-YYYY') AS date,   EXTRACT(HOUR FROM starttime) as hour ,EXTRACT( hour FROM endtime-starttime) AS duration , to_char(b.whenbooked,'DD-MM-YYYY') AS bookeddate , cb.name
        FROM carsharing.booking AS b JOIN carsharing.car AS C ON car=regno JOIN carsharing.member AS m ON b.madeby= m.memberno JOIN carsharing.carbay as cb ON c.parkedat=cb.bayid
        WHERE b.car=%s AND to_char(b.starttime,'DD-MM-YYYY') = %s AND EXTRACT(HOUR FROM starttime) = %s """
        # Get the information about a certain booking
        # It has to have the combination of date, hour and car
        cur.execute(sql , (car, b_date, b_hour))
        row = cur.fetchone()
        if len(row)==0:
            row=None
        else:
            row[4]=int(row[4])
            row[5]=int(row[5])
    except Exception as e:
        print("Error fetching from database")
    cur.close()
    conn.close()
    return row


#####################################################
##  Car (Details and List)
#####################################################

def get_car_details(regno):
    val = None
    #dummy data ['66XY99', 'Ice the Cube','Nissan', 'Cube', '2007', 'auto', 'Luxury', '5', 'SIT', '8', 'http://example.com']
    conn = database_connect()
    if(conn is None):
        return ERROR_CODE
    cur = conn.cursor()
    try:
        cur.execute(""" SELECT regno,c.name, make, model, year,transmission, category,capacity, b.name, walkscore,mapurl FROM carsharing.car AS c NATURAL JOIN carsharing.carmodel JOIN carsharing.carbay AS b ON parkedat=bayid WHERE regno = %s""",(regno,))
        val=cur.fetchone()
        if len(val)==0:
            val=None
    except Exception as e:
        print(e)
        print("Error with fetching from databade")
    cur.close()
    conn.close()
    return val


def get_all_cars():
    rows = None
    #dummy data[ ['66XY99', 'Ice the Cube', 'Nissan', 'Cube', '2007', 'auto'], ['WR3KD', 'Bob the SmartCar', 'Smart', 'Fortwo', '2015', 'auto']]

    conn = database_connect()
    if(conn is None):
        return ERROR_CODE
    cur =conn.cursor()
    try:

    # Get all cars that PeerCar has
    # Return the results

      cur.execute(""" SELECT regno, name from carsharing.car""")
      rows = cur.fetchall()
      if len(rows)==0:
        rows=None
    except Exception as e:
      print(e)
      print("Error fetching from database")
    cur.close()
    conn.close()
    return rows 




#####################################################
##  Bay (detail, list, finding cars inside bay)
#####################################################

def get_all_bays():
    #Dummy Data 
    #[['SIT', '123 Some Street, Boulevard', '2'], ['some_bay', '1 Somewhere Road, Right here', '1']]
    # Get the database connection and set up the cursor
    conn = database_connect()
    if(conn is None):
        return ERROR_CODE
    cur = conn.cursor()
    rows =None
    try:
        #problem need to has indicator!!!!!
        # Get all the bays that PeerCar has :)
        # And the number of bays
        cur.execute(""" SELECT carsharing.carbay.name , address, count(regno) FROM carsharing.carbay  JOIN carsharing.car ON bayid = parkedat GROUP BY bayid """)
        rows = cur.fetchall()
        if len(rows)==0:
           rows=None
    except Exception as e:
        print(e)
        print("Error with database")  
    # Return the results
    return rows

def get_bay(name):
    val = None
    #Dummy Data 'SIT', 'Home to many (happy?) people.', '123 Some Street, Boulevard', '-33.887946', '151.192958']
    #Get the database connection and set up the cursor
    conn = database_connect()
    if(conn is None):
        return ERROR_CODE
    cur = conn.cursor()
    
    # Get the information about the bay with this unique name
    # Make sure you're checking ordering?? ;)
    try:
        #problem need to has indicator!!!!!
        cur.execute(""" SELECT name ,description, address,gps_lat,gps_long FROM carsharing.carbay WhERE name =%s""",(name,))
        val = cur.fetchone()
        if len(val)==0:
            val=None
    except Exception as e:
        print(e)
        print("Error with database")
    cur.close()
    conn.close()
    return val

def search_bays(search_term):
    rows= None
    #dummy data this dummy data is not matched the html template
    #[['SIT', '123 Some Street, Boulevard', '-33.887946', '151.192958']]
    conn = database_connect()
    if(conn is None):
        return ERROR_CODE
    cur = conn.cursor()
    try:
    # Select the bays that match (or are similar) to the search term
    # You may like this
    #problem need to has indicator!!!!!
        search_term = "%" + search_term + "%"
        sql = """ SELECT carsharing.carbay.name, address, count(regno)  FROM carsharing.carbay  JOIN carsharing.car ON bayid = parkedat WHERE carsharing.carbay.name ILIKE %s or address ILIKE %s GROUP BY bayid """
        cur.execute(sql,(search_term,search_term))
        rows = cur.fetchall();
        if len(rows)==0:
            rows=None
    except Exception as e:
        print(e)
        print("error with fetching database")
    return rows

def get_cars_in_bay(bay_name):
    
    #dummy data [ ['66XY99', 'Ice the Cube'], ['WR3KD', 'Bob the SmartCar']]
    rows = None
    # Get the database connection and set up the cursor
    conn = database_connect()
    if (conn is None ):
        return ERROR_CODE
    cur = conn.cursor()
    try:
        # Get the cars inside the bay with the bay name
        # Cars who have this bay as their bay :)
        # Return simple details (only regno and name)
        cur.execute(""" SELECT regno, name FROM carsharing.car WHERE parkedat = ( SELECT bayid FROM carsharing.carbay WHERE name = %s) """ , (bay_name,))
        rows = cur.fetchall()
        if len(rows)==0:
            rows=None
    except Exception as e:
        print(e)
        print("error with fetching from database")
    cur.close()
    conn.close()
    return rows
