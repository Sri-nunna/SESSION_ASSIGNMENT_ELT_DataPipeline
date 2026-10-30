# Titanic ELT Pipeline (MySQL 8+)

This project follows the requested ELT order: Python extracts and loads the raw
Seaborn Titanic dataset; all cleaning, transformation, analytics, and quality
checks are SQL.

## Files

- `extract_load.py` — extracts `seaborn.load_dataset("titanic")` and loads
  `raw_titanic`, preserving source columns and null values, plus `load_timestamp`
  and `batch_id`.
- `sql/01_staging.sql` — creates `stg_titanic` with clearer column names,
  normalized text case, and explicit casts.
- `sql/02_transform.sql` — creates `clean_passengers`.
- `sql/03_analytics.sql` — creates three analytical views.
- `sql/04_data_quality.sql` — records four checks in `dq_results`.
- `run_elt.py` — runs extraction/loading, SQL files in order, then prints each
  quality check as `PASS` or `FAIL`.

## Requirements

- MySQL 8.0+ (CTEs and window functions such as `NTILE`, `AVG OVER`, and `RANK`
  are used).
- Python 3.10+ recommended.

## Setup

1. Create a MySQL database:

   ```sql
   CREATE DATABASE titanic_elt CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. Install dependencies:

   ```bash
   python -m venv .venv
   # Windows: .venv\\Scripts\\activate
   # macOS/Linux:
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. Create a `.env` file from `.env.example` and set the connection variables.
   The scripts load `.env` automatically; explicitly exported environment
   variables still take precedence.

   macOS/Linux example:

   ```bash
   export MYSQL_HOST=localhost
   export MYSQL_PORT=3306
   export MYSQL_USER=root
   export MYSQL_PASSWORD='your_password'
   export MYSQL_DATABASE=titanic_elt
   ```

   PowerShell example:

   ```powershell
   $env:MYSQL_HOST="localhost"
   $env:MYSQL_PORT="3306"
   $env:MYSQL_USER="root"
   $env:MYSQL_PASSWORD="your_password"
   $env:MYSQL_DATABASE="titanic_elt"
   ```

4. Run the whole pipeline:

   ```bash
   python run_elt.py
   ```

## Important implementation notes

- **Reruns:** `raw_titanic` is replaced by a fresh snapshot on each run, rather
  than appended to, so repeated runs do not accumulate duplicate rows. This is
  appropriate for the requested full-snapshot load. Do not use this strategy if
  raw history must be retained across batches; in that case, use a separate
  batch/history design.
- **Raw safety:** SQL scripts never update or transform `raw_titanic`; all
  transformations are materialized into downstream tables. The extract/load
  script recreates `raw_titanic` on a run to satisfy the no-duplicate rerun rule.
- **Age imputation:** `AVG(age)` is calculated by passenger class and sex. If a
  whole class/sex group has no known ages, its age remains null and the DQ check
  will report `FAIL` rather than inventing a value.
- **Embarked imputation:** the global mode is used; alphabetical order breaks
  ties deterministically.
- **Sex encoding:** `sex_encoded = 0` for female and `1` for male. The original
  normalized text value remains in `sex`.
- **Fare categories:** `NTILE(4)` over all non-null fares creates quartiles:
  Low, Medium, High, Premium. Because the dataset's fares are not evenly
  distributed, these are quartile groups, not fixed currency thresholds.
- **Duplicate handling:** the Seaborn Titanic dataset does not provide a stable
  passenger identifier, and multiple rows can have identical recorded
  attributes. Exact duplicate detection is therefore not used as a failing
  quality check; a production source should add a stable passenger identifier
  before enforcing passenger uniqueness.
- **Views:** `vw_top3_fares_by_class` uses `RANK()`, so ties at rank 3 can produce
  more than three rows in a class.
- `to_sql(if_exists="replace")` infers raw column types from the uncleaned
  dataframe. Nulls are retained, though MySQL's inferred column types may differ
  from the original in-memory pandas dtypes.

## Quality checks

The `dq_results` table stores `check_name`, `status`, and `checked_at`. The
pipeline prints the status for every check and exits with an error if any check
fails. Review the results with:

```sql
SELECT check_name, status, checked_at
FROM dq_results
ORDER BY checked_at DESC, check_name;
```

## Inspect analytics

```sql
SELECT * FROM vw_survival_by_class_sex;
SELECT * FROM vw_survival_by_age_group;
SELECT * FROM vw_top3_fares_by_class ORDER BY passenger_class, fare_rank;
```
