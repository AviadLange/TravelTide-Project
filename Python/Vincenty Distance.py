""" The following script calculates the distance between two coordinates
    according to the 'Vincenty Formula'. It then, compares the result to the
    same calculation already built in the 'Geopy' package.
    Finally, I wrote a functions that adjusts the calculations to a DataFrame
    and used 'TravelTide' data as an example."""

import math
import pandas as pd  # Relevant only for the last section

# This functions finds the distance between two coordinates, based on 'Vincenty Formula'.
# It takes two lists as arguments, each should contain two numeric values.
"""I honestly don't really get the whole mathematical process, but I transformed the formula I found online
    into a python script"""
def vincenty_distance(coord1, coord2):
    # Data for WGS 84 ellipsoid  (World Geodetic System 1984)
    a = 6378137.0  # Equatorial radius
    b = 6356752.3142  # Polar radius
    f = (a - b) / a  # Flattening

    # Sets the variable according to the coordinates provided.
    U1 = math.atan((1 - f) * math.tan(math.radians(coord1[0])))
    U2 = math.atan((1 - f) * math.tan(math.radians(coord2[0])))
    L = math.radians(coord2[1] - coord1[1])
    Lambda = L  # Sets the value of lambda to L
    sin_u1 = math.sin(U1)
    cos_u1 = math.cos(U1)
    sin_u2 = math.sin(U2)
    cos_u2 = math.cos(U2)

    tol = 10 ** -12  # Tolerance level for convergence
    iterations = 0
    for i in range(200):  # 200 iterations to get an accurate result
        iterations += 1

        # Mathematical trigonometric calculations to find the estimate of the angular separation ('σ').
        cos_lambda = math.cos(Lambda)
        sin_lambda = math.sin(Lambda)
        sin_sigma = math.sqrt((cos_u2 * sin_lambda) ** 2 + (cos_u1 * sin_u2 - sin_u1 * cos_u2 * cos_lambda) ** 2)
        cos_sigma = sin_u1 * sin_u2 + cos_u1 * cos_u2 * cos_lambda
        sigma = math.atan2(sin_sigma, cos_sigma)
        sin_alpha = (cos_u1 * cos_u2 * sin_lambda) / sin_sigma
        cos_sq_alpha = 1 - sin_alpha ** 2
        cos2_sigma_m = cos_sigma - ((2 * sin_u1 * sin_u2) / cos_sq_alpha)
        C = (f / 16) * cos_sq_alpha * (4 + f * (4 - 3 * cos_sq_alpha))
        Lambda_prev = Lambda
        Lambda = L + (1 - C) * f * sin_alpha * (
                    sigma + C * sin_sigma * (cos2_sigma_m + C * cos_sigma * (-1 + 2 * cos2_sigma_m ** 2)))

        # Determines if the value of Lambda became stable within a certain tolerance level.
        diff = abs(Lambda_prev - Lambda)
        if diff <= tol:
            break

    # This section calculates additional terms and values needed for the final distance calculation.
    u_sq = cos_sq_alpha * ((a ** 2 - b ** 2) / b ** 2)
    A = 1 + (u_sq / 16384) * (4096 + u_sq * (-768 + u_sq * (320 - 175 * u_sq)))
    B = (u_sq / 1024) * (256 + u_sq * (-128 + u_sq * (74 - 47 * u_sq)))
    delta_sig = B * sin_sigma * (cos2_sigma_m + 0.25 * B * (
                cos_sigma * (-1 + 2 * cos2_sigma_m ** 2) - (1 / 6) * B * cos2_sigma_m * (
                -3 + 4 * sin_sigma ** 2) * (-3 + 4 * cos2_sigma_m ** 2)))

    m = b * A * (sigma - delta_sig)  # The distance in meters

    return m

###############################################################################
# Finding the distance with 'geopy' package takes only one line of code!
# Try and compare the results for the two options.
from geopy.distance import geodesic

# Example
coord1, from_city = [52.5200, 13.4050], 'Berlin, Germany'
coord2, to_city = [48.8566, 2.3522], 'Paris, France'

# Calls the functions.
my_distance = vincenty_distance(coord1, coord2).__round__(2)
geopy_distance = geodesic(coord1, coord2).meters.__round__(2)

# Checks whether the results are the same.
if my_distance == geopy_distance:
    print("I did it! The distance between ", from_city, " and ", to_city, " is:", my_distance, "meters")
else:
    print('It seems the function is not accurate enough:(')
    print("According to my function the distance between ", from_city, " and ", to_city, " is:", my_distance, "meters,")
    print("but according to Geopy the distance between ", from_city, " and ", to_city, " is:", geopy_distance, "meters.")

##########################################################################################################
# This section applies the 'vincenty_distance()' function on a given database.
# It uses 'Coordinates and Locations.csv'.

# This function takes a database and the coordinates' fields, and returns the vincenty distance for each record.
def vincenty_from_df(data, points):
    # calls vincenty_distance(arg1, arg2) function on every row.
    def calculate_distance(row):
        return vincenty_distance([row[points[0]], row[points[1]]],
            [row[points[2]], row[points[3]]]).__round__(2)

    # Adds the values calculated to the df as 'vincenty_distance'.
    data['vincenty_distance'] = data.apply(calculate_distance, axis=1)
    return data

# Loads the data based on 'TravelTide' database.
df = pd.read_csv('/Users/aviad87/מסמכים/לימודים/מאסטרסקול/Projects/TravelTide Project/Coordinates and Locations.csv')

# The desired fields from the df.
coordinates = ['home_airport_lat', 'home_airport_lon',
    'destination_airport_lat', 'destination_airport_lon']

# Calls the function with data from 'TravelTide' database.
final_df = (vincenty_from_df(df, coordinates))

final_df.to_csv('/Users/aviad87/מסמכים/לימודים/מאסטרסקול/Projects/TravelTide Project/Distances.csv', index=False)