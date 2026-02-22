import pandas as pd
import matplotlib.pyplot as plt
import os

# Paths
base_path = r"Proyecto1\docs\resultados"
no_index_path = os.path.join(base_path, "queries-base.csv")
index_path = os.path.join(base_path, "queries-after-index.csv")
output_path = os.path.join(base_path, "comparison_queries_index.png")

# Load CSVs
no_index_df = pd.read_csv(no_index_path)
index_df = pd.read_csv(index_path)

# Remove TRY column if present
if "Try" in no_index_df.columns:
    no_index_df = no_index_df.drop(columns=["Try"])

if "Try" in index_df.columns:
    index_df = index_df.drop(columns=["Try"])

# Calculate means
no_index_mean = no_index_df.mean()
index_mean = index_df.mean()

# Combine results
comparison = pd.DataFrame({
    "No Index": no_index_mean,
    "Index": index_mean
})

print("Mean execution times:")
print(comparison)

# Plot
comparison.plot(kind="bar")
plt.title("Query Performance: No Index vs Index")
plt.ylabel("Mean Time")
plt.xlabel("Query")
plt.xticks(rotation=0)
plt.tight_layout()

# Save figure
plt.savefig(output_path, dpi=300)

print(f"Graph saved at: {output_path}")

plt.show()