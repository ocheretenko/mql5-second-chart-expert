//+------------------------------------------------------------------+
//|                                                PeriodConvert.mqh |
//|                                     2020 (c) Oleksii Ocheretenko |
//|                                          https://vk.com/war_k1ng |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Oleksii Ocheretenko"
#property link      "https://vk.com/war_k1ng"
#property version   "1.00"

class PeriodConvert
  {
private:
               datetime history_rewrite_time;
               datetime live_rewrite_time;
               
               datetime rewrite_start_time;
               datetime first_tick_true_time;
               
               datetime history_previous_tick_true_time ,live_previous_tick_true_time;
               
               //datetime previous_tick_real_time;
               enum ClassWasUsedAs {NotYet, TicksConverter, SecondsConverter};
               ClassWasUsedAs used_as;
               
               //methods
               datetime TimeJump(int multiplier, datetime &time);
               
               bool PrivateTicksToMinutes(MqlTick &ticks[], int quantity, datetime &rewrite_with);
                  
               bool PrivateSecondsToMinutes(MqlTick &ticks[], int quantity, datetime &rewrite_with, 
                  datetime &previous_tick_true_time);
public:

               bool inUse;
               
               
                     PeriodConvert();
                    ~PeriodConvert();

               bool HistoryTicksToMinutes(MqlTick &ticks[], int quantity);
               bool HistorySecondsToMinutes(MqlTick &ticks[], int quantity);
               
               void Reset(datetime start_time = D'2000.1.1 0:00');
               
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
   return PeriodConvert::PrivateSecondsToMinutes(ticks, quantity, history_rewrite_time, history_previous_tick_true_time);
}


/***
*  Converts given ticks for printing it as a chart of ticks
***/
bool PeriodConvert::HistoryTicksToMinutes(MqlTick &ticks[], int quantity)
{
   return PeriodConvert::PrivateTicksToMinutes(ticks, quantity, history_rewrite_time);
}


bool PeriodConvert::PrivateSecondsToMinutes(MqlTick &ticks[], int quantity, datetime &rewrite_with, datetime &previous_tick_true_time)
{
   if (used_as == TicksConverter)
   {
      Alert("This object was used as TickConverter. Now it's set for real-time convertation. Please create a new object or use 'PeriodConvert::Reset();' if you need to convert another array.");
      return false;
   }
   
   if (quantity < 1) return false;
   
   if (quantity > 1)
   {
      live_rewrite_time =  
         (ticks[quantity-1].time - ticks[0].time) * 60 + history_rewrite_time; //live time setup
      live_previous_tick_true_time = ticks[quantity-1].time;                   //
   }
   
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



bool PeriodConvert::PrivateTicksToMinutes(MqlTick &ticks[], int quantity, datetime &rewrite_with)
{
   if (used_as == TicksConverter)
   {
      Alert("This object was used as SecondsConverter. Now it's set for real-time convertation. Please create a new object or use 'PeriodConvert::Reset();' if you need to convert another array.");
      return false;
   }



   if (quantity < 1) return false;

   if (quantity > 1)
   {
      live_rewrite_time =  
         (ticks[quantity-1].time - ticks[0].time) * 60 + history_rewrite_time;
   }
   
   for (int i = 0; i < quantity; i++)
   {
      ticks[i].time = rewrite_with;
      ticks[i].time_msc = rewrite_with * 1000;
      TimeJump(1, rewrite_with);
   }
   
   return true;
}


datetime PeriodConvert::TimeJump(int multiplier, datetime &time)
{     
   time += 60 * multiplier;
   
   return time;
}


void PeriodConvert::Reset(datetime start_time = D'2000.1.1 0:00')
{
   history_rewrite_time = 
      live_rewrite_time =  
      rewrite_start_time = start_time;
   
   first_tick_true_time = 
      history_previous_tick_true_time = 
      live_previous_tick_true_time = NULL;
   
   used_as = NotYet;
}



bool PeriodConvert::OnTickUpdateTicks(MqlTick &tick[])
{
   if (used_as == SecondsConverter) return false;
   
   //MqlTick ticks[1];
   //ticks[0] = tick;
   
   
   if (PrivateTicksToMinutes(tick, 1, live_rewrite_time))
         return false;
         
   //tick = ticks[0];
   return true;
}


bool PeriodConvert::OnTickUpdateSeconds(MqlTick &tick[])
{
   if (used_as == TicksConverter) return false;
   
   //MqlTick ticks[1];
  // ticks[0] = tick;
   
   if (PrivateSecondsToMinutes(tick, 1, live_rewrite_time, live_previous_tick_true_time))
         return false;

 //  tick = ticks[0];
   return true;
}