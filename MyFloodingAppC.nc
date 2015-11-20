/*
 * Implementation of Flooding Protocol.
 *
 * Author @HaslizaSofian
*/

configuration MyFloodingAppC{

}

implementation{
	components MainC, LedsC, MyFloodingC, RandomC;
	//components TossimActiveMessageC;
	components ActiveMessageC;
	//components TossimPacketModelC;
	components new TimerMilliC();
	components new AMSenderC(123);
	components new AMReceiverC(123);
	  

	MyFloodingC.Boot -> MainC;
  	MyFloodingC.Leds -> LedsC;
  	MyFloodingC.TMilli   ->  TimerMilliC;
  	MyFloodingC.Random   ->  RandomC;
  	MyFloodingC.Control  ->  ActiveMessageC;
  	MyFloodingC.AMPacket ->  AMReceiverC;

  	MyFloodingC.Packet -> ActiveMessageC;
  	MyFloodingC.AMSend -> AMSenderC;
  	MyFloodingC.Receive->  AMReceiverC;

}