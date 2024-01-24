##########################################
# Create Table A1                        #
# Alexander Dickerson                    #
# Email: a.dickerson@warwick.ac.uk       #
# Date: January 2023                     #
# Updated:  July 2023                    #
# Version:  1.0.1                        #
##########################################

'''
Overview
-------------
This Python script creats Table A.1
 
Requirements
-------------
Data output from "MakeBondDailyMetrics.py" including
    (1) AI_Yield_BBW_TRACE_Enhanced_Dick_Nielsen.csv.gzip

Package versions 
-------------
pandas v1.4.4
numpy v1.21.5
tqdm v4.64.1
datetime v3.9.13
zipfile v3.9.13
'''

#* ************************************** */
#* Libraries                              */
#* ************************************** */ 
import pandas as pd
import numpy as np
from tqdm import tqdm
import datetime as dt
from dateutil.relativedelta import *
from pandas.tseries.offsets import *
from datetime import datetime, timedelta
import urllib.request
import zipfile
tqdm.pandas()

#* ************************************** */
#* Read daily prices and AI               */
#* ************************************** */ 
# We start off by loading the daily price, AI volume and yield file
# This is the output from the script file: "MakeBondDailyMetrics.py"
PriceC = \
pd.read_csv\
    ('daily_dat.csv.gzip', 
                     compression = "gzip")

# Convert columns to uppercase (for now)
PriceC.columns = PriceC.columns.str.upper()

#* ************************************** */
#* Set Indices                            */
#* ************************************** */ 
PriceC         = PriceC.set_index(['CUSIP_ID', 'TRD_EXCTN_DT'])
PriceC = PriceC.reset_index()
PriceC['TRD_EXCTN_DT'] = pd.to_datetime( PriceC['TRD_EXCTN_DT']  )

#* ************************************** */
#* Remove any missing Price values        */
#* ************************************** */ 
# Remove any vales for which we do not have valid price data
PriceC = PriceC[~PriceC.PRCLEAN.isnull()]

#* ************************************** */
#* Create month begin / end column        */
#* ************************************** */ 
PriceC['month_begin']=np.where( PriceC['TRD_EXCTN_DT'].dt.day != 1,
                             PriceC['TRD_EXCTN_DT'] + pd.offsets.MonthBegin(-1),
                             PriceC['TRD_EXCTN_DT'])
PriceC['month_end']    = PriceC['month_begin'] + pd.offsets.MonthEnd(0)


#* ************************************** */
# Page 623-624 of BBWs published paper in JFE:
# where the end (beginning) of month refers to the last (first) 
# five trading days within each month
# "trading" days is assumed to be business days
# Hence, use USFederalHolidayCalendar to account for this and BDay
#* ************************************** */

# Set U.S. Trading day calendars #
from pandas.tseries.holiday import USFederalHolidayCalendar
from pandas.tseries.offsets import CustomBusinessDay
calendar = USFederalHolidayCalendar()

start_date = '01JUL2002'
end_date   = '31DEC2022'
holidays = calendar.holidays(start_date, end_date)
holidays
bday_us = CustomBusinessDay(holidays=holidays)

####
PriceC_Hold = PriceC.copy()
####
              # All d+1, i.e., must trade on "last" bus-day, dz = 1 (0+1) #
for dz in list([9,6,4,2,1]):
        print(dz)
        PriceC = PriceC_Hold.copy()

        #* ************************************** */
        #* n-1 = 4 Businnes Days                  */
        #* ************************************** */ 
        # Use n-1 days: if the first business day is 1st March, then the 5th
        # is t+4 = 5th March, and so on
        dtiB = pd.DataFrame( pd.Series(PriceC['month_begin'].unique()).sort_values() )
        dtiB['cut_off_begin'] = dtiB + dz * bday_us
        dtiB.columns = ['month_begin','cut_off_begin']
        
        dtiE = pd.DataFrame( pd.Series(PriceC['month_end'].unique()).sort_values() )
        dtiE['cut_off_begin'] = dtiE - dz * bday_us
        dtiE.columns = ['month_end','cut_off_end']
        
        #* ************************************** */
        #* Merge eligible dates to PriceC         */
        #* ************************************** */   
        PriceC = PriceC.merge(dtiB,       left_on      = ['month_begin'], 
                                          right_on     = ['month_begin'],
                                          how          = "left")
        
        PriceC = PriceC.merge(dtiE,       left_on      = ['month_end'], 
                                          right_on     = ['month_end'],
                                          how          = "left")
        
        #* ************************************** */
        #* Filter dates in PriceC         */
        #* ************************************** */ 
        mask = (PriceC['TRD_EXCTN_DT'] <= PriceC['cut_off_begin'] ) |\
               (PriceC['TRD_EXCTN_DT'] >= PriceC['cut_off_end'] )
        PriceC = PriceC[mask]
        
        #* ************************************** */
        #* Set min, max dates                     */
        #* ************************************** */ 
        PriceC['month_year'] = pd.to_datetime(PriceC['TRD_EXCTN_DT']).dt.to_period('M')
        PriceC['min_date']   =\
            PriceC.groupby(['CUSIP_ID',
                            'month_year'])['TRD_EXCTN_DT'].transform("min")
        PriceC['max_date']   =\
            PriceC.groupby(['CUSIP_ID',
                            'month_year'])['TRD_EXCTN_DT'].transform("max")
        
        #* ************************************** */
        #* Keep the obs. that are closest to      */
        #* the beginning or end of the month      */
        #* ************************************** */ 
        PriceC = PriceC[ ((  PriceC['TRD_EXCTN_DT'] == PriceC['min_date'])        \
                     &    (  PriceC['TRD_EXCTN_DT'] <= PriceC['cut_off_begin'] )) \
                     |   ((  PriceC['TRD_EXCTN_DT'] == PriceC['max_date'])        \
                     &    (  PriceC['TRD_EXCTN_DT'] >= PriceC['cut_off_end'] ))    ]                                
        
                         
        #* ************************************** */
        #* Dummies for return type                */
        #* ************************************** */ 
        
        PriceC['month_begin_dummy'] =  ( PriceC['TRD_EXCTN_DT']\
                                        <= PriceC['cut_off_begin'] ) * 1           
        PriceC['month_end_dummy']   =  ( PriceC['TRD_EXCTN_DT']\
                                        >= PriceC['cut_off_end'] )   * 1           
        
        #* ************************************** */
        #* Set date reference for end of month ret*/
        #* ************************************** */     
            
        PriceC['date_end'] = np.where( PriceC['month_end_dummy']   == 1,
                                      PriceC['TRD_EXCTN_DT'] + pd.offsets.MonthEnd(0),
                                      PriceC['TRD_EXCTN_DT']   )       
        
        #* ************************************** */
        #* Count Obs in a month                   */
        #* There will always be 2 for month begin */ 
        #* And always 1 for month end             */
        #* ************************************** */ 
        
        PriceC['count'] = PriceC.groupby(['CUSIP_ID',
                                          'month_year'])['PR'].transform('count')
        
        Month_End   = PriceC[ PriceC['month_end_dummy'] == 1 ]
        Month_Begin = PriceC[ PriceC['count'] == 2 ]
        
        #* ************************************** */
        #* Return Type #1: Last 5-Days            */
        #* ************************************** */ 
        Month_End = Month_End.set_index('date_end')
        Month_End = Month_End[['PR', 'PRCLEAN', 'PRFULL','ACCLAST', 'ACCPMT', 
                               'ACCALL','CUSIP_ID','YTM','QVOLUME', 'DVOLUME',
                               'MOD_DUR','CONVEXITY']]
        
        Month_End        = Month_End.reset_index()
        
        #* ************************************** */
        #* Compute days between 2-Month-End Trades*/
        #* ************************************** */ 
        Month_End['n']   = ( Month_End['date_end'] -\
                             Month_End.groupby( "CUSIP_ID")['date_end'].shift(1) ) /\
                             np.timedelta64( 1, 'D' ) 
        
        #* ************************************** */
        #* Compute Returns                        */
        #* ************************************** */ 
        Month_End['ret']      = ( Month_End['PR'] /\
                                 Month_End.groupby(['CUSIP_ID'])['PR'].shift(1)) - 1
        Month_End['retf'] =  ( Month_End['PR'] + Month_End['ACCALL'] -\
                               Month_End.groupby(['CUSIP_ID'])['PR'].shift(1)\
                             - Month_End.groupby(['CUSIP_ID'])['ACCALL'].shift(1)) /\
                               Month_End.groupby(['CUSIP_ID'])['PR'].shift(1)
        Month_End['retff'] =  (Month_End['PR'] + Month_End['ACCALL'] -\
                               Month_End.groupby(['CUSIP_ID'])['PR'].shift(1)\
                             - Month_End.groupby(['CUSIP_ID'])['ACCALL'].shift(1)) /\
                               Month_End.groupby(['CUSIP_ID'])['PRFULL'].shift(1)
        
        #* ************************************** */
        #* Force contiguous return                */
        #* ************************************** */ 
        Month_End = Month_End[Month_End.n <= 31]
        Month_End.columns
        Month_End   = Month_End[['CUSIP_ID','date_end','ret','retf','retff','PR','YTM',
                                 'QVOLUME', 'DVOLUME','MOD_DUR', 'CONVEXITY']]
        Month_End.columns = ['cusip','date','ret','retf','retff','pr','ytm', 
                             'qvolume', 'dvolume','mod_dur','convexity']
        Month_End['dummy']   = 'END'
        Month_End = Month_End.dropna()
        
        #* ************************************** */
        #* Return Type #2: First/Last 5-Days      */
        #* ************************************** */ 
        Month_Begin['ret']  = ( Month_Begin['PR'] /\
                                Month_Begin.groupby(['CUSIP_ID'])['PR'].shift(1)) - 1
        Month_Begin['retf'] =  (Month_Begin['PR'] + Month_Begin['ACCALL'] -\
                                Month_Begin.groupby(['CUSIP_ID'])['PR'].shift(1)-\
                                Month_Begin.groupby(['CUSIP_ID'])['ACCALL'].shift(1)) /\
                                Month_Begin.groupby(['CUSIP_ID'])['PR'].shift(1)
        
        Month_Begin['retff'] =  (Month_Begin['PR'] + Month_Begin['ACCALL'] -\
                                 Month_Begin.groupby(['CUSIP_ID'])['PR'].shift(1)-\
                                 Month_Begin.groupby(['CUSIP_ID'])['ACCALL'].shift(1))/\
                                 Month_Begin.groupby(['CUSIP_ID'])['PRFULL'].shift(1)
        
        Month_Begin['day']     = Month_Begin['TRD_EXCTN_DT'].dt.day
        Month_Begin['day_max'] = Month_Begin.groupby('month_year')['day'].transform("max")
        
        Month_Begin = Month_Begin[Month_Begin.day > 15]
       
        Month_Begin = Month_Begin[['CUSIP_ID','date_end','ret','retf','retff','PR',
                                   'YTM', 'QVOLUME', 'DVOLUME','MOD_DUR', 'CONVEXITY']]
        Month_Begin.columns = ['cusip','date','ret','retf','retff','pr',
                               'ytm', 'qvolume', 'dvolume','mod_dur','convexity']
        Month_Begin['dummy'] = 'BEGIN'
        Month_Begin = Month_Begin.dropna()
        
        # Dummies for END and BEGIN
        Month_End['ret_type']   = "END"
        Month_Begin['ret_type'] = "BEGIN"
        
        
        #* ************************************** */
        #* Concatenate Return Types               */
        #* ************************************** */ 
        df = pd.concat([Month_End, Month_Begin], axis = 0)
        
        df = df.set_index(['date','cusip'])
        df = df.sort_index(level = 'cusip')
        
        #* ************************************** */
        #* Check for duplicates 
        #* Keep Month End then Begin, if End is
        #* Missing
        #* ************************************** */ 
        df['duplicated_begin_end'] = df.index.duplicated(False) * 1
        df['DS_Dup']  = ((  df['duplicated_begin_end'] == 1) &\
                         (df['dummy'] == 'BEGIN'  )) * 1 
        df = df[ df['DS_Dup'] == 0 ]
        
        # Trim returns here #
        # This removes returns from incorrect data #
        # This is standard, compact data to the interval [1,1],
        # to avoid crazy outliers -- see WRDS Bond returns Module
        # https://wrds-www.wharton.upenn.edu/documents/248/WRDS_Corporate_Bond_Database_Manual.pdf
        
        df['retff'] = np.where(df['retff'] >  1, 1, df['retff'])
        df['retff'] = np.where(df['retff'] < -1,-1, df['retff'])
        
        df['retf'] = np.where(df['retf'] >  1, 1, df['retf'])
        df['retf'] = np.where(df['retf'] < -1,-1, df['retf'])
        
        #* ************************************** */
        #* Pick Columns                           */
        #* ************************************** */ 
        # NOTE: retff is the TOTAL BOND RETURN as in th BBW Paper
        # Equation (1)
        # We do not need the coupon, we use quantmod to
        # compute the cumulative coupon which is how the return is computed
        df = df[['retff', 'ytm', 'qvolume', 'dvolume','ret_type','mod_dur','convexity']]
        df.columns = ['bond_ret', 'bond_yield', 'par_volume', 'dol_volume','ret_type',
                      'mod_dur','convexity']
        
        df = df[['bond_ret']]
        df = df.reset_index()
        df = df[df['date'] <= "2016-12-31"]
        df.rename(columns={'bond_ret':'bond_ret'+ str("_")+str(dz)}, 
                  inplace=True)

       
        if dz == 9:           
            dfret = df
        else:
            dfret = dfret.merge(df,
                                how      ="left",
                                left_on  = ['date','cusip'],
                                right_on = ['date','cusip'])
###############################################################################            

#* ************************************** */
#* Connect to WRDS                        */
#* ************************************** */  
import wrds
db = wrds.Connection(wrds_username='phd22jm')

#* ************************************** */
#* Download Mergent File                  */
#* ************************************** */  
fisd_issuer = db.raw_sql("""SELECT issuer_id,country_domicile,sic_code                
                  FROM fisd.fisd_mergedissuer 
                  """)

fisd_issue = db.raw_sql("""SELECT complete_cusip, issue_id,
                  issuer_id, foreign_currency,
                  coupon_type,coupon,convertible,
                  asset_backed,rule_144a,
                  bond_type,private_placement,
                  interest_frequency,dated_date,
                  day_count_basis,offering_date,
                  offering_amt, maturity
                  FROM fisd.fisd_mergedissue  
                  """)
                  
fisd = pd.merge(fisd_issue, fisd_issuer, on = ['issuer_id'], how = "left")          
fisd.rename(columns={'complete_cusip':'cusip'}, inplace=True)
fisd = fisd[['cusip', 'issuer_id','issue_id','offering_amt']]


df   = dfret.merge(fisd,
                how      = "left",
                left_on  = ['cusip'],
                right_on =['cusip'])

#* ************************************** */
#* Amount Out                             */
#* ************************************** */  

#### Monthly amount outstanding ####
#### (new way of merging)       ####
amt = pd.read_hdf('amount_outstanding.h5')
amt = amt[['date','cusip','action_amount']]
amt.columns = ['date','cusip','action_amount']

df  = df.sort_values(['date' ,'cusip'])
amt = amt.sort_values(['date','cusip'])

df  = pd.merge_asof(df,
              amt, 
              on= "date", 
              by= "cusip")  

df['action_amount']    = np.where(df['action_amount'].isnull(),
                               0,df['action_amount'] )

df['bond_amount_out'] =df['offering_amt'] - df['action_amount']
df['bond_amount_out'] = np.where(df['bond_amount_out'] < 0 , 0,
                                  df['bond_amount_out'])

# Forward fill here, for the seperate TRACE dataset analysis #
df['bond_amount_out'] = df.groupby("cusip")['bond_amount_out'].ffill()

# Where missing, set to offering_amt
df['bond_amount_out'] = np.where(df['bond_amount_out'].isnull(),
                                 df['offering_amt'], df['bond_amount_out'])

#* ************************************** */
#* Ratings                                */
#* ************************************** */  
#### Monthly ratings            ####
#### (new way of merging)       ####
mdr = pd.read_hdf('moody_ratings.h5')
mdr['date'] = mdr['rating_date']+MonthEnd(0)
spr = pd.read_hdf('sp_ratings.h5')
spr['date'] = spr['rating_date']+MonthEnd(0)

df  = df.sort_values(['date','issue_id'])
spr = spr.sort_values(['date','issue_id'])
mdr = mdr.sort_values(['date','issue_id'])

df['issue_id']  = df['issue_id'] .astype(int)
spr['issue_id'] = spr['issue_id'].astype(int)
mdr['issue_id'] = mdr['issue_id'].astype(int)

spr = spr[spr['spr'] <= 21]
mdr = mdr[mdr['mr']  <= 21]
 
df  = pd.merge_asof(df,
              spr[['issue_id','date','spr']], 
              on= "date", 
              by= "issue_id")   

df  = pd.merge_asof(df,
              mdr[['issue_id','date','mr']], 
              on= "date", 
              by= "issue_id")   

df['spr_mr_fill']  = np.where(
                               df['spr'].isnull(),
                               df['mr'] , 
                               df['spr']
                               )

df['mr_spr_fill']  = np.where(
                               df['mr'].isnull(),
                               df['spr'] , 
                               df['mr']
                               )

dfret = df[~df['spr_mr_fill'].isnull()]
dfret = dfret[~dfret['bond_amount_out'].isnull()]

cols = ['bond_ret_1', 'bond_ret_2', 'bond_ret_4',
        'bond_ret_6', 'bond_ret_9' ]


TableA1 = pd.DataFrame()

for c in cols:
    print(c)
    dfh         = dfret[~dfret[c].isnull()]
    TotalBonds  = pd.Series( dfh['cusip'].unique() )
    TotalFirms  = pd.Series( dfh['issuer_id'].unique() )
    nBonds      = dfh.groupby("date")['cusip'].count()
    nBonds.mean()

    dfe = dfh.set_index(['date','issuer_id'])
    dfe = dfe[~dfe.index.duplicated()]

    nFirms     = dfe.groupby("date")['cusip'].count()
    nFirms.mean()
    
    Rows = pd.DataFrame( list([len(dfh),
                 len(TotalBonds),
                 len(TotalFirms),
                 np.round(nBonds.mean(),0),
                 np.round(nFirms.mean(),0)]) ).T
    
    TableA1 = pd.concat([TableA1,
                         Rows], axis = 0)
    
TableA1 .columns = ['Total Obs.',
                   'Total bonds',
                   'Total firms',
                   'Average bonds in month',
                   'Average firms in month' ]
  
TableA1.index = [  'TRACE n = 1',
                   'TRACE n = 3', 
                   'TRACE n = 5',
                   'TRACE n = 7',
                   'TRACE n = 10',                  
                   ]     
###############################################################################   
print(TableA1)