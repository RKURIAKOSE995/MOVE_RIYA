/* Create tables for the processed data */
/* This file creates tables using corrected normalisation tables */

CREATE TABLE SALFORDMOVE.dbo.APPLICATIONS(
	applicationID INT NOT NULL,
	applicationName NVARCHAR(20) NULL,
	CONSTRAINT PK_APPLICATIONS PRIMARY KEY (applicationID)
);

CREATE TABLE SALFORDMOVE.dbo.NETWORKS(
	networkID INT NOT NULL,
	networkName NVARCHAR(20) NULL,
	CONSTRAINT PK_NETWORKS PRIMARY KEY (networkID)
);

CREATE TABLE SALFORDMOVE.dbo.SENSORS(
	sensorID UNIQUEIDENTIFIER NOT NULL,
	applicationID INT NOT NULL,
	networkID INT NOT NULL,
	sensorName NVARCHAR(MAX),
	CONSTRAINT PK_SENSORS PRIMARY KEY (sensorID),
	CONSTRAINT FK_SENSORS_APPLICATIONS FOREIGN KEY (applicationID)
	REFERENCES SALFORDMOVE.dbo.APPLICATIONS (applicationID)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	CONSTRAINT FK_SENSORS_NETWORKS FOREIGN KEY (networkID)
	REFERENCES SALFORDMOVE.dbo.NETWORKS (networkID)
	ON DELETE CASCADE
	on UPDATE CASCADE
);

CREATE TABLE SALFORDMOVE.dbo.DATA_TYPES(
	dataTypeID UNIQUEIDENTIFIER NOT NULL,
	dataType NVARCHAR(20) NOT NULL,
	CONSTRAINT PK_DATA_TYPES PRIMARY KEY (dataTypeID)
);

CREATE TABLE SALFORDMOVE.dbo.PLOT_LABELS(
	plotLabelID UNIQUEIDENTIFIER NOT NULL,
	plotLabel NVARCHAR(20) NOT NULL,
	CONSTRAINT PK_PLOT_LABELS PRIMARY KEY (plotLabelID)
);

CREATE TABLE SALFORDMOVE.dbo.READINGS(
	readingID UNIQUEIDENTIFIER NOT NULL,
	dataMessageGUID UNIQUEIDENTIFIER NOT NULL,
	sensorID UNIQUEIDENTIFIER REFERENCES SALFORDMOVE.dbo.SENSORS(sensorID) NOT NULL,
	dataTypeID UNIQUEIDENTIFIER NOT NULL,
	plotLabelID UNIQUEIDENTIFIER NOT NULL,
	messageDate DATETIME NOT NULL,
	rawData NVARCHAR(10) NOT NULL,
	dataValue NVARCHAR(10) NOT NULL,
	plotValue NVARCHAR(10) NOT NULL,
	CONSTRAINT PK_READINGS PRIMARY KEY (readingID, dataMessageGUID),
	CONSTRAINT FK_READINGS_SENSORID FOREIGN KEY (sensorID)
	REFERENCES SALFORDMOVE.dbo.SENSORS (sensorID)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	CONSTRAINT FK_READINGS_DTYPE FOREIGN KEY (dataTypeID)
	REFERENCES SALFORDMOVE.dbo.DATA_TYPES (dataTypeID)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	CONSTRAINT FK_READINGS_PLABEL FOREIGN KEY (plotLabelID)
	REFERENCES SALFORDMOVE.dbo.PLOT_LABELS (plotLabelID)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE SALFORDMOVE.dbo.SIGNAL_STATUS(
	readingID UNIQUEIDENTIFIER NOT NULL,
	dataMessageGUID UNIQUEIDENTIFIER NOT NULL,
	signalStrength FLOAT,
	CONSTRAINT FK_SIGNAL_STATUS FOREIGN KEY (readingID, dataMessageGUID)
	REFERENCES SALFORDMOVE.dbo.READINGS (readingID, dataMessageGUID)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE SALFORDMOVE.dbo.BATTERY_STATUS(
	readingID UNIQUEIDENTIFIER NOT NULL,
	dataMessageGUID UNIQUEIDENTIFIER NOT NULL,
	batteryLevel INT,
	CONSTRAINT FK_BATTERY_STATUS FOREIGN KEY (readingID, dataMessageGUID)
	REFERENCES SALFORDMOVE.dbo.READINGS (readingID, dataMessageGUID)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE SALFORDMOVE.dbo.PENDING_CHANGES(
	readingID UNIQUEIDENTIFIER NOT NULL,
	dataMessageGUID UNIQUEIDENTIFIER NOT NULL,
	pendingChange BIT,
	CONSTRAINT FK_PENDING_CHANGES FOREIGN KEY (readingID, dataMessageGUID)
	REFERENCES SALFORDMOVE.dbo.READINGS (readingID, dataMessageGUID)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE SALFORDMOVE.dbo.SENSOR_VOLTAGE(
	readingID UNIQUEIDENTIFIER NOT NULL,
	dataMessageGUID UNIQUEIDENTIFIER NOT NULL,
	voltage FLOAT,
	CONSTRAINT FK_SENSOR_VOLTAGE FOREIGN KEY (readingID, dataMessageGUID)
	REFERENCES SALFORDMOVE.dbo.READINGS (readingID, dataMessageGUID)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

GO