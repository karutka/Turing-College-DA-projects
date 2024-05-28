/*
This query gets data used for the RFM analysis dashboard.
The results of this query were imported to Power BI for further analysis.
*/

WITH 
--Compute for F & M
fm AS (
    SELECT  
    CustomerID,
    Country,
    MAX(InvoiceDate) AS last_purchase_date,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    SUM(Quantity * UnitPrice) AS monetary 
    FROM `tc-da-1.turing_data_analytics.rfm`
    WHERE Quantity > 0 AND InvoiceDate BETWEEN '2010-12-01' AND '2011-12-02'
    GROUP BY CustomerID, Country
),

--Compute for R
rfm AS (
    SELECT *,
DATE_DIFF(TIMESTAMP('2011-12-02'), last_purchase_date, DAY) AS recency
FROM fm
WHERE CustomerID IS NOT NULL AND monetary > 0
),

--Determine quintiles for RFM
quintiles AS (
SELECT 
    rfm.*,
    m.percentiles[offset(25)] AS m25, 
    m.percentiles[offset(50)] AS m50,
    m.percentiles[offset(75)] AS m75, 
    m.percentiles[offset(100)] AS m100,
    f.percentiles[offset(25)] AS f25, 
    f.percentiles[offset(50)] AS f50,
    f.percentiles[offset(75)] AS f75, 
    f.percentiles[offset(100)] AS f100,
    r.percentiles[offset(25)] AS r25, 
    r.percentiles[offset(50)] AS r50,
    r.percentiles[offset(75)] AS r75, 
    r.percentiles[offset(100)] AS r100
FROM 
    rfm,
    (SELECT APPROX_QUANTILES(monetary, 100) percentiles FROM
    rfm) m,
    (SELECT APPROX_QUANTILES(frequency, 100) percentiles FROM
    rfm) f,
    (SELECT APPROX_QUANTILES(recency, 100) percentiles FROM
    rfm) r
),

--Assign scores for R and combined FM
rfm_scores AS (
    SELECT *, 
    CAST(ROUND((f_score + m_score) / 2, 0) AS INT64) AS fm_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score
    FROM (
        SELECT *, 
        CASE WHEN monetary <= m25 THEN 1
            WHEN monetary <= m50 AND monetary > m25 THEN 2 
            WHEN monetary <= m75 AND monetary > m50 THEN 3 
            WHEN monetary <= m100 AND monetary > m75 THEN 4
        END AS m_score,
        CASE WHEN frequency <= f25 THEN 1
            WHEN frequency <= f50 AND frequency > f25 THEN 2 
            WHEN frequency <= f75 AND frequency > f50 THEN 3 
            WHEN frequency <= f100 AND frequency > f75 THEN 4 
        END AS f_score,
        --Recency scoring is reversed
        CASE WHEN recency <= r25 THEN 4 
            WHEN recency <= r50 AND recency > r25 THEN 3 
            WHEN recency <= r75 AND recency > r50 THEN 2 
            WHEN recency <= r100 AND recency > r75 THEN 1
        END AS r_score,
        FROM quintiles
        )
),

--Define RFM segments
rfm_segments AS (
    SELECT 
        CustomerID, 
        Country,
        recency,
        frequency, 
        monetary,
        r_score,
        f_score,
        m_score,
        rfm_score,
        fm_score,
        CASE WHEN (r_score = 4 AND fm_score = 4) 
            OR (r_score = 4 AND fm_score = 3) 
        THEN 'Champions'
        WHEN (r_score = 3 AND fm_score = 4) 
        THEN 'Loyal Customers'
        WHEN (r_score = 3 AND fm_score = 2) 
        THEN 'Potential Loyalists'
        WHEN r_score = 4 AND fm_score = 1 
            OR (r_score = 4 AND fm_score = 2)
        THEN 'New Customers'
        WHEN (r_score = 3 AND fm_score = 1) 
        THEN 'Promising'
        WHEN (r_score = 3 AND fm_score = 3) 
        THEN 'Need Attention'
        WHEN r_score = 2 AND fm_score = 2 
            OR (r_score = 2 AND fm_score = 3)
        THEN 'About to Sleep'
        WHEN (r_score = 2 AND fm_score = 4) 
        THEN 'At Risk'
        WHEN (r_score = 1 AND fm_score = 3)
            OR (r_score = 1 AND fm_score = 4)        
        THEN 'Cant Lose Them'
        WHEN r_score = 1 AND fm_score = 2 
            OR (r_score = 2 AND fm_score = 1)
        THEN 'Hibernating'
        WHEN r_score = 1 AND fm_score = 1 THEN 'Lost'
        END AS rfm_segment 
    FROM rfm_scores
)

SELECT * FROM rfm_segments
