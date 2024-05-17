CREATE DATABASE myskill_project;

SELECT * FROM ds_salaries;

-- 1. Bagaimana ringkasan statistik mengenai gaji di bidang data?
WITH min_salary AS (
SELECT MIN(salary_in_usd) min_sal_in_usd
FROM ds_salaries
), max_salary AS (
SELECT MAX(salary_in_usd) max_sal_in_usd
FROM ds_salaries
), avg_salary AS (
SELECT AVG(salary_in_usd) avg_sal_in_usd
FROM ds_salaries
), range_salary AS (
SELECT (MAX(salary_in_usd) - MIN(salary_in_usd)) range_sal_in_usd
FROM ds_salaries
), standard_deviation AS (
SELECT SQRT(SUM((salary_in_usd - avg_sal_in_usd)^2)/(COUNT(*)-1)) std_value
FROM ds_salaries CROSS JOIN avg_salary
)
SELECT 
	min_sal_in_usd, 
	max_sal_in_usd, 
	avg_sal_in_usd, 
	range_sal_in_usd, 
	std_value
FROM min_salary
CROSS JOIN max_salary
CROSS JOIN avg_salary
CROSS JOIN range_salary
CROSS JOIN standard_deviation;

-- 2. Berapa banyak masing-masing pekerjaan yang berkaitan dengan Data Science, Data Analysis,
-- Data Engineer, Machine Learning, AI dan pekerjaan lainnya?
WITH ds_jobs AS (
SELECT COUNT(*) num_of_ds_jobs FROM ds_salaries WHERE job_title LIKE "%data scien%"
), da_jobs AS (
SELECT COUNT(*) num_of_da_jobs FROM ds_salaries WHERE job_title LIKE "%data ana%"
), de_jobs AS (
SELECT COUNT(*) num_of_de_jobs FROM ds_salaries WHERE job_title LIKE "%data engine%"
), ml_jobs AS (
SELECT COUNT(*) num_of_ml_jobs FROM ds_salaries
WHERE job_title LIKE "%machine learn%" OR job_title LIKE "%ML%"
), ai_jobs AS (
SELECT COUNT(*) num_of_ai_jobs FROM ds_salaries WHERE job_title LIKE "%AI%"
), total_jobs AS (
SELECT COUNT(*) total_jobs FROM ds_salaries
)
SELECT *,
(total_jobs-(num_of_ds_jobs + num_of_da_jobs + num_of_de_jobs + num_of_ml_jobs + num_of_ai_jobs)
    ) AS num_of_other_jobs
FROM total_jobs 
CROSS JOIN ds_jobs ds
CROSS JOIN da_jobs da
CROSS JOIN de_jobs de
CROSS JOIN ml_jobs ml
CROSS JOIN ai_jobs ai;

-- 3. Berapa gaji rata-rata pekerjaan yang berkaitan dengan Data Scientist (DS), Data Analyst (DA),
-- Data Engineer (DE), Machine Learning Engineer (ML), AI Scientist (AI), dan lainnya (OTHER) 
-- untuk experience level junior (EN) hingga intermediate (MI)?
WITH label AS (
SELECT *,
CASE
	WHEN job_title LIKE "%data scien%" THEN "DS"
	WHEN job_title LIKE "%data ana%" THEN "DA"
	WHEN job_title LIKE "%data engine%" THEN "DE"
	WHEN job_title LIKE "%machine learning%" OR job_title LIKE "%ML%" THEN "ML"
	WHEN job_title LIKE "%AI%" THEN "AI"
	ELSE "OTHER"
END AS job_label
FROM ds_salaries)
SELECT 
	job_label, 
	employment_type, 
	AVG(salary_in_usd) avg_sal_in_usd
FROM label
WHERE experience_level IN ("EN","MI")
GROUP BY 1, 2
ORDER BY 1, 2;

-- 4. Pekerjaan apa saja yang memiliki gaji tertinggi di tahun 2022 dengan experience level junior
-- (EN)?
SELECT 
	job_title, 
	employment_type, 
	company_location, 
	company_size, 
	salary_in_usd
FROM ds_salaries
WHERE work_year = 2022 AND experience_level IN ("EN")
ORDER BY salary_in_usd DESC
LIMIT 10;

-- 5. Bagaimana tren rata-rata gaji dan selsihnya dibandingkan dengan tahun sebelumnya tiap
-- label pekerjaan tiap tahunnya?
SELECT *,
	(avg_sal_in_usd - LAG(avg_sal_in_usd)
	OVER(PARTITION BY job_label ORDER BY work_year)) difference
FROM
	(SELECT 
		work_year, 
		job_label, 
		AVG(salary_in_usd) avg_sal_in_usd
	FROM (
		SELECT *,
			CASE
				WHEN job_title LIKE "%data scien%" THEN "DS"
				WHEN job_title LIKE "%data ana%" THEN "DA"
				WHEN job_title LIKE "%data engine%" THEN "DE"
				WHEN job_title LIKE "%machine learning%" OR job_title LIKE "%ML%" THEN "ML"
				WHEN job_title LIKE "%AI%" THEN "AI"
				ELSE "OTHER"
			END AS job_label
		FROM ds_salaries
	) t1
	GROUP BY 1,2) t2
ORDER BY 2,1;

-- 6. Pekerjaan data analyst yang mana yang memiliki gaji tertinggi?
SELECT DISTINCT job_title
FROM ds_salaries
WHERE job_title LIKE "%Data Ana%"
ORDER BY salary_in_usd DESC;

-- 7. Pekerjaan apa saja yang memiliki gaji terbesar di bidang data analyst?
-- (level junior (EN))
SELECT
	job_title,
	work_year,
    employment_type,
    remote_ratio,
	company_location,
    company_size,
    salary_in_usd,
    DENSE_RANK() OVER (ORDER BY salary_in_usd DESC) ranks
FROM ds_salaries
WHERE job_title LIKE "%Data Ana%" AND experience_level = "EN" 
ORDER BY salary_in_usd DESC;

-- 8. Pada tahun berapa pekerjaan data analyst penuh waktu memiliki kenaikan gaji tertinggi dari
-- level menengah (MI) ke senior (SE)
WITH t_year AS (
	SELECT DISTINCT work_year FROM ds_salaries
), da_1 AS (
	SELECT work_year, AVG(salary_in_usd) sal_in_usd_se
    FROM ds_salaries 
    WHERE job_title LIKE "%data ana%" AND experience_level = "SE" AND employment_type = "FT"
    GROUP BY 1
), da_2 AS (
	SELECT work_year, AVG(salary_in_usd) sal_in_usd_mi
    FROM ds_salaries 
    WHERE job_title LIKE "%data ana%" AND experience_level = "MI" AND employment_type = "FT"
    GROUP BY 1
)

SELECT work_year, sal_in_usd_se, sal_in_usd_mi, (sal_in_usd_se - sal_in_usd_mi) difference
FROM t_year
LEFT JOIN da_1 USING(work_year)
LEFT JOIN da_2 USING(work_year);

-- 9. Apakah semakin besar perusahaan memiliki rata-rata gaji yang semakin tinggi?
-- (Untuk pekerjaan yang berkaitan dengan data analyst)
SELECT company_size, COUNT(*) num_of_da_jobs, AVG(salary_in_usd) avg_sal_in_usd
FROM ds_salaries
WHERE job_title LIKE "%data ana%"
GROUP BY 1
ORDER BY 1 DESC;

-- 10. Apakah pekerjaan yang rasio remotenya semakin tinggi memiliki gaji yang lebih tinggi?
-- (Untuk pekerjaan yang berkaitan dengan data analyst)
SELECT remote_ratio, COUNT(*) num_of_da_jobs, AVG(salary_in_usd) avg_sal_in_usd
FROM ds_salaries
WHERE job_title LIKE "%data ana%"
GROUP BY 1
ORDER BY 1 DESC;

-- 11. Apakah karyawan yang bekerja sebagai data analyst yang bertempat tinggal di lokasi
-- yang sama dengan lokasi perusahaan lebih mungkin untuk kerja dari kantor?
SELECT
	"Total Employee" descr, 
	CAST(SUM(CASE WHEN remote_ratio = 100 THEN 1 END) AS CHAR) num_of_fully_remote_employee,
	CAST(SUM(CASE WHEN remote_ratio = 50 THEN 1 END) AS CHAR) num_of_partially_remote_employee,
	CAST(SUM(CASE WHEN remote_ratio = 0 THEN 1 END) AS CHAR) num_of_no_remote_employee
FROM ds_salaries
WHERE job_title LIKE "%data ana%"
GROUP BY 1
UNION ALL
SELECT 
	"Pctg of employee WFO" descr,
	-- Menghitung persentase karyawan yang rasio remote-nya 100
	-- yang tinggal di lokasi yang sama dengan perusahaan
    	CAST(SUM(CASE 
		WHEN (remote_ratio = 100) AND (employee_residence = company_location) THEN 1
            	END)*100/(SUM(CASE
				WHEN remote_ratio = 100 THEN 1
                            	END) 
	) AS CHAR) num_of_fully_remote_employee,
	-- Menghitung persentase karyawan yang rasio remote-nya 50
	-- yang tinggal di lokasi yang sama dengan perusahaan
	CAST(SUM(CASE 
		WHEN (remote_ratio = 50) AND (employee_residence = company_location) THEN 1
            	END)*100/(SUM(CASE
				WHEN remote_ratio = 50 THEN 1
	                        END)
	) AS CHAR) num_of_partially_remote_employee,
	-- Menghitung persentase karyawan yang rasio remote-nya 0
	-- yang tinggal di lokasi yang sama dengan perusahaan
	CAST(SUM(CASE 
		WHEN (remote_ratio = 0) AND (employee_residence = company_location) THEN 1
		END)*100/(SUM(CASE
				WHEN remote_ratio = 0 THEN 1
				END)
	) AS CHAR) num_of_no_remote_employee
FROM ds_salaries
WHERE job_title LIKE "%data ana%"
GROUP BY 1;
