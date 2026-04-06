INSERT INTO posts (user_id, contenido, fecha)
SELECT 
    (random()*10000)::int, 
    'Post #' || generate_series,
    NOW() - (random() * interval '30 days')
FROM generate_series(1, 50000);


