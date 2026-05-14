-- ----------------------------------------------------------------------
--  This is the DRL initialization file. Modify at your own risk :). 
--  If you mess up something overwrite with a new config.lua.
-- ----------------------------------------------------------------------

-- Graphics mode. Can be CONSOLE for raw console, or TILES for graphical 
-- tiles. Overriden by -graphics and -console command line parameters.
Graphics = "TILES"

-- Sound engine, by default is FMOD on Windows, SDL on *nix. To use SDL on 
-- Windows you'll need SDL_mixer.dll and smpeg.dll from SDL_mixer website.
-- For using FMOD on *nix systems you'll need the proper packages.
-- Possible values are FMOD, SDL, NONE, DEFAULT
SoundEngine = "DEFAULT"

-- Whether to allow high-ASCII signs. Set to false if you see weird signs 
-- on the screen. Not setting it at all will use the default which
-- is true on Windows and false on OS X and Linux
-- AllowHighAscii   = true

-- Specifies wether items in inventory and equipment should be colored
ColoredInventory = true

-- Setting this to anything except "" will always use that as the name.
-- Warning - no error checking, so don't use too long names, or especially
-- the "@" sign (it's a control char). This setting overrides the one above!
--AlwaysName       = ""

-- Setting to false will turn off music during gameplay
GameMusic        = true

-- Setting to false will turn off sounds during gameplay
GameSound        = true

-- Setting to true will turn on enhancements for blind people playing
-- DRL using a screen reader. Yes, some do.
BlindMode        = false

-- Setting to true will make old messages disappear from the screen 
-- (useful in BlindMode)
ClearMessages    = false

-- Setting to false will prevent DRL from waiting for confirmation
-- when too many messages are printed in a turn. Usefull for Speedrunning.
MorePrompt       = true

-- If set to true, pickup sound will be used for quickkeys and weapon
-- swapping.
SoundEquipPickup = false

-- (ASCII Only) Sets the delay value when running. Value is in milliseconds. Set to 0 for no delay.
RunDelay         = 20

-- Handles what should be done in case of trying to unwield an item when inventory
-- is full : if set to false will ask the player if he wants to drop it. If set
-- to true will drop it without questions.
InvFullDrop      = false

-- Messages held in the message buffer.
MessageBuffer    = 100

-- Sets wether message coloring will be enabled. Needs [messages] section.
MessageColoring  = true

-- If set to true will archive EVERY mortem.txt produced in the mortem subfolder.
-- The amount of files can get big after a while :)
MortemArchive    = true

-- Sets the amount of player.wad backups. Set 0 to turn off. At most one backup
-- is held for a given day.
PlayerBackups    = 7

-- Sets the amount of score.wad backups. Set 0 to turn off.  At most one backup
-- is held for a given day.
ScoreBackups     = 7

-- If set to false DRL will quit on death and quitting. Normally it will go back
-- to the main menu.
MenuReturn       = true

-- Defines the maximum repeat for the run command. Setting it to larger than 80
-- basically means no limit.
MaxRun           = 100

-- Defines the maximum repeat for the run command when waiting.
MaxWait          = 20

-- Windows only - disables Ctrl-C/Ctrl-Break closing of program. 
-- true by default.
LockBreak        = true

-- Windows only - Disables closing of DRL by console close button. 
-- true by default.
LockClose        = true

-- Sets the color of intuition effect for beings
IntuitionColor   = LIGHTMAGENTA

-- Sets the char of intuition effect for beings
IntuitionChar    = "*"

-- Mortem and screenshot timestamp format
-- Format : http://www.freepascal.org/docs-html/rtl/sysutils/formatchars.html
-- note that / and : will be converted to "-" due to filesystem issues
TimeStamp        = "yyyy/mm/dd hh:nn:ss"

-- Controls whether the game will attempt to save the game on crash, set to false
-- to turn this off
SaveOnCrash      = true

-- Message coloring system. Works only if MessageColoring
-- variable is set to true. Use basic color names available in 
-- colors.lua.
-- As for the string, it's case sensitive, but you may use
-- the wildcard characters * and ?.

-- Unsure how these work and want to fiddle with them?
-- Head over to http://forum.chaosforge.org/ for more info.

-- Colors can be:
BLUE        = 1
GREEN       = 2
CYAN        = 3
RED         = 4
MAGENTA     = 5
BROWN       = 6
LIGHTGRAY   = 7
DARKGRAY    = 8
LIGHTBLUE   = 9
LIGHTGREEN  = 10
LIGHTCYAN   = 11
LIGHTRED    = 12
LIGHTMAGENTA= 13
YELLOW      = 14
WHITE       = 15
-- The darker (first 8) work better, as they get highlighted
-- rest will highlight to White.

Messages = {
	["Warning!*"] 		              = RED,
	["Your * destroyed!"]             = RED,
	["You die*"]                      = RED,
	["Your * damaged!"]               = BROWN,
	["You feel relatively safe now."] = BLUE
}

-- == Path configuration ==
-- You can use command line switch -config=/something/something/config.lua 
-- to load a different config!

-- Uncomment the following paths if needed:

-- This is the directory path to the read only data folder (current dir by
-- default, needs slash at end if changed). -datapath= to override on 
-- command line.
--DataPath = ""

-- This is the directory path for writing (save, log) (current dir by
-- default, needs slash at end if changed). -writepath= to override on 
-- command line.
--WritePath = ""

-- This is the directory path for score table (by default it will be the
-- same as WritePath, change for multi-user systems. -scorepath= to override
-- on command line.
--ScorePath = ""

-- Custom coloring based on entity ID's. Search the DRL wiki
-- for id's for entities.
--
-- In case of cells, there are two overrides - [id]_light and [id]_dark
-- [id]_dark cells are out of vision, [id]_light cells are ones you can see.

-- An example of how to change DRL's color scheme.
Colors = {
--	floor_dark  = GREEN,
--	floor_light = BLUE,
--	former = BLUE,
--	demon  = GREEN,
}

-- you can add move or add your changes in separate files using dofile:
--dofile "colors.lua"