-- Retail Sales & Profitability Analytics
-- Author: Gauri Kotwal
-- Database: Oracle 10g
-- Purpose: Core validation and business-analysis queries for AdventureWorks Internet Sales

SET SQLBLANKLINES ON
SET PAGESIZE 100
SET LINESIZE 200
SET WRAP OFF

/* =========================================================
   1. CORE DATA VALIDATION
   ========================================================= */

SELECT COUNT(*) AS FACT_ROWS
FROM AW_INTERNET_SALES;

SELECT COUNT(*) AS NULL_SALES_AMOUNT
FROM AW_INTERNET_SALES
WHERE SALESAMOUNT IS NULL;

SELECT COUNT(*) AS FACT_ROWS,
       COUNT(d.DATEKEY) AS MATCHED_DATE_ROWS
FROM AW_INTERNET_SALES f
LEFT JOIN AW_DATE d
    ON f.ORDERDATEKEY = d.DATEKEY;

SELECT COUNT(*) AS FACT_ROWS,
       COUNT(c.PRODUCTCATEGORYKEY) AS MATCHED_CATEGORY_ROWS
FROM AW_INTERNET_SALES f
LEFT JOIN AW_PRODUCT p
    ON f.PRODUCTKEY = p.PRODUCTKEY
LEFT JOIN AW_PRODUCT_SUBCATEGORY s
    ON p.PRODUCTSUBCATEGORYKEY = s.PRODUCTSUBCATEGORYKEY
LEFT JOIN AW_PRODUCT_CATEGORY c
    ON s.PRODUCTCATEGORYKEY = c.PRODUCTCATEGORYKEY;

/* =========================================================
   2. OVERALL BUSINESS KPIs
   ========================================================= */

SELECT ROUND(SUM(SALESAMOUNT), 2) AS TOTAL_SALES,
       ROUND(SUM(SALESAMOUNT - TOTALPRODUCTCOST), 2) AS TOTAL_GROSS_PROFIT,
       COUNT(DISTINCT SALESORDERNUMBER) AS TOTAL_ORDERS,
       SUM(ORDERQUANTITY) AS TOTAL_UNITS
FROM AW_INTERNET_SALES;

SELECT ROUND(
           SUM(SALESAMOUNT - TOTALPRODUCTCOST)
           / SUM(SALESAMOUNT) * 100,
           2
       ) AS GROSS_PROFIT_MARGIN_PCT,
       ROUND(
           SUM(SALESAMOUNT)
           / COUNT(DISTINCT SALESORDERNUMBER),
           2
       ) AS AVERAGE_ORDER_VALUE
FROM AW_INTERNET_SALES;

/* =========================================================
   3. MONTHLY SALES & GROSS PROFIT TREND
   ========================================================= */

SELECT TO_CHAR(d.FULLDATE, 'YYYY-MM') AS YEAR_MONTH,
       ROUND(SUM(f.SALESAMOUNT), 2) AS TOTAL_SALES,
       ROUND(SUM(f.SALESAMOUNT - f.TOTALPRODUCTCOST), 2) AS GROSS_PROFIT,
       COUNT(DISTINCT f.SALESORDERNUMBER) AS TOTAL_ORDERS,
       SUM(f.ORDERQUANTITY) AS TOTAL_UNITS
FROM AW_INTERNET_SALES f
JOIN AW_DATE d
    ON f.ORDERDATEKEY = d.DATEKEY
GROUP BY TO_CHAR(d.FULLDATE, 'YYYY-MM')
ORDER BY YEAR_MONTH;

/* =========================================================
   4. CATEGORY PERFORMANCE
   ========================================================= */

SELECT c.ENGLISHPRODUCTCATEGORYNAME AS CATEGORY,
       ROUND(SUM(f.SALESAMOUNT), 2) AS TOTAL_SALES,
       ROUND(SUM(f.SALESAMOUNT - f.TOTALPRODUCTCOST), 2) AS GROSS_PROFIT,
       ROUND(
           SUM(f.SALESAMOUNT - f.TOTALPRODUCTCOST)
           / SUM(f.SALESAMOUNT) * 100,
           2
       ) AS MARGIN_PCT,
       SUM(f.ORDERQUANTITY) AS UNITS_SOLD
FROM AW_INTERNET_SALES f
JOIN AW_PRODUCT p
    ON f.PRODUCTKEY = p.PRODUCTKEY
JOIN AW_PRODUCT_SUBCATEGORY s
    ON p.PRODUCTSUBCATEGORYKEY = s.PRODUCTSUBCATEGORYKEY
JOIN AW_PRODUCT_CATEGORY c
    ON s.PRODUCTCATEGORYKEY = c.PRODUCTCATEGORYKEY
GROUP BY c.ENGLISHPRODUCTCATEGORYNAME
ORDER BY TOTAL_SALES DESC;

/* =========================================================
   5. SUBCATEGORY PERFORMANCE
   ========================================================= */

SELECT s.ENGLISHPRODUCTSUBCATEGORYNAME AS SUBCATEGORY,
       ROUND(SUM(f.SALESAMOUNT), 2) AS TOTAL_SALES,
       ROUND(SUM(f.SALESAMOUNT - f.TOTALPRODUCTCOST), 2) AS GROSS_PROFIT,
       ROUND(
           SUM(f.SALESAMOUNT - f.TOTALPRODUCTCOST)
           / SUM(f.SALESAMOUNT) * 100,
           2
       ) AS MARGIN_PCT,
       SUM(f.ORDERQUANTITY) AS UNITS_SOLD
FROM AW_INTERNET_SALES f
JOIN AW_PRODUCT p
    ON f.PRODUCTKEY = p.PRODUCTKEY
JOIN AW_PRODUCT_SUBCATEGORY s
    ON p.PRODUCTSUBCATEGORYKEY = s.PRODUCTSUBCATEGORYKEY
GROUP BY s.ENGLISHPRODUCTSUBCATEGORYNAME
ORDER BY TOTAL_SALES DESC;

/* =========================================================
   6. TOP 10 PRODUCTS BY SALES
   ========================================================= */

SELECT *
FROM (
    SELECT p.PRODUCTKEY,
           p.ENGLISHPRODUCTNAME AS PRODUCT_NAME,
           ROUND(SUM(f.SALESAMOUNT), 2) AS TOTAL_SALES,
           ROUND(SUM(f.SALESAMOUNT - f.TOTALPRODUCTCOST), 2) AS GROSS_PROFIT,
           ROUND(
               SUM(f.SALESAMOUNT - f.TOTALPRODUCTCOST)
               / SUM(f.SALESAMOUNT) * 100,
               2
           ) AS MARGIN_PCT,
           SUM(f.ORDERQUANTITY) AS UNITS_SOLD
    FROM AW_INTERNET_SALES f
    JOIN AW_PRODUCT p
        ON f.PRODUCTKEY = p.PRODUCTKEY
    GROUP BY p.PRODUCTKEY,
             p.ENGLISHPRODUCTNAME
    ORDER BY TOTAL_SALES DESC
)
WHERE ROWNUM <= 10;

/* =========================================================
   7. TERRITORY PERFORMANCE
   ========================================================= */

SELECT t.SALESTERRITORYREGION AS TERRITORY,
       t.SALESTERRITORYCOUNTRY AS COUNTRY,
       ROUND(SUM(f.SALESAMOUNT), 2) AS TOTAL_SALES,
       ROUND(SUM(f.SALESAMOUNT - f.TOTALPRODUCTCOST), 2) AS GROSS_PROFIT,
       ROUND(
           SUM(f.SALESAMOUNT - f.TOTALPRODUCTCOST)
           / SUM(f.SALESAMOUNT) * 100,
           2
       ) AS MARGIN_PCT,
       SUM(f.ORDERQUANTITY) AS UNITS_SOLD
FROM AW_INTERNET_SALES f
JOIN AW_SALES_TERRITORY t
    ON f.SALESTERRITORYKEY = t.SALESTERRITORYKEY
GROUP BY t.SALESTERRITORYREGION,
         t.SALESTERRITORYCOUNTRY
ORDER BY TOTAL_SALES DESC;

/* =========================================================
   8. TOP 10 CUSTOMERS BY SALES
   ========================================================= */

SELECT *
FROM (
    SELECT c.CUSTOMERKEY,
           TRIM(
               c.FIRSTNAME || ' ' ||
               NVL(c.MIDDLENAME || ' ', '') ||
               c.LASTNAME
           ) AS CUSTOMER_NAME,
           ROUND(SUM(f.SALESAMOUNT), 2) AS TOTAL_SALES,
           COUNT(DISTINCT f.SALESORDERNUMBER) AS TOTAL_ORDERS,
           ROUND(
               SUM(f.SALESAMOUNT)
               / COUNT(DISTINCT f.SALESORDERNUMBER),
               2
           ) AS AVERAGE_ORDER_VALUE
    FROM AW_INTERNET_SALES f
    JOIN AW_CUSTOMER c
        ON f.CUSTOMERKEY = c.CUSTOMERKEY
    GROUP BY c.CUSTOMERKEY,
             c.FIRSTNAME,
             c.MIDDLENAME,
             c.LASTNAME
    ORDER BY TOTAL_SALES DESC
)
WHERE ROWNUM <= 10;

/* =========================================================
   9. CUSTOMERS WITH HIGHEST ORDER FREQUENCY
   ========================================================= */

SELECT *
FROM (
    SELECT c.CUSTOMERKEY,
           TRIM(
               c.FIRSTNAME || ' ' ||
               NVL(c.MIDDLENAME || ' ', '') ||
               c.LASTNAME
           ) AS CUSTOMER_NAME,
           COUNT(DISTINCT f.SALESORDERNUMBER) AS TOTAL_ORDERS,
           ROUND(SUM(f.SALESAMOUNT), 2) AS TOTAL_SALES
    FROM AW_INTERNET_SALES f
    JOIN AW_CUSTOMER c
        ON f.CUSTOMERKEY = c.CUSTOMERKEY
    GROUP BY c.CUSTOMERKEY,
             c.FIRSTNAME,
             c.MIDDLENAME,
             c.LASTNAME
    ORDER BY TOTAL_ORDERS DESC,
             TOTAL_SALES DESC
)
WHERE ROWNUM <= 10;

/* =========================================================
   10. CUSTOMERS WITH HIGHEST AVERAGE ORDER VALUE
   ========================================================= */

SELECT *
FROM (
    SELECT c.CUSTOMERKEY,
           TRIM(
               c.FIRSTNAME || ' ' ||
               NVL(c.MIDDLENAME || ' ', '') ||
               c.LASTNAME
           ) AS CUSTOMER_NAME,
           ROUND(
               SUM(f.SALESAMOUNT)
               / COUNT(DISTINCT f.SALESORDERNUMBER),
               2
           ) AS AVERAGE_ORDER_VALUE,
           COUNT(DISTINCT f.SALESORDERNUMBER) AS TOTAL_ORDERS,
           ROUND(SUM(f.SALESAMOUNT), 2) AS TOTAL_SALES
    FROM AW_INTERNET_SALES f
    JOIN AW_CUSTOMER c
        ON f.CUSTOMERKEY = c.CUSTOMERKEY
    GROUP BY c.CUSTOMERKEY,
             c.FIRSTNAME,
             c.MIDDLENAME,
             c.LASTNAME
    ORDER BY AVERAGE_ORDER_VALUE DESC,
             TOTAL_SALES DESC
)
WHERE ROWNUM <= 10;

/* =========================================================
   11. ACTIVE CUSTOMERS
   ========================================================= */

SELECT COUNT(DISTINCT CUSTOMERKEY) AS ACTIVE_CUSTOMERS
FROM AW_INTERNET_SALES;

/* =========================================================
   12. TOP 10 CUSTOMER SALES SHARE
   ========================================================= */

SELECT ROUND(
           SUM(t.CUSTOMER_SALES) / MAX(g.TOTAL_SALES) * 100,
           2
       ) AS TOP10_CUSTOMER_SALES_SHARE_PCT
FROM (
    SELECT CUSTOMER_SALES
    FROM (
        SELECT CUSTOMERKEY,
               SUM(SALESAMOUNT) AS CUSTOMER_SALES
        FROM AW_INTERNET_SALES
        GROUP BY CUSTOMERKEY
        ORDER BY CUSTOMER_SALES DESC
    )
    WHERE ROWNUM <= 10
) t
CROSS JOIN (
    SELECT SUM(SALESAMOUNT) AS TOTAL_SALES
    FROM AW_INTERNET_SALES
) g;

/* =========================================================
   13. MONTH-OVER-MONTH SALES GROWTH
   ========================================================= */

WITH MONTHLY_SALES AS (
    SELECT TO_CHAR(d.FULLDATE, 'YYYY-MM') AS YEAR_MONTH,
           SUM(f.SALESAMOUNT) AS TOTAL_SALES
    FROM AW_INTERNET_SALES f
    JOIN AW_DATE d
        ON f.ORDERDATEKEY = d.DATEKEY
    GROUP BY TO_CHAR(d.FULLDATE, 'YYYY-MM')
),
MONTHLY_COMPARISON AS (
    SELECT YEAR_MONTH,
           TOTAL_SALES,
           LAG(TOTAL_SALES) OVER (ORDER BY YEAR_MONTH) AS PREVIOUS_MONTH_SALES
    FROM MONTHLY_SALES
)
SELECT YEAR_MONTH,
       ROUND(TOTAL_SALES, 2) AS TOTAL_SALES,
       ROUND(PREVIOUS_MONTH_SALES, 2) AS PREV_MONTH_SALES,
       ROUND(
           (TOTAL_SALES - PREVIOUS_MONTH_SALES)
           / PREVIOUS_MONTH_SALES * 100,
           2
       ) AS MOM_GROWTH_PCT
FROM MONTHLY_COMPARISON
ORDER BY YEAR_MONTH;

-- End of analysis_queries.sql
