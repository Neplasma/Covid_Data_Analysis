-- Data cleaning portfolio project for Nashville Housing data
/* Data cleaning in SQL queries */

SELECT *
FROM PortfolioProject..NashvilleHousing

-- Standardise Date Format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDate, SaleDateConverted
FROM PortfolioProject..NashvilleHousing
--------------------------------------------------------------------------------
-- Populate Property Address Data, remove NULL
SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL

-- ParcelID is linked to a PropertyAddress, use ISNULL to fill the address with the same ParcelID
SELECT A.ParcelID AS ParcelID_A, A.PropertyAddress AS ADDRESS_A, B.ParcelID AS ParcelID_B, B.PropertyAddress AS ADDRESS_B, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM PortfolioProject..NashvilleHousing A
JOIN PortfolioProject..NashvilleHousing B
	ON	A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM PortfolioProject..NashvilleHousing A
JOIN PortfolioProject..NashvilleHousing B
	ON	A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL
--------------------------------------------------------------------------------
-- Break out Address into individual columns (Address, City, State)
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address_1, -- select the first part of the address, seperated by delimiter ',', and -1 means to remove the last char which is the comma
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address_2 -- +1 means to remove the first Char
FROM PortfolioProject..NashvilleHousing

/* SUBSTRING(string, start, length) */
/* CHARINDEX(substring, string, start) and return the position of the substring */

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject..NashvilleHousing

-- another way (better way) to do this, example using ownerAddress
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1), -- the last piece of OwnerAddress, which is the state
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2), -- the last but 1 piece of OwnerAddress, which is the city
PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)  -- the last but 2 piece of OwnerAddress, which is the street
FROM PortfolioProject..NashvilleHousing
/* REPLACE(string, old_string, new_string) */
/* PARSENAME('object_name', object_piece) split string with '.' */

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)

SELECT *
FROM PortfolioProject..NashvilleHousing

--------------------------------------------------------------------------------
-- Change Y and N to Yes and No in 'Sold as Vacant' field
-- in 'Sold as Vacant' field, some filled with Yes and No, some with Y and N
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) -- when use COUNT, always use GROUP BY
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

/*
Y	52
N	399
Yes	4623
No	51403
*/

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END 
	 AS Updated
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant

/*
N	No
Yes	Yes
Y	Yes
No	No
*/

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END 

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

/*	
Yes	4675
No	51802
*/

-----------------------------------------------------------------------
-- Remove Duplicates

-- use CTE to find all the duplicates
/* ROW_NUMBER() Numbers the output of a result set. More specifically, returns the sequential number of a row within a partition of a result set, starting at 1 for the first row in each partition.
/* Use SQL PARTITION BY to divide the result set into partitions and perform computation on each subset of partitioned data.
The PARTITION BY clause is a subclause of the OVER clause. */
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY ParcelID,  -- find rows with same values in the following fields
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 ORDER BY
					 	UniqueID
	) row_num
FROM PortfolioProject..NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1 -- row_num > 1 means the row appeared more than once
ORDER BY ParcelID

-- delete the duplicated rows
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 ORDER BY
					 	UniqueID
	) row_num
FROM PortfolioProject..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1 
/* CTE table shall return 0 result now
! Don't use this query on raw data ! */

--------------------------------------------------------------------
-- Delete Unused Columns ! Don't use this query on raw data !
SELECT *
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
