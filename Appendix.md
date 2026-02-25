**Appendix**

**Party size logic**
The calcualtion is run on every bill

Due to legacy POS limitations, guest counts were estimated using a tiered logic model to prevent "cover-inflation" from shared items:

**Priority 1:** If Main Courses were present, Guest Count = Sum of Main Courses.

**Priority 2 (Fallback):** If no Main Courses were present, Guest Count = 50% of Appetizer count (rounded up), accounting for the shared nature of small plates.

**Validation:** This ensures a "drinks-and-snacks" table is still represented in the denominator for attachment rate calculations without skewing the data.

