//+------------------------------------------------------------------+
//|                                 TradeablePositionGraphicItem.mqh |
//|                                     2020 (c) Oleksii Ocheretenko |
//|                                          https://vk.com/war_k1ng |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Oleksii Ocheretenko"
#property link      "https://vk.com/war_k1ng"
#property version   "1.03"

#include "PositionGraphicItem.mqh"
#include "AESTrader.mqh"

AESTrader aesTrader;

class TradeablePositionGraphicItem : public PositionGraphicItem
  {
private:

public:
                     void OnItemClick(string item_name);
                     void SyncThisItem(string item_name);
                     bool ContainsItem(string item_name);
                     void OnItemDelete(string item_name);
                     
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

void TradeablePositionGraphicItem::SyncThisItem(string item_name)
{
   if (expired) return;
   
   if (!ContainsItem(item_name)) return;
   
   double new_position = -2000;
   if (!ObjectGetDouble(chart_id, item_name, OBJPROP_PRICE,0,new_position)) return;
   
   if (new_position == -2000) return;
   
   
   double send_tp = tp, send_sl = sl;
   
   
   if (tp == -2000) send_tp=0;
   if (sl == -2000) send_sl=0;
   
   if (item_name == tp_name) 
   {
      send_tp = new_position;
   }
   if (item_name == sl_name) 
   {
      send_sl = new_position;
   }
   
   aesTrader.SetStopOrders(ticket,send_sl,send_tp);
   
   reprint(price, tp, sl, true);
   
   ChartRedraw(chart_id);
}

bool TradeablePositionGraphicItem::ContainsItem(string item_name)
{
   if (expired) return false;
   
   if (tp_name == item_name || sl_name == item_name || price_name == item_name)
      return true;

   return false;
}

void TradeablePositionGraphicItem::OnItemDelete(string item_name)
{
   if (expired) return;
   
   if (!ContainsItem(item_name)) return;
   
   double var;
   if (ObjectGetDouble(chart_id, item_name, OBJPROP_PRICE, 0, var)) return;   //not deleted
   
   
   if (item_name == tp_name)
      HLineCreate(chart_id,tp_name ,0, tp ,255 ,STYLE_DASHDOT,1,false,true);
      
   if (item_name == sl_name)
      HLineCreate(chart_id,sl_name ,0, sl ,255  ,STYLE_DASHDOT,1,false,true);
   
   if (item_name == price_name)
      HLineCreate(chart_id,price_name ,0, price ,clrForestGreen ,STYLE_DOT, 1, false, false);
   
   ChartRedraw(chart_id);
}



void TradeablePositionGraphicItem::OnItemClick(string item_name)
{
   if (ObjectGetInteger(chart_id, item_name, OBJPROP_SELECTED) == false)
   {
      ObjectSetInteger(chart_id, item_name, OBJPROP_SELECTED, 1);
      ChartRedraw(chart_id);
   }
}