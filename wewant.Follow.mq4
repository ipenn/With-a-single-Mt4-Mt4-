#property version   "1.00"
#property strict

int Socket = 0;
extern int LocalPort = 6001;
extern int DestPort = 6002;

extern string Suffix = "";
extern double Multiple = 1;
extern int Magic_Number = 12345;
extern int Max_Slippage = 3;

#import "WecapitalMT4Socket.dll"
   int MT4initConnect(int port);
   int MT4Send(int socket, int port, string msg, int messagelen);
   string MT4Recv(int socket, int port);
   int Disconnect(int socket);
#import

string orders;
int orderTotal;

int OnInit()
{
   Socket = MT4initConnect(LocalPort);
   
   if( Socket < 0)
   {
      Print("Socket connection error");
   }else
   {
      Print("Socket connection Succeed!");
   }
   
   EventSetMillisecondTimer(20);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   int err = Disconnect(Socket);
   if(err != 0)printf("Disconnect error: %d", err);
}

void OnTick()
{

}

void OnTimer()
{
   string msg = MT4Recv(Socket , DestPort);
   if(msg == "0")
   {
      OrderC(0);
      return;
   }
   else if(!msg)
   {
      return;
   }
   int exist = 0, i = 0;
   string strplit[],order[];
   ushort u_sep = StringGetCharacter("@",0);
   int size = StringSplit(msg,u_sep,strplit);
   if(size == 0)
   {
      return;
   }
   if(strplit[0] == "s")
   {
      orders = "";
      orderTotal = StrToInteger(strplit[1]);
      return;
   }
   else
   {
      u_sep = StringGetCharacter(",",0);
      for(i = 0; i < size; i++)
      {
         int elementOfOrder = StringSplit(strplit[i],u_sep,order);
         if(elementOfOrder > 1)
         {
            int exist = 0,cpt = 0 ;
            double lot;
            for(cpt = 0;cpt < OrdersTotal();cpt++)
            {
               if(OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES)  && OrderMagicNumber()== Magic_Number)
               {
                  if(OrderComment() == order[0])
                  {
                     exist++;
                  }
               }
            }
            if(exist == 0)
            {
               lot = MathRound( StrToDouble(order[3])*Multiple *100)/100;
               OrderO(StrToInteger(order[2]), lot, order[1]+Suffix, order[0]);
               exist++;
            }
            orders += order[0] +  ",";
         }
      }
   }
   string orderTickets[];
   StringSplit(orders,u_sep,orderTickets);
   size = ArraySize(orderTickets) - 1;
   if(size == orderTotal)
   {
      for(int cpt = 0;cpt<OrdersTotal();cpt++)
      {  
         if(OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES) && OrderMagicNumber()== Magic_Number)
         {
            exist = 0;
            for(i = 0;i < size; i++)
            {
               if(OrderComment() == orderTickets[i])
               {
                  exist = 1;
               }
            }
            if(exist == 0)
            {
               if(OrderType()==OP_BUY)
               {
                  OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol() , MODE_BID),Max_Slippage,Blue);
               }
               if(OrderType()==OP_SELL)
               {
                  OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol() , MODE_ASK),Max_Slippage,Red);
               }
               int err=GetLastError();
               Print("Error OrderC ",err);
            }
         }
      }
   }  
}


void OrderO(int ord,double LOT,string symbol,string commt)
{
   double SL,TP,openPrice = MarketInfo(symbol , MODE_ASK);
   int error;
   color c = Blue;
   if(ord == OP_SELL)
   {
      c = Red;
      openPrice = MarketInfo(symbol , MODE_BID);
   }
   error=OrderSend(symbol,ord,LOT,openPrice, Max_Slippage ,SL,TP,commt,Magic_Number,0,c);
   if (error==-1) 
   {  
     int err=GetLastError();
     Print("Error OPENORDER ",err);
   }
   return;
}

void OrderC(int ord)
{
   int cpt, orders = OrdersTotal();
   for(cpt = orders - 1;cpt >= 0;cpt--)
   {
      if( OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES) && OrderMagicNumber()== Magic_Number)
      {
         if(OrderType()==OP_BUY && (ord == 1 || ord == 0))
         {
            OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol() , MODE_BID),Max_Slippage,Blue);
         }
         if(OrderType()==OP_SELL&& (ord == -1 || ord == 0))
         {
            OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol() , MODE_ASK),Max_Slippage,Red);
         }
      }
   }
}