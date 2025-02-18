/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface linkND;
}

implementation{
   pack sendPackage;

   // Prototypes
   /* void makePack(pack *Package, uint8_t src, uint8_t proto, uint8_t TTL, uint8_t seq, uint8_t *payload, uint8_t length); */

   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On node: %d\n", (uint8_t)TOS_NODE_ID);
         if((uint8_t)TOS_NODE_ID == 1) {
           dbg(GENERAL_CHANNEL, "Starting\n");
           call linkND.startPing();
         }
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      /* dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len); */
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      /* dbg(GENERAL_CHANNEL, "PING EVENT \n");
      //tos node id is uint16_t
      makePack(&sendPackage, (uint8_t)TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination); */
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   /* void makePack(pack *Package, uint8_t src, uint8_t proto, uint8_t TTL, uint8_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->proto = proto;
      Package->TTL = TTL;
      Package->seq = seq;
      memcpy(Package->payload, payload, length);
   } */
}
