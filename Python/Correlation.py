""" The following script visualize the correlation between the numeric fields,
    which stood as the parameters for the grading of each perk"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

df = pd.read_csv('/Users/aviad87/מסמכים/לימודים/מאסטרסקול/Projects/TravelTide Project/Relevant_Filtered_data.csv')

# Stores each numeric fields with its corresponding perk.
# 'Free Hotel Meal' has only 1 numeric field behind it, so doesn't need correlation test.
perks_and_fields = {'Free checked bag': ['scaled_bags_per_flight', 'avg_scaled_distance_km', 'return_ratio'],
    'No cancellation fee': ['cancellations_ratio', 'avg_scaled_session_in_seconds', 'scaled_clicks_per_session'],
    'Exclusive discount': ['scaled_price_per_km', 'f_discount_ratio', 'f_discount_per'],
    '1 night free hotel with flight': ['packages_per_session', 'avg_scaled_room_price']}

# Iterates over the perks_and_fields dictionary.
for perk, fields in perks_and_fields.items():
    # Extracts only the fields from the dictionary.
    data = df[fields]

    # Calculates the correlation between the fields.
    correlation_matrix = data.corr()

    # Creates a heatmap for every perk.
    plt.figure(figsize=(8, 6))
    sns.set(font_scale=0.8)
    sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', center=0, linewidths=0.5,
                xticklabels=fields, yticklabels=fields, vmin=-1, vmax=1)  # Customizes the heatmap

    plt.title(f"Pearson's Correlation Heatmap for '{perk}'", sns.set(font_scale=1.5))
    plt.show()

""" As the visualizations show, there is no strong enough correlation for all cases but one.
    Other then that one, The strongest correlation found is between
    'cancellations_ratio' and 'scaled_clicks_per_session' with a value of 0.057 (quite low).
    The one high correlation is between 'scaled_clicks_per_session' and 'avg_scaled_session_in_seconds'
    with a value of 0.94.
    This indicates that the use of only one of these fields, instead of both,
    would result in a very similar score for the 'No Cancellation Fee' field.
    Although it appears to be pointless to use both fields, it does not spoil the result,
    and that's why I left my segmentation code as is.
    It's just important to point that out."""