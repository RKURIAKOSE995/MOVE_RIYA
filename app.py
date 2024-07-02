# Import libraries
from flask import Flask, request, abort, g
from flask_basicauth import BasicAuth
from werkzeug.serving import WSGIRequestHandler
import json
import pandas as pd
import os
import datetime
from pandas import json_normalize
import pyodbc
import requests
from decouple import config, Csv

from move_functions.functions import jsonDump, rmTrailingValues, aqProcessing, filterNetwork, split_dataframe_rows, strToUUID, csvDump
from move_functions.db import execProcedureNoReturn, execProcedure, getDB, commitDB, closeDB

# Variable declarations
JSON_NAME = 'monnit_' + str(datetime.datetime.now()) + '.json'
CSV_DIR = os.getcwd() + '/data/csv/'
JSON_DIR = os.getcwd() + '/data/json/'

# POST credentials info
post_uname = config('MONNIT_WEBHOOK_UNAME')
post_pwd = config('MONNIT_WEBHOOK_PWD')

# Open file containing the sensor types to look for
sensor_types = config('MONNIT_SENSOR_TYPES', cast=Csv())

# SQL Server connection info
db_driver = config('DB_DRIVER')
db_server = config('AZURE_DB_SERVER')
db_database = config('AZURE_DB_DATABASE')
db_usr = config('AZURE_DB_USR')
db_pwd = config('AZURE_DB_PWD')

# Formatted connection string for the SQL DB without username and password
#SQL_CONN_STR = "DRIVER={0};SERVER={1};Database={2};Trusted_Connection=yes;".format(db_driver, db_server, db_database)
SQL_CONN_STR = "DRIVER={0};SERVER={1};Database={2};UID={3};PWD={4};".format(db_driver, db_server, db_database, db_usr, db_pwd)

# Flask web server
app = Flask(__name__)
app.config['BASIC_AUTH_USERNAME'] = post_uname
app.config['BASIC_AUTH_PASSWORD'] = post_pwd
app.config['BASIC_AUTH_FORCE'] = True
basic_auth = BasicAuth(app)

# Main body
@app.route('/', methods =['POST'])
@basic_auth.required
# Primary (main) function
def webhook():
    print('Request Authenticated & JSON Received')
    print('Received request:', request.get_data(as_text=True))
    print('Headers:', request.headers)
    print('JSON Payload:', request.json)

    # Store the received JSON file from the request
    json_load = request.json
    # Dump JSON to file system (disabled for production use)
    #jsonDump('output.json',json_load)
    
    # Add the desired Content-Type header to the request
    #headers = {'Content-Type': 'application/json'}
    
    # Make the POST request with the updated headers
    #response = requests.post(url='http://192.168.1.25:80/', json=json_load, headers=headers)

    # Access the response to avoid the warning
    #print('Response status code:', response.status_code)
    #print('Response text:', response.text)

    # Load gateway and sensor message data form JSON into separate variables
    gateway_messages = json_load['gatewayMessage']
    sensor_messages = json_load['sensorMessages']
    
    # Convert the JSONs into pandas dataframes
    gateway_messages = json_normalize(gateway_messages)
    sensor_messages = json_normalize(sensor_messages)

    # Remove the trailing values present in the rawData field of some sensors
    sensor_messages = rmTrailingValues(sensor_messages, sensor_types)
    
    # Process any sensor messages for Air Quality
    sensor_messages = aqProcessing(sensor_messages)
    
    # Filter out messages from networks not related to MOVE
    sensor_messages = filterNetwork(sensor_messages, str(58947))

    # Delimiters used in the received sensor JSON
    delimiters = "%2c", "|", "%7c"
    
    # The columns that need to be split to remove concatenated values
    sensor_columns = ["rawData", "dataValue", "dataType", "plotValues", "plotLabels"]
    
    # Split the dataframe to move concatenated values to new rows
    split_df = split_dataframe_rows(sensor_messages, sensor_columns, delimiters)

    # Use the Pandas 'loc' function to find and replace pending changes in the dataset
    split_df.loc[(split_df.pendingChange == 'False'), 'pendingChange'] = 0
    split_df.loc[(split_df.pendingChange == 'True'), 'pendingChange'] = 1

    # Connect to DB
    conn = getDB()

    # Additional processing
    for i, sensor_data in split_df.iterrows():
        print("Processing sensor message " + str(i) + ".")
        
        # CREATE NETWORK
        sql = "{CALL [dbo].[PROC_GET_OR_CREATE_NETWORK] (?)}"
        params = (sensor_data['networkID'])
        print('Step 1/10: Creating network entry')
        execProcedureNoReturn(conn, sql, params)
        print('Network entry created')

        # CREATE APPLICATION
        sql = "{CALL [dbo].[PROC_GET_OR_CREATE_APPLICATION] (?)}"
        params = (sensor_data['applicationID'])
        print('Step 2/10: Creating application entry')
        execProcedureNoReturn(conn, sql, params)
        print('Network application created')

        # GET OR CREATE SENSOR
        sql = """\
            DECLARE @out UNIQUEIDENTIFIER;
            EXEC [dbo].[PROC_GET_OR_CREATE_SENSOR] @applicationID = ?, @networkID = ?, @sensorName = ?, @sensorID = @out OUTPUT;
            SELECT @out AS the_output;
            """
        params = (sensor_data['applicationID'], sensor_data['networkID'], sensor_data['sensorName'])
        print('Step 3/10: Creating or getting sensor')
        sensor_data['sensorID'] = strToUUID(execProcedure(conn, sql, params))
        print(sensor_data['sensorID'])

        # GET OR CREATE DATA TYPE
        sql = """\
            DECLARE @out UNIQUEIDENTIFIER;
            EXEC [dbo].[PROC_GET_OR_CREATE_DATA_TYPE] @dataType = ?, @dataTypeID = @out OUTPUT;
            SELECT @out AS the_output;
            """
        params = sensor_data['dataType']
        print('Step 4/10: Creating or getting data type ID')
        sensor_data['dataTypeID'] = strToUUID(execProcedure(conn, sql, params))
        print(sensor_data['dataTypeID'])

        # GET OR CREATE PLOT LABELS
        sql = """\
            DECLARE @out UNIQUEIDENTIFIER;
            EXEC [dbo].[PROC_GET_OR_CREATE_PLOT_LABELS] @plotLabel = ?, @plotLabelID = @out OUTPUT;
            SELECT @out AS the_output;
            """
        params = sensor_data['plotLabels']
        print('Step 5/10: Creating or getting plot label ID')
        sensor_data['plotLabelID'] = strToUUID(execProcedure(conn, sql, params))

        # GET OR CREATE READING
        sql = """\
            DECLARE @out UNIQUEIDENTIFIER;
            EXEC [dbo].[PROC_CREATE_READING] @dataMessageGUID = ?, @sensorID = ?, @rawData = ?, @dataTypeID = ?, @dataValue = ?, @plotLabelID = ?, @plotValue = ?, @messageDate = ?, @readingID = @out OUTPUT;
            SELECT @out AS the_output;
            """
        params = (sensor_data['dataMessageGUID'], sensor_data['sensorID'], sensor_data['rawData'], sensor_data['dataTypeID'], sensor_data['dataValue'], sensor_data['plotLabelID'], sensor_data['plotValues'], sensor_data['messageDate'])
        print('Step 6/10: Creating reading, and getting ID')
        sensor_data['readingID'] = strToUUID(execProcedure(conn, sql, params))

        # GET OR CREATE SIGNAL STATUS
        sql = "{CALL [dbo].[PROC_CREATE_SIGNAL_STATUS] (?, ?, ?)}"
        params = (sensor_data['readingID'], sensor_data['dataMessageGUID'], sensor_data['signalStrength'])
        print('Step 7/10: Creating signal status')
        execProcedureNoReturn(conn, sql, params)

        # GET OR CREATE BATTERY STATUS
        sql = "{CALL [dbo].[PROC_CREATE_BATTERY_STATUS] (?, ?, ?)}"
        params = (sensor_data['readingID'], sensor_data['dataMessageGUID'], sensor_data['batteryLevel'])
        print('Step 8/10: Creating battery status')
        execProcedureNoReturn(conn, sql, params)

        # GET OR CREATE PENDING CHANGES
        sql = "{CALL [dbo].[PROC_CREATE_PENDING_CHANGES] (?, ?, ?)}"
        params = (sensor_data['readingID'], sensor_data['dataMessageGUID'], sensor_data['pendingChange'])
        print('Step 9/10: Creating pending change')
        execProcedureNoReturn(conn, sql, params)

        # GET OR CREATE SENSOR VOLTAGE
        sql = "{CALL [dbo].[PROC_CREATE_SENSOR_VOLTAGE] (?, ?, ?)}"
        params = (sensor_data['readingID'], sensor_data['dataMessageGUID'], sensor_data['voltage'])
        print('Step 10/10: Creating voltage reading')
        execProcedureNoReturn(conn, sql, params)

    # Commit data and close open database connection
    commitDB()
    closeDB()

    # Dump the data to CSV files using the prepared functions (disabled for production use)
    csvDump('sensorData', split_df)
    csvDump('gatewayData', gateway_messages)

    # Return status 200 (success) to the remote client
    return '', 200

if __name__ == '__main__':
    WSGIRequestHandler.protocol_version = "HTTP/1.1"
    app.run(host='0.0.0.0', port= 80, debug=True)
