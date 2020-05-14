//+------------------------------------------------------------------+
//|                                 TradeablePositionGraphicItem.mqh |
//|                                     2020 (c) Oleksii Ocheretenko |
//|                                          https://vk.com/war_k1ng |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Oleksii Ocheretenko"
#property link      "https://vk.com/war_k1ng"
#property version   "1.00"

#include "PositionGraphicItem.mqh"
#include "AESTrader.mqh"

AESTrader aesTrader;

class TradeablePositionGraphicItem : public PositionGraphicItem
  {
private:

public:
                     
                     void SyncThisItem(string item_name, double new_position);
                     bool ContainsItem(string item_name);
                     
                     
                     TradeablePositionGraphicItem();
                    ~TradeablePositionGraphicItem();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TradeablePositionGraphicItem::TradeablePositionGraphicItem()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TradeablePositionGraphicItem::~TradeablePositionGraphicItem()
  {
  }
//+------------------------------------------------------------------+

void TradeablePositionGraphicItem::SyncThisItem(string item_name, double new_position)
{
   if (!ContainsItem(item_name)) return;
   
   if (new_position == -2000) return;
   
   if (!ObjectGetDouble(chart_id, item_name, OBJPROP_PRICE,0,new_position)) return;
   
   double send_tp = tp, send_sl = sl;
   
   
   if (tp == -2000) send_tp=0;
   if (sl == -2000) send_sl=0;
   
   if (item_name == tp_preffix) 
   {
      send_tp = new_position;
   }
   if (item_name == sl_preffix) 
   {
      send_sl = new_position;
   }
   
   aesTrader.SetStopOrders(ticket,send_sl,send_tp);
   
   reprint(price, tp, sl, true);
   
   ChartRedraw(chart_id);
}

bool TradeablePositionGraphicItem::ContainsItem(string item_name)
{
   if (tp_preffix == item_name || sl_preffix == item_name) 
      return true;

   return false;
}