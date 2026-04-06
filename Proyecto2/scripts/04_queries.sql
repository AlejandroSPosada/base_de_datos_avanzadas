EXPLAIN ANALYZE
SELECT * FROM posts WHERE user_id = 500;

-- ----------------

EXPLAIN ANALYZE
SELECT * FROM posts
WHERE user_id IN (10, 200, 3500, 4000, 9999)
ORDER BY fecha DESC
LIMIT 20;

-- -----------------

EXPLAIN ANALYZE
SELECT user_id, COUNT(*)
FROM posts
GROUP BY user_id
ORDER BY COUNT(*) DESC
LIMIT 10;

-- -----------------

-- Sin partición
EXPLAIN ANALYZE
SELECT * FROM posts_no_partition WHERE user_id = 500;
