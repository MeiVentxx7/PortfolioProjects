/*

Cleaning Data in SQL Queries

*/


select top 10 * from PortfolioProject.dbo.NashvilleHousing 

---------------------------------------------------------------------------

-- Standardize Date Format of [SaleDate]


select SaleDate, CONVERT(Date, SaleDate) 
from PortfolioProject.dbo.NashvilleHousing 

-- Add new column
ALTER TABLE dbo.NashvilleHousing
ADD SaleDateConverted Date;

-- Update the new column with the converted sale dates
Update dbo.NashvilleHousing
set SaleDateConverted = Convert(Date,SaleDate)



---------------------------------------------------------------------------

-- Populate Property Address Data


select *
from PortfolioProject.dbo.NashvilleHousing 
 -- WHERE PropertyAddress is null
ORDER BY ParcelID 

-- Self Join 
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
from PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ]<> b.[UniqueID ]
WHERE a.PropertyAddress is null


-- IF a.PropertyAddress is null then b.PropertyAddress
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ]<> b.[UniqueID ]
WHERE a.PropertyAddress is null


-- Update PropertyAddress
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ]<> b.[UniqueID ]
WHERE a.PropertyAddress is null



---------------------------------------------------------------------------

-- Breaking out PropertyAddress into individual columns (Address, City)

select PropertyAddress
from PortfolioProject.dbo.NashvilleHousing 
 

-- Extract Address 
SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) as Address
from PortfolioProject.dbo.NashvilleHousing 

-- Get the result without , (comma)
SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
from PortfolioProject.dbo.NashvilleHousing 

-- Extract City
SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
from PortfolioProject.dbo.NashvilleHousing 


-- Create new columns, PropertySplitAddress and PropertySplitCity, and update and set values
ALTER TABLE NashvilleHousing 
add PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing 
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


ALTER TABLE NashvilleHousing 
add PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing  
set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))




---------------------------------------------------------------------------

-- Breaking out OwnerAddress into individual columns (Address, City, State)


select OwnerAddress from PortfolioProject.dbo.NashvilleHousing 

-- Extract Address, City, and State
select PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
from PortfolioProject.dbo.NashvilleHousing 


-- Create new columns, PropertySplitAddress and PropertySplitCity, and update and set values
ALTER TABLE NashvilleHousing 
add OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing 
set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)



ALTER TABLE NashvilleHousing 
add OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing  
set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)



ALTER TABLE NashvilleHousing 
add OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing 
set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)



---------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field


select distinct(SoldAsVacant)
from PortfolioProject.dbo.NashvilleHousing 


select SoldAsVacant,
 case when SoldAsVacant = 'Y' then 'Yes'
      when SoldAsVacant = 'N' then 'No'
	  ELSE SoldAsVacant
	  END
from PortfolioProject.dbo.NashvilleHousing 


UPDATE NashvilleHousing
set SoldAsVacant = 
 case when SoldAsVacant = 'Y' then 'Yes'
      when SoldAsVacant = 'N' then 'No'
	  ELSE SoldAsVacant
	  END


---------------------------------------------------------------------------

-- Remove Duplicates

-- Assign a number for each row in a new column
select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice, 
				 SaleDate,
				 LegalReference
				 ORDEr by UniqueID
				 ) row_num

from PortfolioProject.dbo.NashvilleHousing
order by ParcelID

-- Put the above in a CTE and Delete Duplicates
WITH RowNumCTE as (
select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice, 
				 SaleDate,
				 LegalReference
				 ORDEr by UniqueID
				 ) row_num

from PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)

DELETE FROM RowNumCTE
where row_num > 1



---------------------------------------------------------------------------

--Delete unused columns

select * from PortfolioProject.dbo.NashvilleHousing


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate, OwnerAddress, TaxDistrict, PropertyAddress

