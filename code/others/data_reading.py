import os
import pandas as pd
date_list = [201503, 201506, 201509, 201512, 201603, 201606, 201609, 201612, 201703, 201706, 201709, 201712, 201803, 201806, 201809, 201812, 201903, 201906, 201909, 201912]

## Create four patterns of columsn for datasets whose longest list elemenet is 153, 164, 175, and 186.
column_name = ['price', 'report_carrier', 'date', 'num_coupon', 'num_passenger', 
           'airport_city_code', 'dollar_id', 'city_market_id', 'airport_id', 'state_id', 
          'opeartin_carrier', 'coupon', 'ticketed_carrier', 'ticketed_carrier_coupon', 'fare_type',
          'distance', 'airport_city', 'trip', 'city_market_id2', 'airport_id2', 'state_id2',
              'opeartin_carrier_1', 'coupon_1', 'ticketed_carrier_1', 'ticketed_carrier_coupon_1', 'fare_type_1','distance_1', 'airport_city_1', 'trip_1', 'city_market_id2_1', 'airport_id2_1', 'state_id2_1',
              'opeartin_carrier_2', 'coupon_2', 'ticketed_carrier_2', 'ticketed_carrier_coupon_2', 'fare_type_2','distance_2', 'airport_city_2', 'trip_2', 'city_market_id2_2', 'airport_id2_2', 'state_id2_2',
              'opeartin_carrier_3', 'coupon_3', 'ticketed_carrier_3', 'ticketed_carrier_coupon_3', 'fare_type_3','distance_3', 'airport_city_3', 'trip_3', 'city_market_id2_3', 'airport_id2_3', 'state_id2_3',
              'opeartin_carrier_4', 'coupon_4', 'ticketed_carrier_4', 'ticketed_carrier_coupon_4', 'fare_type_4','distance_4', 'airport_city_4', 'trip_4', 'city_market_id2_4', 'airport_id2_4', 'state_id2_4',
              'opeartin_carrier_5', 'coupon_5', 'ticketed_carrier_5', 'ticketed_carrier_coupon_5', 'fare_type_5','distance_5', 'airport_city_5', 'trip_5', 'city_market_id2_5', 'airport_id2_5', 'state_id2_5',
              'opeartin_carrier_6', 'coupon_6', 'ticketed_carrier_6', 'ticketed_carrier_coupon_6', 'fare_type_6','distance_6', 'airport_city_6', 'trip_6', 'city_market_id2_6', 'airport_id2_6', 'state_id2_6',
              'opeartin_carrier_7', 'coupon_7', 'ticketed_carrier_7', 'ticketed_carrier_coupon_7', 'fare_type_7','distance_7', 'airport_city_7', 'trip_7', 'city_market_id2_7', 'airport_id2_7', 'state_id2_7',
              'opeartin_carrier_8', 'coupon_8', 'ticketed_carrier_8', 'ticketed_carrier_coupon_8', 'fare_type_8','distance_8', 'airport_city_8', 'trip_8', 'city_market_id2_8', 'airport_id2_8', 'state_id2_8',
              'opeartin_carrier_9', 'coupon_9', 'ticketed_carrier_9', 'ticketed_carrier_coupon_9', 'fare_type_9','distance_9', 'airport_city_9', 'trip_9', 'city_market_id2_9', 'airport_id2_9', 'state_id2_9',
              'opeartin_carrier_10', 'coupon_10', 'ticketed_carrier_10', 'ticketed_carrier_coupon_10', 'fare_type_10','distance_10', 'airport_city_10', 'trip_10', 'city_market_id2_10', 'airport_id2_10', 'state_id2_10',
              'opeartin_carrier_11', 'coupon_11', 'ticketed_carrier_11', 'ticketed_carrier_coupon_11', 'fare_type_11','distance_11', 'airport_city_11', 'trip_11', 'city_market_id2_11', 'airport_id2_11', 'state_id2_11',
              'opeartin_carrier_12', 'coupon_12', 'ticketed_carrier_12', 'ticketed_carrier_coupon_12', 'fare_type_12','distance_12', 'airport_city_12', 'trip_12', 'city_market_id2_12', 'airport_id2_12', 'state_id2_12']
column_name1 = column_name.copy()
column_name2 = column_name1 + ['opeartin_carrier_13', 'coupon_13', 'ticketed_carrier_13', 'ticketed_carrier_coupon_13', 'fare_type_13','distance_13', 'airport_city_13', 'trip_13', 'city_market_id2_13', 'airport_id2_13', 'state_id2_13']
column_name3 = column_name2 + ['opeartin_carrier_14', 'coupon_14', 'ticketed_carrier_14', 'ticketed_carrier_coupon_14', 'fare_type_14','distance_14', 'airport_city_14', 'trip_14', 'city_market_id2_14', 'airport_id2_14', 'state_id2_14']
column_name4 = column_name3 + ['opeartin_carrier_15', 'coupon_15', 'ticketed_carrier_15', 'ticketed_carrier_coupon_15', 'fare_type_15','distance_15', 'airport_city_15', 'trip_15', 'city_market_id2_15', 'airport_id2_15', 'state_id2_15']



date_list5 = [201806, 201809, 201812]
for i in date_list5:
    filename = 'db1b.public.' + str(i) + '.asc'
    filepath = os.path.join('/Users/tsukik/Downloads/data_public/asc/', filename)
    f = open(filepath, 'r')
    data = []
    for line in f:
        line = line.strip('\n')
        line = line.split('|')
        data.append(line)
    print(i, "dataframe creating!")
    df = pd.DataFrame(data)
    if df.shape[1] == 153:
        df.columns = column_name1
    elif df.shape[1] == 164:
        df.columns = column_name2 
    elif df.shape[1] == 175:
        df.columns = column_name3
    else: #186
        df.columns = column_name4
    dataset_name = 'public' + str(i) + '.dta'
    print(i, ".dta creating!")
    df.to_stata(os.path.join('/Users/tsukik/Downloads/data_public/dta/', dataset_name))
    print(i, ".dta downloaded!")



    date_list6 = [201903, 201906, 201909, 201912]
for i in date_list6:
    filename = 'db1b.public.' + str(i) + '.asc'
    filepath = os.path.join('/Users/tsukik/Downloads/data_public/asc/', filename)
    f = open(filepath, 'r')
    data = []
    for line in f:
        line = line.strip('\n')
        line = line.split('|')
        data.append(line)
    print(i, "dataframe creating!")
    df = pd.DataFrame(data)
    if df.shape[1] == 153:
        df.columns = column_name1
    elif df.shape[1] == 164:
        df.columns = column_name2
    elif df.shape[1] == 175:
        df.columns = column_name3
    else: #186
        df.columns = column_name4
    dataset_name = 'public' + str(i) + '.dta'
    print(i, ".dta creating!")
    df.to_stata(os.path.join('/Users/tsukik/Downloads/data_public/dta/', dataset_name))
    print(i, ".dta downloaded!")