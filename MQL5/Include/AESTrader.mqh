//+------------------------------------------------------------------+
//|                                                    AESTrader.mqh |
//|                                     2020 (c) Oleksii Ocheretenko |
//|                                          https://vk.com/war_k1ng |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Oleksii Ocheretenko"
#property link      "https://vk.com/war_k1ng"
#property version   "1.03"
#include <Trade\Trade.mqh>


class AESTrader
{
private:
                     
                     void Init();
public:              CTrade AESTrader::trade;
                     bool SetStopOrders(ulong ticket, double sl, double tp);
                     AESTrader();
                    ~AESTrader();
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
AESTrader::AESTrader()
{
   Init();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
AESTrader::~AESTrader()
{
}
//+------------------------------------------------------------------+

void AESTrader::Init()
{
//--- зададим MagicNumber для идентификации своих ордеров
   int MagicNumber=777123;
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

bool AESTrader::SetStopOrders(ulong ticket, double sl, double tp)
{
   return trade.PositionModify(ticket, sl, tp);
}