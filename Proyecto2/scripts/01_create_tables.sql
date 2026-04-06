CREATE TABLE posts (
    id SERIAL,
    user_id INT,
    contenido TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(user_id);
