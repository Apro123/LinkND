#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/constants.h"
#include "printf.h"

module linkNDP {
    provides interface linkND;

    uses interface Packet;
    uses interface Receive;
    uses interface SimpleSend as Sender;
    uses interface Timer<TMilli> as linkTimer;
    uses interface Timer<TMilli> as waitToReplyTimer;
    uses interface Hashmap<uint8_t> as neighborIndexes;
    /* uses interface Hashmap<uint16_t> as neighborCost;
    uses interface Hashmap<uint16_t> as neighborWithCost; */
    uses interface Random as Random;
}

implementation {
  //link costs with current neighbors
  uint8_t nodes[NUM_POSSIBLE_NODES];
  uint8_t numSent[NUM_POSSIBLE_NODES];
  uint8_t numReceived[NUM_POSSIBLE_NODES];
  /* uint8_t latestCost[NUM_POSSIBLE_NODES]; //stores the latest costs  but is stored in payloadsLINK*/
  uint8_t index = 0;

  //includes set(seq,node,node,link) //add all payloads including self
  //...when nodes match then highest seq is chosen to overwrite.

  /* uint8_t* payloadsSEQ;
  uint8_t* payloadsNODE1;
  uint8_t* payloadsNODE2;
  uint8_t* payloadsLINK; */

  // storage needed = number of nodes multiplied by possible one way links times 2 for back and forth links
  /* uint8_t totalStorageNeeded = NUM_POSSIBLE_NODES*(NUM_POSSIBLE_NODES-1)*2; */
  uint8_t payloadsSEQ[NUM_POSSIBLE_NODES*(NUM_POSSIBLE_NODES-1)*2];
  uint8_t payloadsNODE1[NUM_POSSIBLE_NODES*(NUM_POSSIBLE_NODES-1)*2]; //src of the one-way link
  uint8_t payloadsNODE2[NUM_POSSIBLE_NODES*(NUM_POSSIBLE_NODES-1)*2]; //dest of the one-way link
  uint8_t payloadsLINK[NUM_POSSIBLE_NODES*(NUM_POSSIBLE_NODES-1)*2];
  uint8_t numPayloads = 0; //payloads in the above 4 lists storage
  uint8_t addToPacketIndex = 0; //index used to round robin send packets in the packet

  //list pointing to [numSent, numReceived, lastest cost] the index which corresponds to the
  //...tosnodeid is in the HASHMAP datatype
  //latest cost = definite calculated costs (every time numSent turns to COST_FLUSH_LIMIT?)

  //turn tosnodeid to uint 8 through direct assignment

  uint8_t seq = 0;
  bool startedPing = FALSE;

  //if received but numSent is 0, then disregaurd and add neighbor if necessary
  /* command void startListening() {

  } */

  //make pack function
  void makePack(pack *Package, uint8_t src, uint8_t payloadLength, uint8_t TTL, uint8_t givenSeq, uint8_t *payload, uint8_t length);

  //start the neighbor discovery timer
  command void linkND.startPing() {
    if(!startedPing) {
      dbg(GENERAL_CHANNEL, "started ping\n");
      call linkTimer.startPeriodic(LINKND_TIMER_DURATION + (uint16_t) (call Random.rand16()%600));
      startedPing = TRUE;
    } else {
      if(!(call linkTimer.isRunning())) {
        dbg(GENERAL_CHANNEL, "shall def not be happening");
      }
      dbg(GENERAL_CHANNEL, "ping already started");
    }
  }

  /* task void findAndStoreAvailable(uint8_t numRec, uint8_t node1, uint8_t node2, uint8_t cost) {
    dbg(GENERAL_CHANNEL, "should not really be hitting this function");
  } */

  //add old or new link
  void addLink(uint8_t givenSeq, uint8_t node1, uint8_t node2, uint8_t cost) {
    bool found = FALSE;
    uint8_t i;

    //search into for existing link in the storage. start from back
    for(i = numPayloads-1; !found; i--) {
      /* dbg(GENERAL_CHANNEL, "add link test4 %d\n", (i >= 0 && !found)); */
      //if src matched current node and destination matches replied node, then next step
      if(payloadsNODE1[i] == node1 && payloadsNODE2[i] == node2) {
        //if the sequence number is "higher" then modify the existing solution
        uint8_t savedSeq = payloadsSEQ[i];
        //do seq calculation
        if(givenSeq >= savedSeq || (savedSeq < SEQ_LOW_NUM_THRESHOLD && givenSeq > SEQ_HIGH_NUM_THRESHOLD)) {
          //update the sequence number
          payloadsSEQ[i] = givenSeq;
          //replace the link cost
          payloadsLINK[i] = cost; //new cost
          printf("-%u,%u,%u,%u-", seq,node1,node2,cost);
          printfflush();
          dbg(GENERAL_CHANNEL, "Updated link = SEQ: %d, Node1: %d, Node2: %d, COST: %d\n", seq, node1, node2, cost);
        } //else keep it as it is
        found = TRUE; //found but not necessarily updated link
      }
      if(i == 0) {
        break;
      }
    }
    //if not found, then add it to the list
    if(!found) {
      if(numPayloads+1 >= NUM_POSSIBLE_NODES*(NUM_POSSIBLE_NODES-1)*2) {
        dbg(GENERAL_CHANNEL, "filled up too much");
        //go to ones where link is 0
        /* post findAndStoreAvailable(givenSeq, node1, node2, cost); */
      } else {
        printf("-%u,%u,%u,%u-", seq,node1,node2,cost);
        printfflush();
        dbg(GENERAL_CHANNEL, "Added link to Storage = SEQ: %d, Node1: %d, Node2: %d, COST: %d\n", seq, node1, node2, cost);
        payloadsSEQ[numPayloads] = seq;
        payloadsNODE1[numPayloads] = node1;
        payloadsNODE2[numPayloads] = node2;
        payloadsLINK[numPayloads] = cost;
        numPayloads += 1;
      }
    }
  }

  //heavy operation, every time a broadcast is made and count is reached before sending packet at the end of the time interval
  //task
  void calculateCost(uint8_t numRec, uint8_t node) {
    /* uint8_t cost = (uint8_t)(((uint16_t)numRec)*255)/COST_FLUSH_LIMIT; //real cost is cost/255 */
    uint8_t cost;
    if(numRec == 0) {
      /* dbg(GENERAL_CHANNEL, "Zero cost with node %d\n", node); */
      cost = 0;
    } else {
      /* dbg(GENERAL_CHANNEL, "cost flush limit: %d, numRec: %d\n", COST_FLUSH_LIMIT, numRec); */
      cost = (numRec*255)/COST_FLUSH_LIMIT; //real cost is cost/255. higher number means higher cost. up to 1
    }

    addLink(seq, TOS_NODE_ID, node, cost);

    /* //add into rest of the storage with the other links
    for(i = 0; i < numPayloads, i++) {
      //if src matched current node and destination matches replied node, then modify
      if(payloadsNODE1[i] == (uint8_t) TOS_NODE_ID && payloadsNODE2[i] = node) {
        found = true
        //self and current link cost calculation
        payloadsSEQ[i] = seq;
        payloadsLINK[i] = cost
        dbg(GENERAL_CHANNEL, "SEQ: %d, Node: %d, Num Rec: %d, COST: %d", seq, node, numRec, cost)
      }
    }
    if(!found) {
      if(numPayloads+1 == totalStorageNeeded) {
        dbg(GENERAL_CHANNEL, "filled up too much");
        //go to ones where link is 0
        post findAndStoreAvailable(numRec, node, cost);
      } else {
        dbg(GENERAL_CHANNEL, "adding to storage");
        payloadsSEQ[numPayloads] = seq;
        payloadsNODE1[numPayloads] = (uint8_t) TOS_NODE_ID;
        payloadsNODE2[numPayloads] = node;
        payloadsLink[numPayloads] = cost;
      }
      numPayloads = numPayloads + 1;
    } */
  }

  //task
  void sendPacket(uint8_t dest) {
    uint8_t i;
    uint8_t pay[PACKET_MAX_PAYLOAD_SIZE]; //payload to store into the sent packet
    uint8_t firstIndex; //used to avoiding sending repeated sets
    uint8_t len = 0; //payloadLength //num of link sets that are in the packet;
    pack toSend;

    /* dbg(GENERAL_CHANNEL, "test1\n"); */

    if(dest == 0) { //aka broadcast
      /* <= index */
      for(i = 0; i < index; i++) { //index of current nodes
        /* if(nodes[i] != 0) { //node has fall out of the map if 0 */
        if(numSent[i] == COST_FLUSH_LIMIT) {
          /* dbg(GENERAL_CHANNEL, "test1.4\n"); */
          calculateCost(numReceived[i], nodes[i]);
          /* dbg(GENERAL_CHANNEL, "test1.5\n"); */
          numReceived[i] = 0; //reset the calculations
          numSent[i] = 0;
        }
        numSent[i] = numSent[i]+1;
      }
    }

    // add the packets in the storage into the packet payload using round robin style of packets
    //set size is 4 that is why you divide by 4
    for(i = 0; i < PACKET_MAX_PAYLOAD_SIZE/4; i++) { //this equals 6
      /* uint8_t savedSeq
      uint8_t node1
      uint8_t node2
      uint8_t savedCost */
      if(i != 0) {
        //reach around for packet
        if(firstIndex == addToPacketIndex) {
          /* dbg(GENERAL_CHANNEL, "break no adding packets\n"); */

          break; //break out of the loop to avoid any addition addition into the payload of the packet
        }
      } else {
        firstIndex = addToPacketIndex;
        if(numPayloads == 0) {
          break;
        }
      }
      memcpy(&pay[(i*4)+0], &payloadsSEQ[addToPacketIndex], sizeof(uint8_t));
      memcpy(&pay[(i*4)+1], &payloadsNODE1[addToPacketIndex], sizeof(uint8_t));
      memcpy(&pay[(i*4)+2], &payloadsNODE2[addToPacketIndex], sizeof(uint8_t));
      memcpy(&pay[(i*4)+3], &payloadsLINK[addToPacketIndex], sizeof(uint8_t));

      /* dbg(GENERAL_CHANNEL, "--\n");
      dbg(GENERAL_CHANNEL, "orig: %d, seqNum: %d\n", payloadsSEQ[addToPacketIndex], pay[(i*4)+0]);
      dbg(GENERAL_CHANNEL, "orig: %d, node1: %d\n", payloadsNODE1[addToPacketIndex], pay[(i*4)+1]);
      dbg(GENERAL_CHANNEL, "orig: %d, node2: %d\n", payloadsNODE2[addToPacketIndex], pay[(i*4)+2]);
      dbg(GENERAL_CHANNEL, "orig: %d, newCost: %d\n", payloadsLINK[addToPacketIndex], pay[(i*4)+3]); */
      /* pay[(i*4)+0] = payloadsSEQ[addToPacketIndex];
      pay[(i*4)+1] = payloadsNODE1[addToPacketIndex];
      pay[(i*4)+2] = payloadsNODE2[addToPacketIndex];
      pay[(i*4)+3] = payloadsLINK[addToPacketIndex]; */

      addToPacketIndex += 1;
      if(addToPacketIndex >= numPayloads) {
        //at the end so reset to 0
        addToPacketIndex = 0;
      }
      /* dbg(GENERAL_CHANNEL, "sending\n"); */
      len += 1;
    }
    /* dbg(GENERAL_CHANNEL, "test2\n"); */

    /* dbg(GENERAL_CHANNEL, "Payload sending--------\n");
    for(i = 0; i < len; i++) {
      dbg(GENERAL_CHANNEL, "seq: %d, node1: %d, node2: %d, link: %d\n", pay[(i*4)+0], pay[(i*4)+1], pay[(i*4)+2], pay[(i*4)+3]);
    }
    dbg(GENERAL_CHANNEL, "Payload sending end--------\n"); */

    makePack(&toSend, (uint8_t)TOS_NODE_ID, len, dest, seq, pay, PACKET_MAX_PAYLOAD_SIZE);
    if(seq == 254) {
        seq = 0;
    } else {
        seq = seq + 1;
    }
    call Sender.send(toSend, AM_BROADCAST_ADDR);
    if(dest == 0) {
      /* dbg(GENERAL_CHANNEL, "Sending Broadcast\n"); */
    }
  }

  event void waitToReplyTimer.fired() {

  }

  /* void printStuff() {
    uint8_t i;
    dbg(GENERAL_CHANNEL, "--------\n");
    for(i = 0; i < index; i++) {
      dbg(GENERAL_CHANNEL, "i: %d, node: %d, numSent: %d, numRec: %d\n", i, nodes[i], numSent[i], numReceived[i]);
    }
    dbg(GENERAL_CHANNEL, "--------\n");
  } */

  event void linkTimer.fired() {
    /* printStuff(); */
    /* dbg(GENERAL_CHANNEL, "timer fired\n"); */
    sendPacket(0); //destination is 0, thus broadcast
  }

  /* void sendPacket() {
    call Sender.send(replu, AM_BROADCAST_ADDR);
  } */

  //task
  void storeFromPayloads(uint8_t* payload, uint8_t length) {
    uint8_t i = 0;

    /* dbg(GENERAL_CHANNEL, "Payload recieving--------\n");
    for(i = 0; i < len; i++) {
      dbg(GENERAL_CHANNEL, "seq: %d, node1: %d, node2: %d, link: %d\n", pay[(i*4)+0], pay[(i*4)+1], pay[(i*4)+2], pay[(i*4)+3]);
    }
    dbg(GENERAL_CHANNEL, "Payload recieving--------\n"); */

    //payload contains sets (seq, node1, node2, link cost)
    for(i = 0; i < length; i++) {
      uint8_t seqNum;
      uint8_t node1;
      uint8_t node2;
      uint8_t newCost;

      /* uint8_t seqNum = payload[i];
      uint8_t node1 = payload[i+1];
      uint8_t node2 = payload[i+2];
      uint8_t newCost = payload[i+3]; */

      memcpy(&seqNum, &payload[(i*4)+0], sizeof(uint8_t));
      memcpy(&node1, &payload[(i*4)+1], sizeof(uint8_t));
      memcpy(&node2, &payload[(i*4)+2], sizeof(uint8_t));
      memcpy(&newCost, &payload[(i*4)+3], sizeof(uint8_t));

      /* dbg(GENERAL_CHANNEL, "Link received seq: %d, n1: %d, n2: %d, cost: %d\n", seqNum, node1, node2, newCost); */
      /* dbg(GENERAL_CHANNEL, "seqNum: %d\n", seqNum);
      dbg(GENERAL_CHANNEL, "node1: %d\n", node1);
      dbg(GENERAL_CHANNEL, "node2: %d\n", node2);
      dbg(GENERAL_CHANNEL, "newCost: %d\n", newCost);
      dbg(GENERAL_CHANNEL, "Link received--\n"); */


      addLink(seqNum, node1, node2, newCost);
      /* if(numPayloads != 0) {
        bool stop = false;
        for(j = numPayloads-1; j >= 0 && !stop, j--) {
          if(payloadsNODE1[j] == node1 && payloadsNODE2[j] == node2) {
            uint8_t savedSeq = payloadsSEQ[j]
            //do seq calculation
            if(seqNum > savedSeq || (savedSeq < SEQ_LOW_NUM_THRESHOLD && seqNum > SEQ_HIGH_NUM_THRESHOLD)) {
              //replace the link cost
              payloadsLINK[j] = newCost; //new cost
            } //else keep it as it is
            stop = true; //found matching
          }
        }
      } else {
        //store into the payloads
        dbg(GENERAL_CHANNEL, "should only happen once in each node");
        numPayloads+=1
        payloadsSEQ[0] = seq
        payloadsNODE1[0] = node1
        payloadsNODE2[0] = node2;
        payloadsLINK[0] = newCost;
      } */
    }

  }

  //task to handle the received packet
  void handleReceive(pack* myMsg) {
    bool exists; //exists in current way
    exists = call neighborIndexes.contains(myMsg->src);

    //if it is the reply to this node's broadcast then enter it into the storage
    if(myMsg->dest == TOS_NODE_ID) { //reply to the current node's broadcast from other node
      uint8_t ind;
      if(!exists) {
        //add it to the hashmap and the list
        index = index + 1;
        call neighborIndexes.insert(myMsg->src,index-1);
        /* dbg(GENERAL_CHANNEL, "Adding node %d to list with index: %d\n", myMsg->src, index-1); */
        nodes[index-1] = myMsg->src;
        /* dbg(GENERAL_CHANNEL, "going to1\n"); */

      }

      ind = call neighborIndexes.get(myMsg->src);
      if(numSent[ind] != 0) {
      /* dbg(GENERAL_CHANNEL, "increasing numrecieved %d of node %d with index: %d\n", numReceived[ind], myMsg->src, ind); */
        numReceived[ind] = numReceived[ind]+1;
      }
      //if not then it is a new calculation (and packet arrived late) and dont do anything
    }

    //nonetheless store the calucated link costs
    //UNCOMMENT IN Production
    storeFromPayloads((uint8_t*) myMsg->payload, myMsg->payloadLength); //task to store into the array (costly)

    //if it has not been seen before then the below code will run
    if(!startedPing) {
      /* dbg(GENERAL_CHANNEL, "going to2\n"); */
      //confrom to nearby seq number
      //not really needed but might be useful.
      seq = myMsg->seq;
      call linkND.startPing();
    }

    /* printStuff(); */

    if(myMsg->dest == 0) {
      /* dbg(GENERAL_CHANNEL, "Sending reply to dest: %d\n", myMsg->src); */
      //it is another node's broadcast and need to reply.
      sendPacket(myMsg->src);
    }

  }

  //receive the packet on a specific channel and handle the receive in a task
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    /* dbg(GENERAL_CHANNEL, "Recieved Packet\n"); */

    if(len==sizeof(pack)){
       pack* myMsg =(pack*) payload;
       handleReceive(myMsg); //posts task to handle this later

       return msg;
    }

    dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
    return msg;
  }


  void makePack(pack *Package, uint8_t src, uint8_t payloadLength, uint8_t dest, uint8_t givenSeq, uint8_t* payload, uint8_t length){
     Package->src = src;
     Package->payloadLength = payloadLength;
     Package->dest = dest;
     Package->seq = givenSeq;
     memcpy(Package->payload, payload, length);
  }
}
