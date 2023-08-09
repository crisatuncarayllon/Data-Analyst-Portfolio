/*

Cleaning Data in SQL Queries

*/

Select * 
from NashvilleHousing
-------------------------------------------------------------------------------------------------------
--STANDARIZE DATE FORMAT

--1°: Observamos exactamente lo que queremos modificar y que es lo que queremos obtener
Select SaleDate, CONVERT(Date,SaleDate) 
from NashvilleHousing

--2°: Actualizamos los datos de la tabla y modificamos el campo SaleDate, pero no siempre funciona
--como en mi caso
Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate);

--3°: Otra manera es modificando la tabla, donde agregamos un campo  
ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;
--y luegonasignamos la conversión del otro campo,
Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate);
--por ultimo borramos la columna que no fue modificada
TABLE NashvilleHousing
DROP COLUMN SaleDate;
--Y renombramos la columna que quedaba 

--Querie para mostrar las columna agregada con los datos correctos.
Select SaleDateConverted
from NashvilleHousing


-------------------------------------------------------------------------------------------------------
--POPULATE PROPERTY ADDRESS DATA

--I explore data and I realize that :
--In the field PropertyAddress there are some data that is null so we need to populate
Select PropertyAddress
From NashvilleHousing
Where PropertyAddress is null
--ParcelID is relation to PropertyAddress, so let's join itself to populate data in this part 
Select PropertyAddress, ParcelID
From NashvilleHousing
Order by 2
--Let's join where has the same ParcelID but not in the same row
Select a.PropertyAddress, a.ParcelID, b.PropertyAddress, b.ParcelID
From NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <>b.[UniqueID ]
--Replace what is null from field a.PropertyAddress with b.PropertyAddress
Select a.PropertyAddress, a.ParcelID, b.PropertyAddress, b.ParcelID, ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <>b.[UniqueID ]
Where a.PropertyAddress is null
--As we know how to replace, now we have to update the field PropertyAddress of my table with a query
--similar to before
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <>b.[UniqueID ]
Where a.PropertyAddress is null

-------------------------------------------------------------------------------------------------------
--BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

--We explore data and we see that we have the address and the city in the same field, and they are separated by a coma
Select PropertyAddress
From NashvilleHousing

--We use substring to separate what we have left to the coma and what we have in the right
Select
SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) AS City
From NashvilleHousing

--We can not split 1 field into 2 fields so what we are going to do is to create 2 news columns
ALTER TABLE NashvilleHousing
Add SpecificAddress NVARCHAR(255);

Update NashvilleHousing
SET SpecificAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE NashvilleHousing
Add SpecificCity NVARCHAR(255);

Update NashvilleHousing
SET SpecificCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

--So now we have to see what we add
Select PropertyAddress, SpecificAddress, SpecificCity
From NashvilleHousing

--Taking a look into the field OwnerAddress we realize a case similar to before
Select OwnerAddress
From NashvilleHousing

--In this case we have 2 comas so we can not look for a coma in the string
--We can use PARSENAME, it split the string in the number of parts where it finds periods "." and it 
--takes back the string splited from the last to the first
Select PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
From NashvilleHousing

--We can not split 1 field into 2 fields so what we are going to do is to create 2 news columns
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress NVARCHAR(255);
Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity NVARCHAR(255);
Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing
Add OwnerSplitState NVARCHAR(255);
Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

--And we select to see what we did
Select OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
From NashvilleHousing


-------------------------------------------------------------------------------------------------------
--CHANGE Y AND N YO YES AND NO IN "SOLDASVACANT" FIELD

--First we select the fiel "SoldAsVacant" and we realize that there are some records where we have "y" or "n" AS Yes or Not
Select SoldAsVacant
from NashvilleHousing
Where SoldAsVacant!='No' AND SoldAsVacant !='Yes'
--Or select distinct values for that fiel, just to see all tha values recorded
Select Distinct SoldAsVacant
from NashvilleHousing

--Then we are going to replace some records where the record is N to No, we use Case statement to do that
Select SoldAsVacant, 
CASE 
	When SoldAsVacant = 'Y' or SoldAsVacant = 'Yes'  Then 'Yes'
	When SoldAsVacant = 'N' or SoldAsVacant = 'No' Then 'No'
END AS SoldAsVacantCorrected
from NashvilleHousing

--Finally, we update the field with the correct values
Update NashvilleHousing
SET SoldAsVacant = CASE 
	When SoldAsVacant = 'Y' or SoldAsVacant = 'Yes'  Then 'Yes'
	When SoldAsVacant = 'N' or SoldAsVacant = 'No' Then 'No'
END

--We select to see the changes
Select Distinct SoldAsVacant
from NashvilleHousing



-------------------------------------------------------------------------------------------------------
--REMOVE DUPLICATES

--The standard practice is not to delete data, we need to use some functions to see where data is duplicate for example, rownumber or rank, etc
--In this case we need to partion it on things that should be unique
WITH CTE_ROW_NUM AS (
Select *,
ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) rownumber
from NashvilleHousing
)
SELECT*
FROM CTE_ROW_NUM
Where rownumber >1
--All of the result that is greather than 1 are duplicates, so we just change select statement for delete
WITH CTE_ROW_NUM AS (
Select *,
ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) rownumber
from NashvilleHousing
)
DELETE
FROM CTE_ROW_NUM
Where rownumber >1
--Then we select everything to check if we continue seeing the same duplicate data
WITH CTE_ROW_NUM AS (
Select *,
ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) rownumber
from NashvilleHousing
)
SELECT*
FROM CTE_ROW_NUM
Where rownumber >1


*Me quede en el minuto 47.17
-------------------------------------------------------------------------------------------------------
--DELETE UNUSED COLUMNS

Select *
From NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate
