//+------------------------------------------------------------------+
//|                                                 HistoryMaker.mqh |
//|                              2020 (c) Kharkiv Technologies Corp. |
//|                                              https://google.com/ |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Kharkiv Technologies Corp."
#property link      "https://google.com/"
#property version   "1.00"
class HistoryMaker
  {
private:

public:
                     //vars
                     datetime rewrite_time;
                     
                     //methods
                     HistoryMaker();
                    ~HistoryMaker();
                    datetime TimeJump(int multiplier);
                    bool Make(string from_symbl, string to_symbl);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
HistoryMaker::HistoryMaker()
  {
   rewrite_time = D'2001.1.1 0:00';
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
HistoryMaker::~HistoryMaker()
  {
  }
//+------------------------------------------------------------------+

bool HistoryMaker::Make(string from_symbl, string to_symbl)
{
   MqlTick ticks[];
   
   int copied = -1;
   
   if ((copied = CopyTicks(from_symbl, ticks,COPY_TICKS_ALL,0,1000000)) < 1) 
   {
      Print("History Maker -- could not copy history ticks ERROR# " + (string)GetLastError());
      return false;
   }
   
   datetime previous_dt = NULL;
   
   for (int i=0; i < copied; i++)
   {
      MqlDateTime dt;
      TimeToStruct(ticks[i].time, dt);
      
      if (previous_dt == NULL)                           //set datetime on 1st iteration
      {
         previous_dt = ticks[i].time;
      }
      
      int sec_dif = (int)(ticks[i].time - previous_dt);  //get time difference between ticks in second 
      
      if (sec_dif > 0)
      {
         TimeJump(sec_dif);
         
         previous_dt = ticks[i].time;                    //refresh previous datetime
      }
      
      long msc = ticks[i].time_msc - ticks[i].time *1000;//calc difference between ticks in ms
      
      previous_dt = ticks[i].time;                       //set previous tick time for the next iteration
      
      ticks[i].time = rewrite_time;                      //set new sec. time for current tick
      ticks[i].time_msc = rewrite_time * 1000 + msc;     //set new ms. time for current tick
      
      
   }
   
   //calculating is done
   if (!SymbolSelect(to_symbl,true) || !CustomTicksAdd(to_symbl, ticks))
   {
      
      Print("History Maker -- SymbolSelect/CustomTicksAdd false result -- ERROR# " + (string)GetLastError());
      return false;
   }
   
   return true;
}

datetime HistoryMaker::TimeJump(int multiplier)
{     
   rewrite_time += 60 * multiplier;
   
   return rewrite_time;
}