# Q1

## gráfica explain

![alt text](./imagenes/imageQ1.png)

## explain

```
"Sort  (cost=98645.08..98645.10 rows=10 width=41)"
"  Sort Key: (sum(o.total_amount)) DESC"
"  ->  Finalize GroupAggregate  (cost=98641.81..98644.91 rows=10 width=41)"
"        Group Key: c.city"
"        ->  Gather Merge  (cost=98641.81..98644.61 rows=24 width=41)"
"              Workers Planned: 2"
"              ->  Sort  (cost=97641.79..97641.81 rows=10 width=41)"
"                    Sort Key: c.city"
"                    ->  Partial HashAggregate  (cost=97641.50..97641.62 rows=10 width=41)"
"                          Group Key: c.city"
"                          ->  Parallel Hash Join  (cost=21569.00..95572.26 rows=413848 width=15)"
"                                Hash Cond: (o.customer_id = c.customer_id)"
"                                ->  Parallel Seq Scan on orders o  (cost=0.00..72916.90 rows=413848 width=14)"
"                                      Filter: ((order_date >= '2023-01-01 00:00:00+00'::timestamp with time zone) AND (order_date < '2024-01-01 00:00:00+00'::timestamp with time zone))"
"                                ->  Parallel Hash  (cost=16360.67..16360.67 rows=416667 width=17)"
"                                      ->  Parallel Seq Scan on customer c  (cost=0.00..16360.67 rows=416667 width=17)"
```

## explain analyze
```
"Sort  (cost=98723.76..98723.78 rows=10 width=41) (actual time=3085.667..3093.618 rows=10.00 loops=1)"
"  Sort Key: (sum(o.total_amount)) DESC"
"  Sort Method: quicksort  Memory: 25kB"
"  Buffers: shared hit=1144 read=52732"
"  ->  Finalize GroupAggregate  (cost=98720.49..98723.59 rows=10 width=41) (actual time=3085.567..3093.568 rows=10.00 loops=1)"
"        Group Key: c.city"
"        Buffers: shared hit=1144 read=52732"
"        ->  Gather Merge  (cost=98720.49..98723.29 rows=24 width=41) (actual time=3085.554..3093.527 rows=30.00 loops=1)"
"              Workers Planned: 2"
"              Workers Launched: 2"
"              Buffers: shared hit=1144 read=52732"
"              ->  Sort  (cost=97720.47..97720.49 rows=10 width=41) (actual time=3071.384..3071.396 rows=10.00 loops=3)"
"                    Sort Key: c.city"
"                    Sort Method: quicksort  Memory: 25kB"
"                    Buffers: shared hit=1144 read=52732"
"                    Worker 0:  Sort Method: quicksort  Memory: 25kB"
"                    Worker 1:  Sort Method: quicksort  Memory: 25kB"
"                    ->  Partial HashAggregate  (cost=97720.18..97720.30 rows=10 width=41) (actual time=3071.340..3071.354 rows=10.00 loops=3)"
"                          Group Key: c.city"
"                          Batches: 1  Memory Usage: 32kB"
"                          Buffers: shared hit=1128 read=52732"
"                          Worker 0:  Batches: 1  Memory Usage: 32kB"
"                          Worker 1:  Batches: 1  Memory Usage: 32kB"
"                          ->  Parallel Hash Join  (cost=21568.00..95598.92 rows=424252 width=15) (actual time=975.215..2612.901 rows=333785.00 loops=3)"
"                                Hash Cond: (o.customer_id = c.customer_id)"
"                                Buffers: shared hit=1128 read=52732"
"                                ->  Parallel Seq Scan on orders o  (cost=0.00..72917.25 rows=424252 width=14) (actual time=0.257..666.389 rows=333785.00 loops=3)"
"                                      Filter: ((order_date >= '2023-01-01 00:00:00+00'::timestamp with time zone) AND (order_date < '2024-01-01 00:00:00+00'::timestamp with time zone))"
"                                      Rows Removed by Filter: 1332882"
"                                      Buffers: shared hit=564 read=41103"
"                                ->  Parallel Hash  (cost=16359.67..16359.67 rows=416667 width=17) (actual time=972.426..972.428 rows=333333.33 loops=3)"
"                                      Buckets: 1048576  Batches: 1  Memory Usage: 59968kB"
"                                      Buffers: shared hit=564 read=11629"
"                                      ->  Parallel Seq Scan on customer c  (cost=0.00..16359.67 rows=416667 width=17) (actual time=0.385..434.284 rows=333333.33 loops=3)"
"                                            Buffers: shared hit=564 read=11629"
"Planning:"
"  Buffers: shared hit=8"
"Planning Time: 0.206 ms"
"Execution Time: 3093.692 ms"
```

# Q2

## gráfica explain

![alt text](./imagenes/imageQ2.png)

## explain
```
"Limit  (cost=346998.55..346998.58 rows=10 width=21)"
"  ->  Sort  (cost=346998.55..347248.55 rows=100000 width=21)"
"        Sort Key: (sum(oi.quantity)) DESC"
"        ->  Finalize HashAggregate  (cost=343837.59..344837.59 rows=100000 width=21)"
"              Group Key: p.name"
"              ->  Gather  (cost=317637.59..342637.59 rows=240000 width=21)"
"                    Workers Planned: 2"
"                    ->  Partial HashAggregate  (cost=316637.59..317637.59 rows=100000 width=21)"
"                          Group Key: p.name"
"                          ->  Hash Join  (cost=3096.00..274971.30 rows=8333258 width=17)"
"                                Hash Cond: (oi.product_id = p.product_id)"
"                                ->  Parallel Seq Scan on order_item oi  (cost=0.00..249999.58 rows=8333258 width=12)"
"                                ->  Hash  (cost=1846.00..1846.00 rows=100000 width=21)"
"                                      ->  Seq Scan on product p  (cost=0.00..1846.00 rows=100000 width=21)"
"JIT:"
"  Functions: 16"
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
```

## explain analyze
```
"Limit  (cost=347000.18..347000.21 rows=10 width=21) (actual time=38842.179..38842.299 rows=10.00 loops=1)"
"  Buffers: shared hit=1695 read=167513"
"  ->  Sort  (cost=347000.18..347250.18 rows=100000 width=21) (actual time=38728.539..38728.649 rows=10.00 loops=1)"
"        Sort Key: (sum(oi.quantity)) DESC"
"        Sort Method: top-N heapsort  Memory: 26kB"
"        Buffers: shared hit=1695 read=167513"
"        ->  Finalize HashAggregate  (cost=343839.22..344839.22 rows=100000 width=21) (actual time=38573.563..38652.428 rows=100000.00 loops=1)"
"              Group Key: p.name"
"              Batches: 1  Memory Usage: 9241kB"
"              Buffers: shared hit=1692 read=167513"
"              ->  Gather  (cost=317639.22..342639.22 rows=240000 width=21) (actual time=37888.155..38252.181 rows=300000.00 loops=1)"
"                    Workers Planned: 2"
"                    Workers Launched: 2"
"                    Buffers: shared hit=1692 read=167513"
"                    ->  Partial HashAggregate  (cost=316639.22..317639.22 rows=100000 width=21) (actual time=37889.015..38004.600 rows=100000.00 loops=3)"
"                          Group Key: p.name"
"                          Batches: 1  Memory Usage: 7193kB"
"                          Buffers: shared hit=1692 read=167513"
"                          Worker 0:  Batches: 1  Memory Usage: 9241kB"
"                          Worker 1:  Batches: 1  Memory Usage: 7193kB"
"                          ->  Hash Join  (cost=3096.00..274972.47 rows=8333350 width=17) (actual time=245.244..26277.534 rows=6666666.67 loops=3)"
"                                Hash Cond: (oi.product_id = p.product_id)"
"                                Buffers: shared hit=1692 read=167513"
"                                ->  Parallel Seq Scan on order_item oi  (cost=0.00..250000.50 rows=8333350 width=12) (actual time=2.105..7825.658 rows=6666666.67 loops=3)"
"                                      Buffers: shared read=166667"
"                                ->  Hash  (cost=1846.00..1846.00 rows=100000 width=21) (actual time=242.509..242.512 rows=100000.00 loops=3)"
"                                      Buckets: 131072  Batches: 1  Memory Usage: 6493kB"
"                                      Buffers: shared hit=1692 read=846"
"                                      ->  Seq Scan on product p  (cost=0.00..1846.00 rows=100000 width=21) (actual time=12.938..117.981 rows=100000.00 loops=3)"
"                                            Buffers: shared hit=1692 read=846"
"Planning:"
"  Buffers: shared hit=58 read=10 dirtied=2"
"Planning Time: 6.642 ms"
"JIT:"
"  Functions: 62"
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
"  Timing: Generation 7.102 ms (Deform 3.986 ms), Inlining 0.000 ms, Optimization 13.061 ms, Emission 139.046 ms, Total 159.209 ms"
"Execution Time: 39454.580 ms"
```

# Q3

## gráfica explain

![alt text](./imagenes/imageQ3.png)

## explain
```
"Limit  (cost=68708.70..68709.28 rows=5 width=34)"
"  ->  Gather Merge  (cost=68708.70..68709.28 rows=5 width=34)"
"        Workers Planned: 2"
"        ->  Sort  (cost=67708.68..67708.68 rows=2 width=34)"
"              Sort Key: order_date DESC"
"              ->  Parallel Seq Scan on orders  (cost=0.00..67708.67 rows=2 width=34)"
"                    Filter: (customer_id = 12345)"
```

## explain analyze
```
"Limit  (cost=68708.91..68709.49 rows=5 width=34) (actual time=219.050..222.638 rows=6.00 loops=1)"
"  Buffers: shared hit=1204 read=40539"
"  ->  Gather Merge  (cost=68708.91..68709.49 rows=5 width=34) (actual time=219.048..222.627 rows=6.00 loops=1)"
"        Workers Planned: 2"
"        Workers Launched: 2"
"        Buffers: shared hit=1204 read=40539"
"        ->  Sort  (cost=67708.88..67708.89 rows=2 width=34) (actual time=194.709..195.015 rows=2.00 loops=3)"
"              Sort Key: order_date DESC"
"              Sort Method: quicksort  Memory: 25kB"
"              Buffers: shared hit=1204 read=40539"
"              Worker 0:  Sort Method: quicksort  Memory: 25kB"
"              Worker 1:  Sort Method: quicksort  Memory: 25kB"
"              ->  Parallel Seq Scan on orders  (cost=0.00..67708.88 rows=2 width=34) (actual time=108.191..194.662 rows=2.00 loops=3)"
"                    Filter: (customer_id = 12345)"
"                    Rows Removed by Filter: 1666665"
"                    Buffers: shared hit=1128 read=40539"
"Planning:"
"  Buffers: shared hit=24"
"Planning Time: 0.131 ms"
"Execution Time: 222.671 ms"
```

# Q4

## gráfica explain

![alt text](./imagenes/imageQ4.png)

## explain
```
"Limit  (cost=113803.29..113805.62 rows=20 width=21)"
"  ->  Gather Merge  (cost=113803.29..338737.10 rows=1931318 width=21)"
"        Workers Planned: 2"
"        ->  Sort  (cost=112803.26..114815.05 rows=804716 width=21)"
"              Sort Key: o.total_amount DESC"
"              ->  Parallel Hash Join  (cost=21569.00..91390.06 rows=804716 width=21)"
"                    Hash Cond: (o.customer_id = c.customer_id)"
"                    ->  Parallel Seq Scan on orders o  (cost=0.00..67708.67 rows=804716 width=14)"
"                          Filter: (total_amount > '500'::numeric)"
"                    ->  Parallel Hash  (cost=16360.67..16360.67 rows=416667 width=23)"
"                          ->  Parallel Seq Scan on customer c  (cost=0.00..16360.67 rows=416667 width=23)"
"JIT:"
"  Functions: 14"
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
```

## explain analyze
```
"Limit  (cost=113895.90..113898.23 rows=20 width=21) (actual time=5146.532..5159.002 rows=20.00 loops=1)"
"  Buffers: shared hit=2834 read=51040"
"  ->  Gather Merge  (cost=113895.90..339722.77 rows=1938986 width=21) (actual time=5140.455..5152.904 rows=20.00 loops=1)"
"        Workers Planned: 2"
"        Workers Launched: 2"
"        Buffers: shared hit=2834 read=51040"
"        ->  Sort  (cost=112895.88..114915.66 rows=807911 width=21) (actual time=5109.975..5109.994 rows=19.00 loops=3)"
"              Sort Key: o.total_amount DESC"
"              Sort Method: top-N heapsort  Memory: 27kB"
"              Buffers: shared hit=2834 read=51040"
"              Worker 0:  Sort Method: top-N heapsort  Memory: 27kB"
"              Worker 1:  Sort Method: top-N heapsort  Memory: 27kB"
"              ->  Parallel Hash Join  (cost=21568.00..91397.66 rows=807911 width=21) (actual time=984.970..4116.004 rows=646219.67 loops=3)"
"                    Hash Cond: (o.customer_id = c.customer_id)"
"                    Buffers: shared hit=2820 read=51040"
"                    ->  Parallel Seq Scan on orders o  (cost=0.00..67708.88 rows=807911 width=14) (actual time=0.230..1198.985 rows=646219.67 loops=3)"
"                          Filter: (total_amount > '500'::numeric)"
"                          Rows Removed by Filter: 1020447"
"                          Buffers: shared hit=1692 read=39975"
"                    ->  Parallel Hash  (cost=16359.67..16359.67 rows=416667 width=23) (actual time=982.126..982.129 rows=333333.33 loops=3)"
"                          Buckets: 1048576  Batches: 1  Memory Usage: 63040kB"
"                          Buffers: shared hit=1128 read=11065"
"                          ->  Parallel Seq Scan on customer c  (cost=0.00..16359.67 rows=416667 width=23) (actual time=10.339..467.941 rows=333333.33 loops=3)"
"                                Buffers: shared hit=1128 read=11065"
"Planning:"
"  Buffers: shared hit=15 dirtied=1"
"Planning Time: 0.202 ms"
"JIT:"
"  Functions: 40"
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
"  Timing: Generation 1.520 ms (Deform 0.695 ms), Inlining 0.000 ms, Optimization 0.878 ms, Emission 33.101 ms, Total 35.499 ms"
"Execution Time: 5159.550 ms"
```

# Q5

## gráfica explain

![alt text](./imagenes/imageQ5.png)

## explain
```
"Finalize Aggregate  (cost=79207.48..79207.49 rows=1 width=8)"
"  ->  Gather  (cost=79207.26..79207.47 rows=2 width=8)"
"        Workers Planned: 2"
"        ->  Partial Aggregate  (cost=78207.26..78207.27 rows=1 width=8)"
"              ->  Parallel Seq Scan on orders  (cost=0.00..78125.33 rows=32772 width=0)"
"                    Filter: (order_date >= (now() - '30 days'::interval))"
```

## explain analyze
```
"Finalize Aggregate  (cost=79210.07..79210.08 rows=1 width=8) (actual time=534.742..539.913 rows=1.00 loops=1)"
"  Buffers: shared hit=2256 read=39411"
"  ->  Gather  (cost=79209.86..79210.07 rows=2 width=8) (actual time=534.627..539.891 rows=3.00 loops=1)"
"        Workers Planned: 2"
"        Workers Launched: 2"
"        Buffers: shared hit=2256 read=39411"
"        ->  Partial Aggregate  (cost=78209.86..78209.87 rows=1 width=8) (actual time=510.918..510.921 rows=1.00 loops=3)"
"              Buffers: shared hit=2256 read=39411"
"              ->  Parallel Seq Scan on orders  (cost=0.00..78125.62 rows=33694 width=0) (actual time=0.599..472.602 rows=27177.67 loops=3)"
"                    Filter: (order_date >= (now() - '30 days'::interval))"
"                    Rows Removed by Filter: 1639489"
"                    Buffers: shared hit=2256 read=39411"
"Planning:"
"  Buffers: shared hit=3"
"Planning Time: 0.071 ms"
"Execution Time: 539.944 ms"
```
# Q6

## gráfica explain

![alt text](./imagenes/imageQ6.png)

## explain
```
"Limit  (cost=68708.91..68709.49 rows=5 width=14)"
"  ->  Gather Merge  (cost=68708.91..68709.49 rows=5 width=14)"
"        Workers Planned: 2"
"        ->  Sort  (cost=67708.88..67708.89 rows=2 width=14)"
"              Sort Key: total_amount DESC"
"              ->  Parallel Seq Scan on orders  (cost=0.00..67708.88 rows=2 width=14)"
"                    Filter: (customer_id = 9876)"
```

## explain analyze
```
"Limit  (cost=68708.91..68709.49 rows=5 width=14) (actual time=212.654..220.321 rows=4.00 loops=1)"
"  Buffers: shared hit=2894 read=38847"
"  ->  Gather Merge  (cost=68708.91..68709.49 rows=5 width=14) (actual time=212.650..220.312 rows=4.00 loops=1)"
"        Workers Planned: 2"
"        Workers Launched: 2"
"        Buffers: shared hit=2894 read=38847"
"        ->  Sort  (cost=67708.88..67708.89 rows=2 width=14) (actual time=189.425..189.427 rows=1.33 loops=3)"
"              Sort Key: total_amount DESC"
"              Sort Method: quicksort  Memory: 25kB"
"              Buffers: shared hit=2894 read=38847"
"              Worker 0:  Sort Method: quicksort  Memory: 25kB"
"              Worker 1:  Sort Method: quicksort  Memory: 25kB"
"              ->  Parallel Seq Scan on orders  (cost=0.00..67708.88 rows=2 width=14) (actual time=111.558..189.291 rows=1.33 loops=3)"
"                    Filter: (customer_id = 9876)"
"                    Rows Removed by Filter: 1666665"
"                    Buffers: shared hit=2820 read=38847"
"Planning Time: 0.067 ms"
"Execution Time: 220.367 ms"
```
