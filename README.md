# Vistara Sales Analysis

Vistara is a Python and MySQL data-analysis project that explores retail sales performance across branches, cities, product categories, payment methods, and time periods.

The workflow cleans a raw transaction dataset, calculates revenue and profit, exports the processed data to MySQL, and answers a collection of business questions using SQL.

## Key Features

- Loads and explores the raw sales dataset with pandas
- Removes missing rows and standardizes currency and date fields
- Calculates total revenue and estimated profit
- Exports the cleaned data to a MySQL database
- Provides SQL analysis for:
  - Year-over-year and monthly revenue
  - Branch and city performance
  - Product-category profitability
  - Payment preferences
  - Customer ratings
  - Daily, hourly, and shift-based sales trends

## Project Files

| File | Description |
| --- | --- |
| `project.ipynb` | Data loading, cleaning, feature creation, and MySQL export |
| `vistaradata.csv` | Raw transaction data |
| `cleaned_vistaradata.csv` | Cleaned data with `total_price` and `profit` columns |
| `Businessanalysis.sql` | SQL queries for business analysis |
| `requirements.txt` | Python dependencies |

## Dataset

The raw dataset contains 10,000 transaction rows. After removing rows with missing values, the cleaned dataset contains 9,969 transactions and 13 columns.

### Fields

- `invoice_id`: Unique transaction identifier
- `Branch`: Store branch code
- `City`: Store location
- `category`: Product category
- `unit_price`: Price of one unit
- `quantity`: Number of units sold
- `date`: Transaction date
- `time`: Transaction time
- `payment_method`: Payment method used
- `rating`: Customer rating
- `profit_margin`: Profit margin applied to the transaction
- `total_price`: `unit_price * quantity`
- `profit`: `total_price * profit_margin`

## Requirements

- Python 3.x
- MySQL Server
- Jupyter Notebook
- The packages in `requirements.txt`:
  - pandas
  - PyMySQL
  - SQLAlchemy

## Setup

1. Clone or download the project.

2. Create and activate a Python environment:

   ```powershell
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   pip install jupyter
   ```

3. Ensure MySQL is running locally and create the target database:

   ```sql
   CREATE DATABASE vistara_db;
   ```

4. Start Jupyter:

   ```powershell
   jupyter notebook
   ```

5. Open `project.ipynb` and update the MySQL connection values in the database connection cell:

   ```python
   username = "root"
   password = "YOUR_MYSQL_PASSWORD"
   host = "localhost"
   port = "3306"
   database = "vistara_db"
   ```

   Run the notebook in order. Do not place real database passwords in source-controlled files.

## Running the Analysis

After the notebook exports `df` to the `vistara` MySQL table, run:

```sql
USE vistara_db;
SOURCE Businessanalysis.sql;
```

The SQL script can also be opened directly in MySQL Workbench or another MySQL client.

## Data Cleaning Performed

The notebook:

1. Reads `vistaradata.csv`.
2. Displays the dataset structure and missing-value summary.
3. Removes rows containing missing values.
4. Converts the currency-formatted `unit_price` column to a numeric value.
5. Converts `date` to a datetime value.
6. Creates `total_price` and `profit`.
7. Saves the processed data as `cleaned_vistaradata.csv`.
8. Loads the processed records into the MySQL `vistara` table.
