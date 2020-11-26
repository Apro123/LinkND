#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#include "../../includes/constants.h"
#include "printf.h"

configuration linkNDC {
  provides interface linkND;
}

implementation {
  components linkNDP;
  linkND = linkNDP;
  components ActiveMessageC;
  linkNDP.Packet->ActiveMessageC;

  components PrintfC;
  components SerialStartC;

  components new AMReceiverC(AM_LINK) as GeneralReceive;
  linkNDP.Receive -> GeneralReceive;

  components new SimpleSendC(AM_LINK);
  linkNDP.Sender->SimpleSendC;

  components new TimerMilliC() as Timer1;
  linkNDP.linkTimer -> Timer1;

  components new TimerMilliC() as Timer2;
  linkNDP.waitToReplyTimer -> Timer2;

  components new HashmapC(uint8_t, NUM_POSSIBLE_NODES) as neighborIndexes;
  linkNDP.neighborIndexes->neighborIndexes;

  /* components new HashmapC(uint16_t, 19) as neighborCost;
  linkNDP.neighborCost->neighborCost;

  components new HashmapC(uint16_t, 19) as neighborwithCost;
  linkNDP.neighborWithCost->neighborwithCost; */

  components RandomC as Random;
  linkNDP.Random -> Random;

}
