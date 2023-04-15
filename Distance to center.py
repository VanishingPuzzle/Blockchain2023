import pandas as pd
import numpy as np

# create example dataframe with x,y coordinates
df = pd.DataFrame({'coordinates': [[-17.0, 40.0], [10.0, -8.0], [5.0, 12.0]]})

# define a function to calculate euclidean distance
def euclidean_distance(coord):
    return np.sqrt(coord[0]**2 + coord[1]**2)

# create new columns for x and y, and calculate their values from coordinates
df['x'] = df['coordinates'].apply(lambda coord: coord[0])
df['y'] = df['coordinates'].apply(lambda coord: coord[1])

# calculate distance to origin and create a new column
df['distance_to_origin'] = df['coordinates'].apply(euclidean_distance)

# drop the original coordinates column
df = df.drop('coordinates', axis=1)

print(df)
