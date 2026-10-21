-- ----------------------------------------------------------------------
--  This is the DRL initialization file. Modify at your own risk :). 
--  If you mess up something overwrite with a new config.lua.
-- ----------------------------------------------------------------------

-- Graphics mode. Can be CONSOLE for raw console, or TILES for graphical 
-- tiles. Overriden by --graphics and --console command line parameters.
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

-- Message coloring system. Remove or comment out the Messages
-- table to turn it off. Use basic color names available in
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
-- You can use command line switch --config=/something/something/config.lua
-- to load a different config!

-- Uncomment the following paths if needed:

-- This is the directory path to the read only data folder (current dir by
-- default, needs slash at end if changed). --data-path= to override on
-- command line.
--DataPath = ""

-- This is the directory path for writing (save, log) (current dir by
-- default, needs slash at end if changed). --write-path= to override on
-- command line.
--WritePath = ""

-- This is the directory path for score table (by default it will be the
-- same as WritePath, change for multi-user systems. --score-path= to override
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