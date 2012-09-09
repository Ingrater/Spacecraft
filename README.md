Spacecraft
==========

A 3d multiplayer deathmatch space game written in D 2.0

Setup
-----

 * This project currently only works with dmd 2.058
 * You will also need my versions of druntime, phobos and thBase
 * Copy the sc.ini from thBase into your dmd2\windows\bin folder. Make a backup copy of the old one, it will break compiling other D projects.
 * Download the data package from the download section and unzip into the Spacecraft\game\data directory

The folder structure should look as follows:

 * SomeGroupFolder
	* druntime
	* phobos
	* thBase
	* Spacecraft
	
Then just build Spacecraft using one of the Visual Studio Solutions. You will need to have VisualD installed.