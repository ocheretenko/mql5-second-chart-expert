//+------------------------------------------------------------------+
//|                                                OrderGraphics.mqh |
//|                                     2020 (c) Oleksii Ocheretenko |
//|                                          https://vk.com/war_k1ng |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Oleksii Ocheretenko"
#property link      "https://vk.com/war_k1ng"
#property version   "1.00"

#include "OrderGraphicsItem.mqh"

class OrderGraphics
{
private:

public:
      int in_list;
      OrderGraphicsItem orders[255];
      long chart_id;
      
      
      OrderGraphics();
     ~OrderGraphics();
      void OrderGraphics::SetChartId(long chart_id_);
      void Add(ulong ticket, double price, double tp, double sl);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
OrderGraphics::OrderGraphics()
{
   chart_id = NULL;
   in_list = 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
OrderGraphics::~OrderGraphics()
{
}
//+------------------------------------------------------------------+



void OrderGraphics::Add(ulong ticket, double price, double tp, double sl)
{
   if (chart_id < 1)
   {
      Alert("OrderGraphics::Add(); -- chart_id < 1. Use 'SetChartId(chart_id);' method.");
      ExpertRemove();
   }
   
   OrderGraphicsItem ord;
   ord.Init(chart_id, ticket,price,in_list);
   
   orders[0] = ord;
   in_list ++;
   
   ChartRedraw(chart_id);
}

void OrderGraphics::SetChartId(long chart_id_)
{
   if (chart_id_ < 1)
   {
      Alert("OrderGraphics::SetChartId -- chart_id < 1'");
      ExpertRemove();
   }
   
   chart_id = chart_id_;
}