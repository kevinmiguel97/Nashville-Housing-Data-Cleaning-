/*
CLeaning data with queries
*/

-- Visualizing full data set
SELECT *
FROM [SQL Tutorial]..Housing

----------------------------------------------------------------------------------------------------------------------------

-- Standarize date format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM [SQL Tutorial]..Housing

UPDATE Housing
SET SaleDate = CONVERT(Date, SaleDate)

----------------------------------------------------------------------------------------------------------------------------

-- Popularte property adress data

/*
We have some datapoints withoyt Property Address. However, when 2 ParcelIDs are the same, so are the Addresses. 
We are going to join our table to itself to populate some of the addresses missing. 
ISNULL() function substitutes null values with a specified value
*/

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM [SQL Tutorial]..Housing AS A
JOIN [SQL Tutorial]..Housing  AS B
    ON A.ParcelID = B.ParcelID
    AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress IS NULL 

-- Now we use  the previous query to update our table
-- When we use joins in an update we have to use the alias to update
UPDATE a
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM [SQL Tutorial]..Housing AS A
JOIN [SQL Tutorial]..Housing  AS B
    ON A.ParcelID = B.ParcelID
    AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress IS NULL 

-- Now all NULL values have been replaced
SELECT PropertyAddress
FROM [SQL Tutorial]..Housing
WHERE PropertyAddress IS NULL

----------------------------------------------------------------------------------------------------------------------------

-- Breaking out property address into components (Address, City, State)
-- Adress and state are separated by ',' 
-- CHAIRINDEX() returns the position of a specifc character in a string

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) Address, 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress)) AS State
FROM [SQL Tutorial]..Housing

-- Adding columns
ALTER TABLE Housing
ADD Street NVARCHAR(255), 
    State NVARCHAR(255)

-- Updating table
UPDATE Housing
SET Street = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1), 
State = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress))

-- Now we have columns Street and State
SELECT *
FROM Housing

--------------------------------------------------------------------------------------------------------------------------------

--Breaking out owner address into components (Street, City, State)
-- PARSENAME() function splits components of a string using '.' as a separator
-- We replace commas with dots to use the PARSENAME function
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerStreet,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM [SQL Tutorial]..Housing

-- Adding new columns
ALTER TABLE Housing
Add OwnerStreet NVARCHAR(255),
    OwnerCity NVARCHAR(255),
    OwnerState NVARCHAR(255)

-- Popukating new columns
UPDATE Housing
SET OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Now we have 3 more columns in the table
SELECT * 
FROM Housing

-------------------------------------------------------------------------------------------------------------------------------------

-- Clean SoldAsVacant column
-- There are 52 rows with value Y and 399 with value N. 
-- We have to replace those for Yes and No
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Housing
GROUP BY SoldAsVacant
ORDER BY 2

-- We will use a CASE statement to do so
SELECT SoldAsVacant, 
CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END 
AS Corrected
FROM Housing

-- Updating Table
UPDATE Housing
SET SoldAsVacant = CASE 
                        WHEN SoldAsVacant = 'Y' THEN 'Yes'
                        WHEN SoldAsVacant = 'N' THEN 'No'
                        ELSE SoldAsVacant
                    END  

-------------------------------------------------------------------------------------------------------------------------------------

-- Removing duplicate observations
/* We will consider observations with the same ParcelID, PropertyAddress, SalePrice,
 SaleDate,and LegalReference as a single House. 
 
 To account for this we will use a Window Function called ROW_NUMBER() which assigns a unique
 sequential integer to rows within a partition of a result ordered by certain variable. 
 In this case, if 3 rows share all variables mentioned they will receive values 1, 2, 3 
 based on the UniqueID
 */

SELECT *, 
ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                    ORDER BY UniqueID) AS DuplicatedRow
FROM Housing

-- We create a CTE to query those whose ROW_Number is higher than 1 and delete them 

WITH CTE_CountingDuplocates AS(
    SELECT *, 
    ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                        ORDER BY UniqueID) AS DuplicatedRow
    FROM Housing
    )
DELETE 
FROM CTE_CountingDuplocates
WHERE DuplicatedRow > 1

-- Now CTE_CountingDuplicates contains no duplicate rows

-------------------------------------------------------------------------------------------------------------------------------------

-- Drop unused columns
-- We will delete the Address columns from which we extracted the information

ALTER TABLE Housing
DROP COLUMN PropertyAddress, OwnerAddress

-- Now Table Housing doesn´t contain these columns
SELECT *
FROM Housing
