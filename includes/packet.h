#ifndef PACKET_H
#define PACKET_H


#include "protocol.h"
#include "channels.h"

enum{
	PACKET_HEADER_LENGTH = 4,
	PACKET_MAX_PAYLOAD_SIZE = 28 - PACKET_HEADER_LENGTH, //24 uint8_t
};


typedef nx_struct pack{
	nx_uint8_t payloadLength; //# for #of sets (seq, node,node,link) stored in the payload.
	//reply and regular broadcast can both send things inside payload
	nx_uint8_t dest;		//destination = 0 in broadcast
	nx_uint8_t src;
	nx_uint8_t seq;		//Sequence Number
	// nx_uint8_t protocol; //deleteing this since only one protocol is to be implmented
	nx_uint8_t payload[PACKET_MAX_PAYLOAD_SIZE]; //(seq, [node 1] [node 2] [link quality metric]) * 6
}pack;

/*
 * logPack
 * 	Sends packet information to the general channel.
 * @param:
 * 		pack *input = pack to be printed.
 */
// void logPack(pack *input){
// 	dbg(GENERAL_CHANNEL, "Src: %hhu Dest: %hhu Seq: %hhu TTL: %hhu Protocol:%hhu  Payload: %s\n",
// 	input->src, input->dest, input->seq, input->TTL, input->protocol, input->payload);
// }

enum{
	AM_PACK=6
};

#endif
