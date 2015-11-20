/*
 * Implementation of Flooding Routing Protocol.
 *
 * Author @HaslizaSofian
*/

#include "MyFlooding.h"

module MFloodingC  {

	uses interface Boot;
	uses interface Leds;
	uses interface SplitControl as Control;
  uses interface Timer<TMilli> as TMilli;
  //uses interface Timer<TMilli> as TMilli02;
  uses interface Random;

  uses interface AMPacket;

  uses interface Packet;
  uses interface AMSend;
  uses interface Receive;
}

implementation{

	message_t packet;		//packet to send
  //message_t packet02;
	uint16_t count;
	uint16_t counter;
	uint16_t counters;
	uint16_t counterest;
	uint16_t currHop;

	uint16_t currTargetVal;
	uint16_t lastTargetVal;
	uint16_t countDuplicate;
	uint16_t theMessage;
	uint32_t timeSent;
	uint32_t timeReceive;

	uint32_t timenow;
	uint32_t timelastelapse;

	uint16_t currVal;
	uint16_t lastVal;

	enum {
      SINK = 5,
      SOURCE = 7,
  	}; 

	event void Boot.booted() {
    call Leds.led0On();
    call Control.start();
    
    call TMilli.startPeriodic(1000); 	//0.25data per sec, 1 data per 4 sec
    //call TMilli02.startPeriodic(1024);	//1 data per sec
  	
  	}

  	event void Control.startDone(error_t e){
  	//do nothing
    }

  	event void TMilli.fired(){
  		if (TOS_NODE_ID == SINK){		//node id is the sink
      
  			MyRequest* data;

  			//every timer fired, the SINK will flood request for the data from SOURCE.
  			data = (MyRequest*) (call Packet.getPayload(&packet, sizeof(MyRequest)));
  			data->nodeid = TOS_NODE_ID;			//nodeid= the current node id
  			
  			data->mymessage = call Random.rand16();	// mymessage is the generated message
  			//dbg("messages", "The message is message: %u \n", data->mymessage); //to ensure the data not the same
  			theMessage = data->mymessage;		//keep in variable
  			
  			data->hopcount = 0;					//initialize the hopcount to 1

  			//dbg("messages", "then node id is: %u \n", data->nodeid);
  			//dbg("messages", "The hop sent count is: %u \n", data->hopcount);
  			dbg("messages", "The random message is: %u \n", data->mymessage);

  			if(call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(MyRequest)) == SUCCESS){
  				count++;

  				timeSent = call TMilli.getNow();
  				//dbg("messages", "The time now is: %u \n", timeSent);

  				dbg("messages", "Packet sent. \n");
  				
  				timelastelapse = call TMilli.gett0();
    			//dbg("messages", "The time last elapse is: %u \n", timelastelapse);

    			dbg("output", /*"This is send number: */ "%u , ", count);
  				dbg("output", /*"Time sent is: */ "%u , ", timeSent);  				
  				dbg("output", /*"With message: */ "%u \n", theMessage);
  			}

  			else{
  				//dbg("messages", "Packet not sent. \n");
  			}
  		}
  		else{
  			//dbg("messages", "Packet not generated, I am not the SINK. \n");
  		}
      //Set the message buffer as NULL
      //packet = packet02;
  	}

  	event void AMSend.sendDone(message_t* msg, error_t error){
  		counter++;
  		
  		if (TOS_NODE_ID == SINK){
  			dbg("succsend", "This is sendDone number: %u \n", counter);
  		}

  		else{
  			//dbg("messages", "I dont need this. \n");
  		}

  	}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){

      //call AMPacket.setDestination(msg, SOURCE);
      dbg("messages", "Lets receive this messages. \n");

        if(TOS_NODE_ID == SOURCE){		//if node is the source, receive the node.

   			MyRequest* data = (MyRequest*)payload;

   			timeReceive = call TMilli.getNow();

   			//dbg("messages","the data is: %u \n", data->mymessage);
   			//dbg("messages", "the hopcount received is: %u \n", data->hopcount);

   			currTargetVal = data->mymessage;        //currVal is the current message
      		//dbg("messages", "the current target val is: %u \n", currTargetVal);
      		
      		//if message received for the first time
      	if (currTargetVal != lastTargetVal){
      		counters++;

      		dbg("messages", "Data received at source for the first time. \n");
   				
          dbg("output2", /*"This is received no: */ " %u , ", counters);
          dbg("output2", /*"The time is: */ " %u , ", timeReceive);  				
          dbg("output2", /*"The message is: */ "%u \n", data->mymessage);
   				
          //dbg("output2", "Data is from node number: %u , with hopcount: %u \n", data->nodeid, data->hopcount);	
   			}

   			else{

          counterest ++;
          dbg("output3","duplicated data received number: %u \n", counterest);
   			}

   			lastTargetVal = currTargetVal;
   		}

   		else{		//if this node is not a source, broadcast message

   			error_t error;
   			MyRequest* data = (MyRequest*)payload;
   			//dbg("messages", "The message received by non-source is: %u \n", data->mymessage);
   			
   			currVal = data->mymessage;
   			//dbg("messages", "current value is: %u \n", currVal);

   			currHop = data->hopcount;
   			//dbg("messages", "The unpacked hop count is: %u \n", currHop); //unpack hopcount

   			//if node receive it for the first time, broadcast it
   			if (currVal != lastVal){
   				//dbg("messages"," Msg received for the first time, snoop it, broadcast the message and add the hop count \n");

          		data = (MyRequest*) (call Packet.getPayload(&packet, sizeof(MyRequest)));
          		data->nodeid = TOS_NODE_ID;		//change node id to current node id
  				
  				data->mymessage = currVal;
  				//dbg("messages","the data packed is: %u \n", data->mymessage);

  				currHop++;
  				data->hopcount = currHop;
  				//dbg("output2", "The updated hopcount is: %u \n", counthop); //hopcount + 1
          		
          		error = call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(MyRequest)); //broadcast updated info

          		/*
          		if (error == SUCCESS){
          			dbg("messages", "Packet broadcasted \n");
          		}
          		else{
          			dbg("message", "Re-broadcast failed. \n");
          		}
          		*/

          		lastVal = currVal;		//update the message received
          		//dbg("messages", "The lastVal is: %u \n", lastVal);
   			}

   			else{
   				countDuplicate++;
   				dbg("output4","This is duplicated data at intermediate node no: %u, ignore packet. \n", countDuplicate);
   			}	  
   		}
   		
   		return msg;
   	}

   event void Control.stopDone(error_t e){    //turn off the radio

   }

}