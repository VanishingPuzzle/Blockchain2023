import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

# Load the Decentraland dataset
data = pd.read_csv('../data/processed_decentraland.csv')

data.drop(columns=['bids_count'], inplace=True)
data.head()
def euclidean_distance(x, y):
    return np.sqrt(x**2 + y**2)

# calculate distance to origin and create a new column
data['distance_to_origin'] = data.apply(lambda row: euclidean_distance(row['mean_latitude'], row['mean_longitude']), axis=1)

data.head()

# Define the features (characteristics) and the target (price)
features = ['parcels_count', 'distance_to_origin', 'road', 'plaza', 'district']
target = 'price'

# Define the weights and baskets for each feature
weights = {
    'parcels_count': 0.3,
    'distance_to_origin': 0.2,
    'road': 0.2,
    'plaza': 0.1,
    'district': 0.2
}

baskets = {
    'low': (0, 25),
    'medium': (25, 50),
    'high': (50, 75),
    'very_high': (75, 100)
}

# Define the scoring function for each feature
def score_size(x):
    if x < 500:
        return 0
    elif x < 1000:
        return 25
    elif x < 2000:
        return 50
    else:
        return 100

def score_distance(x):
    if x < 0.5:
        return 100
    elif x < 1:
        return 75
    elif x < 2:
        return 50
    else:
        return 25

# Apply the scoring function to each feature
data['score_parcels_count'] = data['parcels_count'].apply(score_size)
data['score_distance_to_origin'] = data['distance_to_origin'].apply(score_distance)
data['score_road'] = data['road'].apply(score_distance)
data['score_plaza'] = data['plaza'].apply(score_distance)
data['score_district'] = data['district'].apply(score_distance)

# Calculate the weighted score for each feature
for feature in features:
    data[f'weighted_score_{feature}'] = data[f'score_{feature}'] * weights[feature]

# Calculate the total score for each NFT LAND parcel
data['total_score'] = data[[f'weighted_score_{feature}' for feature in features]].sum(axis=1)

# Assign each NFT LAND parcel to a basket based on the total score
for basket, (lower_bound, upper_bound) in baskets.items():
    data.loc[(data['total_score'] >= lower_bound) & (data['total_score'] < upper_bound), 'basket'] = basket

# Calculate the floor price for each NFT LAND parcel in each basket
for basket in baskets:
    lower_bound, upper_bound = baskets[basket]
    data.loc[data['basket'] == basket, 'floor_price'] = (data.loc[data['basket'] == basket, 'total_score'] *
                                                         (lower_bound + upper_bound) / 2 * 1000)

# Display the floor price for a new NFT LAND parcel
new_parcel = {'parcels_count': 10, 'distance_to_origin': 2, 'road': 0.5, 'plaza': 1, 'district': 3}
scores = [score_size(new_parcel['parcels_count']),
          score_distance(new_parcel['distance_to_origin']),
          score_distance(new_parcel['road']),
          score_distance(new_parcel['plaza']),
          score_distance(new_parcel['district'])]
total_score = sum([score * weight for score, weight in zip(scores, weights.values())])
for basket, (lower_bound, upper_bound) in baskets.items():
    if lower_bound <= total_score < upper_bound:
        floor_price = total_score * (lower_bound + upper_bound) / 2 * 1000
        print(f"The floor price for the new NFT LAND parcel is: {floor_price:.2f} ETH in the {basket} basket.")
        break
