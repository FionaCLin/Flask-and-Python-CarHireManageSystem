#!/usr/bin/env python3

from modules import pg8000
import configparser
import bcrypt

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
    # TODO
    # Check if the user details are correct!
    # Return the relevant information (watch the order!)
    #make password comparable
    val = None
    conn = database_connect()
    if conn is None:
        return ERROR_CODE
    cur = conn.cursor()
    try:
        # sql = """select nickname, nametitle, namegiven, namefamily, 
        #          address, homebay, since, subscribed, stat_nrOfBookings,
        #          password
        #          from carsharing.member
        #          where email = %s
        #       """
        # cur.execute(sql, (email,))
        sql = """SELECT  nickname, nametitle, namegiven , namefamily, c.address, cb.name,since, subscribed,stat_nrofbookings, password FROM carsharing.Member as c join carsharing.carbay as cb on homebay = bayid WHERE email = %s """
        cur.execute(sql , (email,))
        val = cur.fetchone()
        if not isinstance(password, bytes):
            password = password.encode('UTF-8')
        if not isinstance(val[9], bytes):
            val[9] = val[9].encode('UTF-8')
        if bcrypt.hashpw(password, val[9]) != val[9]:
            val = None
    except:
        print("Error")

    cur.close()
    conn.close()
    return val


#~ def update_homebay(email, bayname):
    #~ # TODO
    #~ # Update the user's homebay
    #~ isUpdated = False
    #~ conn = database_connect()
    #~ if conn is None:
        #~ return ERROR_CODE
    #~ cur = conn.cursor()
    #~ try:
        #~ sql = """update carsharing.member
                 #~ set homebay = (select bayid from carsharing.carbay where name = %s)
                 #~ where email = %s
              #~ """
        #~ cur.execute(sql, (bayname, email))
        #~ conn.commit()
        #~ isUpdated = cur.rowcount() > 0
    #~ except:
        #~ print("Error")

    #~ cur.close()
    #~ conn.close()
    #~ return isUpdated




#~ def check_login(email, password):
    #~ # Dummy data 
    #~ #['Shadow', 'Mr', 'Evan', 'Nave', '123 Fake Street, Fakesuburb', 'SIT', '01-05-2016', 'Premium', '1']
    #~ val = None
    #~ #Ask for the database connection, and get the cursor set up
    #~ conn = database_connect()
    #~ if(conn is None):
        #~ return ERROR_CODE
    #~ cur = conn.cursor()
    #~ try:
        #~ #Try executing the SQL and get from the database
        #~ sql = """SELECT  nickname, nametitle, namegiven , namefamily, c.address, cb.name,since, subscribed,stat_nrofbookings FROM carsharing.Member as c join carsharing.carbay as cb on homebay = bayid
            #~ WHERE email = %s AND password = %s """
        #~ cur.execute(sql , (email, password))
        #~ val = cur.fetchone()
        #~ if len(val)==0:
            #~ val=None
    #~ except:
        #~ #If there were any errors, return a NULL row printing an error to the debug
        #~ print("Error with Database")
    #~ cur.close()             #Close the cursor
    #~ conn.close()            #Close the connection to the db
    #~ return val

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
        isUpdated = cur.rowcount() > 0
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
    val = None
    isCreate=False
    conn = database_connect()
    if(conn is None):
        return ERROR_CODE
    cur = conn.cursor()
    try:
    # Insert a new booking
    # prototype or my procedure
        sql = """ SELECT makeBooking(%s,%s,%s,%s,%s)"""

        cur.excecute(sql,(car_rego,email,date,hour,duration))
        conn.commit()
        isCreate = cur.rowcount() > 0
        if(isCreate):
            val = get_booking( date, hour, car_rego)
    except Exception as e:
        print(e)
        print("Error with database")
    cur.close()
    conn.close()
    # Make sure to check for:(I think for this check, we can use some constraint check from assignment 2)
    #       - If the member already has booked at that time
    #       - If there is another booking that overlaps
    #       - Etc.
    # return False if booking was unsuccessful :)
    # We want to make sure we check this thoroughly
    return val


def get_all_bookings(email):
    # Get the database connection and set up the cursor
    conn = database_connect()
    if(conn is None):
        return ERROR_CODE
    cur = conn.cursor()
    rows =None
    try:
        #Try to get all the info return from the query
        cur.execute(""" SELECT * FROM getAllBooking(%s); """, (email,))
        rows = cur.fetchall()
        print(rows)
    except Exception as e:
        print(e);
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
        
        # Get the information about a certain booking
        # It has to have the combination of date, hour and car
        cur.execute("""SELECT * FROM fetchbooking(%s,%s,%s)""", (car, b_date, b_hour))
        row = cur.fetchone()
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
        cur.execute(""" Select * From getCarDetail(%s)""",(regno,))
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
      print(rows)
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
        cur.execute("""SELECT * FROM GETALLBAYS()""")
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
        cur.execute("""SELECT * FROM getBay(%s)""",(name,))
        val = cur.fetchone()
        
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
       
        cur.execute("""SELECT * FROM fetchBays(%s)""",(search_term,))
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
        cur.execute(""" select * from getCarsInBay(%s) """ , (bay_name,))
        rows = cur.fetchall()
        if len(rows)==0:
            rows=None
    except Exception as e:
        print(e)
        print("error with fetching from database")
    cur.close()
    conn.close()
    return rows
