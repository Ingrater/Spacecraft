import base.logger, std.stdio;

shared void log(const char[] msg){
	synchronized stderr.writeln(msg);
}

void main(){
	base.logger.hook(&log);
	base.logger.level = base.logger.level_t.WARN;
	
	base.logger.info("hello");
	base.logger.warn("test: %s", 123);
	base.logger.error("test: %s %d", "abc", 123);
	base.logger.test("hello");
}
