"""The following script calculates the most fitting perk for each TravelTide user.
    The reasoning of my choices is explained in an elaborated way on the PDF report attached.
    Data creation: 'Relevant fields only.sql'."""

import pandas as pd
import math as ma
import numpy as np

df = pd.read_csv('/Users/aviad87/מסמכים/לימודים/מאסטרסקול/Projects/TravelTide Project/Relevant_Filtered_data.csv')

"""Potential issues avoided in the following 5 functions:
    # Multiplication by 0. This for example, could have lowered the 'score' for a user
    with two high metrics, and third NULL/0 one. That's why I used the 'conditioning structure'.
    # Decreasing value for product of two ratio values (0-1). In order to deal with that,
    I took the square of the number of numbers being multiplied, e.g. sqrt3(x*y*z)."""

# This function ranks the users for their fit for the free meal perk based mainly on their demographics.
# This is the only perk I had to manually grade, as its parameters do not have real numeric value.
# For more information see the PDF report attached.
def free_hotel_meal(row):
    age = row['group_age']  # Contains four age groups
    kids = row['has_children']  # Boolean
    nights = row['avg_scaled_nights']
    # Assigns a score to every group, from 0 to 0.875 (7/8, as there are 8 combinations).
    ranking = {'kids_17': 0.875, 'kids_26': 0.75, 'kids_41': 0.625, 'kids_55': 0.5,
            'no_kids_17': 0, 'no_kids_26': 0.125, 'no_kids_41': 0.25, 'no_kids_55': 0.375}
    if pd.isna(nights) or nights == 0:
        if kids:
            if age == '17-25':
                return ranking['kids_17']
            elif age == '26-40':
                return ranking['kids_26']
            elif age == '41-55':
                return ranking['kids_41']
            else:  # 55+
                return ranking['kids_55']
        else:  # No children
            if age == '17-25':
                return ranking['no_kids_17']
            elif age == '26-40':
                return ranking['no_kids_26']
            elif age == '41-55':
                return ranking['no_kids_41']
            else:  # 55+
                return ranking['no_kids_55']
    else:  # Booked at least 1 night
        if kids:
            if age == '17-25':
                return ma.sqrt(nights*ranking['kids_17'])
            elif age == '26-40':
                return ma.sqrt(nights*ranking['kids_26'])
            elif age == '41-55':
                return ma.sqrt(nights*ranking['kids_41'])
            else:  # 55+
                return ma.sqrt(nights*ranking['kids_55'])
        else:  # No children
            if age == '17-25':
                return ma.sqrt(nights*ranking['no_kids_17'])
            elif age == '26-40':
                return ma.sqrt(nights*ranking['no_kids_26'])
            elif age == '41-55':
                return ma.sqrt(nights*ranking['no_kids_41'])
            else:  # 55+
                return ma.sqrt(nights*ranking['no_kids_55'])

""" This function ranks the users based on past behavior,
    in order to find potential fit for the free checked bag perk."""
def free_checked_bag(row):
    bags = row['scaled_bags_per_flight']
    distance = row['avg_scaled_distance_km']
    return_flight = row['return_ratio']

    if pd.isna(bags) or bags == 0:
        if pd.isna(return_flight) or return_flight == 0:
            if pd.isna(distance) or distance == 0:
                return 0
            else:
                return distance
        else:
            if pd.isna(distance) or distance == 0:
                return return_flight
            else:
                return ma.sqrt(return_flight * distance)
    else:
        if pd.isna(return_flight) or return_flight == 0:
            if pd.isna(distance) or distance == 0:
                return bags
            else:
                return ma.sqrt(distance * bags)
        else:
            if pd.isna(distance) or distance == 0:
                return ma.sqrt(return_flight * bags)
            else:
                return (distance * bags * return_flight)**(1/3)

""" This function ranks the users based on past behavior,
    in order to find potential fit for the no cancellation fee perk."""
def no_cancellation_fee(row):
    # All three fields have no Null values.
    cancellation_ratio = row['cancellations_ratio']
    session_duration = row['avg_scaled_session_in_seconds']
    clicks = row['scaled_clicks_per_session']

    if clicks == 0:
        if cancellation_ratio == 0:
            if session_duration == 0:
                return 0
            else:
                return session_duration
        else:
            if session_duration == 0:
                return cancellation_ratio
            else:
                return ma.sqrt(cancellation_ratio * session_duration)
    else:
        if cancellation_ratio == 0:
            if session_duration == 0:
                return clicks
            else:
                return ma.sqrt(session_duration * clicks)
        else:
            if session_duration == 0:
                return ma.sqrt(cancellation_ratio * clicks)
            else:
                return (session_duration * clicks * cancellation_ratio)**(1/3)

""" This function ranks the users based on past behavior, and bargaining character,
    in order to find potential fit for the exclusive discounts perk."""
def exclusive_discounts(row):
    price_per_km = 1 - row['scaled_price_per_km']  # To reverse the score, as I want it higher for lower prices.
    avg_flight_discount = row['f_discount_per']
    discounted_flight_proportion = row['f_discount_ratio']  # Has no Null values

    if pd.isna(price_per_km) or price_per_km == 0:
        if pd.isna(avg_flight_discount) or avg_flight_discount == 0:
            if discounted_flight_proportion == 0:
                return 0
            else:
                return discounted_flight_proportion
        else:
            if discounted_flight_proportion == 0:
                return avg_flight_discount
            else:
                return ma.sqrt(avg_flight_discount * discounted_flight_proportion)
    else:
        if pd.isna(avg_flight_discount) or avg_flight_discount == 0:
            if discounted_flight_proportion == 0:
                return price_per_km
            else:
                return ma.sqrt(discounted_flight_proportion * price_per_km)
        else:
            if discounted_flight_proportion == 0:
                return ma.sqrt(avg_flight_discount * price_per_km)
            else:
                return (discounted_flight_proportion * price_per_km * avg_flight_discount)**(1/3)

""" This function ranks the users based on past behavior,
    in order to find potential fit for the 1 night free hotel with flight perk."""
def one_night_free_hotel_with_flight(row):
    has_flight = row['flights_ratio']  # Has no Null values
    package = row['packages_per_session']  # Has no Null values
    room_price = row['avg_scaled_room_price']
    # Eliminates first users who didn't book any flight.
    if has_flight == 0:
        return 0
    else:
        if package == 0:
            if pd.isna(room_price) or room_price == 0:
                return 0
            else:
                return room_price
        else:
            if pd.isna(room_price) or room_price == 0:
                return package
            else:
                return ma.sqrt(room_price * package)

# Executes the functions and inserts them into the database.
df['free_hotel_meal'] = df.apply(free_hotel_meal, axis=1)
df['free_checked_bag'] = df.apply(free_checked_bag, axis=1)
df['no_cancellation_fee'] = df.apply(no_cancellation_fee, axis=1)
df['exclusive_discounts'] = df.apply(exclusive_discounts, axis=1)
df['1_night_free_hotel_with_flight'] = df.apply(one_night_free_hotel_with_flight, axis=1)

# Ranks every perk field from 1 to n records.
df['free_hotel_meal_ranking'] = np.argsort(np.argsort(df['free_hotel_meal'])) + 1
df['free_checked_bag_ranking'] = np.argsort(np.argsort(df['free_checked_bag'])) + 1
df['no_cancellation_fee_ranking'] = np.argsort(np.argsort(df['no_cancellation_fee'])) + 1
df['exclusive_discounts_ranking'] = np.argsort(np.argsort(df['exclusive_discounts'])) + 1
df['1_night_free_hotel_with_flight_ranking'] = np.argsort(np.argsort(df['1_night_free_hotel_with_flight'])) + 1

# The newly created perks' fields.
ranked_perks = df[['free_hotel_meal_ranking', 'free_checked_bag_ranking',
        'no_cancellation_fee_ranking', 'exclusive_discounts_ranking',
        '1_night_free_hotel_with_flight_ranking']]

# Creates a field which holds the value of the highest perk for each row.
df['max'] = ranked_perks.max(axis=1)

# Compares every perk's score to the max score.
conditions = [(df['max'] == df['free_hotel_meal_ranking']), (df['max'] == df['free_checked_bag_ranking']),
    (df['max'] == df['no_cancellation_fee_ranking']), (df['max'] == df['exclusive_discounts_ranking']),
    (df['max'] == df['1_night_free_hotel_with_flight_ranking'])]

# Perks' names that will apper as values in the database.
segments = ['Free hotel meal', 'Free checked bag', 'No cancellation fee',
    'Exclusive discounts', '1 night free hotel with flight']

# Picks up the perk with the highest score for every user.
df['segmentation'] = np.select(conditions, segments, default=0)

df = df.drop('max', axis=1)  # This field by itself doesn't contribute anything.

# Prints the count of users in each segment.
# Visualization: https://public.tableau.com/app/profile/aviad.lange/viz/TravelTideProject/SegmentationwithUnsupervisedMachineLearning
print(df['segmentation'].value_counts())

# Downloads the final database.
df.to_csv('/Users/aviad87/מסמכים/לימודים/מאסטרסקול/Projects/TravelTide Project/Final_segmentation.csv', index=False)

# Filters the database to include only relevant fields (used in Tableau).
short_df = df[['user_id', 'free_hotel_meal', 'free_checked_bag', 'no_cancellation_fee',
    'exclusive_discounts', '1_night_free_hotel_with_flight', 'segmentation']]

# Downloads the narrowed down version of the final database.
short_df.to_csv('/Users/aviad87/מסמכים/לימודים/מאסטרסקול/Projects/TravelTide Project/segmentation_short_version.csv', index=False)

# Filters for only user_id and segment.
super_short_df = df[['user_id', 'segmentation']]

# Downloads the file for submission.
super_short_df.to_csv('/Users/aviad87/מסמכים/לימודים/מאסטרסקול/Projects/TravelTide Project/segmentation_for_submittion.csv', index=False)