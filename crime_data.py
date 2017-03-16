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
        temp = file_link.split("/")[-1].strip().split("_by")[0]
        df = pd.read_excel(file_link, 
                       header=[2], 
                       index_col=[0,1], 
                       sheetname="Sheet1")
        df = df.reset_index()
        df.columns = df.columns.astype(str)
        check_pct = [i for i in range(0,124)]
        check_pct.append("DOC")
        df = df[df["PCT"].isin(check_pct)].fillna(0)
        df["file_type"] = temp
        frame_list.append(df)


    whole_frame = pd.concat(frame_list)
    whole_frame = whole_frame[whole_frame["PCT"] != "DOC"]
    whole_frame.PCT = whole_frame.PCT.astype(int)

    return whole_frame

def main(input, output):
    whole_frame = crime_frame(input)

    new_idx = []
    name = [s for s in whole_frame.CRIME.unique() if "TOTAL" not in s]
    total = [s for s in whole_frame.CRIME.unique() if "TOTAL" in s]
    name.extend(total)
    for prct in whole_frame.PCT.unique():
        for types in whole_frame.file_type.unique():
            for ct in name:
                new_idx.append((prct, types, ct))

    whole_frame.set_index(['PCT', "file_type", 'CRIME'], inplace=True)


    whole_frame.reindex(new_idx).dropna().to_excel(sys.argv[2]+".xls")
    whole_frame.reindex(new_idx).dropna().to_csv(sys.argv[2]+".csv")


if __name__ == '__main__':
    main(sys.argv[1],sys.argv[2])