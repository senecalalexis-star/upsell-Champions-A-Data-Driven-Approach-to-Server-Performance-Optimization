--======================
--CREATE ANALYSIS TABLE
--======================

-- Step 0: Clean up
DROP TABLE IF EXISTS final_transaction_stats;

-- PART 1: Create the permanent table
CREATE TABLE final_transaction_stats AS
WITH DailyVolumes AS (
    SELECT "date", COUNT(bill_id) AS total_bills_that_day
    FROM bill_id -- Check if this should be public.bill_id
    WHERE "date" BETWEEN '2025-06-01' AND '2025-10-31'
    GROUP BY "date"
),
-- Create daily volume filter
DailyClassification AS (
    SELECT "date",
        CASE 
            WHEN total_bills_that_day <= 39 THEN 1
            WHEN total_bills_that_day > 39 AND total_bills_that_day < 76 THEN 2
            WHEN total_bills_that_day >= 76 THEN 3
        END AS volume_category
    FROM DailyVolumes
)
SELECT 
    t.*, 
    b."date" AS bill_date, 
    b.employee_id, 
    dc.volume_category
FROM transaction_25 t
JOIN bill_id b ON t.bill_id = b.bill_id
JOIN DailyClassification dc ON b."date" = dc."date";

-- PART 2: Run the Customer Count
WITH BillPoints AS (
    SELECT 
        t.bill_id,
        t.volume_category,
        -- Check if bill_item should be bill_items (plural)
        SUM(CASE WHEN i.category_id = 2 THEN bi.quantity ELSE 0 END) AS cat2_points,
        SUM(CASE WHEN i.category_id = 1 THEN bi.quantity ELSE 0 END) AS cat1_points
    FROM final_transaction_stats t
    JOIN bill_items bi ON t.bill_id = bi.bill_id -- Added 's' to bill_items here
    JOIN item i ON bi.item_id = i.item_id
    GROUP BY t.bill_id, t.volume_category
),
FinalCustomerCount AS (
    SELECT 
        bill_id, 
        volume_category,
        CASE 
            WHEN cat2_points > 0 THEN cat2_points 
            ELSE CEIL(cat1_points * 0.5) 
        END AS estimated_customers
    FROM BillPoints
)
SELECT 
    volume_category,
    COUNT(bill_id) AS total_bills,
    SUM(estimated_customers) AS total_customer_count,
    ROUND(AVG(estimated_customers)::numeric, 2) AS avg_customers_per_bill
FROM FinalCustomerCount
GROUP BY volume_category
ORDER BY volume_category;

--======================
--ANALYSIS QUERY
--======================

--Get the number of date 
SELECT 
    COUNT(DISTINCT b.date) AS sample_days_count
FROM bill_id b
JOIN transaction_25 t ON b.bill_id = t.bill_id
WHERE b.date BETWEEN '2025-06-01' AND '2025-10-31';

--Get the number of Upsell Item By Volume Category
WITH BillCustomerCount AS (
    -- 1. First, establish the customer count per bill
    SELECT 
        t.bill_id,
        t.volume_category,
        CASE 
            WHEN SUM(CASE WHEN i.category_id = 2 THEN bi.quantity ELSE 0 END) > 0 
                THEN SUM(CASE WHEN i.category_id = 2 THEN bi.quantity ELSE 0 END)
            ELSE CEIL(SUM(CASE WHEN i.category_id = 1 THEN bi.quantity ELSE 0 END) * 0.5)
        END AS estimated_customers
    FROM final_transaction_stats t
    JOIN bill_items bi ON t.bill_id = bi.bill_id
    JOIN item i ON bi.item_id = i.item_id
    GROUP BY t.bill_id, t.volume_category
),
BillMetrics AS (
    -- 2. Aggregate quantities using the correct join: bi.item_id
    SELECT 
        bcc.bill_id,
        bcc.volume_category,
        bcc.estimated_customers,
        SUM(CASE WHEN i.name LIKE '%BTL%' THEN bi.quantity ELSE 0 END) AS count_btl,
        SUM(CASE WHEN i.category_id = 4 THEN bi.quantity ELSE 0 END) AS count_extras,
        SUM(CASE WHEN i.category_id = 5 THEN bi.quantity ELSE 0 END) AS count_dessert,
        SUM(CASE WHEN i.category_id = 8 THEN bi.quantity ELSE 0 END) AS count_hot_drinks,
        SUM(CASE WHEN i.category_id IN (6,7,11,12,13,14,15,19,20,22) THEN bi.quantity ELSE 0 END) AS total_drink_qty
    FROM BillCustomerCount bcc
    JOIN bill_items bi ON bcc.bill_id = bi.bill_id -- This was the fixed line
    JOIN item i ON bi.item_id = i.item_id
    GROUP BY bcc.bill_id, bcc.volume_category, bcc.estimated_customers
)
-- 3. Final aggregation
SELECT 
    volume_category,
    SUM(count_btl) AS total_btl,
    SUM(count_extras) AS total_extras,
    SUM(count_dessert) AS total_dessert,
    SUM(count_hot_drinks) AS total_hot_drinks,
    COUNT(CASE WHEN total_drink_qty >= (estimated_customers * 2) THEN 1 END) AS second_drinks,
    COUNT(CASE WHEN total_drink_qty >= (estimated_customers * 3) THEN 1 END) AS third_drinks,
    COUNT(bill_id) AS total_bills_analyzed
FROM BillMetrics
GROUP BY volume_category
ORDER BY volume_category;

--Get the count of upsell item by employee over the Category Volume
WITH BillCustomerCount AS (
    -- 1. Establish the customer count per bill AND keep employee_id
    SELECT 
        t.bill_id,
        t.employee_id,
        t.volume_category,
        CASE 
            WHEN SUM(CASE WHEN i.category_id = 2 THEN bi.quantity ELSE 0 END) > 0 
                THEN SUM(CASE WHEN i.category_id = 2 THEN bi.quantity ELSE 0 END)
            ELSE CEIL(SUM(CASE WHEN i.category_id = 1 THEN bi.quantity ELSE 0 END) * 0.5)
        END AS estimated_customers
    FROM final_transaction_stats t
    JOIN bill_items bi ON t.bill_id = bi.bill_id
    JOIN item i ON bi.item_id = i.item_id
    GROUP BY t.bill_id, t.employee_id, t.volume_category
),
BillMetrics AS (
    -- 2. Aggregate quantities for each bill
    SELECT 
        bcc.bill_id,
        bcc.employee_id,
        bcc.volume_category,
        bcc.estimated_customers,
        SUM(CASE WHEN i.name LIKE '%BTL%' THEN bi.quantity ELSE 0 END) AS count_btl,
        SUM(CASE WHEN i.category_id = 4 THEN bi.quantity ELSE 0 END) AS count_extras,
        SUM(CASE WHEN i.category_id = 5 THEN bi.quantity ELSE 0 END) AS count_dessert,
        SUM(CASE WHEN i.category_id = 8 THEN bi.quantity ELSE 0 END) AS count_hot_drinks,
        SUM(CASE WHEN i.category_id IN (6,7,11,12,13,14,15,19,20,22) THEN bi.quantity ELSE 0 END) AS total_drink_qty
    FROM BillCustomerCount bcc
    JOIN bill_items bi ON bcc.bill_id = bi.bill_id
    JOIN item i ON bi.item_id = i.item_id
    GROUP BY bcc.bill_id, bcc.employee_id, bcc.volume_category, bcc.estimated_customers
)
-- 3. Final aggregation with Total Customer Count
SELECT 
    employee_id,
    volume_category,
    COUNT(bill_id) AS total_bills_analyzed,
    SUM(estimated_customers) AS total_customer_count, -- This is your new metric
    SUM(count_btl) AS total_btl,
    SUM(count_extras) AS total_extras,
    SUM(count_dessert) AS total_dessert,
    SUM(count_hot_drinks) AS total_hot_drinks,
    COUNT(CASE WHEN total_drink_qty >= (estimated_customers * 2) THEN 1 END) AS second_drinks,
    COUNT(CASE WHEN total_drink_qty >= (estimated_customers * 3) THEN 1 END) AS third_drinks
FROM BillMetrics
GROUP BY employee_id, volume_category
ORDER BY employee_id ASC, volume_category ASC;