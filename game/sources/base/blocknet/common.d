module base.blocknet.common;

import base.socket: ntohs;

/**
 * Range that takes raw data and interprets it as a list of byte blocks. Each
 * block starts with an ushort (in network byte order!) that defines the length
 * of the following raw data. After that data block the next block begins.
 */
struct block_range_t {
	const void[] data;
	uint consumed_bytes = 0;
	
	@property bool empty(){
		auto remaining_bytes = data.length - consumed_bytes;
		if (remaining_bytes < 2)
			return true;
		else
			return (remaining_bytes < current_block_size);
	}
	
	@property const(void[]) front(){
		return data[consumed_bytes+2 .. consumed_bytes + 2 + current_block_size];
	}
	
	void popFront(){
		consumed_bytes += 2 + current_block_size();
	}
	
	private ushort current_block_size(){
		ushort* size_ptr = cast(ushort*) data[consumed_bytes .. consumed_bytes+2].ptr;
		return ntohs(*size_ptr);
	}
	
	@property const(void[]) rest(){
		return data[consumed_bytes..$];
	}
}

unittest {
	// Test normal operation with a buffer that only contains complete blocks
	auto data = "\x00\x05hallo\x00\x04test";
	auto blocks = block_range_t(data);
	
	assert(!blocks.empty);
	assert(blocks.front == "hallo");
	assert(blocks.rest == data);
	
	blocks.popFront();
	assert(!blocks.empty);
	assert(blocks.front == "test");
	assert(blocks.rest == "\x00\x04test");
	
	blocks.popFront();
	assert(blocks.empty);
	assert(blocks.rest == "");
}

unittest {
	// Test buffer with incomplete blocks
	auto data = "\x00\x04full\x00\x09cont";
	auto blocks = block_range_t(data);
	
	assert(!blocks.empty);
	assert(blocks.front == "full");
	assert(blocks.rest == data);
	
	blocks.popFront();
	assert(blocks.empty);
	assert(blocks.rest == "\x00\x09cont");
}
