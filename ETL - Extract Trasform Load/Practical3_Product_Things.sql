SELECT * FROM DWT_BRANCH_2.PRODUCT;
SELECT * FROM DWT_BRANCH_4.PRODUCT;
SELECT * FROM DWT_BRANCH_5.PRODUCT;

DESC DWT_BRANCH_2.PRODUCT;
DESC DWT_BRANCH_4.PRODUCT;
DESC DWT_BRANCH_5.PRODUCT;

CREATE TABLE staging_Products_br2 AS
SELECT *
FROM DWT_BRANCH_2.PRODUCT;

CREATE TABLE staging_Products_br4 AS
SELECT *
FROM DWT_BRANCH_4.PRODUCT;

CREATE TABLE staging_sort_br4 AS
SELECT *
FROM DWT_BRANCH_4.SORT;

CREATE TABLE staging_Products_br5 AS
SELECT *
FROM DWT_BRANCH_5.PRODUCT;

--Normalising/creating a common tble for branch2
CREATE TABLE NORMALISED_PRODUCT_BR2 AS
SELECT
    p.NUM AS ID,
    INITCAP(TRIM(p.LABEL)) AS PRODUCT_NAME,
    CASE
        WHEN LOWER(TRIM(p.TYPE)) = 'alcoholic'
            THEN 'Alcoholic'
        WHEN LOWER(TRIM(p.TYPE)) = 'non-alcoholic'
            THEN 'Non-Alcoholic'
        ELSE 'Unknown'
    END AS CATEGORY,
    p.LITER AS LITER,

    TO_NUMBER(
        REPLACE(TRIM(p.PRICE), ',', '.'),
        '999999999D9999',
        'NLS_NUMERIC_CHARACTERS=''.,'''
    ) AS PRICE

FROM STAGING_PRODUCTS_BR2 p

WHERE REGEXP_LIKE(
    TRIM(p.PRICE),
    '^[+-]?[0-9]+([.,][0-9]+)?$'
);


--Normalising branch 5

CREATE TABLE normalised_product_br5 AS
SELECT
    p.ID AS ID,
    INITCAP(TRIM(p.NAME)) AS PRODUCT_NAME,
    CASE
        WHEN LOWER(TRIM(p.sort)) = 'alcoholic' THEN 'Alcoholic'
        WHEN LOWER(TRIM(p.sort)) = 'non-alcoholic' THEN 'Non-Alcoholic'
        ELSE 'Unknown'
    END AS CATEGORY,
    p.sz AS LITER,
    p.price AS PRICE
FROM staging_products_br5 p;

--Normalising branch 4

CREATE TABLE normalised_product_br4 AS
SELECT
    p.PRODUCTNUMBER AS ID,
    INITCAP(TRIM(p.NAME)) AS PRODUCT_NAME,
    CASE
        WHEN p.sid = 1 THEN 'Non-Alcoholic'
        WHEN p.sid = 2 THEN 'Alcoholic'
        ELSE 'Unknown'
    END AS CATEGORY,
    CAST(
        REPLACE(TRIM(p."SIZE"), ',', '.')
        AS NUMBER(10,4)
    ) AS LITER,
    p.price AS PRICE
FROM staging_products_br4 p;

select * from normalised_product_br4;
select * from normalised_product_br2;
select * from normalised_product_br5;

--Combining all the normalised tables
CREATE TABLE COMBINED_PRODUCTS AS

SELECT
    'BRANCH_2' AS BRANCH,
    ID AS SOURCE_PRODUCT_ID,
    PRODUCT_NAME,
    CATEGORY,
    LITER,
    PRICE
FROM normalised_product_br2

UNION ALL

SELECT
    'BRANCH_4' AS BRANCH,
    ID AS SOURCE_PRODUCT_ID,
    PRODUCT_NAME,
    CATEGORY,
    LITER,
    PRICE
FROM normalised_product_br4

UNION ALL

SELECT
    'BRANCH_5' AS BRANCH,
    ID AS SOURCE_PRODUCT_ID,
    PRODUCT_NAME,
    CATEGORY,
    LITER,
    PRICE
FROM normalised_product_br5;


SELECT DISTINCT product_name 
FROM COMBINED_PRODUCTS;


CREATE TABLE PRODUCT_A AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY PRODUCT_NAME, CATEGORY, LITER
    ) AS PRODUCT_ID,
    PRODUCT_NAME,
    CATEGORY,
    LITER,
    PRICE
FROM COMBINED_PRODUCTS;

ALTER TABLE PRODUCT_A
ADD PRIMARY KEY (PRODUCT_ID);

select * from product_a;



CREATE TABLE PRODUCT_MAPPING (
    BRANCH             VARCHAR2(20) NOT NULL,
    SOURCE_PRODUCT_ID  NUMBER       NOT NULL,
    PRODUCT_ID         NUMBER       NOT NULL,

    CONSTRAINT PK_PRODUCT_MAPPING
        PRIMARY KEY (BRANCH, SOURCE_PRODUCT_ID),

    CONSTRAINT FK_PRODUCT_MAPPING
        FOREIGN KEY (PRODUCT_ID)
        REFERENCES PRODUCT_A(PRODUCT_ID)
);

INSERT INTO PRODUCT_MAPPING (
    BRANCH,
    SOURCE_PRODUCT_ID,
    PRODUCT_ID
)
SELECT 
    c.BRANCH,
    c.SOURCE_PRODUCT_ID,
    MIN(p.PRODUCT_ID) AS PRODUCT_ID -- Safely picks just one ID to prevent duplicates
FROM COMBINED_PRODUCTS c
JOIN PRODUCT_a p
    ON  c.PRODUCT_NAME = p.PRODUCT_NAME
    AND c.CATEGORY     = p.CATEGORY
    AND c.LITER        = p.LITER
GROUP BY 
    c.BRANCH,
    c.SOURCE_PRODUCT_ID;


