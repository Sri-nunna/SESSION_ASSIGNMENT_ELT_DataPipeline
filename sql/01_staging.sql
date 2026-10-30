-- MySQL 8+
-- Rebuild staging from raw. Raw data is never updated by SQL.
DROP TABLE IF EXISTS stg_titanic;

CREATE TABLE stg_titanic AS
SELECT
    CAST(survived AS UNSIGNED) AS survived,
    CAST(pclass AS UNSIGNED) AS passenger_class,
    LOWER(TRIM(CAST(sex AS CHAR(20)))) AS sex,
    CAST(age AS DECIMAL(5,2)) AS age,
    CAST(sibsp AS UNSIGNED) AS sibsp,
    CAST(parch AS UNSIGNED) AS parch,
    CAST(fare AS DECIMAL(10,4)) AS fare,
    LOWER(TRIM(CAST(embarked AS CHAR(10)))) AS embarked,
    LOWER(TRIM(CAST(`class` AS CHAR(20)))) AS passenger_class_name,
    LOWER(TRIM(CAST(who AS CHAR(20)))) AS who,
    CAST(adult_male AS UNSIGNED) AS adult_male,
    LOWER(TRIM(CAST(deck AS CHAR(10)))) AS deck,
    LOWER(TRIM(CAST(embark_town AS CHAR(50)))) AS embark_town,
    LOWER(TRIM(CAST(alive AS CHAR(10)))) AS alive,
    CAST(alone AS UNSIGNED) AS alone,
    load_timestamp,
    batch_id
FROM raw_titanic;
