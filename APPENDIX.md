**Appendix**

### Party size logic
The calculation is run on every bill

Due to legacy POS limitations, guest counts were estimated using a tiered logic model to prevent "cover-inflation" from shared items:

**Priority 1:** If Main Courses were present, Guest Count = Sum of Main Courses.

**Priority 2 (Fallback):** If no Main Courses were present, Guest Count = 50% of Appetizer count (rounded up), accounting for the shared nature of small plates.

**Validation:** This ensures a "drinks-and-snacks" table is still represented in the denominator for attachment rate calculations without skewing the data.


### Shift Intensity Classification

Volume Distribution (114 Total Nights)

-- Slow **(≤ 39 checks by night)** -- 29 Nights

-- Medium **(40 – 75 checks)** -- 55 Nights

-- High **(76+ checks)** --30 Nights


### Data Filtering

The raw dataset contained **23,898 transactions.** 

After applying quality filters, the final dataset consisted of **3,259 qualified transactions (13.6% of the original records).**

**1.Summer 2025 only transactions 2025-06-01 - 2025-10-31:** -16,337 Transactions

**2.Only Bills with Food Item (using EXISTS logic).:** -4,248 Transactions

**3. Positive Check Only (Exclude empty bills and staff discounts bills):** -54 Transactions

### Revenue Increase Calculation

**Calculate wine increase revenue:** (Total customers ordering wine glasses) × 3% × Avg. Wine Bottle Price ($40)

**Calculate second drink increase revenue:** (Total customers with only 1 drink) × 5% × Avg. Drink Price ($10)

**Note on Conservatism:** These targets are intentionally set lower than the current performance of our "Upsell Champions" (who outperform the baseline by 27%–70%), making these goals highly attainable through floor standardization.

