# drl

DRL a.k.a. "That Trademark", the Roguelike, version 0.10.0
http://drl.chaosforge.org/

## Foreword
This release is dedicated to Jupiter Hell Classic, the commercial remake/expansion to DRL:

https://store.steampowered.com/app/3126530/Jupiter_Hell_Classic/

If you enjoy this Open Source release, please consider buying Jupiter Hell Classic! Also, you might be interested in DRL's modern 3D spiritual successor, Jupiter Hell (yes, it's still turn-based :P):

https://store.steampowered.com/app/811320/Jupiter_Hell/

Parts of this codebase date back to 2002, please do not judge! :P

## Source

This FreePascal source code release is provided as is. You can try compiling it using the latest version of Lazarus ( http://www.lazarus-ide.org/ ). You will also need the FPC Valkyrie library ( https://github.com/ChaosForge/fpcvalkyrie/ ), version 0.10.0. You will also probably need the binary files of the full game downloadable from http://drl.chaosforge.org/ (in particular the sound, soundhq, music and mp3 folder contents, and the premade drl.wad and core.wad if you don't want to create it yourself).

There are two IDEs available: Visual Studio Code and Lazarus. You should only need one of them.

### Components
1. Fpcvalkyrie: is the low level engine that manages the core functions of the game world
2. Makewad.exe assembles the wad files, which contain the digital assets (sounds) and rules (lua)
3. drl.exe is the drl-specific game engine, which references the wads (drl.wad and core.wad)

### Setting up the source folders:
1. Download DRL source from http://drl.chaosforge.org/
2. Download the DRL binaries (if you haven't already)
3. Copy the following files from the DRL binaries:
  * data\\drlhq\music\\* to (bin\\)data\\drlhq\\music
  * data\\drlhq\sounds\\* to (bin\\)data\\drlhq\\sound
  * data\\drlhq\sounds\\* to (bin\\)data\\drllq\\sound
4. Download fpcvalkyrie from https://github.com/ChaosForge/fpcvalkyrie/ to a folder at the same level as the DRL source
5. Ensure drl and fpcvalkyrie are on the same release branch (e.g. master or development)

#### Dependency notes
DRL uses a few sophisticated Lua tricks however v5.1 specifically is compulsory:
* DRL references the dll by name, and the dynamic headers are written against 5.1.
* Upgrading probably won't work simply due to the changes in env-tables.
* Initially the reason to keep being 5.1 compatible for both DRL and JH was due to LuaJIT compatibility, but that point is moot now.

### Updating Lua (no specific IDE required)
#### Configuration
1. Download lua 5.1 (e.g. 5.1.5) from https://sourceforge.net/projects/luabinaries/files/5.1.5/Tools%20Executables/. Unzip it
2. Add lua5.1 in your path
3. Download fpc (e.g. 3.2.2) from https://sourceforge.net/projects/freepascal/ and install it
4. Add fpc to your path

#### Build
1. To build the packages, open a command prompt at the drl root folder and run "lua5.1 makefile.lua". There are also options for lq and hq if you want to change the asset quality.

### Visual Studio Code IDE
#### Configuration
[Instructions appropriated from https://stephan-bester.medium.com/free-pascal-in-visual-studio-code-e1e0a240a430]
1. Download lua 5.1 (e.g. 5.1.5) from https://sourceforge.net/projects/luabinaries/files/5.1.5/Tools%20Executables/. Unzip it
2. Add lua5.1 in your path (the location will be referred to as %lua%)
3. Download and install Lazarus 64-bit (the location will be referred to as %lazarus%)
4. Add %lazarus%\\fpc\\3.2.2\\bin\\x86_64-win64 to your path (to support the release package build)
5. Add %lazarus%\\mingw\\x86_64-win64\\bin to your path (required for gdb, integrated via the Native Debug extension)
6. Install Visual Studio Code
7. Open drl.code-workspace
8. Install the lua extension (by sumneko)
9. Install the OmniPascal - Open Preview (by Wosi)
10. Install the Native Debug extension (from WebFreak)
11. Manage (the cog)/Settings/User/Extensions/OmniPascal configuration
* Default Development Environment: FreePascal
* Free Pascal Source Path: %lazarus%\\fpc\\3.2.2
* Lazbuild path: %lazarus%
12. In the 'drl' (source) folder, open .vscode/settings.json and update the folders to your locations
13. In the status bar you'll see "OmniPascal: Select project". Click and choose drl.lpi (appears to improve the linking experience, although you'll need to do this each time you load the workspace)

#### Build
0. Open drl.code-workspace

To get a debug-ready version going:
1. Terminal/Run Task/Build drl.exe (debug), or Control-Shift-B
At this point you can start debugging, and the lua will compile when you run.

If you want to build the full package:
1. Terminal/Run Task/Build makewad.exe (debug)
2. Terminal/Run Task/Build drl.wad, core.wad
3. Terminal/Run Task/Build the release package (all). This won't work on a windows machine without some adjustments to the build script.

You can test all these steps with Terminal/Run Task/Unit test build scripts (noting the release build step may fail).

#### Build errors
There seems to be an error when attempting to rebuilding drl.exe after the wads exist. Some further analysis might understand this better and possibly remove the wads prior to recompiling drl.exe. The easiest approach to recover from the situation:
1. Terminal/Run Task/Clean Build Folders
2. Repeat the Build tasks from step 1.

#### Debugging
##### Pascal
1. Set a breakpoint (F9). For example at the first line of code in drl.pas.
2. Run/Start Debugging.

##### Lua
Because the lua code is packaged into the wad file, inline debugging is more difficult. Instead the lua console provides an interface to run commands.
1. Run/Start Debugging
2. Launch a game
3. F1
4. Some examples of useful commands are:
   * player:exit(27,0.1) (<i>Jump to the first special level</i>)
   * player.inv:add("nuke") (<i>Give me some real firepower</i>)
   * player:set_affect("inv",5000) (<i>Feeling scared</i>)
   * player:relocate(coord(10,10)) (<i>Send me to this location</i>)
5. You can also use = to print values for classes, methods or properties:
   * =player (<i>class</i>)
   * =player:get_id() (<i>method</i>)
   * =player.id (<i>property</i>)
   * =player.eq.weapon.ammo
   * =player.eq.weapon:is_damaged()
   * =level.name

##### Gameplay
1. Run/Start Debugging
2. Start a new game
3. There is a myriad of game keys defined in godmode.lua to accelerate the character.

#### Lazarus notes
The Lazarus installation is preferred for VS Code (compared with the simpler fpc installation) because using fpc in Windows triggers an error when the debugger is used.

### The Lazarus IDE
#### Configuration
1. Download lua 5.1 (e.g. 5.1.5) from https://sourceforge.net/projects/luabinaries/files/5.1.5/Tools%20Executables/. Unzip it
2. Add lua5.1 in your path (the location will be referred to as %lua%)
3. Download and install Lazarus 64-bit (the location will be referred to as %lazarus%)
4. Add %lazarus%\\fpc\\3.2.2\\bin\\x86_64-win64 to your path (to support the release package build)

#### Build
1. Open src/makewad.lpi (with Lazarus). Build. You should receive '...bin\makewad.exe: Success'
2. Start a command prompt and change to the bin folder. Run makewad.exe
3. Open src/drl.lpi. Build. You should receive '...bin\drl.exe: Success'
4. Open up the Run\Run Parameters screen. Correct the working directory to point to your bin folder. Also note the Command Line Parameters, which might change the application's behaviour
5. Run
6. To build the packages, open a command prompt at the drl root folder and run "lua5.1 makefile.lua all". There are also options for lq and hq if you want to change the asset quality.

## Author's notes
All code is (C) 2003-2025 Kornel Kisielewicz

Code is distributed under the GPL 2.0 license (see LICENSE file in this folder)

Original art and sprites (0.9.9.7) by Derek Yu, (C) 2003-2025, licensed under CC BY-SA 4.0. Modified version and additions (0.9.9.8+) by Łukasz Śliwiński, (C) 2025, licensed under CC BY-SA 4.0.

All art is distributed under the CC-BY-SA 4.0 license (see LICENSE file in bin/data/drl/graphics).

sincerely,
Kornel Kisielewicz 
ChaosForge
