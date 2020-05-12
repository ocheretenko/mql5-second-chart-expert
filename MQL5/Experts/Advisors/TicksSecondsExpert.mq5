//+------------------------------------------------------------------+
//|                                           TicksSecondsExpert.mq5 |
//|                                     2020 (c) Oleksii Ocheretenko |
//|                                          https://vk.com/war_k1ng |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Oleksii Ocheretenko"
#property link      "https://vk.com/war_k1ng"
#property version   "1.00"
//--- input parameters
input uint     LoadHistoryDays = 1;       //Загрузить дней истории   | 0-10
input uint     SecondsInBar = 1;          //Секунд в одной свече       | 1-60
input bool     TicksChart = false;        //Тиковый график
input bool     DeleteOldSymbols = true;   //Удалить неиспользуемые TSE символы

bool           button_bool = false;

static const string   button1_name = "the_button_1";
static const string   button2_name = "the_button_2";
static const string   buy_button_name = "the_buy_button";
static const string   sell_button_name = "the_sell_button";

static long           opened_chart = NULL;
static string         custom_symbol_identifier_affix = "[TSE]";
static string         custom_symbol_name = NULL;
static bool           custom_timer_tick_in_use = false;
static bool           it_was_inited = false;

#include <Trade\Trade.mqh>
#include <HistoryMaker.mqh>
#include <OrderGraphicsItem.mqh>

static CTrade trade;

static HistoryMaker   hist_maker;


class OrderGraphics
{
   public:
   
   int in_list;
   OrderGraphicsItem orders[255];
   
   OrderGraphics()
   {
      in_list = 0;
   }
   
   void add(ulong ticket, double price, double tp, double sl)
   {
      OrderGraphicsItem ord;
      ord.Init(opened_chart, ticket,price,in_list);
      
      orders[0] = ord;
      in_list ++;
      
      ChartRedraw(opened_chart);
   }
   
};

static OrderGraphics handler;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   
   if (it_was_inited) return INIT_SUCCEEDED;
   it_was_inited = true;
   
   RemoveOldSymbols();
   
   //local method
   //CTradeInit();
   
   //button 1
   //ButtonCreate(0,button1_name,0,50,50,200,30,0,"Open Second Chart","Arial");
   
   //button 2
   //ButtonCreate(0,button2_name,0,250,50,50,30,0,"Close","Arial");

   string add_affix;
   
   if (TicksChart)
      add_affix = " [1min=1tick] ";
   else
      add_affix = " [1min=1sec] ";
   
   custom_symbol_name = Symbol()  + add_affix + custom_symbol_identifier_affix;
   
   CustomSymbolCreate(custom_symbol_name,NULL,Symbol());
   
   
   CustomTicksDelete(custom_symbol_name, 0, TimeCurrent() * 1000 );     //clear the history
   
   hist_maker.Make(Symbol(),custom_symbol_name, TicksChart);            //make history
   
   opened_chart = ChartOpen(custom_symbol_name, PERIOD_M1);             //open chart
   
   MarketBookAdd(custom_symbol_name);                                   //book
   
   //MakeSecondChartPanel();                                            //
   ChartRedraw(opened_chart);
   
   
   
   ChartRedraw();
   
   EventSetTimer(1);
  
   return(INIT_SUCCEEDED);
   
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
  }
  
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
//---

   if (opened_chart == NULL) return;
   
//   render.On_tick();
   
   MqlTick Latest_Price;
   
   SymbolInfoTick(Symbol() ,Latest_Price);

   MqlTick tick[1];
   tick[0] = Latest_Price;
   
   if (TicksChart)
      hist_maker.converter.OnTickUpdateTicks(tick);
   else
      hist_maker.converter.OnTickUpdateSeconds(tick);
   
   
   CustomTicksAdd(custom_symbol_name, tick);
   ChartRedraw(opened_chart);
   
 /*  
   MqlRates bar[1];
   CopyRates(_Symbol,_Period,1,1,bar);
   MqlTick tick[1];
   CopyTicks(_Symbol, tick, 0,1,1);
   
   //GetPointer();
   
   Comment( "ask: "+ 
   (string)tick[0].ask + 
   "bid: " +(string)tick[0].bid);*/
}
  


//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
//---

   return;

   if (trans.deal == false) return;

   //order = trans.order;
   
   //Print("trans pos:" + (string)trans.position);
   
   double sl, tp, price_open;
      
   PositionSelectByTicket(trans.position);
   
   if (!PositionGetDouble(POSITION_PRICE_OPEN, price_open) || 
      !PositionGetDouble(POSITION_TP, tp) ||
      !PositionGetDouble(POSITION_SL, sl))
   {
      Alert("Error $17: Could not take price/tp/sl");
      ExpertRemove();
      return;
   }
   
   handler.add(trans.order, price_open, tp, sl);
   
   //Print("Price Open:" + (string)po);
   //PositionSelectByTicket(order);
   
   
   
   
   
//   HLineCreate(opened_chart,
   
   
   //newLine( trans.price );
   
}

static int lineNumber =  0;
void newLine(double price)
{
   HLineCreate(opened_chart, "HLINE" + (string)lineNumber , 0 , price,255);
   lineNumber+=1;
}

class RealTimeRender
{
   public:
      RealTimeRender()
      {
         MakeNewBar();
         seconds_in_bar = 10;
         tick_counter = 0;
         current_bar_time = D'2001.1.3 01:00';
         
      };
      
      
      void Settings(int bar_seconds_)
      {
         
      }
      
      void On_tick(bool debug_random_price = false)
      {
         double price = 0;
         
         if (debug_random_price)
            while ((price = rand() / 100) == 0);
            
         else
         {
            MqlTick Latest_Price;
            SymbolInfoTick(Symbol() ,Latest_Price);
            
            if (true) price = Latest_Price.bid;                //<--------------------TODO switcher
               else price = Latest_Price.ask;          
         }
         
         if (price == 0)
         {
            Alert("Error $11: Bad price came in real time renderer");
            ExpertRemove();
            return;
         }
         
         tick_counter++;
         
         if (IsNewBarRequired()) MakeNewBar();
                              
                                                      //current bar update logic___________________________
         if (currentBar[0].close == price)            //not a new tick (or no my type (bid/ask))
         {
            return;                       
         }
         
         
         currentBar[0].close = price;
         
         if (currentBar[0].open == 0)                 //current bar is not opened
         {
            currentBar[0].open = price;
            currentBar[0].high = price;
            currentBar[0].low = price;
            return;
         }
         
         if (currentBar[0].high < price)
            currentBar[0].high = price;
         else if (currentBar[0].low > price || currentBar[0].low == 0)
            currentBar[0].low = price;
         
         
         Comment("price is: "+ (string)price);
         
         CustomRatesUpdate(custom_symbol_name,currentBar);
         
         MqlBookInfo bf[1];
         
         bf[0].price = price;
         bf[0].type = BOOK_TYPE_SELL; // TODO swticher <----------------------------------------------------------
         bf[0].volume = 100;
         bf[0].volume_real = 100;
         
         MqlTick tick[1];
         tick[0].ask = price + 0.01;
         tick[0].bid = price;
         tick[0].time = current_bar_time;//TimeCurrent();
         tick[0].volume = 100;
         tick[0].volume_real = 100;
         tick[0].flags = TICK_FLAG_BID;
       
         SymbolSelect(custom_symbol_name, true);
         CustomBookAdd(custom_symbol_name, bf);
         CustomTicksAdd(custom_symbol_name, tick);

         ChartRedraw(opened_chart);
         
      }
      
   private:
      MqlRates currentBar[1];
      int seconds_in_bar;
      int tick_counter;
      datetime current_bar_time;
      
      void MakeNewBar()
      {
         MqlRates bar;
         currentBar[0] = bar;
         
         currentBar[0].close = 
            currentBar[0].open =
            currentBar[0].high =
            currentBar[0].low = 0.00;
         
         currentBar[0].time = get_time(); 
      }
      
      bool IsNewBarRequired()
      {
         if (tick_counter > 9)
         {
            tick_counter = 0;
            return true;
         }
         return false;                    //<---------------------------------TODO func
      }
      
      datetime get_time()
      {
         current_bar_time += 60;
         return current_bar_time;
      }
      
};

static RealTimeRender render;
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   //for (int l = 0; l < 5; l++)
   {
   //   CustomTimerTick();
      //Sleep(100);
   }

   return;
}

static datetime time = NULL;

void CustomTimerTick()
{  
  // render.On_tick(true);
   
   //secure start
   if (custom_timer_tick_in_use) return;
   custom_timer_tick_in_use = true;
   //
   
   
   //Alert("Tick");
  // Print("Tick");
   
  // ChartRedraw(0);
  // Comment(".");
   handler.orders[0].sync();
   
   
   
   //if buy button was pressed____________________________________________________________________________
   if (opened_chart != NULL)
   if (1 == ObjectGetInteger(opened_chart,buy_button_name,OBJPROP_STATE))
   {
      //unpress the button
      ObjectSetInteger(opened_chart,buy_button_name,OBJPROP_STATE,0);
      ChartRedraw(opened_chart);
      
      
      Comment("BUYING");
      
      //buy
      //if(!trade.Buy(1.0))
      if (!trade.Buy(1.0,custom_symbol_name))
         Comment("Метод Buy() потерпел неудачу. Код возврата=",trade.ResultRetcode(),
            ". Описание кода: ",trade.ResultRetcodeDescription());
      else
         Comment("Метод Buy() выполнен успешно. Код возврата=",trade.ResultRetcode(),
            " (",trade.ResultRetcodeDescription(),")");
   }
   
   //if button 2 was pressed____________________________________________________________________________
   if (1 == ObjectGetInteger(0,button2_name, OBJPROP_STATE))
   {
      //unpress the button
      ObjectSetInteger(0,button2_name,OBJPROP_STATE,0);
      ChartRedraw(0);
      
      
      //close the chart
      if (opened_chart != NULL) ChartClose(opened_chart);
      
      //deactivate SYMBOL
      SymbolSelect(custom_symbol_name, false);
      
      //delete SYMBOL
      
      if (!CustomSymbolDelete(custom_symbol_name))
      {
         CustomSymbolDelete(custom_symbol_name);
      }
      
   }

   //if button 1 was pressed_____________________________________________________________________________________
   if (1 == ObjectGetInteger(0,button1_name,OBJPROP_STATE) == 1)
   {
      //unpress the button
      ObjectSetInteger(0,button1_name,OBJPROP_STATE,0);
      ChartRedraw(0);
      
      custom_symbol_name = Symbol() + custom_symbol_identifier_affix;
      
      if (true == CustomSymbolCreate(custom_symbol_name,NULL,Symbol())) 
         Comment("CREATED SYMB");
      else 
      {
         Comment("CANT CREATE SYMB");
         //return;
      }
      
      
      CustomTicksDelete(custom_symbol_name, 0, TimeCurrent() * 1000 );     //clear the history
      //CustomSymbolSetString(custom_symbol_name, SYMBOL_BASIS, "");
      
      int ctld = CustomRatesDelete(custom_symbol_name,978307260,2147483646);
   //   ctld = CustomTicksDelete(custom_symbol_name,2147483647,2147483647);
      
      //activate the symbol
      SymbolSelect(custom_symbol_name,true);
      
      //experimental
    //  CustomSymbolSetString( custom_symbol_name,SYMBOL_CURRENCY_PROFIT, AccountInfoString(ACCOUNT_CURRENCY));
   //   CustomSymbolSetString( custom_symbol_name,SYMBOL_CURRENCY_MARGIN, AccountInfoString(ACCOUNT_CURRENCY));
   //   CustomSymbolSetString( custom_symbol_name,SYMBOL_CURRENCY_BASE, AccountInfoString(ACCOUNT_CURRENCY));
      
      //opened_chart = ChartOpen(NULL,PERIOD_M1 );
      //opened_chart = ChartOpen(sname,PERIOD_M1 );
      
      MqlRates rates[];
      
      
      
      
      CopyRates(NULL, 0,0, 100, rates);
      
      //CustomSymbolSetSessionTrade(custom_symbol_name,MONDAY,0,0,10);
      //CustomSymbolSetSessionTrade(custom_symbol_name,MONDAY,1,11,21);
      
     // CustomRatesUpdate(custom_symbol_name,rates);
      
      //CustomSymbolSetDouble(custom_symbol_name, SYMBOL_ASK, 1.11);
      //CustomSymbolSetDouble(custom_symbol_name, SYMBOL_BID, 1.14);
      //CustomSymbolSetInteger(custom_symbol_name, SYMBOL_SESSION_BUY_ORDERS, 100);
      //CustomSymbolSetInteger(custom_symbol_name, SYMBOL_SESSION_SELL_ORDERS, 100);
      
      //CustomSymbolSetMarginRate
      //CustomSymbolSetSessionQuote
      
      
      hist_maker.Make(Symbol(),custom_symbol_name);
      
      //open symbol chart
      opened_chart = ChartOpen(custom_symbol_name, PERIOD_M1);
      
      //MarketBookAdd(custom_symbol_name); //add book
      
      MakeSecondChartPanel();
      ChartRedraw(opened_chart);
   }
   
   
   
   
   
   
   //secure exit
   custom_timer_tick_in_use = false;
   return;
   //
}

  
  
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }



//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
  
}




//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
{
   
}
//+------------------------------------------------------------------+

void MakeSecondChartPanel()
{

   ButtonCreate(opened_chart,buy_button_name,0,50,50,100,50,0,"BUY","Arial");
   
}


void CTradeInit()
{
//--- зададим MagicNumber для идентификации своих ордеров
   int MagicNumber=754896;
   trade.SetExpertMagicNumber(MagicNumber);
//--- установим допустимое проскальзывание в пунктах при совершении покупки/продажи
   int deviation=10;
   trade.SetDeviationInPoints(deviation);
//--- режим заполнения ордера, нужно использовать тот режим, который разрешается сервером
   trade.SetTypeFilling(ORDER_FILLING_RETURN);
//--- режим логирования: лучше не вызывать этот метод вообще, класс сам выставит оптимальный режим
   //trade.LogLevel(1); 
//--- какую функцию использовать для торговли: true - OrderSendAsync(), false - OrderSend()
   trade.SetAsyncMode(true);
   
}







  //method from the documentation
  bool ButtonCreate(const long              chart_ID=0,               // ID графика
                  const string            name="Button",            // имя кнопки
                  const int               sub_window=0,             // номер подокна
                  const int               x=0,                      // координата по оси X
                  const int               y=0,                      // координата по оси Y
                  const int               width=50,                 // ширина кнопки
                  const int               height=18,                // высота кнопки
                  const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // угол графика для привязки
                  const string            text="Button",            // текст
                  const string            font="Arial",             // шрифт
                  const int               font_size=10,             // размер шрифта
                  const color             clr=clrBlack,             // цвет текста
                  const color             back_clr=C'236,233,216',  // цвет фона
                  const color             border_clr=clrNONE,       // цвет границы
                  const bool              state=false,              // нажата/отжата
                  const bool              back=false,               // на заднем плане
                  const bool              selection=false,          // выделить для перемещений
                  const bool              hidden=true,              // скрыт в списке объектов
                  const long              z_order=0)                // приоритет на нажатие мышью
  {
//--- сбросим значение ошибки
   ResetLastError();
//--- создадим кнопку
   if(!ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": не удалось создать кнопку! Код ошибки = ",GetLastError());
      return(false);
     }
//--- установим координаты кнопки
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- установим размер кнопки
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- установим угол графика, относительно которого будут определяться координаты точки
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- установим текст
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- установим шрифт текста
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- установим размер шрифта
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- установим цвет текста
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- установим цвет фона
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- установим цвет границы
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
//--- отобразим на переднем (false) или заднем (true) плане
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- переведем кнопку в заданное состояние
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
//--- включим (true) или отключим (false) режим перемещения кнопки мышью
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- установим приоритет на получение события нажатия мыши на графике
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- успешное выполнение
   return(true);
  }
  
  
void RemoveOldSymbols()
{
   int total = SymbolsTotal(false);
   
   for (int i=0; i < total; i++)
   {
      string symbol_name = SymbolName(i , false);
      
    //  long response;
    //  if (!SymbolInfoInteger(symbol_name, SYMBOL_CUSTOM, response)) continue;       //couldn't get info
      
    //  if (response == 0) continue;                                                  //symbol is not custom
      
      
      if (StringFind(symbol_name, custom_symbol_identifier_affix) == -1) continue;  //did not match
      
   //   if (!SymbolInfoInteger(symbol_name, SYMBOL_SELECT, response)) continue;       //couldn't get info
      
      
   //   if (response == 1) 
         if (!SymbolSelect(symbol_name,false));                                      //deselect if selected
   //         continue;                                                               //couldn't deselect

      CustomSymbolDelete(symbol_name);                                              //try to delete
   }
}
