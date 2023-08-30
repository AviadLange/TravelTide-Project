""" This script segments the users into 5 clusters,
       based only on their metrics without any further information nor instructions.
       (Unsupervised Machine Learning).
       I did give it much more metrics then these I used for my self segmentation
       (Filtered_data.csv). Data creation: 'Machine Learning Code.sql', file attached."""

import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import silhouette_score

def data_segmentation(df, columns, clusters, iterations):
       # Creates alternative database which contains only the relevant fields.
       temp_df = df[columns]

       # Swaps the Null values with 0
       no_null_df = temp_df.fillna(0)

       # Scales the values from the database.
       data_scaler = StandardScaler()
       data_scaled = data_scaler.fit_transform(no_null_df)

       # Converts the scaled data into a pandas DataFrame.
       scaled_df = pd.DataFrame(data_scaled, columns=fields)

       # Initializes and trains the K Means model.
       # Sets the 'random_state' and ensures I'll get the same result every time.
       kmeans = KMeans(n_clusters=clusters, random_state=iterations)
       kmeans.fit(scaled_df)

       # Sets the cluster's labels
       cluster_labels = kmeans.labels_

       # Calculates the silhouette score to assess clustering quality.
       # https://en.wikipedia.org/wiki/Silhouette_(clustering).
       silhouette_avg = silhouette_score(scaled_df, cluster_labels)

       # Adds the labels to the original DataFrame.
       df['clusters'] = cluster_labels

       return df, silhouette_avg

data = pd.read_csv('/Users/aviad87/מסמכים/לימודים/מאסטרסקול/Projects/TravelTide Project/Filtered_data.csv')

# Selects only the numeric fields from the database.
fields = ['bags', 'trips_booked', 'avg_hotel_nights', 'flights_booked', 'return_booked', 'hotels_booked',
       'packages_booked', 'cancellations', 'f_discount', 'h_discount', 'total_sessions',
        'avg_room_price', 'avg_flight_price', 'avg_flight_discount', 'avg_room_discount',
        'f_discount_per', 'h_discount_per', 'avg_clicks', 'session_in_seconds', 'avg_distance',
       'trips_ratio', 'trips_per_click', 'clicks_per_session', 'cancellations_ratio',
        'flights_ratio', 'hotels_ratio', 'packages_per_session', 'f_discounted_price',
        'h_discounted_price', 'return_ratio', 'f_discount_ratio', 'h_discount_ratio',
       'package_per_trip', 'bags_per_flight', 'price_per_km', 'discount_per_km']

# Basically the number of segments.
number_of_clusters = 5  # Equal to the number of perks

# The number of iteration over the data. different value here will result in different distribution per cluster.
num_iterations = 42  # I read that's a commonly used value, but it has no deeper significance :)

# Executes the 'data_segmentation' function.
result_df, silhouette_avg = data_segmentation(data, fields, number_of_clusters, num_iterations)

# Prints the count of users in each cluster.
# Visualization: https://public.tableau.com/app/profile/aviad.lange/viz/TravelTideProject/SegmentationwithUnsupervisedMachineLearning
print(result_df['clusters'].value_counts())

result_df.to_csv('/Users/aviad87/מסמכים/לימודים/מאסטרסקול/Projects/TravelTide Project/machine_learning.csv', index=False)