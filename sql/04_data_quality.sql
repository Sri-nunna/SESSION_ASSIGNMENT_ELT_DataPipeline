-- Each run replaces the prior run's quality-check results.
CREATE TABLE IF NOT EXISTS dq_results (
    check_name VARCHAR(100) NOT NULL,
    status VARCHAR(4) NOT NULL,
    checked_at DATETIME NOT NULL
);

DELETE FROM dq_results;

INSERT INTO dq_results (check_name, status, checked_at)
SELECT
    'raw_count_equals_clean_count',
    CASE WHEN (SELECT COUNT(*) FROM raw_titanic) =
              (SELECT COUNT(*) FROM clean_passengers)
         THEN 'PASS' ELSE 'FAIL' END,
    NOW();

INSERT INTO dq_results (check_name, status, checked_at)
SELECT
    'no_null_age_or_embarked',
    CASE WHEN NOT EXISTS (
        SELECT 1 FROM clean_passengers
        WHERE age IS NULL OR embarked IS NULL
    ) THEN 'PASS' ELSE 'FAIL' END,
    NOW();

INSERT INTO dq_results (check_name, status, checked_at)
SELECT
    'age_between_0_and_100',
    CASE WHEN NOT EXISTS (
        SELECT 1 FROM clean_passengers
        WHERE age IS NULL OR age < 0 OR age > 100
    ) THEN 'PASS' ELSE 'FAIL' END,
    NOW();

INSERT INTO dq_results (check_name, status, checked_at)
SELECT
    'sex_encoded_only_0_or_1',
    CASE WHEN NOT EXISTS (
        SELECT 1 FROM clean_passengers
        WHERE sex_encoded IS NULL OR sex_encoded NOT IN (0, 1)
    ) THEN 'PASS' ELSE 'FAIL' END,
    NOW();
