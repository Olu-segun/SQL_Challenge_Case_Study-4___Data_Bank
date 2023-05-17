-- A. Customer Nodes Exploration

-- 1) How many unique nodes are there on the Data Bank system?

SELECT COUNT (DISTINCT node_id) AS Unique_Number_of_Node
FROM dbo.customer_nodes;

-- 2) What is the number of nodes per region?
SELECT regions.Region_ID, Region_Name, COUNT (node_id) AS Numper_of_Nodes
FROM dbo.customer_nodes
INNER JOIN regions
ON  customer_nodes.region_id = regions.region_id
GROUP BY regions.Region_ID, Region_Name
ORDER BY Numper_of_Nodes DESC;

-- 3) How many customers are allocated to each region?
SELECT customer_nodes.Region_ID, Region_Name, COUNT (DISTINCT customer_id) AS Numper_of_Customers
FROM dbo.customer_nodes
INNER JOIN regions
ON  customer_nodes.region_id = regions.region_id
GROUP BY customer_nodes.Region_ID,  Region_Name
ORDER BY Numper_of_Customers  DESC;

-- 4) How many days on average are customers reallocated to a different node?
SELECT AVG (DATEDIFF(DAY, start_date, End_date)) AS Avg_Number_of_Day
FROM customer_nodes
WHERE end_date != '9999-12-31';


-- B. Customer Transactions

-- 1) What is the unique count and total amount for each transaction type?
SELECT txn_type AS Transaction_Type, COUNT(*), SUM(txn_amount) AS Total_Amount
FROM customer_transactions
GROUP BY txn_type  
ORDER BY txn_type ASC;

-- 2) What is the average total historical deposit counts and amounts for all customers?

WITH Deposit_history AS 
(
	SELECT customer_id, 
			COUNT( CASE WHEN txn_type = 'deposit' THEN 1 END) AS Deposit_Count,
			SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount END) AS Deposit_Amount
	FROM customer_transactions
	GROUP BY customer_id
)
SELECT	AVG(Deposit_Count) AS Avg_Deposit_Count, 
		AVG(Deposit_Amount) AS Avg_Deposit_Amount
FROM Deposit_history;

-- 3) For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

WITH Transactions AS
(
	SELECT customer_id,
           DATEPART(Month, txn_date) AS Month_ID,
		   DATEName(Month, txn_date) AS Month_Name,
		   COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS Deposit_count,
	       COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS Purchase_count,
	       COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS Withdrawal_count
	FROM customer_transactions
	GROUP BY customer_id,DATEPART(Month, txn_date),DATEName(Month, txn_date)
)
SELECT  Month_ID, Month_Name, COUNT( DISTINCT customer_id) AS Cutomer_Count		
FROM Transactions
WHERE Deposit_count > 1
	  AND (Purchase_count > 0 OR Withdrawal_count > 0)
GROUP BY Month_ID, Month_Name
ORDER BY Cutomer_Count DESC;
	


-- 4) What is the closing balance for each customer at the end of the month?

SELECT customer_id, DATEName(Month, txn_date) AS Month_Name
FROM customer_transactions;



-- C. Data Allocation Challenge

-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time
-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

-- 1) running customer balance column that includes the impact each transaction.

SELECT customer_id, txn_date, txn_type, txn_amount,
		SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
				 WHEN txn_type = 'withdrawal' THEN -txn_amount
				 WHEN txn_type = 'purchase' THEN -txn_amount
			 ELSE 0
			 END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS Runing_balance
FROM customer_transactions;

-- 2) Calculate customer balance at the end of each month

SELECT  customer_id, 
		DATEPART(MONTH, txn_date) AS Month_ID,
		DATENAME(MONTH, txn_date) AS Month_Name,
		SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
				 WHEN txn_type = 'withdrawal' THEN -txn_amount
				 WHEN txn_type = 'purchase' THEN -txn_amount
			ELSE 0 
			END) AS Closing_Balance 
FROM customer_transactions
GROUP BY customer_id, DATEPART(MONTH, txn_date), DATENAME(MONTH, txn_date)
ORDER BY Closing_Balance DESC;


-- 3) minimum, average and maximum values of the running balance for each customer

WITH running_balance AS
(
	SELECT  customer_id, txn_date, txn_type, txn_amount,
			SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
				 WHEN txn_type = 'withdrawal' THEN -txn_amount
				 WHEN txn_type = 'purchase' THEN -txn_amount
			 ELSE 0
			 END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS Running_balance
	FROM customer_transactions
)

SELECT  customer_id,
		MIN(Running_balance) AS Minimum_Running_Balance,
		MAX(Running_balance) AS Maximum_Running_Balance,
		AVG(Running_balance) AS Average_Running_Balance
FROM running_balance
GROUP BY customer_id;











  
  


  

  

 

 


  

  