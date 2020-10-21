# Digimon Rumble Arena - Training Tools v1.4.2
A LUA script for Bizhawk that adds training mode options to Digimon Rumble Arena (US version, PS1).

# How to use it
* Load Digimon Rumble Arena via the [Bizhawk emulator](http://tasvideos.org/BizHawk.html). Open the Lua console and load the script **DRA_master_tool.lua** that is found in this repository;
* Select "2 Player mode" and start a match;
* Once in game, you can just pause the game to show the GUI. 

# Controls
* Toggle the GUI on/off by pausing/unpausing the game;
* Scroll through options via L2/R2;
* Change values with L1/R1.

While you are using the GUI, the player 2 character will stand still. It is advised to enter the pause menu while using this GUI to avoid accidental presses (e.g. triggering an unwanted Digivolution when scrolling through the options via R1). I have chosen the shoulder buttons because they are the least disruptive, even when the game is running.

# Features
* Toggleable dummy (P1 or P2)
* Toggleable infinite HP for both characters;
* Toggleable infinite or cyclic timer;
* Dummy actions;
* Dummy movement;
* Damage display and true combo counter (the in-game one is kind of bugged)
* Set action to be performed after damage has been dealt/on wake up;
* Show HP/Digi in numeric form;
* Show timer value in frames;
* Show character state (attack, idle, block...) in text form.

# Known issues
* Calling the GUI during a loading screen can cause the game to freeze;
* This script works only if the controls for the Player 2 character are kept to default, in-game;
* I haven't tested this script with either the JP or the PAL version of the game, thus I cannot guarantee for it to work with those too;
* The script needs BizHawk version 2.5.2 or higher to work. Version 2.2 or lower won't show the life values;
* When the game is set to full screen, the training options won't be scaled, causing visual artifacts;
* After a Digievolution, the state variables used to show the current move don't work for the evolved Digimon;
* If the scalable version is used, when the menu is shown, the game could stutter slightly, depending on your PC specs (not yet selectable).
* The combo counter/damage display doesn't work if the lifebars are set to infinite (no damage = no combo);

# Acknowledgements
* Bizhawk's Memory Watch and Memory Search utilities + all its Lua tools, which made this possible;
* The [Digimon Rumble Arena Discord server](https://discord.gg/DTpRqwd), who helped me figuring out which tools to use;
* This [handy website](http://bsfree.shadowflareindustries.com/index.php?s=1&d=8&g=8415&c=20939) where I could retrieve cheat codes for infinite health and frozen timer. Credits to the user StalkerX for posting the codes I used in that part of the script;
* Yuri Bacon for pointing me in the right direction and supplying some of the material I used for this script;
* Teseo22 for retrieving all defence values by sheer determination with a long, daunting sequence of experiments;
* Connor (ncea) for reporting the issues with BizHawk 2.2 and general improvement suggestions.

# Development journal
* An explanation of why I did this and how I figured out most of the stuff in this script can be found in a short-ish Google Doc [here](https://docs.google.com/document/d/1liomAm0ulcBb3i3iuVjsLtElVEWNgxwlazKeHJq3kug/edit?usp=sharing)
