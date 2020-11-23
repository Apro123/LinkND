#ifndef CONSTANTS_H
#define CONSTANTS_H

enum{
	NUM_POSSIBLE_NODES=255,//from 1 to 255
	COST_FLUSH_LIMIT=5, //after every 5 remove the list of packet received and packet not received
	LINKND_TIMER_DURATION=2500, // timer duration to send broadcast packet
	SEQ_LOW_NUM_THRESHOLD=4,
	// threshold for the seq low number, if seq recived is lower than this while others is higher than below high num
	// threashold then the low number is "higher" than the higher number
	SEQ_HIGH_NUM_THRESHOLD=250,
	// LAST_CONNECTED_NODE_ID=255 //must be sequential
};

#endif
