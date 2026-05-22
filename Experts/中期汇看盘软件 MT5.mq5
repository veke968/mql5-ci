//+------------------------------------------------------------------+
//|                                   ＄ Trading Make Money Tool.mq4 |
//|                                                          mingyang |
//|                                              http://www.MQL5.com |
//+------------------------------------------------------------------+
#property copyright "＄ Trading Make Money Tool"
#property link      "Copyright © 2023"
#property version   ""
#property description "     "
#property description "★★★欢迎使用★★★"
#property description "【超级交易员·专用面板】"
#property description "1. 凡使用本EA交易面板，视为认可本声明；"
#property description "2. 本交易面板，只作为交易辅助工具，不做任何盈利保证；"
#property description "3. EA交易存在风险，使用者需自行承担风险，无论盈亏都与本EA交易面板开发者无关；"
#property description "4. 使用授权请联系开发者【VX：兆盾科技】"
//#property icon    "ewm.ico"
#property strict

#include <Trade\Trade.mqh>
CTrade myTrade;

//-------------------------------------------------------------//
enum tpye
  {
   aq=1,//单个订单
   bq=2,//单个方向
   cq=3,//多空整体
  };
enum tpy
  {
   aqr=1,//单平
   bqr=2,//全平
  };
//-------------------------------------------------------------//

input string  使用说明="欢迎使用EA交易面板";
input string  面板名称="中期汇看盘软件";
input string  交易格言="长期稳定盈利";

input tpye    方式 =3;                        //1-计算止盈/止损金额方式
input double  止盈金额=0;                     //2-止盈金额
input double  止损金额=0;                     //3-止损金额
input bool    是否开启自动保本=false;         //是否开启自动保本
input int     点数=10;                      //3-盈利保本点数
input bool  是否开启移动止损=false;           //是否开启移动止损
input int     间隔=80;                         //4-移损间隔点数
input int     批量平盈利单数量=10;            //5-按比例【平盈利单】数量
//输入计算盈利最大的几张订单，如不满足设置的数量，只计算最大盈利的那张订单。
input int     批量平亏损单数量=10;            //6-按比例【平亏损单】数量
//输入计算亏损最大的几张订单，如不满足设置的数量，只计算最大亏损的那张订单。
input tpy     选择 =2;                        //7-订单小于按比例数量的平仓方式
input double 盈利金额=0.5;                    //8-止盈价位≥该金额启动平仓
long Numbe[]= {123}; //该组魔术号订单首单回撤平仓
input int        首单盈利点数=0;              //9-首单盈利该点数启动回撤平仓（0=不开启）
input int        首单回撤点数=100;            //10-回撤≥该点数平仓同方向订单【仅订单 Magic=123 有效】

input   color    面板主题颜色=clrMediumSeaGreen; //11-面板主题颜色
input   color    SELL色=C'215,40,40';          //12-SELL 按钮颜色
input   color    BUY色=C'40,40,215';           //13-BUY 按钮颜色

input   color    数据颜色=clrLime;             //14-数据文本颜色
input ENUM_BASE_CORNER 数据位置=CORNER_LEFT_UPPER; //16-数据显示位置
input   int      数据X位置=20;                //15-数据显示X位置
input   int      数据Y位置=20;                //16-数据显示Y位置

input   bool     启动警报=false;               //17-是否启动交易警报
input   datetime 编译时间=__DATETIME__;        //EA最后编写时间

//-------------------------------------------------------------//

int xxx=20;    //面板初始X位置
int yyy=20;     //面板初始Y位置
int currentid=0;
int dpi=96;

int g_as,magi;
int MAGIC=0;
int ticket;
int li_12, li_16;
int 滑点;
int 多首[50],空首[50];

string timefoze;
string 货币对;
string 注释;

double 下单量=0.1;
double 最大下单量=100;
double 止损点数,止损价格,止损价格1;
double 止盈点数,止盈价格,止盈价格1;
double lots=0.01,lot;
double dtppc=0,dtpp,dslpc=0,dslp,ktppc=0,ktpp,kslpc=0,kslp;
double fanduo,fankong,tpj=1,slj=1,多最大值[50],空最小值[51];

int sl,tp,avps,avpb,ysd;
int slshuju,tpshuju,avpss,avpbs,ysds,total,kddls,magics;
int modifiedOrders[200];         // 定义一个全局数组用于储存修改的订单号码
int modifiedOrdersCount = 0;     // 这个计数器将跟踪修改过的订单数量
int btpmodifiedOrders[200];      // 定义一个全局数组用于储存修改的订单号码
int btpmodifiedOrdersCount = 0;  // 这个计数器将跟踪修改过的订单数量
int bslmodifiedOrders[200];      // 定义一个全局数组用于储存修改的订单号码
int bslmodifiedOrdersCount = 0;  // 这个计数器将跟踪修改过的订单数量
int sslmodifiedOrders[200];      // 定义一个全局数组用于储存修改的订单号码
int sslmodifiedOrdersCount = 0;  // 这个计数器将跟踪修改过的订单数量
bool flag1=false;

datetime EndTime=D'2026.12.31 23:00';       //设置允许使用的有效时间。
bool     是否只允许模拟账号使用=false;      //设置允许使用的交易账户类型。
long     Number[]= {-1};                    //设置允许使用的交易账户号码，多账户用","区分。

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   for(int r=0; r<=50; r++)
     {
      空最小值[r]=30000;
     }

   dpi=TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,TRUE);
   EventSetTimer(1);
   面板1();
   timefoze="授权到期："+TimeToString(EndTime,TIME_DATE|TIME_MINUTES);
   ObjectSetString(0,"about",OBJPROP_TEXT,timefoze);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   EventKillTimer();
   删除物件();
   dtppc=dtpp;
   dslpc=dslp;
   ktppc=ktpp;
   kslpc=kslp;
   tpj=fankong;
   slj=fanduo;
   slshuju=sl;
   tpshuju=tp;
   avpss=avps;
   avpbs=avpb;
   ysds=ysd;
   lots=lot;
   kddls=total;
   magics=magi;
   ObjectDelete(0,"title1");
   ObjectDelete(0,"mmm");
   ObjectDelete(0,"guanbi");
   ObjectDelete(0,"symbolx");
   ObjectDelete(0,"symbol");
   ObjectDelete(0,"spread");
   ObjectDelete(0,"profitt");
   ObjectDelete(0,"sell");
   ObjectDelete(0,"ask");
   ObjectDelete(0,"buy");
   ObjectDelete(0,"bid");
   ObjectDelete(0,"guafx");
   ObjectDelete(0,"guatype");
   ObjectDelete(0,"openpricex");
   ObjectDelete(0,"openprice");
   ObjectDelete(0,"lotx");
   ObjectDelete(0,"lot");
   ObjectDelete(0,"kddlx");
   ObjectDelete(0,"kddl");
   ObjectDelete(0,"zonex");
   ObjectDelete(0,"zone");
   ObjectDelete(0,"daoqitimex1");
   ObjectDelete(0,"daoqitime1");
   ObjectDelete(0,"slx");
   ObjectDelete(0,"sl");
   ObjectDelete(0,"tpx");
   ObjectDelete(0,"tp");
   ObjectDelete(0,"ysdx");
   ObjectDelete(0,"ysd");
   ObjectDelete(0,"fgdsx");
   ObjectDelete(0,"fgds");
   ObjectDelete(0,"avpsx");
   ObjectDelete(0,"avps");
   ObjectDelete(0,"avpbx");
   ObjectDelete(0,"avpb");
   ObjectDelete(0,"magicx");
   ObjectDelete(0,"magic");
   ObjectDelete(0,"comtx");
   ObjectDelete(0,"comt");
   ObjectDelete(0,"closesellwin");
   ObjectDelete(0,"closebuywin");
   ObjectDelete(0,"closeall");
   ObjectDelete(0,"closesellx");
   ObjectDelete(0,"closebuyx");
   ObjectDelete(0,"closebuyloss");
   ObjectDelete(0,"closesellloss");
   ObjectDelete(0,"sljx");
   ObjectDelete(0,"slj");
   ObjectDelete(0,"tpjx");
   ObjectDelete(0,"tpj");
   ObjectDelete(0,"submit");
   ObjectDelete(0,"yijian");
   ObjectDelete(0,"deletess");
   ObjectDelete(0,"deletesl");
   ObjectDelete(0,"deletebs");
   ObjectDelete(0,"deletebl");
   ObjectDelete(0,"ktppx");
   ObjectDelete(0,"ktpp");
   ObjectDelete(0,"dtppx");
   ObjectDelete(0,"dtpp");
   ObjectDelete(0,"kslpx");
   ObjectDelete(0,"kslp");
   ObjectDelete(0,"dslpx");
   ObjectDelete(0,"dslp");
   ObjectDelete(0,"about");
   ObjectDelete(0,"bg1");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(使用限制(EndTime,Number,是否只允许模拟账号使用)==0)
     {
      Alert("EA授权到期,请联系开发者:兆盾科技");
      return;
     }
   OnTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer()
  {
   输出信息();
   ObjectSetString(0,"symbol",OBJPROP_TEXT,Symbol());
   string symbol=ObjectGetString(0,"symbol",OBJPROP_TEXT);
   int spread=(int)SymbolInfoInteger(symbol,SYMBOL_SPREAD);
   ObjectSetString(0,"spread",OBJPROP_TEXT,"点差："+IntegerToString(spread));
   int buy=0;
   int sell=0;
   int otype=-1;
   int fgds=(int)GlobalVariableGet("fgds"); //返挂点数点数
   string comt=(string)GlobalVariableGet("comt");;
   sl=int(获取输入框的值("sl"));
   tp=int(获取输入框的值("tp"));
   string tmp=ObjectGetString(0,"magic",OBJPROP_TEXT);;
   int magiCC=StringToInteger(tmp);
   int magic=magiCC;
   double stpj=止盈金额;//空单止盈金额
   double btpj=止盈金额;//多单止盈金额
   double sslj=止损金额;//空单止损金额
   double bslj=止损金额;//多单止损金额
   lot=获取输入框的值("lot");
   string tmp6=ObjectGetString(0,"closebuyx",OBJPROP_TEXT);
   double buyx=StringToDouble(tmp6);
   string tmp7=ObjectGetString(0,"closesellx",OBJPROP_TEXT);
   double sellx=StringToDouble(tmp7);
   fanduo=获取输入框的值("slj");
   fankong=获取输入框的值("tpj");
   ObjectSetString(0,"ask",OBJPROP_TEXT,DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_ASK),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))); //买单开单价格
   ObjectSetString(0,"buy",OBJPROP_TEXT,"买入  "+DoubleToString(Profit_BUY(Symbol(),magic),2));
   ObjectSetString(0,"bid",OBJPROP_TEXT,DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_BID),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))); //卖单开仓价格
   ObjectSetString(0,"sell",OBJPROP_TEXT,"卖出  "+DoubleToString(Profit_SELL(Symbol(),magic),2));
   total=int(获取输入框的值("kddl"));//开单单数
   comt=ObjectGetString(0,"comt",OBJPROP_TEXT);
   货币对=Symbol();
   止损点数=sl;
   止盈点数=tp;
   下单量=lot;
   MAGIC=magic;

// Comment("下单量=",下单量);

   if(ObjectGetInteger(0,"sell",OBJPROP_STATE)==true)
     {
      for(int i=0; i<total; i++)
        {
         注释=comt+string(MAGIC)+"--"+string(sell_VOL(货币对,magic)+1);
         卖下();
        }
      ObjectSetInteger(0,"sell",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"buy",OBJPROP_STATE)==true)
     {
      for(int i=0; i<total; i++)
        {
         注释=comt+string(MAGIC)+"--"+string(buy_VOL(货币对,magic)+1);
         买上();
        }
      ObjectSetInteger(0,"buy",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"closebuywin",OBJPROP_STATE)==true)
     {
      if(buyx==0)
        {
         FindTopNProfits(1,magic,批量平盈利单数量, 1,0,1);
        }
      else
         FindTopNProfits(1,magic,批量平盈利单数量, 1,0,buyx);
      ObjectSetInteger(0,"closebuywin",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"closesellwin",OBJPROP_STATE)==true)
     {
      if(sellx==0)
        {
         FindTopNProfits(1,magic,批量平盈利单数量, 1,1,1);
        }
      else
         FindTopNProfits(1,magic,批量平盈利单数量, 1,1,sellx);
      ObjectSetInteger(0,"closesellwin",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"closebuyloss",OBJPROP_STATE)==true)
     {
      if(buyx==0)
        {
         FindTopNProfits(-1,magic,批量平亏损单数量,0,0,1);
        }
      else
         FindTopNProfits(-1,magic,批量平亏损单数量,0,0,buyx);
      ObjectSetInteger(0,"closebuyloss",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"closesellloss",OBJPROP_STATE)==true)
     {
      if(sellx==0)
        {
         FindTopNProfits(-1,magic,批量平亏损单数量,0,1,1);
        }
      else
         FindTopNProfits(-1,magic,批量平亏损单数量,0,1,sellx);
      ObjectSetInteger(0,"closesellloss",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"closeall",OBJPROP_STATE)==true)
     {
      关闭卖单(货币对,magic,2);
      关闭买单(货币对,magic,2);
      ObjectSetInteger(0,"closeall",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"sljx",OBJPROP_STATE)==true)
     {
      下单量=fanduo*sell_lottotal(货币对,magic);
      关闭卖单(货币对,magic,2);
      注释="平空反多订单"+"--"+string(MAGIC);
      买上();//平空反多
      ObjectSetInteger(0,"sljx",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"tpjx",OBJPROP_STATE)==true)
     {
      下单量=fankong*buy_lottotal(货币对,magic);
      关闭买单(货币对,magic,2);//平多反空
      注释="平多反空订单"+"--"+string(MAGIC);
      卖下();
      ObjectSetInteger(0,"tpjx",OBJPROP_STATE,false);
     }
   if(方式 ==2)
     {
      if((Profit_SELL(Symbol(),magic)>stpj&&stpj!=0)||(sslj!=0&&Profit_SELL(Symbol(),magic)<-sslj))
        {
         关闭卖单(货币对,magic,2);//空单止盈止损出场
        }

      if((Profit_BUY(Symbol(),magic)>btpj&&btpj!=0)||(bslj!=0&&Profit_BUY(Symbol(),magic)<-bslj))
        {
         关闭买单(货币对,magic,2);//多单止盈止损出场
        }
     }
   if(方式 ==3)
     {
      if((Profit_SELL(Symbol(),magic)+Profit_BUY(Symbol(),magic)>stpj&&stpj!=0)||(sslj!=0&&Profit_SELL(Symbol(),magic)+Profit_BUY(Symbol(),magic)<-sslj))
        {
         关闭卖单(货币对,magic,2);//空单止盈止损出场
         关闭买单(货币对,magic,2);//多单止盈止损出场
        }
     }
   dtpp=获取输入框的值("dtpp");
   ktpp=获取输入框的值("ktpp");
   dslp=获取输入框的值("dslp");
   kslp=获取输入框的值("kslp");
   ysd=int(获取输入框的值("ysd"));

   手动空单改止盈("-1",0,tp);
   手动多单改止盈("-1",0,tp);
   手动多单改止损("-1",0,sl);
   手动空单改止损("-1",0,sl);//"-1"

   if(ysd!=0)
     {
      移动止损(货币对,magic,ysd) ;
     }

   if(方式 ==1)
     {
      关闭买上(货币对,magic,btpj,bslj);//空单止盈止损出场
      关闭卖下(货币对,magic,stpj,sslj);//多单止盈止损出场
     }
   if(ObjectGetInteger(0,"slx",OBJPROP_STATE)==true)
     {
      修改多单止损(Symbol(),magic,sl);
      修改空单止损(Symbol(),magic,sl);  //点击按键修改止损点数
      ObjectSetInteger(0,"slx",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"tpx",OBJPROP_STATE)==true)
     {
      修改多单止盈(Symbol(),magic,tp);
      修改空单止盈(Symbol(),magic,tp); //点击按键修改止盈点数
      ObjectSetInteger(0,"tpx",OBJPROP_STATE,false);
     }

   avps=int(获取输入框的值("avps"));
   avpb=int(获取输入框的值("avpb"));

   if(ObjectGetInteger(0,"avpsx",OBJPROP_STATE)==true)
     {
      改空单止盈(Symbol(),magic,空单均价(Symbol(),magic)-avps*SymbolInfoDouble(货币对,SYMBOL_POINT))  ;
      ObjectSetInteger(0,"avpsx",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"avpbx",OBJPROP_STATE)==true)
     {
      改多单止盈(Symbol(),magic,多单均价(Symbol(),magic)+avpb*SymbolInfoDouble(货币对,SYMBOL_POINT))  ;
      ObjectSetInteger(0,"avpbx",OBJPROP_STATE,false);
     }
   if(SymbolInfoDouble(Symbol(),SYMBOL_BID)>多单均价(Symbol(),magic)+avpb*SymbolInfoDouble(货币对,SYMBOL_POINT)&&avpb!=0)
     {
      关闭买单(货币对,magic,2);
     }
   if(SymbolInfoDouble(Symbol(),SYMBOL_ASK)<空单均价(Symbol(),magic)-avps*SymbolInfoDouble(货币对,SYMBOL_POINT)&&avps!=0)
     {
      关闭卖单(货币对,magic,2);
     }
   if(ObjectGetInteger(0,"ktppx",OBJPROP_STATE)==true)
     {
      if(ktpp!=0)
        { 改空单止盈(Symbol(),magic,ktpp);} //点击按键修改空单止盈价位
      ObjectSetInteger(0,"ktppx",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"dtppx",OBJPROP_STATE)==true)
     {
      if(dtpp!=0)
        { 改多单止盈(Symbol(),magic,dtpp);} //点击按键修改多单止盈价位
      ObjectSetInteger(0,"dtppx",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"kslpx",OBJPROP_STATE)==true)
     {
      if(kslp!=0)
        { 改空单止损(Symbol(),magic,kslp);} //点击按键修改空单止损价位
      ObjectSetInteger(0,"kslpx",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"dslpx",OBJPROP_STATE)==true)
     {
      if(dslp!=0)
        { 改多单止损(Symbol(),magic,dslp);} //点击按键修改多单止损价位
      ObjectSetInteger(0,"dslpx",OBJPROP_STATE,false);
     }

   if(SymbolInfoDouble(Symbol(),SYMBOL_BID)<dslp&&dslp!=0)
     {
      关闭买单(货币对,magic,2);
     }
   if((SymbolInfoDouble(Symbol(),SYMBOL_BID)>dtpp&&dtpp!=0))
     {
      关闭买单(货币对,magic,1);
     }
   if(SymbolInfoDouble(Symbol(),SYMBOL_ASK)>kslp&&kslp!=0)
     {
      关闭卖单(货币对,magic,2);
     }
   if((SymbolInfoDouble(Symbol(),SYMBOL_ASK)<ktpp&&ktpp!=0))
     {
      关闭卖单(货币对,magic,1);
     }
   if(g_as==1)
     {
      magi=magic;
     }

   if(Profit_ALL(Symbol(),magi)>=0)
     {
      ObjectSetInteger(0,"profitt",OBJPROP_COLOR,clrLimeGreen);
     }
   else
     {
      ObjectSetInteger(0,"profitt",OBJPROP_COLOR,clrRed);
     }
   ObjectSetString(0,"profitt",OBJPROP_TEXT,"当前获利："+DoubleToString(Profit_ALL(Symbol(),magi),2));


   if(ObjectGetInteger(0,"submit",OBJPROP_STATE)==true)
     {
      submit();//开挂单
      ObjectSetInteger(0,"submit",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"yijian",OBJPROP_STATE)==true)
     {
      deleteguadan(货币对,999);//删除挂单
      ObjectSetInteger(0,"yijian",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"deletess",OBJPROP_STATE)==true)
     {
      deletess(货币对,magic);//删除挂单
      ObjectSetInteger(0,"deletess",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"deletesl",OBJPROP_STATE)==true)
     {
      deletesl(货币对,magic);//删除挂单
      ObjectSetInteger(0,"deletesl",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"deletebs",OBJPROP_STATE)==true)
     {
      deletebs(货币对,magic);//删除挂单
      ObjectSetInteger(0,"deletebs",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"deletebl",OBJPROP_STATE)==true)
     {
      deletebl(货币对,magic);//删除挂单
      ObjectSetInteger(0,"deletebl",OBJPROP_STATE,false);
     }
   if(ObjectGetInteger(0,"openpricex",OBJPROP_STATE)==false)
     {
      ObjectSetInteger(0,"openprice",OBJPROP_READONLY,true);
      ObjectSetString(0,"openprice",OBJPROP_TEXT,DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_ASK),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)));
     }
   if(ObjectGetInteger(0,"openpricex",OBJPROP_STATE)==true)
     {
      ObjectSetInteger(0,"openprice",OBJPROP_READONLY,false);
     }

   if(ObjectGetInteger(0,"mmm",OBJPROP_STATE)==true)
     {
      if(flag1==true)
        {
         面板1();
         ObjectSetString(0,"mmm",OBJPROP_TEXT,"∨");
         flag1=false;
        }
      else
        {
         删除面板1();
         ObjectSetString(0,"mmm",OBJPROP_TEXT,"∧");
         flag1=true;
        }
      ObjectSetInteger(0,"mmm",OBJPROP_STATE,false);
     }

   if(ObjectGetInteger(0,"guanbi",OBJPROP_STATE)==true)
     {
      ExpertRemove();
      ObjectSetInteger(0,"guanbi",OBJPROP_STATE,false);
     }

   if(ObjectGetInteger(0,"guafx",OBJPROP_STATE)==true)
     {
      tmp=ObjectGetString(0,"guafx",OBJPROP_TEXT);

      if(tmp=="BUY / SELL")
        {
         ObjectSetString(0,"guafx",OBJPROP_TEXT,"BUY");
        }
      if(tmp=="BUY")
        {
         ObjectSetString(0,"guafx",OBJPROP_TEXT,"SELL");
        }
      if(tmp=="SELL")
        {
         ObjectSetString(0,"guafx",OBJPROP_TEXT,"BUY / SELL");
        }
      ObjectSetInteger(0,"guafx",OBJPROP_STATE,false);
     }

   if(ObjectGetInteger(0,"guatype",OBJPROP_STATE)==true)
     {
      tmp=ObjectGetString(0,"guatype",OBJPROP_TEXT);
      if(tmp=="STOP / LIMIT")
        {
         ObjectSetString(0,"guatype",OBJPROP_TEXT,"STOP");
        }
      if(tmp=="STOP")
        {
         ObjectSetString(0,"guatype",OBJPROP_TEXT,"LIMIT");
        }
      if(tmp=="LIMIT")
        {
         ObjectSetString(0,"guatype",OBJPROP_TEXT,"STOP / LIMIT");
        }
      ObjectSetInteger(0,"guatype",OBJPROP_STATE,false);
     }

//K线倒计时剩余时间
   li_12 =int(iTime(Symbol(),PERIOD_CURRENT,0) + 60 * PeriodSeconds(PERIOD_CURRENT) - TimeCurrent());
   li_16 = li_12 % 60;
   li_12 = (li_12 - li_12 % 60) / 60;

   ObjectDelete(0,"剩余时间");
   ObjectCreate(0,"剩余时间",OBJ_TEXT,0,iTime(Symbol(),PERIOD_CURRENT,0)+ PeriodSeconds(PERIOD_CURRENT)*120,SymbolInfoDouble(Symbol(),SYMBOL_BID)-100*SymbolInfoDouble(Symbol(),SYMBOL_POINT));
   ObjectSetInteger(0,"剩余时间",OBJPROP_COLOR,clrYellow);
   ObjectSetInteger(0,"剩余时间",OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetString(0,"剩余时间",OBJPROP_TEXT,"<"+string(li_12) + ":" + string(li_16));


//Comment(" 多首[i]=", 多首[0],"  多最大值[i]=",多最大值[0],"  ArraySize(Numbe)=",ArraySize(Numbe),"  SHULIANG ==",buy_VOL(货币对,int(Numbe[0])),"  XHH==",price_BUYfirst(int(Numbe[0])));
   for(int i=0; i<ArraySize(Numbe); i++)
     {
      if(buy_VOL(货币对,int(Numbe[i]))==0)
        {
         多最大值[i]=0;
         多首[i]=0;
        }
      if(buy_VOL(货币对,int(Numbe[i]))>=1&&首单盈利点数!=0)
        {
         if(SymbolInfoDouble(货币对,SYMBOL_ASK)-price_BUYfirst(int(Numbe[i])) >=首单盈利点数*SymbolInfoDouble(货币对,SYMBOL_POINT))
           {
            多首[i]=1;
           }
        }
      if(buy_VOL(货币对,int(Numbe[i]))>=1)
        {
         if(SymbolInfoDouble(货币对,SYMBOL_ASK)>多最大值[i])
           {
            多最大值[i]=SymbolInfoDouble(货币对,SYMBOL_ASK);
           }
        }

      if(多首[i]==1)
        {
         if(首单盈利点数!=0&&多最大值[i]- SymbolInfoDouble(货币对,SYMBOL_ASK)>=首单回撤点数*SymbolInfoDouble(货币对,SYMBOL_POINT))
           {
            Print("首张多单盈利到一定点数且发生回撤，将同方向多单及顺势对冲的空单平仓出场！");
            关闭买单(货币对,int(Numbe[i]),2);
            多首[i]=0;
            多最大值[i]=0;
           }
        }

      if(sell_VOL(货币对,int(Numbe[i]))==0)
        {
         空最小值[i]=0;
         空首[i]=0;
        }
      if(sell_VOL(货币对,int(Numbe[i]))>=1&&首单盈利点数!=0)
        {
         if(price_SELLfirst(int(Numbe[i]))- SymbolInfoDouble(货币对,SYMBOL_BID)>=首单盈利点数*SymbolInfoDouble(货币对,SYMBOL_POINT))
           {
            空首[i]=1;
           }
        }  //else 空首单盈利到一定点数=false;

      if(sell_VOL(货币对,int(Numbe[i]))>=1)
        {
         if(SymbolInfoDouble(货币对,SYMBOL_BID)<空最小值[i])
           {
            空最小值[i]=SymbolInfoDouble(货币对,SYMBOL_BID);
           }
        }
      if(空首[i]==1)
        {
         if(首单盈利点数!=0&&SymbolInfoDouble(货币对,SYMBOL_ASK)-空最小值[i] >=首单回撤点数*SymbolInfoDouble(货币对,SYMBOL_POINT))
           {
            Print("首空单盈利到一定点数且发生回撤，将同方向空单及顺势对冲的多单平仓出场！");
            关闭卖下(货币对,int(Numbe[i]),2);
            空首[i]=0;
            空最小值[i]=30000;

           }
        }
     }
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)

  {
   if(id==CHARTEVENT_MOUSE_MOVE)
     {
      拖动((int)lparam,(int)dparam);
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(id==CHARTEVENT_OBJECT_ENDEDIT)
     {
      if(sparam=="symbol")
        {
         string symbol=ObjectGetString(0,"symbol",OBJPROP_TEXT);
         int spread=(int)SymbolInfoInteger(symbol,SYMBOL_SPREAD);
         ObjectSetString(0,"spread",OBJPROP_TEXT,"点差："+IntegerToString(spread));
         ChartSetSymbolPeriod(0,symbol,PERIOD_CURRENT);
        }


      if(sparam=="zone")    //挂单间距
        {
         string tmp=ObjectGetString(0,sparam,OBJPROP_TEXT);
         int zone=StringToInteger(tmp);
         GlobalVariableSet("zone",zone);
        }

      if(sparam=="daoqitime1")    //挂单到期时间
        {
         string tmp=ObjectGetString(0,sparam,OBJPROP_TEXT);
         int daoqitime1=StringToInteger(tmp);
         GlobalVariableSet("daoqitime1",daoqitime1);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void 删除面板1()
  {
   ObjectDelete(0,"symbolx");
   ObjectDelete(0,"symbol");
   ObjectDelete(0,"spread");
   ObjectDelete(0,"profitt");
   ObjectDelete(0,"sell");
   ObjectDelete(0,"ask");
   ObjectDelete(0,"buy");
   ObjectDelete(0,"bid");
   ObjectDelete(0,"guafx");
   ObjectDelete(0,"guatype");
   ObjectDelete(0,"openpricex");
   ObjectDelete(0,"openprice");
   ObjectDelete(0,"lotx");
   ObjectDelete(0,"lot");
   ObjectDelete(0,"kddlx");
   ObjectDelete(0,"kddl");
   ObjectDelete(0,"zonex");
   ObjectDelete(0,"zone");
   ObjectDelete(0,"daoqitimex1");
   ObjectDelete(0,"daoqitime1");
   ObjectDelete(0,"slx");
   ObjectDelete(0,"sl");
   ObjectDelete(0,"tpx");
   ObjectDelete(0,"tp");
   ObjectDelete(0,"ysdx");
   ObjectDelete(0,"ysd");
   ObjectDelete(0,"fgdsx");
   ObjectDelete(0,"fgds");
   ObjectDelete(0,"avpsx");
   ObjectDelete(0,"avps");
   ObjectDelete(0,"avpbx");
   ObjectDelete(0,"avpb");
   ObjectDelete(0,"magicx");
   ObjectDelete(0,"magic");
   ObjectDelete(0,"comtx");
   ObjectDelete(0,"comt");
   ObjectDelete(0,"closesellwin");
   ObjectDelete(0,"closebuywin");
   ObjectDelete(0,"closeall");
   ObjectDelete(0,"closesellx");
   ObjectDelete(0,"closebuyx");
   ObjectDelete(0,"closebuyloss");
   ObjectDelete(0,"closesellloss");
   ObjectDelete(0,"sljx");
   ObjectDelete(0,"slj");
   ObjectDelete(0,"tpjx");
   ObjectDelete(0,"tpj");
   ObjectDelete(0,"submit");
   ObjectDelete(0,"yijian");
   ObjectDelete(0,"deletess");
   ObjectDelete(0,"deletesl");
   ObjectDelete(0,"deletebs");
   ObjectDelete(0,"deletebl");
   ObjectDelete(0,"ktppx");
   ObjectDelete(0,"ktpp");
   ObjectDelete(0,"dtppx");
   ObjectDelete(0,"dtpp");
   ObjectDelete(0,"kslpx");
   ObjectDelete(0,"kslp");
   ObjectDelete(0,"dslpx");
   ObjectDelete(0,"dslp");
   ObjectDelete(0,"about");
   ObjectSetInteger(0,"bg1",OBJPROP_YSIZE,int(28*dpi/96.0));
  }

//+------------------------------------------------------------------+
//|                  交易面板                                        |
//+------------------------------------------------------------------+
void 面板1()
  {
   int x=xxx;
   int y=yyy;
   int b=0;
   int s=0;
   int otype=-1;
   double profit=0;
   string tmp=ObjectGetString(0,"magic",OBJPROP_TEXT);
   int magic=StringToInteger(tmp);

   edit("bg1",x,y,300,700,"",clrGray);
   ObjectSetInteger(0,"bg1",OBJPROP_READONLY,true);
   edit("title1",x,y,300,29,面板名称,clrWhite,面板主题颜色,clrBlack);
   ObjectSetInteger(0,"title1",OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,"title1",OBJPROP_SELECTED,true);
   ObjectSetInteger(0,"title1",OBJPROP_READONLY,true);
   ObjectSetInteger(0, "title1", OBJPROP_STYLE, STYLE_DOT);

   anniu("mmm",x+245,y+3,26,20,"∨",clrWhite,面板主题颜色,clrBlue);
   ObjectSetInteger(0,"mmm",OBJPROP_FONTSIZE,15);
   anniu("guanbi",x+270,y+3,26,20,"×",clrWhite,面板主题颜色,clrBlue);
   ObjectSetInteger(0,"guanbi",OBJPROP_FONTSIZE,15);
   ObjectSetString(0,"guanbi",OBJPROP_TOOLTIP,"关闭当前EA");

   y+=28;
   edit("symbolx",x+1,y,149,27,"交易品种");
   edit("symbol",151+x,y,148,27,Symbol());
   ObjectSetInteger(0,"symbol",OBJPROP_READONLY,false);
   ObjectSetString(0,"symbol",OBJPROP_TOOLTIP,"默认为当前图表品种，输入需要交易的品种可快速切换品种图表");

   y+=28;
   string symbol=ObjectGetString(0,"symbol",OBJPROP_TEXT);
   int spread=(int)SymbolInfoInteger(symbol,SYMBOL_SPREAD);
   edit("spread",x+1,y,149,20,"点差："+IntegerToString(spread));
   edit("profitt",x+151,y,148,20,"当前获利： "+DoubleToString(Profit_ALL(Symbol(),magic),2));
   ObjectSetString(0,"profitt",OBJPROP_TOOLTIP,"当前品种Magic号总获利金额");

   if(Profit_ALL(Symbol(),magi)>=0)
     {
      ObjectSetInteger(0,"profitt",OBJPROP_COLOR,clrLimeGreen);
     }
   else
     {
      ObjectSetInteger(0,"profitt",OBJPROP_COLOR,clrRed);
     }
   ObjectSetString(0,"profitt",OBJPROP_TEXT,"当前获利："+DoubleToString(Profit_ALL(Symbol(),magi),2));

   if(currentid==0)
     {
      mianpad11();
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void mianpad11()
  {
   g_as=1;
   int x=int(ObjectGetInteger(0,"spread",OBJPROP_XDISTANCE)/(dpi/96.0));
   int y=int(ObjectGetInteger(0,"spread",OBJPROP_YDISTANCE)/(dpi/96.0));
   int magic=(int)GlobalVariableGet("magic");
   int b=0;
   int btype=-1;
   double bprofit=0;

   y+=21;
   anniu("sell",x,y,74,20,"卖出  "+DoubleToString(0,2),clrWhite,SELL色);
   edit("bid",75+x,y,74,20,DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_BID),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)),clrRed);
   edit("ask",150+x,y,74,20,DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_ASK),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)),clrBlue);
   anniu("buy",225+x,y,73,20,"买入  "+DoubleToString(0,2),clrWhite,BUY色);

   y+=21;
   anniu("guafx",x,y,149,20,"BUY / SELL",clrWhite,SELL色);
   anniu("guatype",x+150,y,148,20,"STOP / LIMIT",clrWhite,BUY色);

   y+=21;
   anniu("openpricex",x,y,149,20,"挂单价格",clrBlack,clrAliceBlue);
   edit("openprice",x+150,y,148,20,DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_ASK),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)),clrDarkViolet,clrAliceBlue);
   ObjectSetString(0,"openprice",OBJPROP_TOOLTIP,"默认为当前价格挂单，点【开仓价格】可设置指定价格挂单");

   y+=21;
   edit("lotx",x,y,74,20,"开单手数");
   edit("lot",x+75,y,74,20,DoubleToString(lots,2));
   ObjectSetInteger(0,"lot",OBJPROP_READONLY,FALSE);

   edit("kddlx",x+150,y,74,20,"开单单数");
   if(kddls==0)
     {
      kddls=1;
     }
   edit("kddl",x+225,y,73,20,IntegerToString(kddls));
   ObjectSetInteger(0,"kddl",OBJPROP_READONLY,FALSE);

   y+=21;
   edit("zonex",x,y,74,20,"挂单间距");
   int zone=(int)GlobalVariableGet("zone");
   if(zone==0)
     {
      zone=100;
     }
   edit("zone",x+75,y,74,20,IntegerToString(zone));
   ObjectSetInteger(0,"zone",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"zone",OBJPROP_TOOLTIP,"每张挂单的间距点数");

   edit("daoqitimex1",x+150,y,74,20,"挂单时效");
   int daoqitime1=(int)GlobalVariableGet("daoqitime1");
   if(daoqitime1==0)
     {
      daoqitime1=0;
     }
   edit("daoqitime1",x+225,y,73,20,IntegerToString(daoqitime1));
   ObjectSetInteger(0,"daoqitime1",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"daoqitime1",OBJPROP_TOOLTIP,"当前品种Magic号挂单有效时间（输入分钟），到期自动删除未成交的挂单");

   y+=21;
   anniu("slx",x,y,74,20,"止损点数",clrBlack,clrWhite);
// int sl=(int)GlobalVariableGet("sl");
   edit("sl",x+75,y,74,20,IntegerToString(slshuju));
   ObjectSetInteger(0,"sl",OBJPROP_READONLY,FALSE);
   anniu("tpx",x+150,y,74,20,"止盈点数",clrBlack,clrWhite);
// int tp=(int)GlobalVariableGet("tp");
   edit("tp",x+225,y,73,20,IntegerToString(tpshuju));
   ObjectSetInteger(0,"tp",OBJPROP_READONLY,FALSE);

   y+=21;//设置均价上盈利N点止盈
   anniu("avpsx",x,y,74,20,"空均盈点",clrBlack);
   edit("avps",x+75,y,74,20,IntegerToString(avpss));
   ObjectSetInteger(0,"avps",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"avps",OBJPROP_TOOLTIP,"输入当前品种Magic号空单平均价之下+该点数止盈");

   anniu("avpbx",x+150,y,74,20,"多均盈点",clrBlack);
   edit("avpb",x+225,y,73,20,IntegerToString(avpbs));
   ObjectSetInteger(0,"avpb",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"avpb",OBJPROP_TOOLTIP,"输入当前品种Magic号多单平均价之上+该点数止盈");

   y+=21;
   edit("ysdx",x,y,74,20,"移损点数");
//int ysd=(int)GlobalVariableGet("ysd");
   edit("ysd",x+75,y,74,20,IntegerToString(ysds));
   ObjectSetInteger(0,"ysd",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"ysd",OBJPROP_TOOLTIP,"输入启动移动止损的盈利点数");

   edit("fgdsx",x+150,y,74,20,"反挂点数");
   int fgds=(int)GlobalVariableGet("fgds");
   edit("fgds",x+225,y,73,20,IntegerToString(fgds));
   ObjectSetInteger(0,"fgds",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"fgds",OBJPROP_TOOLTIP,"当前品种Magic号挂STOP单时同时挂一张LIMIT单的间距点数");

   y+=21;
   edit("magicx",x,y,74,20,"MAGIC");
   edit("magic",x+75,y,223,20,IntegerToString(magics));
   ObjectSetInteger(0,"magic",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"magic",OBJPROP_TOOLTIP,"Magic=999,为当前品种所有订单，Magic=0,为手动订单");

   y+=21;
   edit("comtx",x,y,74,20,"订单注释");
   string comt=(string)GlobalVariableGet("comt");
   if(comt=="")
     {
      comt="Make Money--";
     }
   edit("comt",x+75,y,223,20,"Make Money--");
   ObjectSetInteger(0,"comt",OBJPROP_READONLY,FALSE);

   y+=21;
   anniu("closesellwin",x,y,74,20,"平盈利空",clrWhite,SELL色,clrBlack);
   anniu("closesellloss",x+75,y,74,20,"平亏损空",clrWhite,SELL色,clrBlack);
   anniu("closebuyloss",x+150,y,74,20,"平亏损多",clrWhite,BUY色,clrBlack);
   anniu("closebuywin",x+225,y,73,20,"平盈利多",clrWhite,BUY色,clrBlack);

   y+=21;
   edit("closesellx",x,y,74,20,"平空比例",clrWhite,SELL色,clrBlack);
   ObjectSetInteger(0,"closesellx",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"closesellx",OBJPROP_TOOLTIP,"输入平空单的百分比，默认最低平0.01手，0.1=10%，1=100%");

   anniu("closeall",x+75,y,149,20,"一键全平清仓",clrBlack,clrGold,clrBlack);
   edit("closebuyx",x+225,y,73,20,"平多比例",clrWhite,BUY色,clrBlack);
   ObjectSetInteger(0,"closebuyx",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"closebuyx",OBJPROP_TOOLTIP,"输入平多单的百分比，默认最低平0.01手，0.1=10%，1=100%");

   y+=21;
   anniu("sljx",x,y,74,20,"平空反多",clrWhite,SELL色,clrBlack);
   edit("slj",x+75,y,74,20,DoubleToString(slj,2),clrBlack,clrWhite,clrBlack);
   ObjectSetInteger(0,"slj",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"slj",OBJPROP_TOOLTIP,"平空反多，开仓倍数");

   edit("tpj",x+150,y,74,20,DoubleToString(tpj,2),clrBlack,clrWhite,clrBlack);
   anniu("tpjx",x+225,y,73,20,"平多反空",clrWhite,BUY色,clrBlack);
   ObjectSetInteger(0,"tpj",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"tpj",OBJPROP_TOOLTIP,"平多反空，开仓倍数");

   y+=21;
   anniu("yijian",x,y,149,20,"一键删除挂单",clrWhite,SELL色,clrBlack);
   anniu("submit",x+150,y,148,20,"一键提交挂单",clrWhite,BUY色,clrBlack);

   y+=21;
   anniu("deletess",x,y,74,20,"删SELL STOP",clrWhite,SELL色);
   ObjectSetInteger(0,"deletess",OBJPROP_FONTSIZE,8);
   anniu("deletesl",x+75,y,74,20,"删SELL LIMIT",clrWhite,SELL色);
   ObjectSetInteger(0,"deletesl",OBJPROP_FONTSIZE,8);
   anniu("deletebs",x+150,y,74,20,"删BUY STOP",clrWhite,BUY色);
   ObjectSetInteger(0,"deletebs",OBJPROP_FONTSIZE,8);
   anniu("deletebl",x+225,y,73,20,"删BUY LIMIT",clrWhite,BUY色);
   ObjectSetInteger(0,"deletebl",OBJPROP_FONTSIZE,8);

   y+=21;//空单止盈价位设置；
   anniu("ktppx",x,y,74,20,"空止盈价位");
   edit("ktpp",x+75,y,74,20,DoubleToString(ktppc,(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)));
   ObjectSetInteger(0,"ktpp",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"ktpp",OBJPROP_TOOLTIP,"当前品种Magic号空单平仓止盈价位");

//多单止盈价位设置；
   anniu("dtppx",x+150,y,74,20,"多止盈价位");
   edit("dtpp",x+225,y,73,20,DoubleToString(dtppc,(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)));

   ObjectSetInteger(0,"dtpp",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"dtpp",OBJPROP_TOOLTIP,"当前品种Magic号多单平仓止盈价位");

   y+=21;//空单止损价位设置；
   anniu("kslpx",x,y,74,20,"空止损价位");
   edit("kslp",x+75,y,74,20,DoubleToString(kslpc,(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)));
   ObjectSetInteger(0,"kslp",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"kslp",OBJPROP_TOOLTIP,"当前品种Magic号空单平仓止损价位");

//多单止损价位设置；
   anniu("dslpx",x+150,y,74,20,"多止损价位");
   edit("dslp",x+225,y,73,20,DoubleToString(dslpc,(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)));
   ObjectSetInteger(0,"dslp",OBJPROP_READONLY,FALSE);
   ObjectSetString(0,"dslp",OBJPROP_TOOLTIP,"当前品种Magic号多单平仓止损价位");

   y+=21;
   edit("about",x,y,298,20,timefoze) ;
   ObjectSetInteger(0,"bg1",OBJPROP_YSIZE,int(20*22.8*dpi/96.0));
   ObjectSetString(0,"about",OBJPROP_TOOLTIP,"此EA为正版授权，如需获取授权，请联系开发者：兆盾科技");
  }

//+------------------------------------------------------------------+
//|                        移动交易面板                              |
//+------------------------------------------------------------------+
void 拖动(int xx,int yy)
  {
   int x=int(ObjectGetInteger(0,"title1",OBJPROP_XDISTANCE)/(dpi/96.0));
   int y=int(ObjectGetInteger(0,"title1",OBJPROP_YDISTANCE)/(dpi/96.0));
   xxx=x;
   yyy=y;

   move("bg1",x,y);
   move("mmm",x+245,y+3);
   move("guanbi",x+270,y+3);

   y+=28;
   move("symbolx",x+1,y);
   move("symbol",x+151,y);

   y+=28;
   move("spread",x+1,y);
   move("profitt",x+151,y);

   if(ObjectFind(0,"sell")>=0)
     {
      y+=21;
      move("sell",x+1,y);
      move("bid",x+76,y);
      move("ask",x+151,y);
      move("buy",x+226,y);

      y+=21;
      move("guafx",x+1,y);
      move("guatype",x+151,y);

      y+=21;
      move("openpricex",x+1,y);
      move("openprice",x+151,y);

      y+=21;
      move("lotx",x+1,y);
      move("lot",x+76,y);
      move("kddlx",x+151,y);
      move("kddl",x+226,y);

      y+=21;
      move("zonex",x+1,y);
      move("zone",x+76,y);
      move("daoqitimex1",x+151,y);
      move("daoqitime1",x+226,y);

      y+=21;
      move("slx",x+1,y);
      move("sl",x+76,y);
      move("tpx",x+151,y);
      move("tp",x+226,y);

      y+=21;
      move("avpsx",x+1,y);
      move("avps",x+76,y);
      move("avpbx",x+151,y);
      move("avpb",x+226,y);

      y+=21;
      move("ysdx",x+1,y);
      move("ysd",x+76,y);
      move("fgdsx",x+151,y);
      move("fgds",x+226,y);

      y+=21;
      move("magicx",x+1,y);
      move("magic",x+76,y);

      y+=21;
      move("comtx",x+1,y);
      move("comt",x+76,y);

      y+=21;
      move("closesellwin",x+1,y);
      move("closesellloss",x+76,y);
      move("closebuyloss",x+151,y);
      move("closebuywin",x+226,y);

      y+=21;
      move("closesellx",x+1,y);
      move("closeall",x+76,y);
      move("closebuyx",x+226,y);

      y+=21;
      move("sljx",x+1,y);
      move("slj",x+76,y);
      move("tpj",x+151,y);
      move("tpjx",x+226,y);

      y+=21;
      move("yijian",x+1,y);
      move("submit",x+151,y);

      y+=21;
      move("deletess",x+1,y);
      move("deletesl",x+76,y);
      move("deletebs",x+151,y);
      move("deletebl",x+226,y);

      y+=21;
      move("ktppx",x+1,y);
      move("ktpp",x+76,y);
      move("dtppx",x+151,y);
      move("dtpp",x+226,y);

      y+=21;
      move("kslpx",x+1,y);
      move("kslp",x+76,y);
      move("dslpx",x+151,y);
      move("dslp",x+226,y);

      y+=21;
      move("about",x+1,y);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void move(string name,int x,int y)
  {
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,int(x*dpi/96.0));
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,int(y*dpi/96.0));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int kddluum()
  {
   int res=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol())
           {
            if(PositionGetInteger(POSITION_TYPE)>1)
              {
               res++;
              }
           }
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int sell_number(int magic=0)   //卖单计算
  {
   int res=0;
   for(int i=0; i<PositionsTotal() && !IsStopped(); i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && (magic==0 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               res++;
              }
           }
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int buy_number(int magic=0)  //多单计算
  {
   int res=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() &&(magic==0 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               res++;
              }
           }
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closebuyloss(int magic=0)  //平盈利单
  {
   while(win_number(magic)>0 && !IsStopped())
     {
      for(int i=0; i<PositionsTotal() && !IsStopped(); i++)
        {
         if((ticket=PositionGetTicket(i))>0)
           {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() && (magic==0 || PositionGetInteger(POSITION_MAGIC)==magic))
              {
               double p=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_COMMISSION)+PositionGetDouble(POSITION_SWAP);
               if(p>0)
                 {
                  bool res=myTrade.PositionClose(ticket,PositionGetDouble(POSITION_VOLUME));
                  PlaySound("ok");
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int win_number(int magic=0)//盈利单计算
  {
   int res=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() &&(magic==0 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            double p=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_COMMISSION)+PositionGetDouble(POSITION_SWAP);
            if(p>0)
              {
               res++;
              }
           }
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closesellloss(int magic=0)  //平亏损单
  {
   while(loss_number(magic)>0 && !IsStopped())
     {
      for(int i=0; i<PositionsTotal() && !IsStopped(); i++)
        {
         if((ticket=PositionGetTicket(i))>0)
           {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() &&(magic==0 || PositionGetInteger(POSITION_MAGIC)==magic))
              {
               double p=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_COMMISSION)+PositionGetDouble(POSITION_SWAP);
               if(p<0)
                 {
                  bool res=myTrade.PositionClose(ticket,PositionGetDouble(POSITION_VOLUME));
                  PlaySound("ok");
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int loss_number(int magic=0)  //亏损单计算
  {
   int res=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && (magic==0 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            double p=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_COMMISSION)+PositionGetDouble(POSITION_SWAP);
            if(p<0)
              {
               res++;
              }
           }
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeall(int magic=0)  //全部平仓
  {
   while(all_number(magic)>0 && !IsStopped())
     {
      for(int i=0; i<PositionsTotal() && !IsStopped(); i++)
        {
         if((ticket=PositionGetTicket(i))>0)
           {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() && (magic==0 || PositionGetInteger(POSITION_MAGIC)==magic))
              {
               if(PositionGetInteger(POSITION_TYPE)<2)
                 {
                  bool res=myTrade.PositionClose(ticket,PositionGetDouble(POSITION_VOLUME));
                  PlaySound("ok");
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int all_number(int magic=0) //持仓订单计算
  {
   int res=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && (magic==0 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(PositionGetInteger(POSITION_TYPE)<2)
              {
               res++;
              }
           }
        }
     }
   return res;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//一键挂单
void submit()
  {
   string symbol=ObjectGetString(0,"symbol",OBJPROP_TEXT);
   string tmp=ObjectGetString(0,"lot",OBJPROP_TEXT);
   lot=StringToDouble(tmp);
   tmp=ObjectGetString(0,"magic",OBJPROP_TEXT);
   int magic=StringToInteger(tmp);
   tmp=ObjectGetString(0,"sl",OBJPROP_TEXT);
   sl=StringToInteger(tmp);
   tmp=ObjectGetString(0,"tp",OBJPROP_TEXT);
   tp=StringToInteger(tmp);
   tmp=ObjectGetString(0,"zone",OBJPROP_TEXT);
   int zone=StringToInteger(tmp);
   tmp=ObjectGetString(0,"kddl",OBJPROP_TEXT);
   int kddl=StringToInteger(tmp);
   tmp=ObjectGetString(0,"daoqitime1",OBJPROP_TEXT);
   int daoqitime=StringToInteger(tmp);
   string comt=ObjectGetString(0,"comt",OBJPROP_TEXT);
   double p=StringToDouble(ObjectGetString(0,"openprice",OBJPROP_TEXT));
   string guafx=ObjectGetString(0,"guafx",OBJPROP_TEXT);
   string guatype=ObjectGetString(0,"guatype",OBJPROP_TEXT);
//  Print(guafx+","+guatype);
   tmp=ObjectGetString(0,"fgds",OBJPROP_TEXT);
   int fgds=StringToInteger(tmp);
   if(StringFind(guafx,"BUY")>-1 && StringFind(guatype,"STOP")>-1)
     {
      buystop(lot,p,zone,kddl,sl,tp,comt,magic,daoqitime);
      if(fgds!=0)
        {
         selllimit(lot,p+fgds*SymbolInfoDouble(Symbol(),SYMBOL_POINT),zone,1,sl,tp,comt,magic,daoqitime);
        }
     }
   if(StringFind(guafx,"BUY")>-1 && StringFind(guatype,"LIMIT")>-1)
     {
      buylimit(lot,p,zone,kddl,sl,tp,comt,magic,daoqitime);
     }
   if(StringFind(guafx,"SELL")>-1 && StringFind(guatype,"STOP")>-1)
     {
      sellstop(lot,p,zone,kddl,sl,tp,comt,magic,daoqitime);
      if(fgds!=0)
        {
         buylimit(lot,p-fgds*SymbolInfoDouble(Symbol(),SYMBOL_POINT),zone,1,sl,tp,comt,magic,daoqitime);
        }
     }
   if(StringFind(guafx,"SELL")>-1 && StringFind(guatype,"LIMIT")>-1)
     {
      selllimit(lot,p,zone,kddl,sl,tp,comt,magic,daoqitime);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void buystop(double lotP,double p,int zone,int kddl,int sls,int tps,string comt,int magic,int t)
  {
   if(lotP>0 && p>0 && zone>0 && kddl>0)
     {
      for(int i=1; i<=kddl; i++)
        {
         double cp=p+i*zone*SymbolInfoDouble(Symbol(),SYMBOL_POINT);//挂单价格
         double slp=cp-sls*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
         double tpp=cp+tps*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
         if(sls==0)
           {
            slp=0;
           }
         if(tps==0)
           {
            tpp=0;
           }
         datetime time=TimeCurrent()+t*60;
         if(t==0)
           {
            time=0;
           }
         myTrade.BuyStop(lotP,cp,Symbol(),slp,tpp,ORDER_TIME_GTC,0,comt+string(magic)+"--"+string(buystop_number(Symbol(),magic)+1),magic);
         //PlaySound("ok");
         if(启动警报)
            Alert(Symbol()+"   ---   BUY STOP   ---   一键挂单成功");
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void buylimit(double lotP,double p,int zone,int kddl,int sls,int tps,string comt,int magic,int t)
  {
   if(lotP>0 && p>0 && zone>0 && kddl>0)
     {
      for(int i=1; i<=kddl; i++)
        {
         double cp=p-i*zone*SymbolInfoDouble(Symbol(),SYMBOL_POINT);//挂单价格
         double slp=cp-sls*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
         double tpp=cp+tps*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
         if(sls==0)
           {
            slp=0;
           }
         if(tps==0)
           {
            tpp=0;
           }
         datetime time=TimeCurrent()+t*60;
         if(t==0)
           {
            time=0;
           }
         myTrade.BuyLimit(lotP,cp,Symbol(),slp,tpp,ORDER_TIME_GTC,0,comt+string(magic)+"--"+string(buylimit_number(Symbol(),magic)+1),magic);
         //PlaySound("ok");
         if(启动警报)
            Alert(Symbol()+"   ---   BUY LIMIT   ---   一键挂单成功");
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sellstop(double lotP,double p,int zone,int kddl,int sls,int tps,string comt,int magic,int t)
  {
   if(lotP>0 && p>0 && zone>0 && kddl>0)
     {
      for(int i=1; i<=kddl; i++)
        {
         double cp=p-i*zone*SymbolInfoDouble(Symbol(),SYMBOL_POINT);//挂单价格
         double slp=cp+sls*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
         double tpp=cp-tps*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
         if(sls==0)
           {
            slp=0;
           }
         if(tps==0)
           {
            tpp=0;
           }
         datetime time=TimeCurrent()+t*60;
         if(t==0)
           {
            time=0;
           }
         myTrade.SellStop(lotP,cp,Symbol(),slp,tpp,ORDER_TIME_GTC,0,comt+string(magic)+"--"+string(sellstop_number(Symbol(),magic)+1),magic);
         //PlaySound("ok");
         if(启动警报)
            Alert(Symbol()+"   ---   SELL STOP   ---   一键挂单成功");
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void selllimit(double lotP,double p,int zone,int kddl,int sls,int tps,string comt,int magic,int t)
  {
   if(lotP>0 && p>0 && zone>0 && kddl>0)
     {
      for(int i=1; i<=kddl; i++)
        {
         double cp=p+i*zone*SymbolInfoDouble(Symbol(),SYMBOL_POINT);//挂单价格
         double slp=cp+sls*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
         double tpp=cp-tps*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
         if(sls==0)
           {
            slp=0;
           }
         if(tps==0)
           {
            tpp=0;
           }

         datetime time=TimeCurrent()+t*60;
         if(t==0)
           {
            time=0;
           }
         myTrade.SellLimit(lotP,cp,Symbol(),slp,tpp,ORDER_TIME_GTC,0,comt+string(magic)+"--"+string(selllimit_number(Symbol(),magic)+1),magic);
         //PlaySound("ok");
         if(启动警报)
            Alert(Symbol()+"   ---   SELL LIMIT   ---   一键挂单成功");
        }
     }
  }

//+------------------------------------------------------------------+
//|                           一键清除挂单                           |
//+------------------------------------------------------------------+
void deleteguadan(string 币对="-1",int magic=999)
  {
   while(guadannum(币对,magic)>0)
     {
      for(int i=0; i<PositionsTotal(); i++)
        {
         if((ticket=PositionGetTicket(i))>0)
           {
            if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
              {
               if(PositionGetInteger(POSITION_TYPE)>0)
                 {
                  bool res=myTrade.OrderDelete(ticket);
                  //PlaySound("ok");
                  if(启动警报)
                     Alert(Symbol()+"   ---   一键清除所有挂单");
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int guadannum(string 币对="-1",int magic=999)
  {
   int res=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(PositionGetInteger(POSITION_TYPE)>1)
              {
               res++;
              }
           }
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deletess(string 币对="-1",int magic=999)    //删除 sell stop挂单
  {
   while(sellstop_number(币对,magic)>0)
     {
      for(int i=0; i<PositionsTotal(); i++)
        {
         if((ticket=PositionGetTicket(i))>0)
           {
            if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
              {
               if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_SELL_STOP)
                 {
                    {
                     bool res=myTrade.OrderDelete(ticket);
                     //PlaySound("ok");
                     if(启动警报)
                        Alert(Symbol()+"   ---   删除·SELL STOP·挂单成功");
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int sellstop_number(string 币对="-1",int magic=999)  //sell stop 挂单计算
  {
   int res=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            //double p=OrderProfit()+OrderCommission()+OrderSwap();
            if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_SELL_STOP)
              {
               res++;
              }
           }
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deletesl(string 币对="-1",int magic=999)    //删除sell limit挂单
  {
   while(selllimit_number(币对,magic)>0)
     {
      for(int i=0; i<PositionsTotal(); i++)
        {
         if((ticket=PositionGetTicket(i))>0)
           {
            if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
              {
               if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_SELL_LIMIT)
                 {
                    {
                     bool res=myTrade.OrderDelete(ticket);
                     //PlaySound("ok");
                     if(启动警报)
                        Alert(Symbol()+"   ---   删除·SELL LIMIT·挂单成功");
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int selllimit_number(string 币对="-1",int magic=999)  //sell stop 挂单计算
  {
   int res=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            //double p=OrderProfit()+OrderCommission()+OrderSwap();
            if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_SELL_LIMIT)
              {
               res++;
              }
           }
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deletebs(string 币对="-1",int magic=999)       //删除 buy stop挂单
  {
   while(buystop_number(币对,magic)>0)
     {
      for(int i=0; i<PositionsTotal(); i++)
        {
         if((ticket=PositionGetTicket(i))>0)
           {
            if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
              {
               if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_BUY_STOP)
                 {
                    {
                     bool res=myTrade.OrderDelete(ticket);
                     //PlaySound("ok");
                     if(启动警报)
                        Alert(Symbol()+"   ---   删除·BUY STOP·挂单成功");
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int buystop_number(string 币对="-1",int magic=999)  //buy stop 挂单计算
  {
   int res=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            // double p=OrderProfit()+OrderCommission()+OrderSwap();
            if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_BUY_STOP)
              {
               res++;
              }
           }
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deletebl(string 币对="-1",int magic=999)    //删除 buy limit挂单
  {
   while(buylimit_number(币对,magic)>0)
     {
      for(int i=0; i<PositionsTotal(); i++)
        {
         if((ticket=PositionGetTicket(i))>0)
           {
            if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
              {
               if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_BUY_LIMIT)
                 {
                  bool res=myTrade.OrderDelete(ticket);
                  //PlaySound("ok");
                  if(启动警报)
                     Alert(Symbol()+"   ---   删除·BUY LIMIT·挂单成功");
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int buylimit_number(string 币对="-1",int magic=999)  //buy stop 挂单计算
  {
   int res=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            // double p=OrderProfit()+OrderCommission()+OrderSwap();
            if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_BUY_LIMIT)
              {
               res++;
              }
           }
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//| 下买单模块                                                       |
//+------------------------------------------------------------------+
void 买上()
  {
//将下单量的数值转化成指定的精度。
   下单量 = NormalizeDouble(下单量, 2);
//限制下单量的数值必须大于系统默认该货币对的最小下单量。
   if(下单量<SymbolInfoDouble(货币对,SYMBOL_VOLUME_MIN))
     {
      下单量=SymbolInfoDouble(货币对,SYMBOL_VOLUME_MIN);
     }
//限制最大下单量。
   if(下单量>最大下单量)
     {
      下单量=最大下单量;
     }
//限制下单量的数值必须小于系统默认该货币对的最大下单量。
   if(下单量>SymbolInfoDouble(货币对,SYMBOL_VOLUME_MAX))
     {
      下单量=SymbolInfoDouble(货币对,SYMBOL_VOLUME_MAX);
     }
//计算订单的止盈价格。
   if(止盈点数==0)
     {
      止盈价格=0;
     }
   if(止盈点数>0)
     {
      止盈价格=(SymbolInfoDouble(货币对,SYMBOL_ASK))+(止盈点数*SymbolInfoDouble(货币对,SYMBOL_POINT));
     }
//计算订单的止损价格。
   if(止损点数==0)
     {
      止损价格=0;
     }
   if(止损点数>0)
     {
      止损价格=(SymbolInfoDouble(货币对,SYMBOL_ASK))-(止损点数*SymbolInfoDouble(货币对,SYMBOL_POINT));
     }
//完成下买单的动作。
   if(myTrade.Buy(下单量,货币对,SymbolInfoDouble(货币对,滑点,止损价格,止盈价格)) ticket=(int)myTrade.ResultOrder();
   if(ticket<0)
     {
      if(启动警报)
        { Alert("下单失败："+IntegerToString(GetLastError())); }
     }
   else
     {
      if(启动警报)
        { Alert(货币对+"   ---   市价买入   ---   下单成功");}
     }
  }
//+-------------------------------------------------------------------+
//| 下卖单模块                                                        |
//+-------------------------------------------------------------------+
void 卖下()
  {
//将下单量的数值转化成指定的精度。
   下单量 = NormalizeDouble(下单量, 2);
//限制下单量的数值必须大于系统默认该货币对的最小下单量。
   if(下单量<SymbolInfoDouble(货币对,SYMBOL_VOLUME_MIN))
     {
      下单量=SymbolInfoDouble(货币对,SYMBOL_VOLUME_MIN);
     }
//限制最大下单量。
   if(下单量>最大下单量)
     {
      下单量=最大下单量;
     }
//限制下单量的数值必须小于系统默认该货币对的最大下单量。
   if(下单量>SymbolInfoDouble(货币对,SYMBOL_VOLUME_MAX))
     {
      下单量=SymbolInfoDouble(货币对,SYMBOL_VOLUME_MAX);
     }
//计算订单的止盈价格。
   if(止盈点数==0)
     {
      止盈价格=0;
     }
   if(止盈点数>0)
     {
      止盈价格=(SymbolInfoDouble(货币对,SYMBOL_BID))-(止盈点数*SymbolInfoDouble(货币对,SYMBOL_POINT));
     }
//计算订单的止损价格。
   if(止损点数==0)
     {
      止损价格=0;
     }
   if(止损点数>0)
     {
      止损价格=(SymbolInfoDouble(货币对,SYMBOL_BID))+(止损点数*SymbolInfoDouble(货币对,SYMBOL_POINT));
     }
//完成下买单的动作。
   if(myTrade.Sell(下单量,货币对,SymbolInfoDouble(货币对,滑点,止损价格,止盈价格)) ticket=(int)myTrade.ResultOrder();
   if(ticket<0)
     {
      if(启动警报)
        { Alert("下单失败："+IntegerToString(GetLastError())); }
     }
   else
     {
      if(启动警报)
        { Alert(货币对+"   ---   市价卖出   ---   下单成功");}
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Profit_ALL(string SYMBOL="-1",int magic=999)
  {
   double bz=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if((SYMBOL=="-1" || PositionGetString(POSITION_SYMBOL)==SYMBOL) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {bz+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION);}
        }
     }
   return(bz);
  }
//+------------------------------------------------------------------+
//|  空单价格                                                        |
//+------------------------------------------------------------------+
double Profit_SELL(string 币对="-1",int magic=999)
  {
   double bz=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&&(币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {bz+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION);}
        }
     }
   return(bz);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Profit_BUY(string 币对="-1",int magic=999)
  {
   double bz=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&&(币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {bz+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION);}
        }
     }
   return(bz);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void 关闭买单(string symbol="",int magic=999,int biaozhi=0)
  {
   if(symbol=="")
      symbol=Symbol();
//定义要用到的局部变量。
   double 卖价;
   double 手数;
   int 订单类型;
   int i;
   bool result = false;
   int 订单号;
//遍历所有订单
   for(i=PositionsTotal()-1; i>=0; i--)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         ////选择符合要求的订单。
         if(PositionsTotal()>0)
           {
            if((symbol=="-1" || PositionGetString(POSITION_SYMBOL)==symbol)  && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic)&&(biaozhi==2|| (biaozhi==1&&PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION)>盈利金额)||(biaozhi==-1&&PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION)<0)))
              {
               //获取要用到的变量数值。
               卖价=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
               订单号=ticket;
               手数=PositionGetDouble(POSITION_VOLUME);
               订单类型=PositionGetInteger(POSITION_TYPE);
               switch(订单类型)
                 {
                  //如果是买单类型，将其关闭。
                  case POSITION_TYPE_BUY:
                     result = myTrade.PositionClose(订单号, 手数);
                     break;
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void 关闭卖单(string symbol="",int magic=999,int biaozhi=0)
  {
//定义要用到的局部变量。
   if(symbol=="")
      symbol=Symbol();
   double 买价;
   double 手数;
   int 订单类型;
   int i;
   bool result = false;
   int 订单号;
//遍历所有订单
   for(i=PositionsTotal()-1; i>=0; i--)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         //选择符合要求的订单。
         if(PositionsTotal()>0)
           {
            //获取要用到的变量数值。
            if((symbol=="-1" || PositionGetString(POSITION_SYMBOL)==symbol)  && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic)&&(biaozhi==2|| (biaozhi==1&&PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION)>盈利金额)||(biaozhi==-1&&PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION)<0)))
              {
               买价=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
               订单号=ticket;
               手数=PositionGetDouble(POSITION_VOLUME);
               订单类型=PositionGetInteger(POSITION_TYPE);
               switch(订单类型)
                 {
                  //如果是卖单类型，将其关闭。
                  case POSITION_TYPE_SELL:
                     result = myTrade.PositionClose(订单号, 手数);
                     break;
                 }
               // if(result) printf("%s%s多单平仓成功！", 货币对,策略名称 );
               // else printf("%s%s多单平仓不成功，错误代码是", 货币对,策略名称, GetLastError());
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|        修改多单止损                                              |
//+------------------------------------------------------------------+
void 修改多单止盈(string 币对="-1",int magic=999,double 多止盈点数=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(多止盈点数!=0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&&NormalizeDouble(PositionGetDouble(POSITION_TP),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)+多止盈点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
              {
               res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL),NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)+多止盈点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL))SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)), 0,CLR_NONE);
              }
            if(多止盈点数==0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              {
               res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL),0);

              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|        修改多单止损                                              |
//+------------------------------------------------------------------+
void 修改空单止盈(string 币对="-1",int magic=999,double 空止盈点数=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(空止盈点数!=0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&&NormalizeDouble(PositionGetDouble(POSITION_TP),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)-空止盈点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
              {
               res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL),NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)-空止盈点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL))SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)), 0,CLR_NONE);

              }
            if(空止盈点数==0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
              {
               res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL),0);

              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|        修改多单止损                                              |
//+------------------------------------------------------------------+
void 修改多单止损(string 币对="-1",int magic=999,double 多止损点数=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(多止损点数!=0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&&NormalizeDouble(PositionGetDouble(POSITION_SL),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)-多止损点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
              {
               res1=myTrade.PositionModify(ticket,NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)-多止损点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT))),PositionGetDouble(POSITION_TP), 0,CLR_NONE);
              }
            if(多止损点数==0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              {
               res1=myTrade.PositionModify(ticket,0,PositionGetDouble(POSITION_TP));
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|        修改多单止损                                              |
//+------------------------------------------------------------------+
void 修改空单止损(string 币对="-1",int magic=999,double 空止损点数=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(空止损点数!=0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&&NormalizeDouble(PositionGetDouble(POSITION_SL),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)+空止损点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
              {
               // Print("前面=",NormalizeDouble(OrderStopLoss(),Digits),"  后面=",NormalizeDouble(OrderOpenPrice()+空止损点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT),Digits));

               res1=myTrade.PositionModify(ticket, NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)+空止损点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT))),PositionGetDouble(POSITION_TP), 0,CLR_NONE);

              }
            if(空止损点数==0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
              {
               res1=myTrade.PositionModify(ticket,0,PositionGetDouble(POSITION_TP));
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|   多单均价                                                       |
//+------------------------------------------------------------------+
double 多单均价(string 币对="-1",int magic=999)
  {
   double 买上总 = 0;
   double 买上平均价 = 0;
   double 买上注 = 0;

   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {

            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              {
               //计算特定买单的总价。
               买上总 += PositionGetDouble(POSITION_PRICE_OPEN) * PositionGetDouble(POSITION_VOLUME);
               //计算特定买单的下单量之和。
               买上注 += PositionGetDouble(POSITION_VOLUME);
               //计算特定买单的平均价格。
               买上平均价 = NormalizeDouble(买上总/ 买上注,(int) SymbolInfoInteger(PositionGetString(POSITION_SYMBOL),SYMBOL_DIGITS));
              }
           }
        }
     }
   return(买上平均价);
  }

//+------------------------------------------------------------------+
//|空单均价                                                          |
//+------------------------------------------------------------------+
double 空单均价(string 币对="-1",int magic=999)
  {
   double  卖下总= 0;
   double  卖下平均价 = 0;
   double  卖下注 = 0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
              {
               //计算特定卖单的总价。
               卖下总 += PositionGetDouble(POSITION_PRICE_OPEN) * PositionGetDouble(POSITION_VOLUME);
               //计算特定卖单的下单量之和。
               卖下注+= PositionGetDouble(POSITION_VOLUME);
               //计算特定卖单的平均价格。
               卖下平均价 =  NormalizeDouble(卖下总/ 卖下注, (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL),SYMBOL_DIGITS));
              }
           }
        }
     }
   return(卖下平均价);
  }
//+------------------------------------------------------------------+
//|        修改多单止损                                              |
//+------------------------------------------------------------------+
void 改多单止盈(string 币对="-1",int magic=999,double 多止盈价格=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&&NormalizeDouble(PositionGetDouble(POSITION_TP),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(多止盈价格,(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
              {
               res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL),NormalizeDouble(多止盈价格)), 0,CLR_NONE);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|        修改多单止损                                              |
//+------------------------------------------------------------------+
void 改空单止盈(string 币对="-1",int magic=999,double 空止盈价格=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&&NormalizeDouble(PositionGetDouble(POSITION_TP),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(空止盈价格,(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
              {
               res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL),NormalizeDouble(空止盈价格)), 0,CLR_NONE);

              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|        修改多单止损                                              |
//+------------------------------------------------------------------+
void 改多单止损(string 币对="-1",int magic=999,double 多止损价格=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&&NormalizeDouble(PositionGetDouble(POSITION_SL),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(多止损价格,(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
              {
               res1=myTrade.PositionModify(ticket, NormalizeDouble(多止损价格,(int)SymbolInfoInteger(Symbol()), 0,CLR_NONE);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|        修改多单止损                                              |
//+------------------------------------------------------------------+
void 改空单止损(string 币对="-1",int magic=999,double 空止损价格=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&&NormalizeDouble(PositionGetDouble(POSITION_SL),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(空止损价格,(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
              {
               res1=myTrade.PositionModify(ticket, NormalizeDouble(空止损价格,(int)SymbolInfoInteger(Symbol()), 0,CLR_NONE);

              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void 移动止损(string 币对="-1",int magic=999,int TS=10)
  {
//TS为移动止损点数。
   if(TS >= 5)
     {
      int tota = PositionsTotal();
      for(int i = 0; i < tota; i++)
        {
         if((ticket=PositionGetTicket(i))>0)
           {
            if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
              {
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                 {
                  if(是否开启自动保本==true)
                    {
                     if(SymbolInfoDouble(货币对,SYMBOL_BID) - PositionGetDouble(POSITION_PRICE_OPEN) > TS * SymbolInfoDouble(货币对,SYMBOL_POINT)&&(PositionGetDouble(POSITION_SL)==0||PositionGetDouble(POSITION_SL)<PositionGetDouble(POSITION_PRICE_OPEN)))
                       {

                        bool res1=myTrade.PositionModify(ticket, SymbolInfoDouble(货币对,SYMBOL_BID) - TS * SymbolInfoDouble(货币对,SYMBOL_POINT), PositionGetDouble(POSITION_TP), 0,CLR_NONE);

                       }
                    }
                  if(是否开启移动止损==true)
                    {
                     if(SymbolInfoDouble(货币对,SYMBOL_BID)-PositionGetDouble(POSITION_SL) > (TS+间隔) * SymbolInfoDouble(货币对,SYMBOL_POINT)&&PositionGetDouble(POSITION_SL)!=0&&PositionGetDouble(POSITION_SL)>PositionGetDouble(POSITION_PRICE_OPEN))
                       {
                        //满足条件修改订单的止损价格。
                        bool res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL)+间隔* SymbolInfoDouble(货币对,SYMBOL_POINT)),CLR_NONE);
                       }
                    }
                 }

               else
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                    {
                     if(是否开启自动保本==true)
                       {
                        if(PositionGetDouble(POSITION_PRICE_OPEN) - SymbolInfoDouble(货币对,SYMBOL_ASK) > TS * SymbolInfoDouble(货币对,SYMBOL_POINT)&&(PositionGetDouble(POSITION_SL)==0||PositionGetDouble(POSITION_SL)>PositionGetDouble(POSITION_PRICE_OPEN)))
                          {

                           bool ress=myTrade.PositionModify(ticket, SymbolInfoDouble(货币对,SYMBOL_ASK) + TS * SymbolInfoDouble(货币对,SYMBOL_POINT), PositionGetDouble(POSITION_TP), 0,CLR_NONE);
                          }
                       }
                     if(是否开启移动止损==true)
                       {
                        if(PositionGetDouble(POSITION_SL)- SymbolInfoDouble(货币对,SYMBOL_ASK) > (TS+间隔) * SymbolInfoDouble(货币对,SYMBOL_POINT) && PositionGetDouble(POSITION_SL)!= 0.0&&PositionGetDouble(POSITION_SL)<PositionGetDouble(POSITION_PRICE_OPEN))
                          {
                           //满足条件修改订单的止损价格。
                           Print("RR=",PositionGetDouble(POSITION_SL),"  差值=",PositionGetDouble(POSITION_SL)- SymbolInfoDouble(货币对,SYMBOL_ASK));
                           bool ress=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL)-间隔* SymbolInfoDouble(货币对,SYMBOL_POINT)),CLR_NONE);
                          }
                       }
                    }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|  多单数量                                                        |
//+------------------------------------------------------------------+
int buy_VOL(string 币对="-1",int magic=999)
  {
   int ba=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&&(币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {ba++;}
        }
     }
   return(ba);
  }

//+------------------------------------------------------------------+
//|  空单数量                                                        |
//+------------------------------------------------------------------+
int sell_VOL(string 币对="-1",int magic=999)
  {
   int cc=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&&(币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {cc++;}
        }
     }
   return(cc);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int number()
  {
   int res=0;
   for(int i=0; i<ObjectsTotal() && IsStopped()==FALSE; i++)
     {
      string objname=ObjectName(0,i);
      string mm=IntegerToString(i);
      if(objname!="bg1" && objname!="title1" && objname!="mmm")
        {
         res++;
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                        编辑框                                    |
//+------------------------------------------------------------------+
void edit(string 物件名称,int x,int y,int 宽度,int 高度,
          string 显示文本,color 字体颜色=clrBlack,color 背景颜色=clrWhite,color 边框颜色=clrBlack)
  {
//创建编辑框
   ObjectCreate(0,物件名称,OBJ_EDIT,0,0,0);
//设置x坐标
   ObjectSetInteger(0,物件名称,OBJPROP_XDISTANCE,int(x*dpi/96.0));
//设置y坐标
   ObjectSetInteger(0,物件名称,OBJPROP_YDISTANCE,int(y*dpi/96.0));
//设置宽度和高度
   ObjectSetInteger(0,物件名称,OBJPROP_XSIZE,int(宽度*dpi/96.0));
   ObjectSetInteger(0,物件名称,OBJPROP_YSIZE,int(高度*dpi/96.0));
//设置颜色
   ObjectSetInteger(0,物件名称,OBJPROP_COLOR,字体颜色);
   ObjectSetInteger(0,物件名称,OBJPROP_BGCOLOR,背景颜色);
   ObjectSetInteger(0,物件名称,OBJPROP_BORDER_COLOR,边框颜色);
//设置字体
   ObjectSetInteger(0,物件名称,OBJPROP_FONTSIZE,9);
   ObjectSetString(0,物件名称,OBJPROP_FONT,"微软雅黑");
   ObjectSetString(0,物件名称,OBJPROP_TEXT,显示文本);
   ObjectSetInteger(0,物件名称,OBJPROP_ALIGN,2);
   ObjectSetInteger(0,物件名称,OBJPROP_READONLY,TRUE);
  }

//+------------------------------------------------------------------+
//|                          按钮                                    |
//+------------------------------------------------------------------+
void anniu(string 物件名称,int x,int y,int 宽度,int 高度,
           string 显示文本,color 字体颜色=clrBlack,color 背景颜色=clrWhite,color 边框颜色=clrBlack)
  {
//创建编辑框
   ObjectCreate(0,物件名称,OBJ_BUTTON,0,0,0);
//设置x坐标
   ObjectSetInteger(0,物件名称,OBJPROP_XDISTANCE,int(x*dpi/96.0));
//设置y坐标
   ObjectSetInteger(0,物件名称,OBJPROP_YDISTANCE,int(y*dpi/96.0));
//设置宽度和高度
   ObjectSetInteger(0,物件名称,OBJPROP_XSIZE,int(宽度*dpi/96.0));
   ObjectSetInteger(0,物件名称,OBJPROP_YSIZE,int(高度*dpi/96.0));
//设置颜色
   ObjectSetInteger(0,物件名称,OBJPROP_COLOR,字体颜色);
   ObjectSetInteger(0,物件名称,OBJPROP_BGCOLOR,背景颜色);
   ObjectSetInteger(0,物件名称,OBJPROP_BORDER_COLOR,边框颜色);
//设置字体
   ObjectSetInteger(0,物件名称,OBJPROP_FONTSIZE,9);
   ObjectSetString(0,物件名称,OBJPROP_FONT,"微软雅黑");
   ObjectSetString(0,物件名称,OBJPROP_TEXT,显示文本);
   ObjectSetInteger(0,物件名称,OBJPROP_ALIGN,2);
   ObjectSetInteger(0,物件名称,OBJPROP_READONLY,TRUE);
  }

//+------------------------------------------------------------------+
//|   多单价格                                                       |
//+------------------------------------------------------------------+
double price_BUY(string 币对="-1",int magic=999)
  {
   double bs=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&&(币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {bs=PositionGetDouble(POSITION_PRICE_OPEN);}
        }
     }
   return(bs);
  }

//+------------------------------------------------------------------+
//|  空单价格                                                        |
//+------------------------------------------------------------------+
double price_SELL(string 币对="-1",int magic=999)
  {
   double be=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&&(币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {be=PositionGetDouble(POSITION_PRICE_OPEN);}
        }
     }
   return(be);
  }
//+------------------------------------------------------------------+
//|   多单手数                                                       |
//+------------------------------------------------------------------+
double buy_lot(string 币对="-1",int magic=999)
  {
   double bs=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&&(币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {bs=PositionGetDouble(POSITION_VOLUME);}
        }
     }
   return(bs);
  }

//+------------------------------------------------------------------+
//|  空单手数                                                        |
//+------------------------------------------------------------------+
double  sell_lot(string 币对="-1",int magic=999)
  {
   double be=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&&(币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {be=PositionGetDouble(POSITION_VOLUME);}
        }
     }
   return(be);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool 使用限制(datetime end_time,long &acc[],bool demoLimit=0)
  {
   bool res=1,allow=0; // 0模拟 1比赛 2实盘
   long myMode=AccountInfoInteger(ACCOUNT_TRADE_MODE);
   if(TimeCurrent()>=end_time)
     {
      Alert("授权使用时间已到期，请联系开发者！");
      res=0;
      ExpertRemove();
     };
   if(demoLimit && myMode!=0)
     {
      Alert("本EA交易面板仅限于模拟账号使用，如需实盘请联系开发者");
      res=0;
      ExpertRemove();
     };
   long account=AccountInfoInteger(ACCOUNT_LOGIN);
   for(int i=0; i<ArraySize(acc); i++)
     {
      if(acc[i]==account || acc[i]<0)
        {
         allow=1;
         break;
        }
     }
   if(allow==0)
     {
      Alert("您的账号不是授权账号，请联系开发者！");
      res=0;
      ExpertRemove();
     }
   return(res);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double buy_lottotal(string 币对="-1",int magic=999)
  {
   double bs=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&&(币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {bs+=PositionGetDouble(POSITION_VOLUME);}
        }
     }
   return(bs);
  }

//+------------------------------------------------------------------+
//|  空单手数                                                        |
//+------------------------------------------------------------------+
double  sell_lottotal(string 币对="-1",int magic=999)
  {
   double be=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&&(币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {be+=PositionGetDouble(POSITION_VOLUME);}
        }
     }
   return(be);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabel(string name,string text,int corner,int x_distance,int y_distance,int size=13,color myclr=White)
  {
   name=name+MQLInfoString(MQL_PROGRAM_NAME);
   ObjectDelete(0,name);
   ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,corner);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x_distance);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y_distance);
   ObjectSetString(0,name,OBJPROP_FONT,"微软雅黑");
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(0,name,OBJPROP_COLOR,myclr);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);//对象列表显示
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void 输出信息()
  {
   int magicValues[];
   GetUniqueMagicValues(magicValues,Symbol());
   string magicOutput = "";
   for(int i = 0; i < ArraySize(magicValues); i++)
     {
      if(i > 0)
         magicOutput += ", ";
      magicOutput += IntegerToString(magicValues[i]);
     }
   double SCAL=TerminalInfoInteger(TERMINAL_SCREEN_DPI)/144.0;
   string Content[100];
   Content[0]=Symbol()+" ：   " +DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_BID),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS));
   Content[1]="多单持仓：     " +DoubleToString(BUY(),2);
   Content[2]="多单均价：     " +DoubleToString(多单均价(Symbol(),999),(int)SymbolInfoInteger(货币对,SYMBOL_DIGITS));
   Content[3]="多挂单数量：   " +DoubleToString(buystop_number(Symbol(),999)+buylimit_number(Symbol(),999),0); //当前品种未成交多单挂单数量
   Content[4]="------------------------" ;
   Content[5]="空单持仓：     " +DoubleToString(SELL(),2);
   Content[6]="空单均价：     " +DoubleToString(空单均价(Symbol(),999),(int)SymbolInfoInteger(货币对,SYMBOL_DIGITS));
   Content[7]="空挂单数量：  " +DoubleToString(sellstop_number(Symbol(),999)+selllimit_number(Symbol(),999),0); //当前品种未成交空单挂单数量
   Content[8]="------------------------" ;
   Content[9]="持仓手数：     " +DoubleToString(BUY() +SELL(),2);
   Content[10]="平仓总手数：   " +DoubleToString(lots_His(),2);
   Content[11]="平仓总盈利：   " +DoubleToString(profit_His(),2);
   Content[12]="持仓 MAGIC：   " +string(magicOutput);      //当前品种已经开仓的Magic，用","区分显示
   Content[13]=交易格言;
   Content[14]=" " +TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   for(int i=0; i<=15; i++)
     {
      画面的字("Make Money"+IntegerToString(i),Content[i],int(数据X位置*SCAL),int((数据Y位置+i*24)*SCAL),9,"Impact",数据颜色,数据位置);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void 删除物件()
  {
   for(int i=0; i<=15; i++)
     {
      string name="Make Money"+IntegerToString(i);
      ObjectDelete(name);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void 画面的字(string 物件名字,string 文字内容,int X位置,int Y位置,int 文本字号,string 文本字体,color 文本颜色,int 角落位置)
  {
//如果没有该物件就创造以下内容。
   if(ObjectFind(0,物件名字)==-1)
      //创建的物件是"OBJ_LABEL"类型。
      ObjectCreate(物件名字, OBJ_LABEL, 0, 0, 0);
//设置该物件的文字内容、字体大小、什么字体和文字的颜色。
ObjectSetString(0,物件名字,OBJPROP_TEXT,文字内容,文本字号,文本字体,文本颜色);

//设置该物件的角落位置。
   ObjectSetInteger(0,物件名字,OBJPROP_CORNER,角落位置);
//设置该物件的X坐标。
   ObjectSetInteger(0,物件名字,OBJPROP_XDISTANCE,X位置);
//设置该物件的Y坐标。
   ObjectSetInteger(0,物件名字,OBJPROP_YDISTANCE,Y位置);
   ObjectSetInteger(0,物件名字,OBJPROP_ANCHOR,ANCHOR_LEFT);
  }

//+------------------------------------------------------------------+
//|                     图表物件                                     |
//+------------------------------------------------------------------+
void 书写文字信息(string name,string StringText,int XDistance,int YDistance,int FontSize,int Corner,int Anchor,color TextColor)
  {
   string Name=name+"X";
   if(ObjectFind(0,Name)==-1)
     {
      ObjectCreate(0,Name,OBJ_LABEL,0,0,0);
      ObjectSetString(0,Name,OBJPROP_FONT,"Impact");
      ObjectSetInteger(0,Name,OBJPROP_FONTSIZE,FontSize);
      ObjectSetInteger(0,Name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,Name,OBJPROP_SELECTABLE,0);
      ObjectSetInteger(0,Name,OBJPROP_COLOR,TextColor);
     }
   ObjectSetInteger(0,Name,OBJPROP_XDISTANCE,XDistance);
   ObjectSetInteger(0,Name,OBJPROP_YDISTANCE,YDistance);
   ObjectSetString(0,Name,OBJPROP_TEXT,StringText);
   ObjectSetInteger(0,Name,OBJPROP_ANCHOR,Anchor);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  profit_His()
  {
   double mo=0;
   for(int r=0; r<HistoryDealsTotal(); r++)
     {
      if((ticket=PositionGetTicket(r))>0)
        {
         if(PositionGetString(POSITION_SYMBOL) == 货币对&&PositionGetInteger(POSITION_TIME))
           {

            mo+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_COMMISSION)+PositionGetDouble(POSITION_SWAP);
           }
        }
     }
   return(mo);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  lots_His()
  {
   double mo=0;
   for(int r=0; r<HistoryDealsTotal(); r++)
     {
      if((ticket=PositionGetTicket(r))>0)
        {
         if(PositionGetString(POSITION_SYMBOL) == 货币对&&PositionGetInteger(POSITION_TIME))
           {

            mo+=PositionGetDouble(POSITION_VOLUME);
           }
        }
     }
   return(mo);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  BUY()
  {
   double  bb=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&& PositionGetString(POSITION_SYMBOL) == 货币对)
           {bb+=PositionGetDouble(POSITION_VOLUME);}
        }
     }
   return(bb);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  SELL()
  {
   double  bb=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&& PositionGetString(POSITION_SYMBOL) == 货币对)
           {bb+=PositionGetDouble(POSITION_VOLUME);}
        }
     }
   return(bb);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Profit_Symbol(string op,int mag)
  {
   double bb=0;
   for(int cnt=0; cnt<PositionsTotal(); cnt++)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetString(POSITION_SYMBOL) == op&&PositionGetInteger(POSITION_MAGIC)==mag)
           {bb+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION);}
        }
     }
   return(bb);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetUniqueMagicValues(int& outMagicValues[], const string symbol)
  {
// 创建一个临时的整型数组，用于存储不同的MAGIC数值
   int tempMagicValues[];

// 遍历所有挂单
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if((ticket=PositionGetTicket(i))<=0)
         continue;


      // 检查订单的品种是否与指定的品种匹配
      if(PositionGetString(POSITION_SYMBOL) != symbol)
         continue;
      // 获取订单的MAGIC数值
      int magic = PositionGetInteger(POSITION_MAGIC);

      // 检查MAGIC数值是否已经存在于临时数组中
      bool found = false;
      for(int j = 0; j < ArraySize(tempMagicValues); j++)
        {
         if(tempMagicValues[j] == magic)
           {
            found = true;
            break;
           }
        }

      // 如果MAGIC数值不在临时数组中，则将其添加到数组
      if(!found)
        {
         ArrayResize(tempMagicValues, ArraySize(tempMagicValues) + 1);
         tempMagicValues[ArraySize(tempMagicValues) - 1] = magic;
        }
     }

// 将临时数组中的MAGIC数值复制到输出数组中
   ArrayCopy(outMagicValues, tempMagicValues);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void 关闭买上(string symbol="",int magic=999,double jige_tp=0,double jige_sl=0)
  {
   if(symbol=="")
      symbol=Symbol();
//定义要用到的局部变量。
   double 卖价;
   double 手数;
   int 订单类型;
   int i;
   bool result = false;
   int 订单号;
//遍历所有订单
   for(i=PositionsTotal()-1; i>=0; i--)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         ////选择符合要求的订单。
         if(PositionsTotal()>0)
           {

            if((symbol=="-1" || PositionGetString(POSITION_SYMBOL)==symbol)  && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic)&&((PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION)>jige_tp&&jige_tp!=0)||(PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION)<-jige_sl&&jige_sl!=0)))
              {
               //获取要用到的变量数值。
               卖价=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
               订单号=ticket;
               手数=PositionGetDouble(POSITION_VOLUME);
               订单类型=PositionGetInteger(POSITION_TYPE);
               switch(订单类型)
                 {
                  //如果是买单类型，将其关闭。
                  case POSITION_TYPE_BUY:
                     result = myTrade.PositionClose(订单号, 手数);
                     break;
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void 关闭卖下(string symbol="",int magic=999,double jige_tp=0,double jige_sl=0)
  {
//定义要用到的局部变量。
   if(symbol=="")
      symbol=Symbol();
   double 买价;
   double 手数;
   int 订单类型;
   int i;
   bool result = false;
   int 订单号;
//遍历所有订单
   for(i=PositionsTotal()-1; i>=0; i--)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         //选择符合要求的订单。
         if(PositionsTotal()>0)
           {
            //获取要用到的变量数值。
            if((symbol=="-1" || PositionGetString(POSITION_SYMBOL)==symbol)  && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic)&&((PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION)>jige_tp&&jige_tp!=0)||(PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+PositionGetDouble(POSITION_COMMISSION)<-jige_sl&&jige_sl!=0)))
              {
               买价=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
               订单号=ticket;
               手数=PositionGetDouble(POSITION_VOLUME);
               订单类型=PositionGetInteger(POSITION_TYPE);
               switch(订单类型)
                 {
                  //如果是卖单类型，将其关闭。
                  case POSITION_TYPE_SELL:
                     result = myTrade.PositionClose(订单号, 手数);
                     break;
                 }
               //  if(result) printf("%s%s多单平仓成功！", 货币对,策略名称 );
               // else printf("%s%s多单平仓不成功，错误代码是", 货币对,策略名称, GetLastError());
              }
           }
        }
     }
  }
// N=批量平盈利单数量
//+------------------------------------------------------------------+
void FindTopNProfits(int ying,int magic,int N, int direction,int type=0,double bili=0.3)
  {
   int ids[];
   double profits[];
   int count = 0;

   FindProfitPos(ying,magic,direction, ids, profits, count);
   Print("数量==",ArraySize(ids));
   if(ArraySize(ids) < N)
     {
      if(选择==1)
        {
         N=1;
        }
      if(选择==2)
        {
         N=ArraySize(ids);
        }
     }

   if(ArraySize(ids)!=0)
     {
      for(int i = 0; i < N; i++)
        {
         // Print(ids[i]);
         部分平仓(bili,ids[i],type);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FindProfitPos(int yingli,int magic,int up_dn,int &id[],double &profit[],int &j)
  {
   int i=0,t=PositionsTotal();
   ArrayResize(id,t);
   ArrayResize(profit,t);
   for(i=0; i<=t-1; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if(PositionGetString(POSITION_SYMBOL) == 货币对&&(magic==999||PositionGetInteger(POSITION_MAGIC)==magic)&&((yingli==-1&&PositionGetDouble(POSITION_PROFIT)<0)||(yingli==1&&PositionGetDouble(POSITION_PROFIT)>0)))
           {
            id[j]=ticket;
            profit[j]=PositionGetDouble(POSITION_PROFIT);
            j++;
           }
        }
     }
   ArrayResize(id,j);
   ArrayResize(profit,j);
   ArraySortByProfit(profit,id,up_dn);
  }
//+-------------------------------------------------------------------+
//|  //进行排序处理                                                   |
//+-------------------------------------------------------------------+
void ArraySortByProfit(double &array[],int &id[],int up_dn=0)
  {
   if(ArraySize(array)<=0)
      return;
   int i=0,j=0;
   double dn=0,up=0;
   int upID,dnID;
   for(i=0; i<ArraySize(array); i++)
     {
      for(j=ArraySize(array)-1; j>i; j--)
        {
         bool next=0;
         if(up_dn==0)
            next=array[j]<array[j-1];//升序排列
         if(up_dn==1)
            next=array[j]>array[j-1];//降序排列
         if(next)
           {
            up=array[j];
            dn=array[j-1];
            array[j]=dn;
            array[j-1]=up;
            /////////
            upID=id[j];
            dnID=id[j-1];
            id[j]=dnID;
            id[j-1]=upID;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool 部分平仓(double 平仓倍数,int mag,int k=1)//LASTTicket  LastTicket
  {
   bool result_all=true;
   for(int i =PositionsTotal()-1; i >=0 ; i--)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if(PositionGetString(POSITION_SYMBOL) ==货币对&&ticket== mag)
           {
            if(PositionGetInteger(POSITION_TYPE)==k)
              {
               double close_price=0;
               if(PositionGetInteger(POSITION_TYPE)==0)
                 {
                  close_price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);//price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
                 }
               else
                 {
                  close_price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);//price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
                 }
               double close_Lots=PositionGetDouble(POSITION_VOLUME)*平仓倍数;
               if(close_Lots<SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_VOLUME_MIN))
                 {
                  close_Lots=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_VOLUME_MIN);
                 }
               close_Lots=NormalizeDouble(close_Lots,2);

               if(close_Lots==0)
                 {
                  close_Lots=PositionGetDouble(POSITION_VOLUME);
                 }
               bool result=myTrade.PositionClose(ticket,close_Lots);
               if(result==false)
                 {
                  result_all=false;
                 }
              }
           }
        }
     }

   if(result_all==false)
     {
      //if(是否显示输出语句)  { Print("部分平仓不成功，错误代码是",GetLastError());}
     }
   return result_all;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double 获取输入框的值(string 输入框名字)
  {
   string 内容=ObjectGetString(0,输入框名字,OBJPROP_TEXT);
   double 输入框数值=StringToDouble(内容);
   return(输入框数值);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double price_BUYfirst(int magic)
  {
   double bb=0;
   for(int cnt=PositionsTotal()-1; cnt>=0; cnt--)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&& PositionGetInteger(POSITION_MAGIC)==magic)
           {bb=PositionGetDouble(POSITION_PRICE_OPEN);}
        }
     }
   return(bb);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double price_SELLfirst(int magic)
  {
   double bb=0;
   for(int cnt=PositionsTotal()-1; cnt>=0; cnt--)
     {
      if((ticket=PositionGetTicket(cnt))>0)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&& PositionGetInteger(POSITION_MAGIC)==magic)
           {bb=PositionGetDouble(POSITION_PRICE_OPEN);}
        }
     }
   return(bb);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void 手动空单改止盈(string 币对="-1",int magic=999,double 空止盈点数=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {

            bool alreadyModified = false;

            // 检查这个订单号是否已经被修改过
            for(int j = 0; j < modifiedOrdersCount; j++)
              {
               if(modifiedOrders[j] == ticket)
                 {
                  alreadyModified = true;
                  break;
                 }
              }
            // 若尚未被修改，则修改止盈价格并存储其订单号在数组中
            if(!alreadyModified)
              {
               if(空止盈点数!=0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&&NormalizeDouble(PositionGetDouble(POSITION_TP),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)-空止盈点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
                 {
                  res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_PRICE_OPEN)-空止盈点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL)),CLR_NONE);
                  modifiedOrders[modifiedOrdersCount] = ticket; // 加入已经修改过的订单号数组
                  modifiedOrdersCount++; // 已修改的订单数增加
                 }
               //if(空止盈点数==0&&OrderType() == POSITION_TYPE_SELL)
               //  {
               //res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL), 0);
               //   modifiedOrders[modifiedOrdersCount] = OrderTicket(); // 加入已经修改过的订单号数组
               //   modifiedOrdersCount++; // 已修改的订单数增加
               //  }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|        修改多单止损                                              |
//+------------------------------------------------------------------+
void 手动多单改止盈(string 币对="-1",int magic=999,double 多止盈点数=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {
            bool btpalreadyModified = false;

            // 检查这个订单号是否已经被修改过
            for(int j = 0; j < btpmodifiedOrdersCount; j++)
              {
               if(btpmodifiedOrders[j] == ticket)
                 {
                  btpalreadyModified = true;
                  break;
                 }
              }
            // 若尚未被修改，则修改止盈价格并存储其订单号在数组中
            if(!btpalreadyModified)
              {
               if(多止盈点数!=0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&&NormalizeDouble(PositionGetDouble(POSITION_TP),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)+多止盈点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
                 {
                  Print(33333);
                  res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_PRICE_OPEN)+多止盈点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL)),CLR_NONE);
                  btpmodifiedOrders[btpmodifiedOrdersCount] = ticket; // 加入已经修改过的订单号数组
                  btpmodifiedOrdersCount++; // 已修改的订单数增加
                 }
               //if(多止盈点数==0&&OrderType() == POSITION_TYPE_BUY)
               // {
               //res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_SL), 0);
               //  btpmodifiedOrders[btpmodifiedOrdersCount] = OrderTicket(); // 加入已经修改过的订单号数组
               //  btpmodifiedOrdersCount++; // 已修改的订单数增加
               // }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|        修改多单止损                                              |
//+------------------------------------------------------------------+
void 手动多单改止损(string 币对="-1",int magic=999,double 多止损点数=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {

            bool bslalreadyModified = false;

            // 检查这个订单号是否已经被修改过
            for(int j = 0; j < bslmodifiedOrdersCount; j++)
              {
               if(bslmodifiedOrders[j] == ticket)
                 {
                  bslalreadyModified = true;
                  break;
                 }
              }
            // 若尚未被修改，则修改止盈价格并存储其订单号在数组中
            if(!bslalreadyModified)
              {
               if(多止损点数!=0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY&&NormalizeDouble(PositionGetDouble(POSITION_SL),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)-多止损点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
                 {
                  res1=myTrade.PositionModify(ticket,PositionGetDouble(POSITION_PRICE_OPEN)-多止损点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT)),CLR_NONE);
                  bslmodifiedOrders[bslmodifiedOrdersCount] = ticket; // 加入已经修改过的订单号数组
                  bslmodifiedOrdersCount++; // 已修改的订单数增加
                 }
               //if(多止损点数==0&&OrderType() == POSITION_TYPE_BUY)
               //  {
               //res1=myTrade.PositionModify(ticket, 0, PositionGetDouble(POSITION_TP));
               //    bslmodifiedOrders[bslmodifiedOrdersCount] = OrderTicket(); // 加入已经修改过的订单号数组
               //   bslmodifiedOrdersCount++; // 已修改的订单数增加
               //  }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|        修改多单止损                                              |
//+------------------------------------------------------------------+
void 手动空单改止损(string 币对="-1",int magic=999,double 空止损点数=0)
  {
   int tota = PositionsTotal();
   bool res1=false;
   bool ress=false;
   for(int i = 0; i < tota; i++)
     {
      if((ticket=PositionGetTicket(i))>0)
        {
         if((币对=="-1" || PositionGetString(POSITION_SYMBOL)==币对) && (magic==999 || PositionGetInteger(POSITION_MAGIC)==magic))
           {

            bool sslalreadyModified = false;

            // 检查这个订单号是否已经被修改过
            for(int j = 0; j < sslmodifiedOrdersCount; j++)
              {
               if(sslmodifiedOrders[j] == ticket)
                 {
                  sslalreadyModified = true;
                  break;
                 }
              }
            // 若尚未被修改，则修改止盈价格并存储其订单号在数组中
            if(!sslalreadyModified)
              {
               if(空止损点数!=0&&PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL&&NormalizeDouble(PositionGetDouble(POSITION_SL),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS))!=NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)+空止损点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT),(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)))
                 {
                  // Print("前面=",NormalizeDouble(OrderStopLoss(),Digits),"  后面=",NormalizeDouble(OrderOpenPrice()+空止损点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT),Digits));

                  res1=myTrade.PositionModify(ticket, PositionGetDouble(POSITION_PRICE_OPEN)+空止损点数*SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT)),CLR_NONE);
                  sslmodifiedOrders[sslmodifiedOrdersCount] = ticket; // 加入已经修改过的订单号数组
                  sslmodifiedOrdersCount++; // 已修改的订单数增加
                 }
               //if(空止损点数==0&&OrderType() == POSITION_TYPE_SELL)
               // {
               //res1=myTrade.PositionModify(ticket, 0, PositionGetDouble(POSITION_TP));
               //  sslmodifiedOrders[sslmodifiedOrdersCount] = OrderTicket(); // 加入已经修改过的订单号数组
               //  sslmodifiedOrdersCount++; // 已修改的订单数增加
               // }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
