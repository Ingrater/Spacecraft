# -version=direct_draw for debug draws
# -debug=net for net code logging
# -debug for console log output
# -version=prediction for client side prediction

all:
	dmd `find base client server game renderer script sound main.d -name '*.d' -printf '%p '` -gc -L-lrt -L-ldl -m32 -ofspacecraft -debug -unittest

# Note: -inline crashes the release build
release:
	dmd `find base client server game renderer script sound main.d -name '*.d' -printf '%p '` -L-lrt -L-ldl -m32 -ofspacecraft -release -O

clean:
	rm spacecraft
	rm *.o

block_server:
	dmd tests/block_server.d base/logger.d base/socket.d base/blocknet/*.d  \
	server/posix_console.d server/windows_console.d server/console.d \
	script/*.d base/script.d base/utilsD2.d base/sharedlib.d \
	-g -L-lrt -L-ldl -ofblock_server

block_client:
	dmd tests/block_client.d base/logger.d base/socket.d base/blocknet/*.d \
	script/*.d base/script.d base/utilsD2.d base/sharedlib.d \
	-g -L-lrt -L-ldl -ofblock_client

script_test:
	dmd tests/scripting.d script/*.d base/script.d base/utilsD2.d base/sharedlib.d  -g -L-lrt -L-ldl

logger_test:
	dmd base/logger.d tests/logger.d -oflogger_test -g -L-lrt -L-ldl
