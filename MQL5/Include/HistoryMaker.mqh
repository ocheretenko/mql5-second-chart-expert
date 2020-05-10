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
                     datetime rewrite_time;
                     HistoryMaker();
                    ~HistoryMaker();
                    datetime NewTime();
                    datetime HistoryMaker::NewTime2(int diff);
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
   
   if ((copied = CopyTicks(from_symbl, ticks,COPY_TICKS_ALL,0,1000000)) < 1) return false;
   
   
   int previous_sec = -1;
   datetime previous_dt = 0;
   
   for (int i=0; i < copied; i++)
   {
      MqlDateTime dt;
      TimeToStruct(ticks[i].time, dt);
      
      if (previous_sec == -1) // if 1st iteration
      {
         previous_dt = ticks[i].time;
         previous_sec = dt.sec;
      }
      
      int sec_dif = (int)(ticks[i].time - previous_dt); //
      
      if (sec_dif > 0)
      {
         NewTime2(sec_dif);
         
         previous_dt = ticks[i].time;
         previous_sec = dt.sec;
         
      }
      
      long msc = ticks[i].time_msc - ticks[i].time *1000;
      
      previous_dt = ticks[i].time;
      
      ticks[i].time = rewrite_time; //+ dt.sec;
      ticks[i].time_msc = rewrite_time * 1000 + msc;
      
      
   }
   
   //calculating is done
   SymbolSelect(to_symbl,true);
   CustomTicksAdd(to_symbl, ticks);
   
   return true;
}

datetime HistoryMaker::NewTime2(int diff)
{     
   rewrite_time += 60 * diff;
   
   return rewrite_time;
}

datetime HistoryMaker::NewTime()
   {
      rewrite_time += 60;
      
      return rewrite_time;
   }