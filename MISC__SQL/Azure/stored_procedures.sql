/* Check if NETWORK exists, if not create it */
CREATE PROCEDURE PROC_GET_OR_CREATE_NETWORK(@networkID INT)
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS
	(
		SELECT networkID
		FROM [SALFORDMOVE].[dbo].NETWORKS
		WHERE networkID = @networkID
	)
	BEGIN
		PRINT('NETWORK ID EXISTS IN TABLE, SKIPPING...')
	END

	ELSE
		BEGIN
			INSERT INTO [SALFORDMOVE].[dbo].NETWORKS (networkID) VALUES (@networkID)
		END
END
GO


/* Check if APPLICATION exists, if not create it */
CREATE PROCEDURE PROC_GET_OR_CREATE_APPLICATION(@applicationID INT)
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS
	(
		SELECT applicationID
		FROM [SALFORDMOVE].[dbo].APPLICATIONS
		WHERE applicationID = @applicationID
	)
	BEGIN
		PRINT('APPLICATION ID EXISTS IN TABLE, SKIPPING...')
	END

	ELSE
		BEGIN
			INSERT INTO [SALFORDMOVE].[dbo].APPLICATIONS (applicationID) VALUES (@applicationID)
		END
END
GO


/* Check if SENSOR exists, 
if not create it and return the generated sensorID, 
if exists SELECT sensorID from table and return it */
CREATE PROCEDURE PROC_GET_OR_CREATE_SENSOR (@applicationID as INT, @networkID as INT, @sensorName as NVARCHAR(MAX), @sensorID UNIQUEIDENTIFIER OUTPUT)
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS
	(
		SELECT sensorID
		FROM [SALFORDMOVE].[dbo].SENSORS
		WHERE sensorName LIKE @sensorName
	)
	BEGIN
		SELECT @sensorID = sensorID
		FROM [SALFORDMOVE].[dbo].SENSORS
		WHERE sensorName LIKE @sensorName
	END

	ELSE
		BEGIN
			SET @sensorID = NULL
			SET @sensorID = NEWID()
			INSERT INTO [SALFORDMOVE].[dbo].SENSORS (sensorID, applicationID, networkID, sensorName) VALUES (@sensorID, @applicationID, @networkID, @sensorName)
		END
END
GO


/* Check if DATA TYPE exists, 
if not create it and return the generated dataTypeID, 
if exists SELECT dataTypeID from table and return it */
CREATE PROCEDURE PROC_GET_OR_CREATE_DATA_TYPE (@dataType AS NVARCHAR(20), @dataTypeID UNIQUEIDENTIFIER OUTPUT)
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS
	(
		SELECT dataTypeID
		FROM [SALFORDMOVE].[dbo].DATA_TYPES
		WHERE dataType LIKE @dataType
	)
	BEGIN
		SELECT @dataTypeID = dataTypeID
		FROM [SALFORDMOVE].[dbo].DATA_TYPES
		WHERE dataType LIKE @dataType
	END

	ELSE
		BEGIN
			SET @dataTypeID = NULL
			SET @dataTypeID = NEWID()

			INSERT INTO [SALFORDMOVE].[dbo].DATA_TYPES (dataTypeID, dataType) VALUES (@dataTypeID, @dataType)
		END
END
GO


/* Check if PLOT LABEL exists,
if not create it and return the generated plotLabelID, 
if exists SELECT plotLabelID from table and return it */
CREATE PROCEDURE PROC_GET_OR_CREATE_PLOT_LABELS (@plotLabel AS NVARCHAR(20), @plotLabelID UNIQUEIDENTIFIER OUTPUT)
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS
	(
		SELECT plotLabelID
		FROM [SALFORDMOVE].[dbo].PLOT_LABELS
		WHERE plotLabel LIKE @plotLabel
	)
	BEGIN
		SELECT @plotLabelID = plotLabelID
		FROM [SALFORDMOVE].[dbo].PLOT_LABELS
		WHERE plotLabel LIKE @plotLabel
	END

	ELSE
		BEGIN
			SET @plotLabelID = NULL
			SET @plotLabelID = NEWID()

			INSERT INTO [SALFORDMOVE].[dbo].PLOT_LABELS (plotLabelID, plotLabel) VALUES (@plotLabelID, @plotLabel)
		END
END
GO


/* Create a new reading in the database, 
and return the genreated readingID */
CREATE PROCEDURE PROC_CREATE_READING (@readingID UNIQUEIDENTIFIER OUTPUT, @dataMessageGUID UNIQUEIDENTIFIER, @sensorID UNIQUEIDENTIFIER, @rawData NVARCHAR(10), @dataTypeID UNIQUEIDENTIFIER, @dataValue NVARCHAR(10), @plotLabelID UNIQUEIDENTIFIER, @plotValue NVARCHAR(10), @messageDate DATETIME)
AS
BEGIN
	SET NOCOUNT ON;
	SET @readingID = NULL
	SET @readingID = NEWID()

	INSERT INTO [SALFORDMOVE].[dbo].READINGS (readingID, dataMessageGUID, sensorID, rawData, dataTypeID, dataValue, plotLabelID, plotValue, messageDate) VALUES (@readingID, @dataMessageGUID, @sensorID, @rawData, @dataTypeID, @dataValue, @plotLabelID, @plotValue, @messageDate)
END
GO


/* Create a new Signal Status entry */
CREATE PROCEDURE PROC_CREATE_SIGNAL_STATUS (@readingID UNIQUEIDENTIFIER, @dataMessageGUID UNIQUEIDENTIFIER, @signalStrength FLOAT)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO [SALFORDMOVE].[dbo].SIGNAL_STATUS (readingID, dataMessageGUID, signalStrength) VALUES (@readingID, @dataMessageGUID, @signalStrength)
END
GO


/* Create a new Battery Status entry */
CREATE PROCEDURE PROC_CREATE_BATTERY_STATUS (@readingID UNIQUEIDENTIFIER, @dataMessageGUID UNIQUEIDENTIFIER, @batteryLevel INT)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO [SALFORDMOVE].[dbo].BATTERY_STATUS (readingID, dataMessageGUID, batteryLevel) VALUES (@readingID, @dataMessageGUID, @batteryLevel)
END
GO


/* Create a new Pending Change entry */
CREATE PROCEDURE PROC_CREATE_PENDING_CHANGES (@readingID UNIQUEIDENTIFIER, @dataMessageGUID UNIQUEIDENTIFIER, @pendingChange BIT)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO [SALFORDMOVE].[dbo].PENDING_CHANGES (readingID, dataMessageGUID, pendingChange) VALUES (@readingID, @dataMessageGUID, @pendingChange)
END
GO


/* Create a new Sensor Voltage entry */
CREATE PROCEDURE PROC_CREATE_SENSOR_VOLTAGE (@readingID UNIQUEIDENTIFIER, @dataMessageGUID UNIQUEIDENTIFIER, @voltage FLOAT)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO [SALFORDMOVE].[dbo].SENSOR_VOLTAGE (readingID, dataMessageGUID, voltage) VALUES (@readingID, @dataMessageGUID, @voltage)
END
GO