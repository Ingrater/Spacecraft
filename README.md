Spacecraft
==========

A 3d multiplayer deathmatch space game written in D 2.0

Setup
-----

 * This project currently only works with dmd 2.060 on windows
 * You will need a Visual Studio (2008,2010 and 2012 should work, I use 2010) and VisualD 0.3.34 ( http://www.dsource.org/projects/visuald )
 * You will also need my versions of druntime, phobos and thBase (clone them from my github account)
 * Make a copy of your dmd2\windows\bin folder to dmd2\windows\bin-nostd
 * Copy the sc.ini from thBase into the just created dmd2\windows\bin-nostd folder. 
 * You might need to change the path to dmd inside druntime\win32nogc.mak and phobos\win32nogc.mak, it should point to your dmd2\windows\bin-nostd\dmd.exe
 * Download the data package from the download section and unzip into the Spacecraft\game\data directory
 * Make sure to install OpenAL

The folder structure should look as follows:

 * SomeGroupFolder
	* druntime
	* phobos
	* thBase
	* Spacecraft
	
If you want a stable and working version switch to the "Playable" or "Spacecraft-Playable" tags in druntime, phobos, thBase and Spacecraft.
	
Then just build Spacecraft using one of the Visual Studio Solutions.

Usage
-----

First you will need to start up a server to connect to:

Spacecraft.exe -server -ip 127.0.0.1

Then you can connect to it using the client

Spacecraft.exe -ip 127.0.0.1

If you want to play with others over the network you need to specifiy your real ip-address instead of localhost. Spacecraft was not designed to be played over
the internet, but it will work. You will however have some lag if you try it out.

Here is a complete list of all command line options

 * **-server** starts the server
 * **-ip** specifies the ip to connect to / host on
 * **-port** use a different port for connecting / hosting
 * **-nograb** does not grab the mouse
 * **-novsync** does turn vsync off (usefull for profiling)
 * **-width** width of the output resolution
 * **-height** height of the output resolution
 * **-fullscreen** start the game in fullscreen mode
 * **-nomusic** does not play the music while playing
 * **-antialiasing** the amount of antialiasing you want
 * **-name** the name for your player character
 * **-sensitivity** mouse sensitivity multiplier
 * **-team** the team you want to play on (number)
 * **-level** the level to load (only server)
 
Controls
--------

 * W,A,S,D      - fly around
 * Space,Ctrl   - fly up down
 * Q,E          - Roll
 * Shift        - Trigger Booster
 * Mouse        - Look around
 * Mouse Button - Shoot
 * V            - Toggle Thrid Person
 * F1,^         - Toggle Developer Console
 * Tab          - Toggle Score Display
 * M            - Enable/Disable Mouse
 * ESC          - Quit the game