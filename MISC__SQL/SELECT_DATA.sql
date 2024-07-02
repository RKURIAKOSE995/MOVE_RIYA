/* Select the top 1000 rows from the READINGS table 
	and join on the relevant metadata from the other tables */
SELECT TOP (1000) s.sensorName
      ,r.[messageDate]
      ,r.[rawData]
      ,r.[dataValue]
	  ,dt.[dataType]
      ,r.[plotValue]
      ,pl.[plotLabel]
FROM [SALFORDMOVE].[dbo].[READINGS] AS r
JOIN [SALFORDMOVE].[dbo].SENSORS AS s
	ON (r.sensorID = s.sensorID)
JOIN [SALFORDMOVE].[dbo].PLOT_LABELS as pl
	ON (r.plotLabelID = pl.plotLabelID)
JOIN [SALFORDMOVE].[dbo].DATA_TYPES as dt
	ON (r.dataTypeID = dt.dataTypeID)