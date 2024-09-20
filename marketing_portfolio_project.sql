use PortfolioProject_MarketingAnalytics

select * from [dbo].[customer_journey]

select * from[dbo].[customer_reviews]

select * from[dbo].[customers]

select * from[dbo].[engagement_data]

select * from[dbo].[geography]

select * from[dbo].[products]

----------------------------------------------------------------------------------------------------------------------------------------------
-- SQL Query to categorize products based on their price

SELECT 
    ProductID,  
    ProductName,  
    Price,  
    CASE                   -- Categorizes the products into price categories: Low, Medium, or High
        WHEN Price < 50 THEN 'Low'  
        WHEN Price BETWEEN 50 AND 200 THEN 'Medium'  
        ELSE 'High'  
    END AS PriceCategory  

FROM 
    dbo.products;

--------------------------------------------------------------------------------------------------------------------------------------------------------

	-- SQL statement to join dim_customers with dim_geography to enrich customer data with geographic information

SELECT 
    c.CustomerID,  
    c.CustomerName,  
    c.Email,  
    c.Gender,  
    c.Age,  
    g.Country,  
    g.City  
FROM 
    dbo.customers as c  
LEFT JOIN
    dbo.geography g  
  on  c.GeographyID = g.GeographyID;  

  -------------------------------------------------------------------------------------------

  -- Query to clean whitespace issues in the ReviewText column

SELECT 
    ReviewID,  
    CustomerID,  
    ProductID,
    ReviewDate,
    Rating,
    REPLACE(ReviewText, '  ', ' ') AS ReviewText -- Cleans up the ReviewText by replacing double spaces with single spaces to ensure the text is more readable and standardized
FROM 
    dbo.customer_reviews;  

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Query to clean and normalize the engagement_data table

SELECT 
    EngagementID,  
    ContentID,  
	CampaignID,  
    ProductID,  
    UPPER(REPLACE(ContentType, 'Socialmedia', 'Social Media')) AS ContentType,  
    LEFT(ViewsClicksCombined, CHARINDEX('-', ViewsClicksCombined) - 1) AS Views, 
	RIGHT(ViewsClicksCombined, LEN(ViewsClicksCombined) - CHARINDEX('-', ViewsClicksCombined)) AS Clicks,  -- Extracts the Clicks part from the ViewsClicksCombined column by taking the substring after the '-' character
    Likes,  -- Selects the number of likes the content received
    FORMAT(CONVERT(DATE, EngagementDate), 'dd.MM.yyyy') AS EngagementDate  -- Converts and formats the date as dd.mm.yyyy
FROM 
    dbo.engagement_data  
WHERE 
    ContentType != 'Newsletter';  -- Filters out rows where ContentType is 'Newsletter' as these are not relevant for our analysis


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Common Table Expression (CTE) to identify and tag duplicate records

WITH DuplicateRecords AS (
    SELECT 
        JourneyID,  
        CustomerID,  
        ProductID,  
        VisitDate,  
        Stage,  
        Action,  
        Duration,  
        -- Use ROW_NUMBER() to assign a unique row number to each record within the partition defined below
        ROW_NUMBER() OVER (PARTITION BY CustomerID, ProductID, VisitDate, Stage, [Action] ORDER BY JourneyID  
        ) AS row_num  -- This creates a new column 'row_num' that numbers each row within its partition
    FROM 
        dbo.customer_journey  
)
SELECT * FROM DuplicateRecords
ORDER BY JourneyID

-----------------------------------------------------------------------------------------------------------------------------------------------

-- Outer query selects the final cleaned and standardized data
    
SELECT 
    JourneyID,  
    CustomerID,
    ProductID, 
    VisitDate,
    Stage, 
    Action,  
    COALESCE(Duration, avg_duration) AS Duration  
FROM 
    (
        SELECT 
            JourneyID,  
            CustomerID, 
            ProductID, 
            VisitDate, 
            UPPER(Stage) AS Stage,  
            Action,  
            Duration,  
            AVG(Duration) OVER (PARTITION BY VisitDate) AS avg_duration,  
            ROW_NUMBER() OVER (
                PARTITION BY CustomerID, ProductID, VisitDate, UPPER(Stage), Action  
                ORDER BY JourneyID  
            ) AS row_num  
        FROM 
            dbo.customer_journey  
    ) AS subquery  
WHERE 
    row_num = 1; 
