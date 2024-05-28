  /* This query gets data used for a dashboard representing the HR employee overview.
The results of this query were imported to Power BI AS the 'Employee' Table. */

-- CTE to rank Employee Department History records
WITH
  RankedEmployeeDepartment AS (
  SELECT
    EmployeeDepartmentHistory.*,
    ROW_NUMBER() OVER (PARTITION BY EmployeeDepartmentHistory.EmployeeID ORDER BY EmployeeDepartmentHistory.StartDate DESC) AS RowNum
  FROM
    `tc-da-1.adwentureworks_db.employeedepartmenthistory` AS EmployeeDepartmentHistory ),
  -- CTE to rank Employee Pay History records
RankedEmployeePayHistory AS (
  SELECT
    EmployeePayHistory.*,
    ROW_NUMBER() OVER (PARTITION BY EmployeePayHistory.EmployeeId ORDER BY EmployeePayHistory.ModifiedDate DESC) AS RowNum
  FROM
    `tc-da-1.adwentureworks_db.employeepayhistory` AS EmployeePayHistory )
-- Main query combining data from various tables
SELECT
  Employee.EmployeeId,
  Employee.Title AS Position,
  Employee.BirthDate,
  Employee.MaritalStatus,
  Employee.Gender,
  Employee.HireDate,
  Employee.CurrentFlag,
  Employee.SalariedFlag,
  Employee.VacationHours,
  Employee.SickLeaveHours,
  Employee.ModifiedDate AS EmployeeModifiedDate,
  PayHistory.Rate,
  DepartmentInfo.Name AS DepartmentName,
  DepartmentInfo.GroupName,
  Department.StartDate AS DepartmentStartDate,
  Department.EndDate AS DepartmentEndDate,
  Shift.Name AS ShiftType
FROM
  `tc-da-1.adwentureworks_db.employee` AS Employee
-- Joining with the RankedEmployeeDepartment CTE to get the latest department information for each employee
JOIN
  RankedEmployeeDepartment AS Department
ON
  Employee.EmployeeId = Department.EmployeeID
  AND Department.RowNum = 1
-- Joining with the RankedEmployeePayHistory CTE to get the latest pay information for each employee
JOIN
  RankedEmployeePayHistory AS PayHistory
ON
  Employee.EmployeeId = PayHistory.EmployeeId
  AND PayHistory.RowNum = 1
-- Joining with the Department table to get additional department information
JOIN
  `tc-da-1.adwentureworks_db.department` AS DepartmentInfo
ON
  Department.DepartmentID = DepartmentInfo.DepartmentID
-- Joining with the Shift table to get the shift information for each department
JOIN
  `tc-da-1.adwentureworks_db.shift` AS Shift
ON
  Department.ShiftID = Shift.ShiftID;
