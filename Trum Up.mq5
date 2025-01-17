//+------------------------------------------------------------------+
//|                                                     Trump Up.mq4 |
//|                                   Copyright 2024, Tony Programa. |
//|                         https://www.instagram.com/tony_programa/ |
//+------------------------------------------------------------------+
#property copyright "Tony Programa"
#property link      "https://www.instagram.com/tony_programa/"
#property version   "1.00"

enum Permit
  {
   Yes = 0,
   No = 1
  };

enum Type_Lotaje
  {
   Lotaje_Fijo       = 0,  //Lotsize
   Porcentaje_riesgo = 1,  //Percent of Capital
   Dollares          = 2,  //Dollars
  };

enum Type_EA
  {
   Grid = 0,      //EA Grid
   PullBack = 1   //EA Pull Back
  };



enum Day_No_Operation
  {
   Monday      = 1,
   Tuesday     = 2,
   Wednesday   = 3,
   Thursday    = 4,
   Friday      = 5,
   All         = 8 //Operate All Days
  };

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

sinput string ____0____                = "";    //---Time Section---
input int Start_Hour                   = 10;    //Start hour
input int Start_Min                    = 30;    //Start minut
input int Final_Hour                   = 15;    //Final hour
input int Final_Min                    = 30;    //Final min


sinput string ____1____                = "";             //---Trend Section---
input ENUM_TIMEFRAMES Period_Trend     = PERIOD_CURRENT; //Period of Trend and ATR
input int Period_Major_EMA             = 30;             //Period Major EMA
input int Period_Minor_EMA             = 5;              //Period Minor EMA
input double Step_Parabolic_Sar        = 0.02;           //Step of Parabolic Sar
input double Maximun_Parabolic_Sar     = 0.2;            //Maximun of Parabolic Sar

sinput string ____2____                = "";                //---RSI Section---
input ENUM_TIMEFRAMES Period_RSI       = PERIOD_M2;         //Period of RSI
input int Period_Ma_RSI                = 14;                //RSI Ma Period


sinput string ____3____                = "";    //---Type EA---
input Type_EA Type_Exp                 = 0;     //Type Expert Advisor


sinput string ____4____                = "";    //---Section Grid---
input double Lotaje_FP                 = 0.02;  //Lotsize of First Operation
input double Lotsize_Multiplier        = 1.5;   //Lotsize Multiplier
input double Initial_Size_grid_Pip     = 20;    //Initial Grid in Pips
input double Grid_Multiplier           = 1.5;   //Grid Multiplier
input int RSI_Buy_Grid                 = 70;    //Buy for RSI
input int RSI_Sell_Grid                = 30;    //Sell for RSI
input double Profit_USD                = 10;    //Profit in USD First Op.
input double Miltiplier_Profit_USD     = 1.5;   //Miltiplier Profit per Op.
input int Magic_Number_Grid            = 213;   //Magic Number of Grid


sinput string ____5____                = "";    //---Pull Back---
input int Stop_Loss_                   = 50;    //Stop Loss in Pips
input int Take_Profit                  = 50;    //Take Profit in Pips
input int RSI_Buy_Pull                 = 70;    //Buy for RSI
input int RSI_Sell_Pull                = 30;    //Sell for RSI
input Type_Lotaje Risk_Type            = 1;     //Risk for Operation
input double Value_Risk                = 1;     //Value of Risk
input Permit Apply_TS                  = 0;     //Apply Trilling Stop (TS)?
input int Trillind_Stop_Start          = 20;    //Start TS in Pips
input int Trilling_Stop_Step           = 15;    //Dif. SL and Price Current in Pips
input int New_Stop_Loss                = 10;    //New SL in Pips
input Day_No_Operation Day_no_operate  = 5;     //What Day do not operate?
input int Magic_Number_PB              = 156;   //Magic Number of Pull Back



sinput string ____6____                 = "";    //---LotSize Inputs---
sinput double min_lotaje_permit        = 0.10;     //Minimum lotSize
sinput double max_lotaje_permit        = 1;        //Maximun lotSize
sinput int Digits_                     = 2;        //Digits of Lot Size


//----Indicators Buffers
double Major_EMA[], Minor_EMA[], RSI[], PA_SAR[];
int Hndler_Ma_EMA, Handler_Mi_EMA, Handles_RSI, Handles_PA_SAR;


//---For Grid
double Per_Buy_Grid  = false;
double Per_Sell_Grid = false;
int Number_Buys   = 0;
int Number_Sells  = 0;


//---For Pull Back
double Final_LotSize = 0;

//---Otras variables
datetime Expiry   = D'2024.10.25 00:00';
int Bars_Trend    = 0;
int Bars_RSI      = 0;
int Size_Buffer   = 2;
bool Time_Permit = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(TimeCurrent()>Expiry)
     {
      Alert("Expired EA");
      return(INIT_FAILED);
     }

   if(Start_Hour >= 24 || Start_Hour < 0)
     {
      Alert("Error in Start_Hour");
      return(INIT_FAILED);
     }

   if(Final_Hour >= 24 || Final_Hour < 0)
     {
      Alert("Error in Final_Hour");
      return(INIT_FAILED);
     }

   if(Start_Min >= 60 || Start_Min < 0)
     {
      Alert("Error in Start_Min");
      return(INIT_FAILED);
     }

   if(Final_Min >= 60 || Final_Min < 0)
     {
      Alert("Error in Final_Min");
      return(INIT_FAILED);
     }

//---Numbers Bars
   Bars_Trend = iBars(Symbol(),Period_Trend);
   Bars_RSI   = iBars(Symbol(),Period_RSI);


//---Handlers
   Hndler_Ma_EMA     = iMA(Symbol(),Period_Trend,Period_Major_EMA,0,MODE_EMA,PRICE_CLOSE);
   Handler_Mi_EMA    = iMA(Symbol(),Period_Trend,Period_Minor_EMA,0,MODE_EMA,PRICE_CLOSE);
   Handles_PA_SAR    = iSAR(Symbol(),Period_Trend,Step_Parabolic_Sar,Maximun_Parabolic_Sar);
   Handles_RSI       = iRSI(Symbol(),Period_RSI,Period_Ma_RSI,PRICE_CLOSE);



//---buffers
   ChartSetInteger(0,CHART_SHIFT,100);

   ArrayResize(Major_EMA,Size_Buffer);
   ArraySetAsSeries(Major_EMA,true);

   ArrayResize(Minor_EMA,Size_Buffer);
   ArraySetAsSeries(Minor_EMA,true);

   ArrayResize(RSI,Size_Buffer);
   ArraySetAsSeries(RSI,true);

   ArrayResize(PA_SAR,Size_Buffer);
   ArraySetAsSeries(PA_SAR,true);


   int Buffer_MT  = CopyBuffer(Hndler_Ma_EMA,0,0,Size_Buffer,Major_EMA);
   int Buffer_MiT = CopyBuffer(Handler_Mi_EMA,0,0,Size_Buffer,Minor_EMA);
   int Buffer_RSI = CopyBuffer(Handles_RSI,0,0,Size_Buffer,RSI);
   int Buffer_PS  = CopyBuffer(Handles_PA_SAR,0,0,Size_Buffer,PA_SAR);


   if(Buffer_MT < 0 || Buffer_MiT < 0 || Buffer_RSI < 0 || Buffer_PS < 0 )
     {
      Bars_Trend = 0;
      Bars_RSI   = 0;
     }

//---Pull Back
   Final_LotSize = NormalizeDouble(Volume(Risk_Type, Value_Risk, (Stop_Loss_*10*Point())),Digits_);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---Close Operations Grid
   if(Type_Exp == 0 && Number_Positions(Magic_Number_Grid) > 0)//Grid
     {

      double profit_Buy    = Profit_Buy(Magic_Number_Grid);
      double profit_Sell   = Profit_Sell(Magic_Number_Grid);

      int number_buy  = Number_Positions_Buy(Magic_Number_Grid);
      int number_sell = Number_Positions_Sell(Magic_Number_Grid);

      Comment("Prfit Buy: ", NormalizeDouble(profit_Buy,2), " USD", "\nPrfit Sell: ", NormalizeDouble(profit_Sell,2), " USD");

      if(profit_Buy >= (Profit_USD*MathPow(Miltiplier_Profit_USD,number_buy-1)))
         Close_Operation(Magic_Number_Grid, POSITION_TYPE_BUY);

      if(profit_Sell >= (Profit_USD*MathPow(Miltiplier_Profit_USD,number_sell-1)))
         Close_Operation(Magic_Number_Grid, POSITION_TYPE_SELL);

      if(number_buy > 0 && number_sell > 0 && (profit_Sell + profit_Buy) >= - Profit_USD)
        {
         Close_Operation(Magic_Number_Grid, POSITION_TYPE_BUY);
         Close_Operation(Magic_Number_Grid, POSITION_TYPE_SELL);
        }
        
        if(number_buy + number_sell > 3 && (profit_Sell + profit_Buy) >= - Profit_USD*(number_buy + number_sell)/2)
        {
         Close_Operation(Magic_Number_Grid, POSITION_TYPE_BUY);
         Close_Operation(Magic_Number_Grid, POSITION_TYPE_SELL);
        }
     }


//---TS Pull Back
   if(Type_Exp == 1 && Number_Positions(Magic_Number_PB) > 0 && Apply_TS == 0)
      Trilling_Stop(Magic_Number_PB, Trilling_Stop_Step, New_Stop_Loss, Trillind_Stop_Start);


//---Open Operations
   if(Bars_Trend != iBars(Symbol(),Period_Trend) || Bars_RSI  != iBars(Symbol(),Period_RSI))
     {
      bool Permit_Continue = true;
      Bars_Trend = iBars(Symbol(),Period_Trend);
      Bars_RSI   = iBars(Symbol(),Period_RSI);

      int Buffer_MT  = CopyBuffer(Hndler_Ma_EMA,0,0,Size_Buffer,Major_EMA);
      int Buffer_MiT = CopyBuffer(Handler_Mi_EMA,0,0,Size_Buffer,Minor_EMA);
      int Buffer_RSI = CopyBuffer(Handles_RSI,0,0,Size_Buffer,RSI);
      int Buffer_PS  = CopyBuffer(Handles_PA_SAR,0,0,Size_Buffer,PA_SAR);


      if(Buffer_MT < 0 || Buffer_MiT < 0 || Buffer_RSI < 0 || Buffer_PS < 0)
        {
         Bars_Trend = 0;
         Bars_RSI   = 0;
         Permit_Continue = false;
        }

      MqlRates PriceInformation[];
      ArraySetAsSeries(PriceInformation,true);
      CopyRates(Symbol(),Period_Trend,0,Size_Buffer,PriceInformation);

      double Ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
      double Bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);

      //---Section Time Permit
      Time_Permit = false;

      MqlDateTime TIME;
      TimeToStruct(TimeCurrent(), TIME);

      if(Start_Hour < Final_Hour)
         if(TIME.hour >= Start_Hour && TIME.hour <= Final_Hour)
           {
            Time_Permit = true;

            if(TIME.hour == Start_Hour && TIME.min < Start_Min)
               Time_Permit = false;

            if(TIME.hour == Final_Hour && TIME.min > Final_Min)
               Time_Permit = false;
           }


      if(Start_Hour > Final_Hour)
         if(TIME.hour >= Start_Hour || TIME.hour <= Final_Hour)
           {
            Time_Permit = true;

            if(TIME.hour == Start_Hour && TIME.min < Start_Min)
               Time_Permit = false;

            if(TIME.hour == Final_Hour && TIME.min > Final_Min)
               Time_Permit = false;
           }

      if(Day_no_operate != 8)
         if(TIME.day_of_week == Day_no_operate)
            Time_Permit = false;

      //Make Operation
      if(Permit_Continue && Time_Permit)
         if(Type_Exp == 0)//Grid
           {
            int number_buy  = Number_Positions_Buy(Magic_Number_Grid);
            int number_sell = Number_Positions_Sell(Magic_Number_Grid);

            //First Operation Buy
            if(number_buy == 0 && Minor_EMA[1] >  Major_EMA[1] && PA_SAR[1] <= PriceInformation[1].low && RSI[1] < RSI_Buy_Grid)
               Apply_Order(ORDER_TYPE_BUY, Magic_Number_Grid, Symbol(), 0, 0, Lotaje_FP, Ask);

            //First Operation Sell
            if(number_sell == 0 && Minor_EMA[1] <  Major_EMA[1] && PA_SAR[1] >= PriceInformation[1].high && RSI[1] > RSI_Sell_Grid)
               Apply_Order(ORDER_TYPE_SELL, Magic_Number_Grid, Symbol(), 0, 0, Lotaje_FP, Bid);

            //No First Operation Buy
            if(number_buy != 0 && PA_SAR[1] <= PriceInformation[1].low && RSI[1] < RSI_Buy_Grid &&
               Ask < Last_Open_Price_Buy(Magic_Number_Grid) - (Initial_Size_grid_Pip*10*Point()*MathPow(Grid_Multiplier,number_buy-1)))
               Apply_Order(ORDER_TYPE_BUY, Magic_Number_Grid, Symbol(), 0, 0, NormalizeDouble(Lotaje_FP*MathPow(Lotsize_Multiplier,number_buy-1),Digits_), Ask);

            //No First Operation Sell
            if(number_sell != 0 && PA_SAR[1] >= PriceInformation[1].high && RSI[1] > RSI_Sell_Grid &&
               Bid > Last_Open_Price_Sell(Magic_Number_Grid) + (Initial_Size_grid_Pip*10*Point()*MathPow(Grid_Multiplier,number_sell-1)))
               Apply_Order(ORDER_TYPE_SELL, Magic_Number_Grid, Symbol(), 0, 0, NormalizeDouble(Lotaje_FP*MathPow(Lotsize_Multiplier,number_sell-1),Digits_), Bid);
           }
         else//Pull Back
            if(Number_Positions(Magic_Number_PB) == 0)
              {
               //Operation Buy
               if(Minor_EMA[1] >  Major_EMA[1] && PA_SAR[1] <= PriceInformation[1].low  && RSI[1] < RSI_Buy_Pull)
                  Apply_Order(ORDER_TYPE_BUY, Magic_Number_PB, Symbol(), Ask + (Take_Profit*10*Point()), Ask - (Stop_Loss_*10*Point()), Final_LotSize, Ask);

               //Operation Sell
               if(Minor_EMA[1] <  Major_EMA[1] && PA_SAR[1] >= PriceInformation[1].high && RSI[1] > RSI_Sell_Pull)
                  Apply_Order(ORDER_TYPE_SELL, Magic_Number_PB, Symbol(), Bid - (Take_Profit*10*Point()), Bid + (Stop_Loss_*10*Point()), Final_LotSize, Bid);
              }
     }//---Final Open Operations



  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Volume                                                            |
//+------------------------------------------------------------------+
double Volume(int Type_Volume, double Volume, double stop_Loss_)
  {
//---The stop Loss is in Diference between OPen Price and Price Stop Loss in Absolute
   double tick_size  = SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE);
   double lot_step   = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   double lotaje = 0;
   double risk = 0;

   if(tick_size == 0 || tick_value == 0 || lot_step == 0 || Type_Volume == 0)
      return Volume;

   if(Type_Volume == 1)
      risk = AccountInfoDouble(ACCOUNT_BALANCE)*Volume/100;

   if(Type_Volume == 2)
      risk = Volume;

   double Money_Lot_Step = (stop_Loss_/tick_size)*tick_value*lot_step;
   lotaje = NormalizeDouble(((risk/Money_Lot_Step)*lot_step),Digits_);

   if(lotaje < min_lotaje_permit)
     {
      Print("Forzó lotaje mínimo lotaje: ", min_lotaje_permit);
      lotaje = min_lotaje_permit;
     }


   if(lotaje > max_lotaje_permit)
     {
      Print("Forzó lotaje máximo Lotaje_Maximo: ",max_lotaje_permit);
      lotaje = max_lotaje_permit;
     }

   return lotaje;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Apply Order                                                       |
//+------------------------------------------------------------------+
ulong Apply_Order(ENUM_ORDER_TYPE type_operation, int magic_number, string symbol_, double tp, double sl, double lotaje_, double price_order)
  {
   ulong ticket = 0;

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   ZeroMemory(request);
   ZeroMemory(result);

   request.action    =     TRADE_ACTION_DEAL;
   request.symbol    =     symbol_;
   request.volume    =     lotaje_;
   request.type      =     type_operation;
   request.price     =     price_order;
   request.deviation =     500;
   request.magic     =     magic_number;

   if(tp>0)
      request.tp    =  tp;

   if(sl>0)
      request.sl   =  sl;

   request.type_filling  = ORDER_FILLING_FOK;
   if(!OrderSend(request,result))
     {
      request.type_filling   = ORDER_FILLING_IOC;
      if(!OrderSend(request,result))
        {
         request.type_filling  = ORDER_FILLING_BOC;
         if(!OrderSend(request,result))
            Print("Error in Open Operation number: ",GetLastError());
         else
            ticket = result.order;
        }
      else
         ticket = result.order;
     }
   else
      ticket = result.order;

   return ticket;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Trilling Stop                                                     |
//+------------------------------------------------------------------+
void Trilling_Stop(int magic_Number, int difference_TS, int New_Stop_Loss_, int start_TS)
  {
   double Ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double Bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   ZeroMemory(request);
   ZeroMemory(result);

   for(int i = 0; i<PositionsTotal(); i++)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_Number && PositionGetString(POSITION_SYMBOL) == Symbol())
        {
         if(PositionGetDouble(POSITION_SL) != 0)
           {
            if((ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE) ==  POSITION_TYPE_BUY && Ask >  PositionGetDouble(POSITION_SL) + (difference_TS*_Point*10)  &&   Ask > PositionGetDouble(POSITION_PRICE_OPEN) + (start_TS*_Point*10))
              {
               request.position        = PositionGetTicket(i);
               request.action          = TRADE_ACTION_SLTP;
               request.symbol          = Symbol();
               request.sl              = Ask - (New_Stop_Loss_*_Point*10);
               request.tp              = PositionGetDouble(POSITION_TP);

               request.type_filling    = ORDER_FILLING_FOK;

               if(!OrderSend(request,result))
                 {
                  request.type_filling   = ORDER_FILLING_IOC;
                  if(!OrderSend(request,result))
                    {
                     request.type_filling  = ORDER_FILLING_BOC;
                     if(!OrderSend(request,result))
                        Print("Error in Modify Buy number: ",GetLastError());
                    }
                 }
              }


            if((ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE) ==  POSITION_TYPE_SELL && Bid <  PositionGetDouble(POSITION_SL) - (difference_TS*_Point*10)  &&   Bid < PositionGetDouble(POSITION_PRICE_OPEN) - (start_TS*_Point*10))
              {
               request.position        = PositionGetTicket(i);
               request.action          = TRADE_ACTION_SLTP;
               request.symbol          = Symbol();
               request.sl              = Bid + (New_Stop_Loss_*_Point*10);
               request.tp              = PositionGetDouble(POSITION_TP);

               request.type_filling    = ORDER_FILLING_FOK;

               if(!OrderSend(request,result))
                 {
                  request.type_filling   = ORDER_FILLING_IOC;
                  if(!OrderSend(request,result))
                    {
                     request.type_filling  = ORDER_FILLING_BOC;
                     if(!OrderSend(request,result))
                        Print("Error in Modify Sell number: ",GetLastError());
                    }
                 }
              }
           }
         else
           {
            if((ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE) ==  POSITION_TYPE_BUY && Ask > PositionGetDouble(POSITION_PRICE_OPEN) + (start_TS*_Point*10))
              {
               request.position        = PositionGetTicket(i);
               request.action          = TRADE_ACTION_SLTP;
               request.symbol          = Symbol();
               request.sl              = Ask - (New_Stop_Loss_*_Point*10);
               request.tp              = PositionGetDouble(POSITION_TP);

               request.type_filling    = ORDER_FILLING_FOK;

               if(!OrderSend(request,result))
                 {
                  request.type_filling   = ORDER_FILLING_IOC;
                  if(!OrderSend(request,result))
                    {
                     request.type_filling  = ORDER_FILLING_BOC;
                     if(!OrderSend(request,result))
                        Print("Error in Modify Buy number: ",GetLastError());
                    }
                 }
              }


            if((ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE) ==  POSITION_TYPE_SELL && Bid < PositionGetDouble(POSITION_PRICE_OPEN) - (start_TS*_Point*10))
              {
               request.position        = PositionGetTicket(i);
               request.action          = TRADE_ACTION_SLTP;
               request.symbol          = Symbol();
               request.sl              = Bid + (New_Stop_Loss_*_Point*10);
               request.tp              = PositionGetDouble(POSITION_TP);

               request.type_filling    = ORDER_FILLING_FOK;

               if(!OrderSend(request,result))
                 {
                  request.type_filling   = ORDER_FILLING_IOC;
                  if(!OrderSend(request,result))
                    {
                     request.type_filling  = ORDER_FILLING_BOC;
                     if(!OrderSend(request,result))
                        Print("Error in Modify Sell number: ",GetLastError());
                    }
                 }
              }
           }
        }
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Remove Operation                                                  |
//+------------------------------------------------------------------+
void Remove_Operation(ulong ticket_, int magic_number, string symbol_, double lotaje_, ENUM_POSITION_TYPE Type_Position)
  {
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   ZeroMemory(request);
   ZeroMemory(result);

   request.action          = TRADE_ACTION_DEAL;
   request.position        = ticket_;
   request.symbol          = symbol_;
   request.deviation       = 500;
   request.volume          = lotaje_;
   request.magic           = magic_number;


   if(Type_Position==POSITION_TYPE_BUY)
     {
      request.type  = ORDER_TYPE_SELL;
      request.price = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
     }
   else
     {
      request.type  = ORDER_TYPE_BUY;
      request.price = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
     }

   request.type_filling    = ORDER_FILLING_FOK;
   if(!OrderSend(request,result))
     {
      request.type_filling   = ORDER_FILLING_IOC;
      if(!OrderSend(request,result))
        {
         request.type_filling  = ORDER_FILLING_BOC;
         if(!OrderSend(request,result))
            Print("Error in Close Position nuember: ",GetLastError());
        }
     }

  }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|Close All Operation Grid                                          |
//+------------------------------------------------------------------+
void Close_Operation(int magic_Number, ENUM_POSITION_TYPE Type_Position)
  {
   int Limit = PositionsTotal();
   int Count = 0;

   while(Count<Limit)
     {
      if(Number_Positions_Buy(magic_Number)==0 &&  Type_Position == POSITION_TYPE_BUY)
         break;

      if(Number_Positions_Sell(magic_Number)==0 &&  Type_Position == POSITION_TYPE_SELL)
         break;

      for(int i = 0; i<PositionsTotal(); i++)
         if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_Number && PositionGetString(POSITION_SYMBOL) == Symbol() && (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE) == Type_Position)
            Remove_Operation(PositionGetTicket(i), magic_Number, Symbol(), PositionGetDouble(POSITION_VOLUME),(ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE));
      Count++;
     }
  }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|Number Positions                                                  |
//+------------------------------------------------------------------+
int Number_Positions(int magic_number)
  {
   int Number_Operations = 0;

   for(int i = 0; i<PositionsTotal(); i++)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number && PositionGetString(POSITION_SYMBOL) == Symbol())
         Number_Operations++;

   return Number_Operations;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Number Positions  Buy                                             |
//+------------------------------------------------------------------+
int Number_Positions_Buy(int magic_number)
  {
   int Number_Operations = 0;

   for(int i = 0; i<PositionsTotal(); i++)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number && (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && PositionGetString(POSITION_SYMBOL) == Symbol())
         Number_Operations++;

   return Number_Operations;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Number Positions Sell                                             |
//+------------------------------------------------------------------+
int Number_Positions_Sell(int magic_number)
  {
   int Number_Operations = 0;

   for(int i = 0; i<PositionsTotal(); i++)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number && (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetString(POSITION_SYMBOL) == Symbol())
         Number_Operations++;

   return Number_Operations;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Last Open Price  Buy                                             |
//+------------------------------------------------------------------+
double Last_Open_Price_Buy(int magic_number)
  {
   double Price = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number && (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && PositionGetString(POSITION_SYMBOL) == Symbol())
        {
         Price = PositionGetDouble(POSITION_PRICE_OPEN);
         break;
        }

   return Price;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Last Open Price  Sell                                             |
//+------------------------------------------------------------------+
double Last_Open_Price_Sell(int magic_number)
  {
   double Price = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number && (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetString(POSITION_SYMBOL) == Symbol())
        {
         Price = PositionGetDouble(POSITION_PRICE_OPEN);
         break;
        }

   return Price;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Profit  Buy                                                       |
//+------------------------------------------------------------------+
double Profit_Buy(int magic_number)
  {
   double profit = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number && (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && PositionGetString(POSITION_SYMBOL) == Symbol())
         profit = profit + PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

   return profit;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Profit  Sell                                                      |
//+------------------------------------------------------------------+
double Profit_Sell(int magic_number)
  {
   double profit = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number && (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetString(POSITION_SYMBOL) == Symbol())
         profit = profit + PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

   return profit;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Profit Total                                                      |
//+------------------------------------------------------------------+
double Profit_Total(int magic_number)
  {
   double profit = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number && PositionGetString(POSITION_SYMBOL) == Symbol())
         profit = profit + PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

   return profit;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
