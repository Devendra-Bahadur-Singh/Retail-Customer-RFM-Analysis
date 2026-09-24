# Retail Customer RFM Segmentation & Business Intelligence

[![Tableau](https://img.shields.io/badge/Tableau-Public_Dashboard-E97627?style=for-the-badge&logo=Tableau&logoColor=white)](https://public.tableau.com/app/profile/devendra.bahadur.singh/viz/rfm_Book/Dashboard1)
[![SQL](https://img.shields.io/badge/SQL-Data_Engineering-4479A1?style=for-the-badge&logo=MySQL&logoColor=white)](#-data-pipeline--methodology)
[![Excel](https://img.shields.io/badge/Excel-Statistical_Audit-217346?style=for-the-badge&logo=MicrosoftExcel&logoColor=white)](#-data-pipeline--methodology)

An end-to-end customer analytics pipeline leveraging **SQL**, **Excel**, and **Tableau** to perform Recency, Frequency, and Monetary (RFM) segmentation across **20,000+ raw transactional records**, categorizing **4,328 active accounts** into actionable strategic cohorts driving **$8.56M in overall revenue**.

---

## 📊 Live Interactive Dashboard

> [!IMPORTANT]
> **Explore the interactive dashboard on Tableau Public:**  
> 👉 **[Retail Customer RFM Segmentation Dashboard](https://public.tableau.com/app/profile/devendra.bahadur.singh/viz/rfm_Book/Dashboard1)**

---

## 📁 Repository Structure

```text
├── Source/
│   └── data.csv                                 # Raw e-commerce transactional dataset
├── rfm_Book.twb                                 # Tableau Desktop Workbook file
├── rfm_final_segments (rfm_final_segments).hyper# Tableau Data Extract file
├── rfm_final_segments.csv                       # Cleaned, aggregated & scored output dataset (CSV)
├── rfm_final_segments.xlsx                      # Excel Pivot validation & Pareto distribution audit
├── rfm_script.sql                               # Full SQL pipeline (Cleaning, Aggregations, NTILE scoring)
└── README.md                                    # Project documentation
📌 Executive SummaryBy analyzing historical customer transactions, this project addresses total revenue distribution, customer retention, and churn risks:Pareto Revenue Concentration: High-Value Champions represent 21.5% of the customer base but drive 65.6% ($5.61M) of cumulative revenue.Revenue at Churn Risk: 420 At-Risk accounts represent $711.8K in historical value with an average inactivity period of 124.5 days.Conversion Potential: 970 Occasional Buyers form the single largest user base (22.4%), providing an immediate cross-selling target to drive repeat orders.⚙️ Data Pipeline & Methodology┌─────────────────┐      ┌─────────────────┐      ┌──────────────────┐      ┌───────────────────┐
│   Source/       │ ───► │  rfm_script.sql │ ───► │ rfm_final_      │ ───► │  rfm_Book.twb     │
│   data.csv      │      │  (MySQL Engine) │      │ segments.xlsx    │      │  (Tableau Public) │
└─────────────────┘      └─────────────────┘      └──────────────────┘      └───────────────────┘
   Raw Logs                 Cleaning &               Statistical Audit &       Interactive Visual
                            Window Functions         Pivot Validation          Analytics
1. Data Cleaning & Engineering (rfm_script.sql)Filtered non-transactional items, returns (C% cancelled invoices), null CustomerID records, and anomalous prices.Derived transaction total spend (Quantity * UnitPrice) and computed exact days elapsed relative to the dataset anchor date.Utilized NTILE(5) window functions to calculate discrete 1–5 quintile scores across Recency, Frequency, and Monetary dimensions.2. Validation & Audit (rfm_final_segments.xlsx)Built validation pivot tables to inspect metric boundary distributions.Validated cohort summary metrics against underlying SQL aggregations to ensure total revenue ($8.56M) and distinct active account count (4,328) reconciled.3. Interactive BI Dashboard (rfm_Book.twb)Implemented log-scale Recency vs. Spend scatter plot matrix with reversed horizontal axes.Constructed a 5x5 RFM grid matrix and dynamic treemap with cross-filtering actions.📈 Customer Segment Matrix & InsightsCustomer SegmentCustomer CountShare (%)Total Revenue ($)Rev Share (%)Avg CLV ($)Primary Strategic FocusHigh-Value / Champions93421.47%$5,613,199.2965.59%$6,009.85VIP loyalty perks & priority supportLoyal Customers86219.82%$1,340,010.2515.66%$1,554.54Upsell higher-margin category linesAt-Risk / Need Attention4209.67%$711,752.178.32%$1,694.65Automated win-back discount triggersOccasional Buyers97022.38%$605,905.897.08%$624.65Post-purchase cross-sell incentivesLost / Inactive91421.18%$210,670.712.46%$230.49Low-cost automated email retargetingRecent / New Buyers2365.47%$75,976.210.89%$321.9330-day onboarding drip series💡 Strategic RecommendationsProtect High-Value Champions: Establish exclusive VIP loyalty tiers and early catalog access to retain top-tier accounts driving two-thirds of enterprise revenue.Win-Back At-Risk Accounts: Deploy targeted automated re-engagement offers to the 420 churn-risk accounts before complete loss of customer lifetime value.Nurture Occasional Buyers: Introduce free-shipping thresholds and post-purchase recommendations to increase order frequency across the largest customer cohort.🛠️ How to Reproduce LocallyDatabase Setup: Load Source/data.csv into your SQL environment and execute rfm_script.sql to clean and calculate RFM scores.Export Dataset: Save the processed dataset output as rfm_final_segments.csv.Open Tableau Workbook: Open rfm_Book.twb using Tableau Desktop or Tableau Public App (connected to rfm_final_segments (rfm_final_segments).hyper or rfm_final_segments.csv).
