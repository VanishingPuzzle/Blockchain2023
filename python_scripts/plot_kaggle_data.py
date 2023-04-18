import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors

# Load the data from CSV file
data = pd.read_csv("/content/processed_decentraland.csv")

# Get the 25th, 50th, and 75th percentiles of the prices
price_perc = np.percentile(data["land_price"], [25, 50, 75])

# Define the colors for each group
colors = ["#ffffb2", "#fecc5c", "#fd8d3c", "#e31a1c"]

# Define a color map that maps each price to a color
cmap = mcolors.ListedColormap(colors)

# Calculate the distance between grid points
x_diff = np.diff(np.unique(data["mean_longitude"])).min()
y_diff = np.diff(np.unique(data["mean_latitude"])).min()

# Create a scatter plot of the data with the color map
fig, ax = plt.subplots(figsize=(8, 8))
ax.set_facecolor('#121212')
scatter = ax.scatter(data["mean_longitude"], data["mean_latitude"], c=data["land_price"], cmap=cmap, s=1, alpha=0.8, vmin=price_perc[0], vmax=price_perc[-1])

# Add a color bar and label
cbar = plt.colorbar(scatter)
cbar.ax.set_ylabel("Land Price (USD)", fontsize=14)

# Set the axis labels and title
ax.set_xlabel("Longitude", fontsize=14)
ax.set_ylabel("Latitude", fontsize=14)
ax.set_title("Land Price Distribution", fontsize=16)

# Show the plot
plt.show()
