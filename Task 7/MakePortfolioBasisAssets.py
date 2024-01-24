# Load libraries #
import pandas as pd
import numpy as np
from tqdm import tqdm
from dateutil.relativedelta import *
from pandas.tseries.offsets import *    
import datetime as datetime
import os
tqdm.pandas()
pd.options.mode.chained_assignment = None  

def portfolio_construction(      database_type    = 'trace'        ,
                                 sample_type      = 'bbw'          ,
                                 weighting_scheme = 'vw'           ,
                                 return_type      = 'excess_rf'    ,                                 
                                 export           = True           ,
                                 file_dir         = ''                ):
    
    if database_type == 'wrds':     
        df = pd.read_hdf( os.path.join(file_dir , 
                'wrds_2002_2021.h5') )\
             .reset_index()                       
        export_path   = 'portfolios_wrds'
        base_dir  = file_dir
        
    elif database_type == 'trace':
        df = pd.read_hdf( os.path.join(file_dir , 
                'trace_2002_2023.h5') )\
             .reset_index()   
        df['cs_lag']  =\
             df.groupby("cusip")['bond_credit_spread_dur'].shift(1)                    
        export_path   = 'portfolios'
        base_dir  = file_dir
                                 
    # Weighting scheme  
    if weighting_scheme == 'vw':
        W = 'bond_amount_out'
    elif weighting_scheme == 'ew':
        df['const'] = 1
        W = 'const'
            
    # Remove bonds with less than 1-Year to maturity
    df = df[df.tmt > 1.0]
    
    # Lag credit spreads here -- contiguous returns #
      
    # Return Type
    if return_type == 'excess_rf':
        yy = 'exretn_t+1'
        df = df[~df[yy].isnull()]
        R  = 'bond_ret'
    elif return_type == 'duration_adj':
        yy = 'exretnc_dur_t+1'
        df = df[~df[yy].isnull()]      
        R  = 'exretnc_dur'  
    elif return_type == 'maturity_adj':
        yy = 'exretnc_t+1'
        df = df[~df[yy].isnull()]      
        R  = 'exretnc' 
            
    # Ratings #
    RAT = 'spr_mr_fill'
    

    #### Credit Spreads 10 portfolios ####
    dfCS = df
    dfCS = dfCS[~dfCS.cs_lag.isnull()]
    dfCS['cs']  = dfCS.groupby("cusip")['cs_lag'].progress_apply(\
                        lambda x: x.rolling(window = 12).mean())
    dfCS = dfCS[~dfCS.cs.isnull()]

    dfCS['csQ']    = dfCS.groupby(by = ['date'])[  'cs'     ]\
        .apply( lambda x: pd.qcut(x,10,labels=False,duplicates='drop')+1)    

    dfCS['value-weights'] = dfCS.groupby([ 'date','csQ' ])[W]\
        .apply( lambda x: x/np.nansum(x) )

    sorts = dfCS.groupby(['date','csQ'])[yy,'value-weights']\
        .apply( lambda x: np.nansum( x[yy] * x['value-weights']) ).\
            to_frame()
    sorts.columns = ['retn']

    panelB  = sorts.pivot_table( index = ['csQ'],
                                values = 'retn', 
                                aggfunc="mean" ) * 100

    sorts  = sorts.pivot_table( index = ['date'],
                               columns = ['csQ'],
                               values = "retn")
    sorts.index = sorts.index + MonthEnd(1)

    idx = sorts.index
    sorts = pd.DataFrame(np.array(sorts) , index = idx)
    sorts.columns = sorts.columns + 1
        
    # Rename columns #
    credit_spread_10 = sorts
    credit_spread_10.columns = ['credit_spread_' + str(col) for col in\
                                credit_spread_10.columns.to_list()]

    #### Time-to-Maturity 5 ####
    dfST = df
    dfST = dfST[~dfST.tmt.isnull()]

    dfST['sizeQ']    = dfST.groupby(by = ['date'])[  'tmt'     ]\
        .apply( lambda x: pd.qcut(x,5,labels=False,duplicates='drop')+1)    

    dfST['value-weights'] = dfST.groupby([ 'date','sizeQ' ])[W]\
        .apply( lambda x: x/np.nansum(x) )

    sorts = dfST.groupby(['date','sizeQ'])[yy,'value-weights']\
        .apply( lambda x: np.nansum( x[yy] * x['value-weights']) ).\
            to_frame()
    sorts.columns = ['retn']

    panelB  = sorts.pivot_table( index = ['sizeQ'],
                                values = 'retn', 
                                aggfunc="mean" ) * 100

    sorts  = sorts.pivot_table( index = ['date'],
                               columns = ['sizeQ'],
                               values = "retn")
    sorts.index = sorts.index + MonthEnd(1)

    idx = sorts.index
    sorts = pd.DataFrame(np.array(sorts) , index = idx)
    sorts.columns = sorts.columns + 1
    
    maturity_5 = sorts
    maturity_5.columns = ['maturity_' + str(col) for col in\
                                maturity_5.columns.to_list()]

    #### Rating 5 ####
    dfST = df
    dfST = dfST[~dfST.spr_mr_fill.isnull()]

    dfST['sizeQ']    = dfST.groupby(by = ['date'])[  'spr_mr_fill'     ]\
        .apply( lambda x: pd.qcut(x,5,labels=False,duplicates='drop')+1)    

    dfST['value-weights'] = dfST.groupby([ 'date','sizeQ' ])[W]\
        .apply( lambda x: x/np.nansum(x) )

    sorts = dfST.groupby(['date','sizeQ'])[yy,'value-weights']\
        .apply( lambda x: np.nansum( x[yy] * x['value-weights']) ).\
            to_frame()
    sorts.columns = ['retn']

    panelB  = sorts.pivot_table( index = ['sizeQ'],
                                values = 'retn', 
                                aggfunc="mean" ) * 100

    sorts  = sorts.pivot_table( index = ['date'],
                               columns = ['sizeQ'],
                               values = "retn")
    sorts.index = sorts.index + MonthEnd(1)

    idx = sorts.index
    sorts = pd.DataFrame(np.array(sorts) , index = idx)
    sorts.columns = sorts.columns + 1
    
    rating_5 = sorts
    rating_5.columns = ['rating_' + str(col) for col in\
                                rating_5.columns.to_list()]

    #### Industry 12 ####
    dfi = df
    dfi = dfi[~dfi.ind_num_12.isnull()]

    # Industry 12
    x = 'ind_num_12'
    dfi['value-weights'] = dfi.groupby([ 'date',
                                        x ])[W]\
        .apply( lambda x: x/np.nansum(x) )

    sorts = dfi.groupby(['date',x])[yy,'value-weights']\
        .apply( lambda x: np.nansum( x[yy] * x['value-weights']) )\
            .to_frame()
    sorts.columns = ['retn']

    sorts17  = sorts.pivot_table( index = ['date'],columns = [x], values = "retn")
    sorts17.index = sorts17.index + MonthEnd(1)
    
    industry_12 = sorts17
    industry_12.columns = ['industry_' + str(col) for col in\
                                industry_12.columns.to_list()]
    

    #### Combine the combinations ####
    combi  = industry_12.merge(credit_spread_10, how = "inner", left_index = True, right_index = True)
    combi  = combi.merge(      maturity_5 , how = "inner", left_index = True, right_index = True)
    combi  = combi.merge(      rating_5 , how = "inner", left_index = True, right_index = True)
    
    if sample_type == 'bbw':
        combi = combi[combi.index<="2022-12-31"]
            # [combi.index<="2021-12-31"]
        combi = combi[combi.index>="2004-08-31"] 
   
    #* ************************************** */
    #* Export                                 */
    #* ************************************** */
   
    if export:
        if return_type == 'excess_rf':
            export_path = str(export_path) + str('.csv')
            combi.to_csv(  os.path.join(base_dir, export_path)  )
                        
        elif return_type == 'duration_adj':
            export_path = str(export_path) + str('_dur.csv')
            combi.to_csv(  os.path.join(base_dir, export_path)    )
               
    return   combi  
        