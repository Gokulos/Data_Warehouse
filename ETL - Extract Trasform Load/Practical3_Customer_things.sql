SELECT * FROM DWT_BRANCH_2.CUSTOMER;
SELECT * FROM DWT_BRANCH_2.PLACE;
SELECT * FROM DWT_BRANCH_4.CUSTOMER;
SELECT * FROM DWT_BRANCH_5.CUSTOMER;

SELECT FIRSTNAME,CUSTUMERNUMBER FROM DWT_BRANCH_4.CUSTOMER WHERE CUSTUMERNUMBER=1;

CREATE TABLE Staging_Customer_br2 AS SELECT * FROM DWT_BRANCH_2.CUSTOMER;
CREATE TABLE Staging_Place_br2 AS SELECT * FROM DWT_BRANCH_2.PLACE;
CREATE TABLE Staging_Customer_br4 AS SELECT * FROM DWT_BRANCH_4.CUSTOMER;
CREATE TABLE Staging_Customer_br5 AS SELECT * FROM DWT_BRANCH_5.CUSTOMER;

--BRANCH 2 Normalised
CREATE TABLE Normalised_Customer_br2 AS
SELECT
    c.NUM AS ID,
    -- Trim for removing the spaces,initcap for capitalising the first letter.
    INITCAP(TRIM(c.FIRSTNAME)) AS FIRST_NAME,
    INITCAP(TRIM(c.LASTNAME))  AS FAMILY_NAME,
    -- Extracting everything before the final house number
    INITCAP(
        TRIM(
            REGEXP_SUBSTR(
                p.STR_NO,
                '^(.*)[[:space:]][^[:space:]]+$',
                1,
                1,
                NULL,
                1
            )
        )
    ) AS STREET,
    -- Extracting the house number from the end
    TRIM(
        REGEXP_SUBSTR(
            p.STR_NO,
            '[^[:space:]]+$'
        )
    ) AS NUM,
    -- Extracting the five-digit ZIP code
    REGEXP_SUBSTR(
        TRIM(p.ZIP_PLACE),
        '^[0-9]{5}'
    ) AS ZIP,
    -- Extracting everything after the ZIP code as the city
    INITCAP(
        TRIM(
            REGEXP_REPLACE(
                p.ZIP_PLACE,
                '^[0-9]{5}[[:space:]]*',
                ''
            )
        )
    ) AS CITY,
    -- Since Branch 2 has no gender column
    CAST('Unknown' AS VARCHAR2(10)) AS GENDER,
    c.BDAY AS DOB
FROM staging_customer_br2 c
LEFT JOIN DWT_BRANCH_2.PLACE p
    ON c.PLACEID = p.PLID;


Select * From normalised_customer_br2;

--Branch 4 Normalised

Select * from staging_customer_br4;

CREATE TABLE Normalised_Customer_br4 AS
SELECT
    c.CUSTUMERNUMBER AS ID,
    INITCAP(TRIM(c.FIRSTNAME)) AS FIRST_NAME,
    INITCAP(TRIM(c.NAME))      AS FAMILY_NAME,
    -- Extract street name: everything before the final house number
    INITCAP(
        TRIM(
            REGEXP_SUBSTR(
                c.STREET_NO,
                '^(.*)[[:space:]][^[:space:]]+$',
                1,
                1,
                NULL,
                1
            )
        )
    ) AS STREET,
    -- Extract house number: final part of STREET_NO
    TRIM(
        REGEXP_SUBSTR(
            c.STREET_NO,
            '[^[:space:]]+$'
        )
    ) AS NUM,
    -- Keep leading zeroes in ZIP
    LPAD(TRIM(TO_CHAR(c.ZIP)), 5, '0') AS ZIP,
    INITCAP(TRIM(c.PLACE)) AS CITY,
    -- Standardize gender
    CASE
        WHEN UPPER(TRIM(c.GENDER)) IN ('M', 'MALE') THEN 'Male'
        WHEN UPPER(TRIM(c.GENDER)) IN ('F', 'W', 'FEMALE') THEN 'Female'
        ELSE 'Unknown'
    END AS GENDER,
    c.BDAY AS DOB
FROM staging_customer_br4 c;

select * from normalised_customer_br4;


--Branch 5 Normalised

CREATE TABLE Normalised_Customer_br5 AS
SELECT
    c.ID AS ID,
    INITCAP(TRIM(c.NAME)) AS FIRST_NAME,
    INITCAP(TRIM(c.SURNAME)) AS FAMILY_NAME,
    INITCAP(TRIM(c.STR)) AS STREET,
    CAST(TRIM(TO_CHAR(c.NO)) AS VARCHAR2(10)) AS NUM,
    -- Preserve leading zeroes in ZIP codes
    LPAD(TRIM(TO_CHAR(c.ZIP)), 5, '0') AS ZIP,
    INITCAP(TRIM(p.PLACE)) AS CITY,
    CASE
        WHEN UPPER(TRIM(c.GEND)) IN ('M', 'MALE') THEN 'Male'
        WHEN UPPER(TRIM(c.GEND)) IN ('F', 'W', 'FEMALE') THEN 'Female'
        ELSE 'Unknown'
    END AS GENDER,
    c.BDAY AS DOB
FROM DWT_BRANCH_5.CUSTOMER c
LEFT JOIN DWT_BRANCH_5.PLACE p
    ON LPAD(TRIM(TO_CHAR(c.ZIP)), 5, '0')
     = LPAD(TRIM(TO_CHAR(p.ZIP)), 5, '0');
     
select * from normalised_customer_br5;


-- Combining all branches
CREATE TABLE Comined_Customers AS

SELECT
    'BRANCH_2' AS BRANCH,
    ID AS SOURCE_ID,
    FIRST_NAME,
    FAMILY_NAME,
    STREET,
    NUM,
    ZIP,
    CITY,
    GENDER,
    DOB
FROM normalised_customer_br2

UNION ALL

SELECT
    'BRANCH_4' AS BRANCH,
    ID AS SOURCE_ID,
    FIRST_NAME,
    FAMILY_NAME,
    STREET,
    NUM,
    ZIP,
    CITY,
    GENDER,
    DOB
FROM normalised_customer_br4

UNION ALL

SELECT
    'BRANCH_5' AS BRANCH,
    ID AS SOURCE_ID,
    FIRST_NAME,
    FAMILY_NAME,
    STREET,
    NUM,
    ZIP,
    CITY,
    GENDER,
    DOB
FROM normalised_customer_br5;

select * from comined_customers;

ALTER TABLE comined_customers
RENAME TO combined_customers;

SELECT *
FROM combined_customers
ORDER BY FAMILY_NAME, FIRST_NAME, DOB, BRANCH;


-- Fixing Duplicates

CREATE TABLE CUSTOMER_No_Dupli AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            FAMILY_NAME,
            FIRST_NAME,
            DOB,
            ZIP,
            STREET,
            NUM
    ) AS CUSTOMER_ID,
    FIRST_NAME,
    FAMILY_NAME,
    STREET,
    NUM,
    ZIP,
    CITY,
    GENDER,
    DOB
FROM (
    SELECT
        FIRST_NAME,
        FAMILY_NAME,
        STREET,
        NUM,
        ZIP,
        CITY,
        /*
          Fixing the unknown gender isssue in branch 2, ie, prefer gender form 4,5 branch rather than unknown if same person/duplicate
        */
        COALESCE(
            MAX(
                CASE
                    WHEN GENDER IN ('Male', 'Female')
                    THEN GENDER
                END
            ),
            'Unknown'
        ) AS GENDER,
        DOB
    FROM combined_customers
    GROUP BY
        FIRST_NAME,
        FAMILY_NAME,
        STREET,
        NUM,
        ZIP,
        CITY,
        DOB
);

select * from customer_no_dupli where gender = 'Unknown';

--Final Customer dimension Table

CREATE TABLE Dimension_Customer (
    CUSTOMER_KEY NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    CUSTOMER_ID  NUMBER,-- since different branch can have diff customer ids so not reliable primary key
    FIRST_NAME   VARCHAR2(50),
    FAMILY_NAME  VARCHAR2(50),
    STREET       VARCHAR2(100),
    NUM          VARCHAR2(10),
    ZIP          VARCHAR2(10),
    CITY         VARCHAR2(50),
    GENDER       VARCHAR2(10),
    DOB          DATE,
    AGE_GROUP    VARCHAR2(20)
);

--Inserting unique customers into customer dimension

INSERT INTO Dimension_Customer (
    CUSTOMER_ID,
    FIRST_NAME,
    FAMILY_NAME,
    STREET,
    NUM,
    ZIP,
    CITY,
    GENDER,
    DOB,
    AGE_GROUP
)
SELECT
    CUSTOMER_ID,
    FIRST_NAME,
    FAMILY_NAME,
    STREET,
    NUM,
    ZIP,
    CITY,
    GENDER,
    DOB,

    CASE
        WHEN DOB IS NULL THEN 'Unknown'

        WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), DOB) / 12) < 18
            THEN 'Child'

        WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), DOB) / 12) < 30
            THEN 'Young Adult'

        WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), DOB) / 12) < 60
            THEN 'Adult'

        ELSE 'Senior'
    END AS AGE_GROUP

FROM CUSTOMER_No_Dupli;

SELECT
    SEGMENT_NAME,
    SEGMENT_TYPE,
    ROUND(BYTES / 1024 / 1024, 2) AS SIZE_MB
FROM USER_SEGMENTS
ORDER BY BYTES DESC;

COMMIT;

select * from dimension_customer;

BEGIN
    FOR t IN (
        SELECT TABLE_NAME
        FROM USER_TABLES
        WHERE TABLE_NAME <> ''
    )
    LOOP
        EXECUTE IMMEDIATE
            'DROP TABLE "' || t.TABLE_NAME ||
            '" CASCADE CONSTRAINTS PURGE';
    END LOOP;
END;
/


-- Mapping Table

CREATE TABLE CUSTOMER_MAPPING (
    BRANCH             VARCHAR2(20) NOT NULL,
    SOURCE_CUSTOMER_ID NUMBER       NOT NULL,
    CUSTOMER_ID        NUMBER       NOT NULL,

    CONSTRAINT PK_CUSTOMER_MAPPING
        PRIMARY KEY (BRANCH, CUSTOMER_ID),

    CONSTRAINT FK_MAPPING_CUSTOMER
        FOREIGN KEY (CUSTOMER_ID)
        REFERENCES DIMENSION_CUSTOMER(CUSTOMER_KEY)
);

INSERT INTO CUSTOMER_MAPPING (
    BRANCH,
    SOURCE_CUSTOMER_ID,
    CUSTOMER_ID
)
SELECT
    a.BRANCH,
    a.SOURCE_ID,
    m.CUSTOMER_ID

FROM combined_customers a

JOIN CUSTOMER_No_Dupli m
    ON  a.FIRST_NAME  = m.FIRST_NAME
    AND a.FAMILY_NAME = m.FAMILY_NAME
    AND a.STREET      = m.STREET
    AND a.NUM         = m.NUM
    AND a.ZIP         = m.ZIP
    AND a.CITY        = m.CITY
    AND a.DOB         = m.DOB;
    
COMMIT;

select * from combined_customers;

select * from customer_no_dupli;

select * from CUSTOMER_MAPPING





