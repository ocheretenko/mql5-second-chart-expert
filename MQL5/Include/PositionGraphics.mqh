//+------------------------------------------------------------------+
//|                                             PositionGraphics.mqh |
//|                                     2020 (c) Oleksii Ocheretenko |
//|                                          https://vk.com/war_k1ng |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Oleksii Ocheretenko"
#property link      "https://vk.com/war_k1ng"
#property version   "1.02"

//#include "PositionGraphicItem.mqh"
#include "TradeablePositionGraphicItem.mqh"

class PositionGraphics
{
private:
      void Add(ulong  ticket);
      
public:
      int in_list;
      TradeablePositionGraphicItem orders[10000];
      long chart_id;
      
      
      PositionGraphics();
     ~PositionGraphics();
      void OnItemClick(string item_name);
      void SetChartId(long chart_id_);
      void Add(ulong ticket, double price, double tp, double sl);
      void SyncChangedObject(string item_name);
      void OnItemDelete(string item_name);
      void Sync(ulong ticket);
      void StartUpSync();
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PositionGraphics::PositionGraphics()
{
   chart_id = NULL;
   in_list = 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PositionGraphics::~PositionGraphics()
{
}
//+------------------------------------------------------------------+



void PositionGraphics::Add(ulong ticket, double price, double gtp, double gsl)
{
   if (chart_id < 1)
   {
      Alert("OrderGraphics::Add(); -- chart_id < 1. Use 'SetChartId(chart_id);' method.");
      ExpertRemove();
   }
   
   PositionGraphicItem ord;
   ord.Init(chart_id, ticket,price,in_list, gtp, gsl);
   
   orders[in_list] = ord;
   in_list ++;
   
   ChartRedraw(chart_id);
}

void PositionGraphics::SetChartId(long chart_id_)
{
   if (chart_id_ < 1)
   {
      Alert("OrderGraphics::SetChartId -- chart_id < 1'");
      ExpertRemove();
   }
   
   chart_id = chart_id_;
}


void PositionGraphics::Sync(ulong ticket)
{
   for (int i=0; i < in_list; i++)
   {
      if (orders[i].ticket == ticket)
      {
         orders[i].sync();
         return;
      }
   }
   
   //if it did not exit the method
   //adding the thing
   
   Add(ticket);
}

void PositionGraphics::StartUpSync()
{
   int total = PositionsTotal();
   
   for (int i=0; i < total; i++)
   {
      ulong ticket;
      if ((ticket = PositionGetTicket(i)) == 0) continue;     //couldn't get position ticket
      
      Sync(ticket);                                           //sync this position
   }
}


void PositionGraphics::Add(ulong  ticket)
{
   double gsl, gtp, price_open;
      
   
   if (!PositionSelectByTicket(ticket) 
      || !PositionGetDouble(POSITION_PRICE_OPEN, price_open) 
      || !PositionGetDouble(POSITION_TP, gtp) 
      || !PositionGetDouble(POSITION_SL, gsl))
   {
      return;
   }
   
   PositionGraphics::Add(ticket,price_open ,gtp, gsl);
}



void PositionGraphics::SyncChangedObject(string item_name)
{
      for (int i=0; i < in_list; i++)
   {
         if (orders[i].ContainsItem(item_name))
         {
            orders[i].SyncThisItem(item_name);
            return;
         }
   }
}


void PositionGraphics::OnItemDelete(string item_name)
{
   for (int i=0; i < in_list; i++)
   {
      if (orders[i].ContainsItem(item_name))
      {
         orders[i].OnItemDelete(item_name);
         return;
      }
   }
}


void PositionGraphics::OnItemClick(string item_name)
{
   for (int i=0; i< in_list; i++)
   {
      if (orders[i].ContainsItem(item_name))
      {
         orders[i].OnItemClick(item_name);
         return;
      }
   }
}