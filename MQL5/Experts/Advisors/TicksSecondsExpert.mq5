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
static const string   Expert_Name = "TicksSecondsExpert";

static long           opened_chart = NULL;
static string         custom_symbol_identifier_affix = "[TSE]";
static string         custom_symbol_name = NULL;
static bool           custom_timer_tick_in_use = false;
static bool           it_was_inited = false;
static bool           host_mode = true;

#include <Trade\Trade.mqh>
#include <HistoryMaker.mqh>
#include <OrderGraphics.mqh>
#include  <Expert.mqh>

static CTrade trade;
static HistoryMaker   hist_maker;
static OrderGraphics ordersIndicator;
static EXPERT expert_lib;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   
   if (it_was_inited) return INIT_SUCCEEDED;
   it_was_inited = true;
   
   
   if (StringFind(_Symbol, custom_symbol_identifier_affix) > -1)     //EA was opened on a TSE chart
   {
      StartAsListener();
      return INIT_SUCCEEDED;
   }
   
   else StartAsHost();                                               //EA was opened on a real symbol chart
   return INIT_SUCCEEDED;
}

void StartAsListener()
{
   host_mode = false;
   CTradeInit();
   ordersIndicator.SetChartId(ChartID());                 //send chart_id to OrderGraphics
   ordersIndicator.StartUpSync();
   
   //EventSetTimer(1);
}


void StartAsHost()
{
   string affix2;
   
   if (TicksChart)
      affix2 = " [1min=1tick] ";
   else
      affix2 = " [1min=1sec] ";
   
   custom_symbol_name = _Symbol +affix2 +custom_symbol_identifier_affix;
   
   
   RemoveHostAndListenerCompetitors();
   
   
   CustomSymbolCreate(custom_symbol_name,NULL,Symbol());
   
   CustomTicksDelete(custom_symbol_name, 0, TimeCurrent() * 1000 );     //clear the history
   
   hist_maker.Make(Symbol(),custom_symbol_name, TicksChart);            //make history
   
   opened_chart = ChartOpen(custom_symbol_name, PERIOD_M1);             //open chart
   
   //MarketBookAdd(custom_symbol_name);                                 //book

   ChartRedraw(opened_chart);
   ChartRedraw();
   
   if (DeleteOldSymbols) DeleteOldSymbolsFunc();
   
   MqlParam p[5];
   
   p[0].string_value = "Experts\\Advisors\\TicksSecondsExpert.ex5";
   
   p[1].type = TYPE_INT;
   p[1].integer_value = 1;
   
   p[2].type = TYPE_INT;
   p[2].integer_value = 1;
   
   p[3].type = TYPE_BOOL;
   p[3].integer_value = 0;
   
   p[4].type = TYPE_BOOL;
   p[4].integer_value = 0;
   
   expert_lib.Run(opened_chart, p);
   
   //EventSetTimer(1);
}

void RemoveHostAndListenerCompetitors()
{
   if (!host_mode) return;                                                      //host-mode only
   
   for (long chart = ChartFirst(); chart != -1; chart = ChartNext(chart))
   {
      string resp, symbol;
      
      symbol = ChartSymbol(chart);
      
      if (symbol == custom_symbol_name)                                        //existing listener on my custom symbol
      {
         if (chart == opened_chart) continue;                                  //it's my new-created listener chart. do nothing
         ChartClose(chart);
         continue;
      }
      
      if (symbol != Symbol()) continue;                                         //symbol did not match
      if (!ChartGetString(chart, CHART_EXPERT_NAME, resp)) continue;            //couldn't get expert's name
      
      
      if (resp != Expert_Name) continue;                                        //expert's name did not match
      if (chart == ChartID()) continue;                                         //it's my current chart. do nothing
      
      ChartClose(chart);                                                        //competitor close
   }
   
   
   
   return;
   string global_var_name = "AES_HOST_CHART_ID_ON_SYMBOL_" + Symbol();
   
   
   if (GlobalVariableCheck(global_var_name))
   {
      long chart_id_in_global = (long)GlobalVariableGet(global_var_name);
      
      //if (chart_id_in_global != 0) DeleteCompetitor(chart_id_in_global);
   }
   
   GlobalVariableSet(global_var_name, (double)2147483647);
   

}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if (!host_mode)
   {
      if (reason == 3 || reason == 7 || reason == 5) return;
      
      ChartClose(ChartID());
   }

   if (!host_mode) return;
   //Alert(reason);
   
   if (reason != 3 && reason != 7)
   {
      ChartClose(opened_chart);                  //close listener

      SymbolSelect(custom_symbol_name, false);   //symbol deselect try

      CustomSymbolDelete(custom_symbol_name);    //symbol delete try

      ExpertRemove();

      return;
   }
   
   if ((reason == 3 || reason == 7) && StringFind(custom_symbol_name, Symbol()) == -1) //symbol has changed. remove expert
   {
      Alert("symbol has changed. remove expert");
      ExpertRemove();
      return;
   }
   
   
   //EventKillTimer();
  }
  
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if (!host_mode) return;
   
   
   if (opened_chart == NULL) return;
   
   MqlTick Latest_Price;
   SymbolInfoTick(Symbol(), Latest_Price);

   MqlTick tick[1];
   tick[0] = Latest_Price;
   
   if (TicksChart)
      hist_maker.converter.OnTickUpdateTicks(tick);
   else
      hist_maker.converter.OnTickUpdateSeconds(tick);
   
   
   CustomTicksAdd(custom_symbol_name, tick);
   ChartRedraw(opened_chart);

}
  

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{

   if (host_mode) return;
   
   if (StringFind(_Symbol,trans.symbol) == -1) return;         //not our symbol, exit


   if  (trans.position != 0)
      ordersIndicator.Sync(trans.position);
      
   return;


   /*
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
   
   if (trans.type == TRADE_TRANSACTION_REQUEST && (trans.order_state == ORDER_STATE_PLACED || trans.order_state == ORDER_STATE_STARTED))         //added new order
         ordersIndicator.Add(trans.order, price_open, tp, sl);
   
   if (trans.order_state == ORDER_STATE_CANCELED
      || trans.order_state == ORDER_STATE_FILLED
      || trans.order_state == ORDER_STATE_REJECTED
      || trans.order_state == ORDER_STATE_EXPIRED
      || trans.order_state == ORDER_STATE_REQUEST_CANCEL
      //|| trans.order_state == ORDER_STATE_
      );
      
      //result.
         //ordersIndicator.Remove(trans.order);
      
   /*
      
      trans.type == TRADE_TRANSACTION_DEAL_ADD
      ||TRADE_TRANSACTION_DEAL_DELETE
      || TRADE_TRANSACTION_DEAL_UPDATE
      || TRADE_TRANSACTION_HISTORY_ADD
      || TRADE_TRANSACTION_HISTORY_DELETE
      || TRADE_TRANSACTION_HISTORY_UPDATE
      || TRADE_TRANSACTION_ORDER_DELETE
      || TRADE_TRANSACTION_ORDER_UPDATE
      || */
      
}


//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   if (host_mode) return;
   return;
   
   for (int l = 0; l < 5; l++)
   {
      CustomTimerTickFunc();
      Sleep(100);
   }
   
   return;
}


void CustomTimerTickFunc()
{
}


 
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
{
}


//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
  if (host_mode) return;
}




//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
{
   
}
//+------------------------------------------------------------------+


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


void DeleteOldSymbolsFunc()
{
   int total = SymbolsTotal(false);
   
   for (int i=0; i < total; i++)
   {
      string symbol_name = SymbolName(i , false);
      
    //  long response;
    //  if (!SymbolInfoInteger(symbol_name, SYMBOL_CUSTOM, response)) continue;       //couldn't get info
      
    //  if (response == 0) continue;                                                  //symbol is not custom
      
      
      if (StringFind(symbol_name, custom_symbol_identifier_affix) == -1) continue;  //did not match
      
      
      if (symbol_name == custom_symbol_name) continue;                              //it's my current symbol
      
   //   if (!SymbolInfoInteger(symbol_name, SYMBOL_SELECT, response)) continue;       //couldn't get info
      
      
   //   if (response == 1) 
      if (!SymbolSelect(symbol_name,false));                                      //deselect if selected
   //         continue;                                                               //couldn't deselect
   
      CustomSymbolDelete(symbol_name);                                              //try to delete
   }
}
