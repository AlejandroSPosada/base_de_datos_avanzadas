import random
from faker import Faker

fake = Faker()

NUM_USERS = 10000
NUM_POSTS = 50000

def generate_users():
users = []
for i in range(1, NUM_USERS + 1):
users.append({
"id": i,
"username": fake.user_name(),
"email": fake.email(),
"created_at": fake.date_time_this_decade()
})
return users

def generate_posts():
posts = []
for i in range(1, NUM_POSTS + 1):
user_id = random.randint(1, NUM_USERS)
posts.append({
"id": i,
"user_id": user_id,
"content": fake.text(max_nb_chars=200),
"created_at": fake.date_time_this_decade()
})
return posts

def save_to_sql(users, posts):
with open("generated_data.sql", "w") as f:
# Users
for u in users:
f.write(
f"INSERT INTO users (id, username, email, created_at) VALUES "
f"({u['id']}, '{u['username']}', '{u['email']}', '{u['created_at']}');\n"
)

```
    # Posts
    for p in posts:
        f.write(
            f"INSERT INTO posts (id, user_id, content, created_at) VALUES "
            f"({p['id']}, {p['user_id']}, '{p['content']}', '{p['created_at']}');\n"
        )
```

if **name** == "**main**":
users = generate_users()
posts = generate_posts()
save_to_sql(users, posts)

```
print("Datos generados en generated_data.sql")
```
