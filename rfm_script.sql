#RFM ANALYSIS

#Creating a database
CREATE DATABASE IF NOT EXISTS rfm_db;

#Using the created database(here, rfm_db)
USE rfm_db;

#Table creation can be done using manual or Table Data Import Wizard(this is used here, because it autocreates schema quickly and it can require some modification)

#Configurations
SET SQL_SAFE_UPDATES = 0;
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE "secure_file_priv";

#Deleting rows when needed
DELETE FROM data_raw;

#Importing table data(rows) manually(using INFILE) because Table Data Import Wizard failed to import rows
LOAD DATA LOCAL INFILE "g:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\data.csv"
INTO TABLE data_raw
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

#Describing Table
DESCRIBE data_raw;

#Data at a glance
SELECT * FROM data_raw LIMIT 10;

#Column names
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'rfm_db'
  AND TABLE_NAME = 'data_raw';
  
#Number Of Columns
SELECT COUNT(*) FROM (#Column names
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'rfm_db'
  AND TABLE_NAME = 'data_raw') AS temp;
  
#Number Of Rows
SELECT COUNT(*) FROM data_raw;

#Data Cleaning Starts Here

#Getting overview of the data
#Checking for null customers, returns, refunds, cancelations with miscellanious and non transactional
SELECT 
    COUNT(*) AS total_records,
    COUNT(CASE WHEN CustomerID IS NULL THEN 1 END) AS null_customers,
    COUNT(CASE WHEN Quantity <= 0 THEN 1 END) AS _returns,
    COUNT(CASE WHEN UnitPrice <= 0 THEN 1 END) AS _refunds,
    COUNT(CASE WHEN InvoiceNo NOT REGEXP '^-?[0-9]+$' THEN 1 END) AS cancelations_misc,
    COUNT(CASE WHEN StockCode NOT REGEXP '^([0-9]{1,10}[A-Za-z]{0,10}|[A-Za-z]{1,10}[0-9]{1,10})$' THEN 1 END) AS non_transactional
FROM data_raw;

#Removing null customers
DELETE FROM data_raw WHERE CustomerID IS NULL OR CustomerID = '';
#Removing returns
DELETE FROM data_raw WHERE Quantity <= 0;
#Removing refunds
DELETE FROM data_raw WHERE UnitPrice <= 0;
#Removing cancelations and miscellanious
DELETE FROM data_raw WHERE InvoiceNo NOT REGEXP '^-?[0-9]+$';
#Removing non transactional
DELETE FROM data_raw WHERE StockCode NOT REGEXP '^([0-9]{1,10}[A-Za-z]{0,10}|[A-Za-z]{1,10}[0-9]{1,10})$';
#Removing invalid or garbage data based on Quantity String
DELETE FROM data_raw WHERE Quantity NOT REGEXP '^(-|\\+)?([0-9]+\\.[0-9]*|[0-9]*\\.[0-9]+|[0-9]+)$';
#Removing Unspecified Countries
DELETE FROM data_raw WHERE Country = 'Unspecified';

#Verifying removals
SELECT * FROM data_raw WHERE CustomerID IS NULL OR CustomerID = '';
SELECT * FROM data_raw WHERE Quantity <= 0;
SELECT * FROM data_raw WHERE UnitPrice <= 0;
SELECT * FROM (SELECT * FROM data_raw WHERE InvoiceNo NOT REGEXP '^-?[0-9]+$') AS temp WHERE InvoiceNo LIKE 'C%';
SELECT * FROM (SELECT * FROM data_raw WHERE InvoiceNo NOT REGEXP '^-?[0-9]+$') AS temp WHERE InvoiceNo NOT LIKE 'C%';
SELECT * FROM data_raw WHERE StockCode NOT REGEXP '^([0-9]{1,10}[A-Za-z]{0,10}|[A-Za-z]{1,10}[0-9]{1,10})$';
SELECT * FROM data_raw WHERE Quantity REGEXP '^(-|\\+)?([0-9]+\\.[0-9]*|[0-9]*\\.[0-9]+|[0-9]+)$';
SELECT * FROM data_raw WHERE Country = 'Unspecified';

#Other columns other than InvoiceDate have been checked for invalid values
#Fixing InvoiceDate and time starts here

SELECT * FROM data_raw WHERE InvoiceDate IS NULL OR TRIM(InvoiceDate) = '';
SELECT * FROM data_raw WHERE LENGTH(InvoiceDate) >= 17 ORDER BY 5 ;
#13-16 is the range of datetime length

#A detailed analysis shows only 1 datetime format is present
WITH dateTime_data AS (
	SELECT InvoiceDate AS raw_date,
    CASE
		WHEN STR_TO_DATE(`InvoiceDate`, '%m/%d/%Y %H:%i') IS NOT NULL THEN 'df1'
        WHEN STR_TO_DATE(`InvoiceDate`, '%d/%m/%Y %H:%i') IS NOT NULL THEN 'df2'
        WHEN STR_TO_DATE(`InvoiceDate`, '%Y-%m-%d %H:%i:%s') IS NOT NULL THEN 'df3'
        WHEN STR_TO_DATE(`InvoiceDate`, '%m/%d/%y %H:%i') IS NOT NULL THEN 'df4'
        ELSE NULL
	END AS date_format
    FROM data_raw
    )
    SELECT * FROM datetime_data WHERE date_format != 'df1';
    
#All other fields are checked for blanks, nulls or invalid values, since verything is according to the data we want
#i.e., clean and well formatted we can start organising and cleaning the filtered raw data into cleaned tables as required

#Creating a clean and well-formatted version of data_raw as data_clean

CREATE TABLE IF NOT EXISTS data_clean AS
SELECT 
    CAST(InvoiceNo AS CHAR(20)) AS InvoiceNo,
    CAST(StockCode AS CHAR(20)) AS StockCode,
    Description,
    CAST(Quantity AS SIGNED) AS Quantity,
    STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i') AS InvoiceDate,
    CAST(UnitPrice AS DECIMAL(10,2)) AS UnitPrice,
    CAST(CustomerID AS SIGNED) AS CustomerID,
    Country,
    ROUND(CAST(Quantity AS SIGNED) * CAST(UnitPrice AS DECIMAL(10,2)), 2) AS LineTotal
FROM data_raw;

#Creating raw rfm metrics

CREATE TABLE IF NOT EXISTS rfm_raw_metrics AS
WITH Anchor AS (
    SELECT DATE_ADD(MAX(InvoiceDate), INTERVAL 1 DAY) AS anchor_date 
    FROM data_clean
)
SELECT 
    c.CustomerID,
    c.Country,
    DATEDIFF(a.anchor_date, MAX(c.InvoiceDate)) AS Recency_Days,
    COUNT(DISTINCT c.InvoiceNo) AS Frequency_Orders,
    ROUND(SUM(c.LineTotal), 2) AS Monetary_Value,
    MAX(c.InvoiceDate) AS Last_Purchase_Date
FROM data_clean c
CROSS JOIN Anchor a
GROUP BY c.CustomerID, c.Country, a.anchor_date;

#Creating final rfm segments with calculated rfm scores

CREATE TABLE IF NOT EXISTS rfm_final_segments AS
WITH Scores AS (
    SELECT 
        CustomerID,
        Country,
        Recency_Days,
        Frequency_Orders,
        Monetary_Value,
        NTILE(5) OVER (ORDER BY Recency_Days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY Frequency_Orders ASC) AS f_score,
        NTILE(5) OVER (ORDER BY Monetary_Value ASC) AS m_score
    FROM rfm_raw_metrics
)
SELECT 
    CustomerID,
    Country,
    Recency_Days,
    Frequency_Orders,
    Monetary_Value,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_combined_score,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'High-Value / Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Recent / New Buyers'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At-Risk / Need Attention'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost / Inactive'
        ELSE 'Occasional Buyers'
    END AS customer_segment
FROM Scores;

#Results of all tables
SELECT * FROM data_raw;
SELECT * FROM data_clean;
SELECT * FROM rfm_raw_metrics;
SELECT * FROM rfm_final_segments;