# Transactions & Index Benchmarks (short)

**Date:** 2025-12-17

## Restaurant sample
- Found Restaurant: id=7, name="Burger Barn"

## EXPLAIN ANALYZE: MenuItem name lookup (ILIKE '%Burger%')
- Plan indicates sequential scan (index not used for leading-wildcard ILIKE):

```
Limit  (cost=0.00..22.10 rows=1 width=169) (actual time=0.108..0.121 rows=2 loops=1)
  ->  Seq Scan on "MenuItem"  (cost=0.00..22.10 rows=1 width=169) (actual time=0.106..0.119 rows=2 loops=1)
        Filter: (name ~~* '%Burger%'::text)
Planning Time: 0.715 ms
Execution Time: 0.180 ms
```

**Note:** For search-with-leading-wildcard, a trigram index (pg_trgm) would be more effective; the current btree index on `name` helps prefix searches but not `%term%` ILIKE patterns.

## EXPLAIN ANALYZE: Orders for user (userId = 1)
- Small table size → planner chooses a sequential scan; index may help when table grows:

```
Limit  (cost=1.03..1.04 rows=1 width=152) (actual time=0.033..0.033 rows=0 loops=1)
  ->  Sort  (cost=1.03..1.04 rows=1 width=152) (actual time=0.031..0.032 rows=0 loops=1)
        Sort Key: "createdAt" DESC
  ->  Seq Scan on "Order"  (cost=0.00..1.02 rows=1 width=152) (actual time=0.005..0.006 rows=0 loops=1)
        Filter: ("userId" = 1)
Planning Time: 1.304 ms
Execution Time: 0.062 ms
```

**Note:** Composite index on `(userId, createdAt)` exists and will help when table size grows; planner may still prefer seq scan for tiny tables.

## Transaction demo (script: `scripts/demo_transactions.ts`)
- Successful transaction:
  - MenuItem id=19 (Margherita Pizza) stock 100 → after success: 99
  - Order created and payment recorded, transaction committed.
- Forced-failure transaction:
  - Attempted to buy more than available stock → error thrown (`Insufficient stock`) and the transaction rolled back.
  - Final stock unchanged after failure (remains 99).

---

Next steps: bundle these logs into README `Database` section and add a short guidance note recommending `pg_trgm` + trigram index for substring searches if we need fast `%term%` searches.
