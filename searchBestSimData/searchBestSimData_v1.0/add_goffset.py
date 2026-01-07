#!/usr/bin/env python

from pathlib import Path
import argparse
import pandas as pd
from astropy.io import fits

def get_goffset_col_val(df_goffset, var_name, is_win=False):
    row_size = 16 if not is_win else 8
    val_dict= {}
    for g, df_sub in df_goffset.groupby('GOFFSET_GRADE'):
        val_dict[str(g)] = df_sub[var_name].to_numpy()
    if var_name[-3:] in ['EBL', 'EBH']:
        dtype = 'float32'
        out = val_dict['0'].astype(dtype)[:row_size]
    elif var_name[-5:] == 'PHCUT':
        dtype = 'int16'
        out = val_dict['0'].astype(dtype)[:row_size]
    else:
        dtype = 'float32'
        out = pd.DataFrame.from_dict(val_dict).astype(dtype)[['0', '2', '34', '6']].iloc[:row_size, :]
    return out

if __name__ == '__main__':
    # args
    parser = argparse.ArgumentParser(
        description='fill goffset params and create new caldb.')
    parser.add_argument('input_caldb_path', type=Path, help='input caldb path')
    parser.add_argument('output_caldb_path', type=Path, help='output caldb path')
    parser.add_argument('csv_path', type=Path, help='csv path')

    # paths
    args = parser.parse_args()
    caldb_path = args.input_caldb_path
    new_caldb_path = args.output_caldb_path
    csv_path = args.csv_path

    # csv and cols
    df_goffset = pd.read_csv(csv_path)
    goffset_cols = ['GOFFSET_AL0',
                    'GOFFSET_AL1',
                    'GOFFSET_AL2',
                    'GOFFSET_AL3',
                    'GOFFSET_AM0',
                    'GOFFSET_AM1',
                    'GOFFSET_AM2',
                    'GOFFSET_AM3',
                    'GOFFSET_AH0',
                    'GOFFSET_EBL',
                    'GOFFSET_EBH',
                    'GOFFSET_PHCUT']

    # fill values and write fits
    with fits.open(caldb_path) as hdulist:
        # HDU 1 (WINDOW1), 2 (WINDOW2)
        for i, is_win in zip((1, 2), (False, True)):
            data = hdulist[i].data
            for goffset_col in goffset_cols:
                data[goffset_col] = get_goffset_col_val(df_goffset, goffset_col, is_win=is_win)
        hdulist.writeto(new_caldb_path, overwrite=True, output_verify='fix', checksum=True)
        print(f'output: {new_caldb_path}')
