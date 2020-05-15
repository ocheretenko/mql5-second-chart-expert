//+------------------------------------------------------------------+
//|                                                PeriodConvert.mqh |
//|                                     2020 (c) Oleksii Ocheretenko |
//|                                          https://vk.com/war_k1ng |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Oleksii Ocheretenko"
#property link      "https://vk.com/war_k1ng"
#property version   "1.02"

class PeriodConvert
{
private:
               datetime rewrite_start_time;
               datetime first_tick_true_time;
               
               uint tick_convert_ticks_in_history;
               
               enum ClassWasUsedAs {NotYet, TicksConverter, SecondsConverter};
               ClassWasUsedAs used_as;
               
               //methods
               datetime TimeJump(int multiplier, datetime &time);
               
               bool PrivateTicksToMinutes(MqlTick &ticks[], int quantity, uint offset);
               bool PrivateSecondsToMinutes(MqlTick &ticks[], int quantity);
public:

               bool inUse;
               
               
                     PeriodConvert();
                    ~PeriodConvert();

               bool HistoryTicksToMinutes(MqlTick &ticks[], int quantity);
               bool HistorySecondsToMinutes(MqlTick &ticks[], int quantity);
               
               void Reset(datetime start_time = D'1971.1.1 0:00');
               
               bool OnTickUpdateTicks(MqlTick &tick[]);
               bool OnTickUpdateSeconds(MqlTick &tick[]);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PeriodConvert::PeriodConvert()
{
   PeriodConvert::Reset();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PeriodConvert::~PeriodConvert()
{
}
//+------------------------------------------------------------------+


/***
*  Converts given ticks for printing it as a second-period chart
***/
bool PeriodConvert::HistorySecondsToMinutes(MqlTick &ticks[], int quantity)
{
   return PeriodConvert::PrivateSecondsToMinutes(ticks, quantity);
}


/***
*  Converts given ticks for printing it as a chart of ticks
***/
bool PeriodConvert::HistoryTicksToMinutes(MqlTick &ticks[], int quantity)
{
   tick_convert_ticks_in_history = quantity;
   return PeriodConvert::PrivateTicksToMinutes(ticks, quantity, 0);
}


bool PeriodConvert::PrivateSecondsToMinutes(MqlTick &ticks[], int quantity)
{
   if (used_as == TicksConverter)
   {
      Alert("This object was used as TickConverter. Now it's set for real-time convertation. Please create a new object or use 'PeriodConvert::Reset();' if you need to convert another array.");
      return false;
   }
   
   if (quantity < 1) return false;
   
   for (int i=0; i < quantity; i++)
   {
      if (first_tick_true_time == NULL)
         first_tick_true_time = ticks[0].time;
      
                                                                     //get the rewrite time for current tick
      datetime rewrite_time = (ticks[i].time - first_tick_true_time) * 60 + rewrite_start_time;
      
      long msc = ticks[i].time_msc - ticks[i].time*1000;             //get tick's ms. state
      
      ticks[i].time = rewrite_time;                                  //set new fake sec. time for current tick
      ticks[i].time_msc = rewrite_time * 1000 + msc;                 //set new fake ms. time for current tick
   }

   return true;
}



bool PeriodConvert::PrivateTicksToMinutes(MqlTick &ticks[], int quantity, uint offset)
{
   if (used_as == TicksConverter)
   {
      Alert("This object was used as SecondsConverter. Now it's set for real-time convertation. Please create a new object or use 'PeriodConvert::Reset();' if you need to convert another array.");
      return false;
   }


   if (quantity < 1) return false;
   
   
   for (int i = 0; i < quantity; i++)
   {
      datetime new_time = (offset + i )* 60 + rewrite_start_time;
      
      ticks[i].time = new_time;
      ticks[i].time_msc = new_time * 1000;
   }
   
   return true;
}



void PeriodConvert::Reset(datetime start_time = D'1971.1.1 0:00')
{

   rewrite_start_time = start_time;
      
   tick_convert_ticks_in_history = NULL;   
   first_tick_true_time = NULL;

   used_as = NotYet;
}



bool PeriodConvert::OnTickUpdateTicks(MqlTick &tick[])
{
   if (used_as == SecondsConverter) return false;
   
   
   if (!PrivateTicksToMinutes(tick, 1, tick_convert_ticks_in_history))
         return false;
   
   
   tick_convert_ticks_in_history++;
   
   
   return true;
}


bool PeriodConvert::OnTickUpdateSeconds(MqlTick &tick[])
{
   if (used_as == TicksConverter) return false;

   if (!PrivateSecondsToMinutes(tick, 1))
         return false;

   return true;
}