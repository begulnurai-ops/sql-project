SELECT * FROM finalproject.transactions;
SELECT * FROM finalproject.customers;


##1. Список клиентов с непрерывной историей за год (каждый месяц без пропусков)

WITH valid_clients AS (
    SELECT
        Id_client
    FROM (
        SELECT
            Id_client,
            DATE_FORMAT(date_new, '%Y-%m') AS month
        FROM finalproject.transactions
        WHERE date_new >= '2015-06-01'
          AND date_new <  '2016-06-01'
        GROUP BY Id_client, month
    ) t
    GROUP BY Id_client
    HAVING COUNT(DISTINCT month) = 12
)
SELECT
    t.Id_client,
    AVG(t.Sum_payment)        AS avg_check_period,
    SUM(t.Sum_payment) / 12   AS avg_month_sum,
    COUNT(t.Id_check)         AS operations_cnt
FROM finalproject.transactions t
JOIN valid_clients v
  ON t.Id_client = v.Id_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new <  '2016-06-01'
GROUP BY t.Id_client;

##2
#a) Средняя сумма чека в месяц
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    AVG(Sum_payment)              AS avg_check
FROM finalproject.transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY month
ORDER BY month;

##b) Среднее количество операций в месяц

SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(Id_check)               AS operations_cnt
FROM finalproject.transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY month
ORDER BY month;

##c) Среднее количество клиентов, совершавших операции
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(DISTINCT Id_client)     AS active_clients
FROM finalproject.transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY month
ORDER BY month;

#d) долю от общего количества операций за год и долю в месяц от общей суммы 
#операций; 
SELECT
    m.month,
    m.ops_cnt / t.total_ops   AS operations_share_year,
    m.sum_amt / t.total_sum   AS sum_share_year
FROM (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(Id_check)               AS ops_cnt,
        SUM(Sum_payment)              AS sum_amt
    FROM finalproject.transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <  '2016-06-01'
    GROUP BY month
) m
JOIN (
    SELECT
        COUNT(Id_check)  AS total_ops,
        SUM(Sum_payment) AS total_sum
    FROM finalproject.transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <  '2016-06-01'
) t
ORDER BY m.month;

#e) вывести % соотношение M/F/NA в каждом месяце с их долей затрат; 
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    IFNULL(c.Gender, 'NA')           AS gender,
    COUNT(t.Id_check)               AS operations_cnt,
    SUM(t.Sum_payment)              AS sum_amt
FROM finalproject.transactions t
JOIN finalproject.customers c
  ON t.Id_client = c.Id_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new <  '2016-06-01'
GROUP BY month, gender
ORDER BY month, gender;

##3  возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет 
#данной информации, с параметрами сумма и количество операций за весь период, 
#и поквартально - средние показатели и %.

####За весь период: сумма и количество операций
SELECT
    IFNULL(
        CONCAT(FLOOR(c.Age/10)*10, '-', FLOOR(c.Age/10)*10 + 9),
        'NA'
    ) AS age_group,
    COUNT(t.Id_check)  AS operations_cnt,
    SUM(t.Sum_payment) AS total_sum
FROM finalproject.transactions t
JOIN finalproject.customers c
  ON t.Id_client = c.Id_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new <  '2016-06-01'
GROUP BY age_group
ORDER BY age_group;

#и поквартально - средние показатели и %.
SELECT
    IFNULL(
        CONCAT(FLOOR(c.Age/10)*10, '-', FLOOR(c.Age/10)*10 + 9),
        'NA'
    ) AS age_group,
    CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter,
    AVG(t.Sum_payment)  AS avg_check,
    COUNT(t.Id_check)   AS operations_cnt,
    SUM(t.Sum_payment) /
      (SELECT SUM(Sum_payment)
       FROM finalproject.transactions
       WHERE YEAR(date_new)=YEAR(t.date_new)
         AND QUARTER(date_new)=QUARTER(t.date_new)
      ) AS sum_share
FROM finalproject.transactions t
JOIN finalproject.customers c
  ON t.Id_client = c.Id_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new <  '2016-06-01'
GROUP BY age_group, quarter
ORDER BY quarter, age_group;


