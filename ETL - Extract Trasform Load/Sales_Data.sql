--Sales Data Branch 2

SELECT DISTINCT AMOUNT 
FROM DWT_BRANCH_2.BUYS;

SELECT 
    CNUMBER,
    PNUMBER,
    "DATE",
    CASE LOWER(AMOUNT)
        WHEN 'two'   THEN 2
        WHEN 'three' THEN 3
        WHEN 'four'  THEN 4
    END AS AMOUNT
FROM DWT_BRANCH_2.BUYS;

--Cleaned Sales from Products and Buys table
CREATE TABLE Cleaned_Sales_Data_br2 AS
SELECT 
    b.CNUMBER, 
    b.PNUMBER, 
    CASE b.AMOUNT 
        WHEN 'two' THEN 2
        WHEN 'three' THEN 3
        WHEN 'four' THEN 4
        ELSE 0 
    END AS QUANTITY,
    -- Safely converts to a number, defaulting to 0 if a row has unconvertible text
    CAST(p.PRICE AS NUMBER DEFAULT 0 ON CONVERSION ERROR) AS PRICE, 
    p.LITER, 
    p.LABEL,
    b."DATE" AS DATE_T
FROM 
    DWT_BRANCH_2.BUYS b
JOIN 
    DWT_BRANCH_2.PRODUCT p ON b.PNUMBER = p.NUM;


select * from cleaned_sales_data_br2;

--Branch 2 Turnover, Sales in Liter for each sale
SELECT 
    CNUMBER,
    PNUMBER,
    QUANTITY,
    PRICE,
    LITER,
    LABEL,
    DATE_T,
    -- Calculation for each row
    (QUANTITY * PRICE) AS TURNOVER,
    (QUANTITY * LITER) AS SALES_IN_LITERS
FROM 
    Cleaned_Sales_Data_br2;
    
--Branch 2 total turnaround,sales in liters

SELECT 
    LABEL,
    SUM(QUANTITY * PRICE) AS TOTAL_TURNOVER,
    SUM(QUANTITY * LITER) AS TOTAL_SALES_IN_LITERS
FROM 
    Cleaned_Sales_Data_br2
GROUP BY 
    LABEL
ORDER BY 
    TOTAL_TURNOVER DESC;



-- Sales Data Branch 4

CREATE TABLE Cleaned_Sales_Data_br4 AS
SELECT 
    o.CID AS CNUMBER, 
    i.PID AS PNUMBER, 
    i.AMOUNT AS QUANTITY,
    p.PRICE, 
    CAST(p."SIZE" AS NUMBER DEFAULT 0 ON CONVERSION ERROR) AS LITER,
    p.NAME AS LABEL,
    o."DATE" AS DATE_T
FROM 
    DWT_BRANCH_4."ORDER" o
JOIN 
    DWT_BRANCH_4.ITEM i ON o.ORDERID = i.OID
JOIN 
    DWT_BRANCH_4.PRODUCT p ON i.PID = p.PRODUCTNUMBER;
    
    
select * from cleaned_sales_data_br4;

--Branch 4 Turnover, Sales in Liter for each sale
SELECT 
    CNUMBER,
    PNUMBER,
    QUANTITY,
    PRICE,
    LITER,
    LABEL,
    DATE_T,
    -- Calculation for each row
    (QUANTITY * PRICE) AS TURNOVER,
    (QUANTITY * LITER) AS SALES_IN_LITERS
FROM 
    cleaned_sales_data_br4;
    
--Branch 4 total turnaround,sales in liters

SELECT 
    LABEL,
    SUM(QUANTITY * PRICE) AS TOTAL_TURNOVER,
    SUM(QUANTITY * LITER) AS TOTAL_SALES_IN_LITERS
FROM 
    cleaned_sales_data_br4
GROUP BY 
    LABEL
ORDER BY 
    TOTAL_TURNOVER DESC;
    
    
--Sales Data Branch 5

CREATE TABLE Cleaned_Sales_Data_br5 AS
SELECT 
    o.CUSTOMER AS CNUMBER, 
    os.PRODUCT AS PNUMBER, 
    os.AMOUNT AS QUANTITY,
    p.PRICE, 
    p.SZ AS LITER,
    p.NAME AS LABEL,
    o."DATE" AS DATE_T
FROM 
    DWT_BRANCH_5.ORDERS os
JOIN 
    DWT_BRANCH_5."ORDER" o ON os."ORDER" = o.OID
JOIN 
    DWT_BRANCH_5.PRODUCT p ON os.PRODUCT = p.ID;
    
select * from cleaned_sales_data_br5;

--Branch 4 Turnover, Sales in Liter for each sale
SELECT 
    CNUMBER,
    PNUMBER,
    QUANTITY,
    PRICE,
    LITER,
    LABEL,
    DATE_T,
    -- Calculation for each row
    (QUANTITY * PRICE) AS TURNOVER,
    (QUANTITY * LITER) AS SALES_IN_LITERS
FROM 
    cleaned_sales_data_br5;
    
--Branch 4 total turnaround,sales in liters

SELECT 
    LABEL,
    SUM(QUANTITY * PRICE) AS TOTAL_TURNOVER,
    SUM(QUANTITY * LITER) AS TOTAL_SALES_IN_LITERS
FROM 
    cleaned_sales_data_br5
GROUP BY 
    LABEL
ORDER BY 
    TOTAL_TURNOVER DESC;
