USE healthcare
--Is there any correlation between exercise frequency and blood pressure levels?

WITH BloodPressureClassification AS (
    SELECT Blood_Pressure,
           Exercise_Frequency,
           TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 2) AS INT) AS Systolic,
           TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 1) AS INT) AS Diastolic,
           CASE
               WHEN TRY_CAST(PARSENAME(REPLACE(blood_pressure, '/', '.'), 2) AS INT) IS NOT NULL AND
                    TRY_CAST(PARSENAME(REPLACE(blood_pressure, '/', '.'), 1) AS INT) IS NOT NULL THEN
               CASE
                   WHEN TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 2) AS INT) < 120 AND
                        TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 1) AS INT) < 80 THEN 'Optimal'
                   WHEN TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 2) AS INT) >= 120 AND 
                        TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 2) AS INT) < 130 AND
                        TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 1) AS INT) < 80 THEN 'Normal'
                   WHEN (TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 2) AS INT) >= 130 AND
                         TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 2) AS INT) < 140) OR
                        (TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 1) AS INT) >= 80 AND
                         TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 1) AS INT) < 90) THEN 'High-Normal'
                   WHEN TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 2) AS INT) >= 140 OR
                        TRY_CAST(PARSENAME(REPLACE(Blood_Pressure, '/', '.'), 1) AS INT) >= 90 THEN 'High'
                   ELSE 'Unknown'
               END
           ELSE 'Invalid'
           END AS BP_Classification
    FROM patient_information
)

SELECT BP_Classification, 
       Exercise_Frequency, 
       COUNT(Exercise_Frequency) AS Exercise_Frequency_Count
FROM BloodPressureClassification
WHERE NOT Exercise_Frequency = 'nan' AND NOT BP_Classification = 'Invalid'
GROUP BY BP_Classification, Exercise_Frequency
ORDER BY Exercise_Frequency

-- Even those that exercise frequently still have have high bp

--What are the most common reasons for hospital visits?

SELECT Reason_For_Visit, COUNT(*) as Num
FROM hospital_visits
GROUP BY Reason_For_Visit
ORDER BY Num DESC

-- Most common reasons for hospital visits was for a cholesterol check

--What is the average cost of a hospital visit, and how does it vary by treatment type?

SELECT Treatment_Given, AVG(Cost_USD) AS AVG_Cost 
FROM hospital_visits
GROUP BY Treatment_Given
UNION ALL
SELECT 'Overall Average' AS Treatment_Given, AVG(Cost_USD) AS AVG_Cost
FROM hospital_visits
ORDER BY AVG_Cost

--Which doctor has the most patients assigned, and what is the average number of visits per patient for each doctor?

WITH PatientCount AS (
SELECT Doctor_Assigned AS Doctor_ID,
COUNT(DISTINCT Patient_ID) AS Num_Patients
FROM patient_information
GROUP BY Doctor_Assigned
),
PopularDoctor AS (
SELECT TOP 1 Doctor_ID, Num_Patients
FROM PatientCount
ORDER BY Num_Patients DESC
)
SELECT * FROM PopularDoctor

SELECT p.Doctor_Assigned AS Doctor_ID,
COUNT(hv.Visit_ID)/COUNT(DISTINCT(hv.Patient_ID)) AS AvgVisitsPerPatient
FROM hospital_visits hv
JOIN patient_information p on hv.Patient_ID = p.Patient_ID
GROUP BY p.Doctor_Assigned


-- The most popular Doctor is Dr.Smith with 56 patients. Give him a raise. 
-- Average visits for Dr.Adams and Dr.Johnson was 2, and Dr.Lee and Dr.Smith was 1

--Is there any difference in the average cost of treatments provided by different doctors?

SELECT p.Doctor_Assigned AS Doctor_ID, Treatment_Given, AVG(Cost_USD) AS AVG_Cost
FROM hospital_visits hv
JOIN patient_information p on hv.Patient_ID = p.Patient_ID
GROUP BY p.Doctor_Assigned, Treatment_Given


--What is the relationship between exercise frequency and the need for follow-up visits?

SELECT p.Exercise_Frequency, COUNT(Follow_Up_Needed) AS Follow_Up_Needed
FROM hospital_visits hv
JOIN patient_information p on hv.Patient_ID = p.Patient_ID
WHERE NOT p.Exercise_Frequency = 'nan' AND Follow_Up_Needed = '1'
GROUP BY p.Exercise_Frequency, Follow_Up_Needed
ORDER BY CASE 
	WHEN p.Exercise_Frequency = 'Frequently' THEN 1
	WHEN p.Exercise_Frequency = 'Occasionally' THEN 2
	WHEN p.Exercise_Frequency = 'Rarely' THEN 3
	ELSE 4
	END
-- Looks like people who worked out frequently had the most follow ups, but that may be due to them having more people in that category.

