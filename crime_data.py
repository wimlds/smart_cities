"""
author: Henry Lin
Date: 2017/03/14
"""


import sys
import pandas as pd

"""
    put links into data link.csv
    python crime_data.py link.csv output_name
    output: single csv file with all the information
"""


def crime_frame(file):
    links = [line.strip() for line in open(file, 'r')]
    frame_list = []
    
    for file_link in links:

        df = pd.read_excel(file_link, 
                       header=[2], 
                       index_col=[0,1], 
                       sheetname="Sheet1")
        df = df.reset_index()
        df.columns = df.columns.astype(str)
        check_pct = [i for i in range(0,124)]
        check_pct.append("DOC")
        df = df[df["PCT"].isin(check_pct)].fillna(0)
        frame_list.append(df)

    whole_frame = pd.concat(frame_list)

    return whole_frame

def main(input, output):
    whole_frame = crime_frame(input)
    whole_frame.to_csv(output, index=False)


if __name__ == '__main__':
    main(sys.argv[1],sys.argv[2])