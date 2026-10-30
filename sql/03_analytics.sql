-- View 1: survival rate by passenger class and encoded sex label
CREATE OR REPLACE VIEW vw_survival_by_class_sex AS
SELECT
    passenger_class,
    CASE sex_encoded WHEN 0 THEN 'female' WHEN 1 THEN 'male' ELSE 'unknown' END AS sex,
    COUNT(*) AS passenger_count,
    SUM(survived) AS survivors,
    ROUND(AVG(survived) * 100, 2) AS survival_rate_pct
FROM clean_passengers
GROUP BY passenger_class, sex_encoded;

-- View 2: survival rate by age group
CREATE OR REPLACE VIEW vw_survival_by_age_group AS
SELECT
    age_group,
    COUNT(*) AS passenger_count,
    SUM(survived) AS survivors,
    ROUND(AVG(survived) * 100, 2) AS survival_rate_pct
FROM clean_passengers
GROUP BY age_group;

-- View 3: three highest fares within each passenger class.
-- RANK retains ties, so a class can return more than three rows if fares tie.
CREATE OR REPLACE VIEW vw_top3_fares_by_class AS
SELECT
    passenger_class,
    fare,
    survived,
    sex_encoded,
    age,
    family_size,
    fare_rank
FROM (
    SELECT
        passenger_class,
        fare,
        survived,
        sex_encoded,
        age,
        family_size,
        RANK() OVER (
            PARTITION BY passenger_class
            ORDER BY fare DESC
        ) AS fare_rank
    FROM clean_passengers
    WHERE fare IS NOT NULL
) ranked
WHERE fare_rank <= 3;
