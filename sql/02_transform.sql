-- MySQL 8+
-- Fill age by average within the same passenger class and sex.
-- Fill embarked using the most frequent non-null embarked value; ties are
-- resolved alphabetically for deterministic results.
DROP TABLE IF EXISTS clean_passengers;

CREATE TABLE clean_passengers AS
WITH
age_filled AS (
    SELECT
        s.*,
        COALESCE(
            s.age,
            AVG(s.age) OVER (PARTITION BY s.passenger_class, s.sex)
        ) AS age_filled
    FROM stg_titanic AS s
),
embarked_mode AS (
    SELECT embarked
    FROM stg_titanic
    WHERE embarked IS NOT NULL
    GROUP BY embarked
    ORDER BY COUNT(*) DESC, embarked ASC
    LIMIT 1
),
fare_quartiles AS (
    SELECT
        a.*,
        NTILE(4) OVER (ORDER BY a.fare ASC, a.passenger_class ASC) AS fare_quartile
    FROM age_filled AS a
)
SELECT
    f.survived,
    f.passenger_class,
    f.sex,
    CAST(f.age_filled AS DECIMAL(5,2)) AS age,
    f.sibsp,
    f.parch,
    f.fare,
    COALESCE(f.embarked, (SELECT embarked FROM embarked_mode)) AS embarked,
    f.passenger_class_name,
    f.who,
    f.adult_male,
    f.alive,
    f.alone,
    CASE
        WHEN f.sex = 'female' THEN 0
        WHEN f.sex = 'male' THEN 1
        ELSE NULL
    END AS sex_encoded,
    CASE
        WHEN f.age_filled BETWEEN 0 AND 12 THEN 'Child'
        WHEN f.age_filled BETWEEN 13 AND 19 THEN 'Teen'
        WHEN f.age_filled BETWEEN 20 AND 59 THEN 'Adult'
        WHEN f.age_filled >= 60 THEN 'Senior'
        ELSE NULL
    END AS age_group,
    (COALESCE(f.sibsp, 0) + COALESCE(f.parch, 0) + 1) AS family_size,
    CASE
        WHEN COALESCE(f.sibsp, 0) = 0 AND COALESCE(f.parch, 0) = 0 THEN 1
        ELSE 0
    END AS is_alone,
    CASE f.fare_quartile
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
        WHEN 4 THEN 'Premium'
    END AS fare_category,
    f.load_timestamp,
    f.batch_id
FROM fare_quartiles AS f;
