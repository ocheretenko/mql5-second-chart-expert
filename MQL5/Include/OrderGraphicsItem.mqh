//+------------------------------------------------------------------+
//|                                            OrderGraphicsItem.mqh |
//|                                     2020 (c) Oleksii Ocheretenko |
//|                                          https://vk.com/war_k1ng |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Oleksii Ocheretenko"
#property link      "https://vk.com/war_k1ng"
#property version   "1.01"

class OrderGraphicsItem
{
private:
      string price_preffix;// = "Second_Price_In_Order_";
      string tp_preffix;// = "Second_Tp_In_Order_";
      string sl_preffix;// = "Second_Sl_In_Order_";
      long chart_id;

      int   index;
      
      double price;
      double sl;
      double tp;

public:
      ulong ticket;
      bool expired;
      
      OrderGraphicsItem();
     ~OrderGraphicsItem();
      void Init(long chart_id_, ulong ticket_ = NULL, double price_ = NULL, int index_ = NULL, double tp_ = 0, double sl_ = 0);
      void sync();
      void reprint(double gprice, double gtp, double gsl);
      void OrderGraphicsItem::Delete();
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
OrderGraphicsItem::OrderGraphicsItem()
{
   expired = false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
OrderGraphicsItem::~OrderGraphicsItem()
  {
  }


void OrderGraphicsItem::Init(long chart_id_, ulong ticket_, double price_ , int index_, double tp_ = 0, double sl_ = 0)
{
   if (price_ == NULL || ticket_ == NULL || chart_id_ < 1)
   {
      Alert("OrderGraphicsItem constructor fail.");
      ExpertRemove();
      return;
   }
   
   chart_id = chart_id_;
   tp = tp_;
   sl = sl_;
   ticket = ticket_;
   index = index_;
   price = price_;
   
   //names init
   price_preffix = "Second_Price_In_Order_" + (string)index;
   tp_preffix = "Second_Tp_In_Order_" + (string)index;
   sl_preffix = "Second_Sl_In_Order_" + (string)index;
   
   //make the lines
   if (sl_ == 0) sl_ = -2000;
   if (tp_ == 0) tp_ = -2000;
   
   HLineCreate(chart_id,price_preffix ,0, price ,clrForestGreen ,STYLE_DOT, 1);
   HLineCreate(chart_id,tp_preffix ,0, tp_ ,255 ,STYLE_DASHDOT);
   HLineCreate(chart_id,sl_preffix ,0, sl_ ,255  ,STYLE_DASHDOT);
   
   ChartRedraw(chart_id);
};


void OrderGraphicsItem::sync()
{
   if (expired) return;
   
   double gsl = NULL, gtp = NULL, gprice = NULL;
   
   if (!PositionSelectByTicket(ticket)) 
   {
      Delete();
      return;
   }
   if (!PositionGetDouble(POSITION_TP, gtp)
   || !PositionGetDouble(POSITION_SL, gsl) 
   || !PositionGetDouble(POSITION_PRICE_OPEN, gprice))
   {
      Delete();
      return;
   }
      
   reprint(gprice, gtp,gsl);
}

void OrderGraphicsItem::Delete()
{
   expired = true;
   
   ObjectDelete(chart_id, price_preffix);
   ObjectDelete(chart_id, tp_preffix);
   ObjectDelete(chart_id, sl_preffix);
   
   ChartRedraw(chart_id);
}

void OrderGraphicsItem::reprint(double gprice, double gtp, double gsl)
{
   bool redraw_need = false;
   
   if (gtp == 0) gtp = -2000;
   if (gsl == 0) gsl = -2000;
   
   if (gtp != NULL && tp != gtp) 
   {
      HLineMove(chart_id,tp_preffix,gtp);
      tp = gtp;
      
      redraw_need = true;
   }
   
   
   if (gsl != NULL && sl != gsl) 
   {
      HLineMove(chart_id,sl_preffix,gsl);
      sl = gsl;
      
      redraw_need = true;
   }
   
   if (gprice != NULL && price != gprice)
   {
      HLineMove(chart_id,price_preffix,gprice);
      price = gprice;

      redraw_need = true;
   }
   
   //redraw
   if (redraw_need) ChartRedraw(chart_id);
}






bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 double                price=0,           // line price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_DASH, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=false,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
{
   //--- if the price is not set, set it at the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   //--- reset the error value
   ResetLastError();
   //--- create a horizontal line
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
     }
   //--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   //--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
   //--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
   //--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   //--- enable (true) or disable (false) the mode of moving the line by mouse
   //--- when creating a graphical object using ObjectCreate function, the object cannot be
   //--- highlighted and moved by default. Inside this method, selection parameter
   //--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   //--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   //--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   //--- successful execution
   return(true);
}



bool HLineMove(const long   chart_ID=0,   // ID графика
               const string name="HLine", // имя линии
               double       price=0)      // цена линии
{
   //--- если цена линии не задана, то перемещаем ее на уровень текущей цены Bid
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   //--- сбросим значение ошибки
   ResetLastError();
   //--- переместим горизонтальную линию
   if(!ObjectMove(chart_ID,name,0,0,price))
     {
      Print(__FUNCTION__,
            ": не удалось переместить горизонтальную линию! Код ошибки = ",GetLastError());
      return(false);
     }
   //--- успешное выполнение
   return(true);
}