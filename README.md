# DigimonRumbleArenaTrainingTools
A LUA script for Bizhawk that adds training mode options to Digimon Rumble Arena (US version, PS1).

# How to use it
Load Digimon Rumble Arena via the [Bizhawk emulator](http://tasvideos.org/BizHawk.html). Open the Lua console and load the script that is found in this repository.
Select 2 Player mode and start a match.
Once in game, you can push the button assigned to L3 on your joypad to call the GUI. 

# Controls
* Toggle the GUI on/off by pressing L3
* Scroll through options via L2/R2
* Change values with L1/R1
While you are using the GUI, the player 2 character will stand still.

# Known issues
* Calling the GUI during a loading screen can cause the game to freeze;
* There is no known way (yet) to have options for "move towards"/"move away" commands, as the memory address where the position of the second character is stored is matchup-specific
* I couldn't manage to make 2-Jab and 3-Jab combos work properly;
* This script works only if the controls for the Player 2 character are kept to default, in-game

# Acknowledgements
* Bizhawk Memory Watch + Lua tools, which made this possible
* The [Digimon Rumble Arena Discord server](https://discord.gg/DTpRqwd), who helped me figuring out which tools to use
* This [handy website](http://bsfree.shadowflareindustries.com/index.php?s=1&d=8&g=8415&c=20939) where I could retrieve cheat codes for infinite health and frozen timer. Credits to the user StalkerX for posting the codes I used in that part of the script.
