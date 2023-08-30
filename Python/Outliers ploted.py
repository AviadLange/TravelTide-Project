""" The following script visualize the outliers for five fields,
    which hold data in relatively large scale and range.
    This script uses a different database, that holds every session for the narrowed down users (Raw_data.csv).
    Database creation: 'Outliers Concern.sql', file attached.
    It also lacks the field with the session duration converted to an integer, so I created the field here first"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

df = pd.read_csv('/Users/aviad87/מסמכים/לימודים/מאסטרסקול/Projects/TravelTide Project/Raw_data.csv')

# This function converts the session_duration type from timestamp to numeric.
def duration_to_seconds(duration):
    parts = duration.split(":")
    hours = int(parts[0])
    minutes = int(parts[1])
    seconds, milliseconds = map(float, parts[2].split("."))

    # Add up the time parts as seconds.
    total_seconds = (hours*3600) + (minutes * 60) + seconds + (milliseconds/1000)
    return total_seconds

# Applies the conversion to a new column.
df['duration_in_seconds'] = df['session_duration'].apply(duration_to_seconds)

##########################################################################################
# From here on, the code plots 6 fields to histograms with the outliers pointed out.
fields = ['page_clicks', 'room_price', 'flight_price', 'distance', 'duration_in_seconds', 'nights']
xlabels = ['Page Clicks', 'Room Price', 'Flight Price', 'Distance', 'Session Duration', 'Hotel Nights']
positions = [[68, 8000], [440, 1000], [2500, 1800], [7800, 850], [1600, 7500], [12, 1250]]
bins = [70, 50, 100, 50, 100, 70]

# Iterates over the upper lists content.
for i in range(len(fields)):
    mean_price = np.mean(df[fields[i]])  # Finds the mean of the field
    std_dev = np.std(df[fields[i]])  # Finds the standard deviation of the field
    red_border = mean_price + (2 * std_dev)  # Defines the border's location.
    plt.hist(df[fields[i]], bins=bins[i], edgecolor='black')  # Creates the histogram
    plt.axvline(x=red_border, color='red', linestyle='dashed', linewidth=2)  # Border characterization
    plt.text(red_border, plt.ylim()[1] * 0.9, '2 STDEVs away', color='red',
             rotation='vertical', position=(positions[i]))  # Border's text characterization
    plt.xlabel(xlabels[i])
    plt.ylabel('Number of Users')
    plt.title(xlabels[i] + ' Distribution with Outliers Highlighted')
    plt.show()

""" As the visualizations show, there where outliers in every field
    (although very little for 'page_clicks' and 'duration_in_seconds').
    Therefore, the data I used for the segmentation filtered out these outliers. (Relevant_filtered_data.csv)"""