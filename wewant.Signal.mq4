#property copyright "WeWant"
#property link "http://www.moneywang.com"

#include <Arrays\ArrayString.mqh>

#import "WecapitalMT4Socket.dll"
   int MT4initConnect(int port);
   int MT4Send(int socket, int port, string msg, int messagelen);
   string MT4Recv(int socket, int port);
   int Disconnect(int socket);
#import


int Socket = 0;
extern int LocalPort = 6002;
extern int DestPort = 6001;

int OnInit()
{  
   Socket = MT4initConnect(LocalPort);
   
   if( Socket < 0)
   {
      Print("Init connection error");
   }else
   {
      Print("Init connection Succeed!");
   }
   
   EventSetMillisecondTimer(20);
   return(INIT_SUCCEEDED);
}


int SocketSend(string msg)
{
   if (Socket <= 0)
   {
      Print("Socket error!");
      return -1;
   }
   Print(msg);
   if (MT4Send(Socket, DestPort, msg, StringLen(msg)*2 ) <= 0)
   {
      return -1;
   }
   else
   {
      return 1;
   }
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   int err = Disconnect(Socket);
   if(err != 0)printf("Disconnect error: %d", err);
}
void OnTimer()
{
   int orderTotal = OrdersTotal();
   string sendMsg,str;
   if(orderTotal  == 0)
   {
      SocketSend("0");
   }
   else
   {
      CArrayString *arr = new CArrayString; 
      int i = 0,index = 0;
      for(int cpt = 0;cpt < orderTotal;cpt++)
      {
         if(OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES))
         {  
            str = OrderTicket()+","+StringSubstr(OrderSymbol(),0,6)+","+OrderType()+","+OrderLots()+"@";
            if(i%2 == 0)
            {
               arr.Add(str);
               index++;
            }else{
               arr.Update(index-1 , arr[index-1] + str);
            }
            i++;
         }
      }
      arr.Sort();
      SocketSend("s@"+orderTotal);
      for(i=0;i<arr.Total();i++)
      {
         sendMsg = arr[i];
         SocketSend(sendMsg);
         Sleep(200);
      }
      delete arr;
   }
}