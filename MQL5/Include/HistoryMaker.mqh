//+------------------------------------------------------------------+
//|                                                 HistoryMaker.mqh |
//|                                     2020 (c) Oleksii Ocheretenko |
//|                                          https://vk.com/war_k1ng |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Kharkiv Technologies Corp."
#property link      "https://google.com/"
#property version   "1.00"

#include <PeriodConvert.mqh>

class HistoryMaker
{
   private:

   public:
                     PeriodConvert converter;
                     
                     //methods
                     HistoryMaker();
                    ~HistoryMaker();
                    bool Make(string from_symbl, string to_symbl, bool tick_chart = false);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
HistoryMaker::HistoryMaker()
{
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
HistoryMaker::~HistoryMaker()
{
}
//+------------------------------------------------------------------+

bool HistoryMaker::Make(string from_symbl, string to_symbl, bool tick_chart = false)
{
   MqlTick ticks[];
   int copied = -1;
   
   if ((copied = CopyTicks(from_symbl, ticks,COPY_TICKS_ALL,0,1000000)) < 1) 
   {
      if (copied == 0)
         Print("History Maker -- could not copy history ticks -- 0 ticks copied");
      else
         Print("History Maker -- could not copy history ticks ERROR# " + (string)GetLastError());
         
      return false;
   }
   
   if (tick_chart)
      converter.HistoryTicksToMinutes(ticks, copied);
   else
      converter.HistorySecondsToMinutes(ticks, copied);
   
   if (!SymbolSelect(to_symbl,true) || !CustomTicksAdd(to_symbl, ticks))
   {
      
      Print("History Maker -- SymbolSelect/CustomTicksAdd false result -- ERROR# " + (string)GetLastError());
      return false;
   }
   
   return true;
}