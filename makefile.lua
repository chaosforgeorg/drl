#!/usr/bin/lua
xpcall( function() dofile( "config.lua") end, function() end )
VALKYRIE_ROOT = VALKYRIE_ROOT or os.getenv("FPCVALKYRIE_ROOT") or "../fpcvalkyrie/"
dofile (VALKYRIE_ROOT.."scripts/lua_make.lua")

local BUILT = false

function set_demo(path, value)
    local new_value = value and "true" or "false"

    local f = assert(io.open(path, "r"))
    local content = f:read("*a")
    f:close()

    local new_content, n = content:gsub(
        'core%.declare%s*%(%s*"DEMO"%s*,%s*%a+%s*%)',
        'core.declare( "DEMO", ' .. new_value .. ' )'
    )

    if n == 0 then
        error("No matching DEMO declaration found in " .. path)
    end

	f = assert(io.open(path, "w"))
    f:write(new_content)
    f:close()
end

makefile = {
	name = "drl",
	fpc_params = {
		"-Fu"..VALKYRIE_ROOT.."src",
		"-Fu"..VALKYRIE_ROOT.."libs",
	},
	fpc_os_params = {
		WINDOWS = {},
		LINUX = {	
			"-TLINUX",
		},
		MACOSX = {	
			"-dOSX_APP_BUNDLE",
			"-k-macosx_version_min -k10.4",
		},
	},
	pre_build = function()
		local v = make.readversion( "bin/version.txt" )
		local s = make.gitrevision()
		v.core = "drl"
		make.writeversion( "src/version.inc", v, s )
		--make.svncheck(s)
	end,
	post_build = function()
	end,
	source_files = { "drl.pas", "makewad.pas", "drlwad.pas" },
	publish = {
		lq = {
			exec = { "drl" },
			files = { "config.lua", "font.dat" },
			os = {
				WINDOWS = { "fmod64.dll", "lua5.1.dll", "SDL3.dll", "SDL3_image.dll", "drl_console.bat" },
				LINUX   = { "unix_notes.txt", "drl_gnome-terminal", "drl_konsole", "drl_xterm", dos2unix = true, },
				MACOSX  = { "unix_notes.txt" },
			},
			subdirs = {
				["data/drllq/sound"] = "*.wav",
				["data/drllq/music"] = "*.mid",
				["data/drllq"] = "*.lua",
			},
			other = { "manual.txt", "version.txt", "version_api.txt", "drl.wad", "core.wad" },
		},
		hq = {
			exec = { "drl" },
			files = { "config.lua", "font.dat" },
			os = {
				WINDOWS = { "fmod64.dll", "lua5.1.dll", "SDL3.dll", "SDL3_image.dll", "drl_console.bat" },
				LINUX   = { "unix_notes.txt", "drl_gnome-terminal", "drl_konsole", "drl_xterm",  dos2unix = true, },
				MACOSX  = { "unix_notes.txt" },
			},
			subdirs = {
				["data/drlhq/sound"] = "*.wav",
				["data/drlhq/music"] = "*.mp3",
				["data/drlhq"] = "*.lua",
			},
			other = { "manual.txt", "version.txt", "version_api.txt", "drl.wad", "core.wad" },
		},
		jhc = {
			exec = { "drl" },
			files = { "config.lua", "font.dat" },
			os = {
				WINDOWS = { "steam_api64.dll", "fmod64.dll", "lua5.1.dll", "SDL3.dll", "SDL3_image.dll", "drl_console.bat" },
				LINUX   = { "unix_notes.txt", "drl_gnome-terminal", "drl_konsole", "drl_xterm",  dos2unix = true, },
				MACOSX  = { "unix_notes.txt" },
			},
			other = { "jhc.wad", "core.wad" },
		}
	},
	commands = {
		jhc_demo_test = function()
			os.execute_in_dir( "makewad jhc", "bin" )
			local path = make.publish( "deploy", "jhc" )
			make.steam( path, os.pwd().."\\bin\\data\\jhc\\setup\\demo\\app_build_3256910.vdf" )
		end,
		jhc_demo = function()
			set_demo("bin/data/jhc/main.lua", true)
			os.execute_in_dir( "makewad jhc demo.txt", "bin" )
			set_demo("bin/data/jhc/main.lua", false)
			local path = make.publish( "deploy", "jhc" )
			make.steam( path, os.pwd().."\\bin\\data\\jhc\\setup\\demo\\app_build_3256910.vdf" )
		end,
		jhc = function()
			os.execute_in_dir( "makewad jhc", "bin" )
			local path = make.publish( "deploy", "jhc" )
			make.steam( path, os.pwd().."\\bin\\data\\jhc\\setup\\app_build_3126530.vdf" )
		end,
		lq = function()
			if not BUILT then
				os.execute_in_dir( "makewad", "bin" )
				BUILT = true
			end
			make.package( make.publish( (OS_VER_PREFIX or "")..make.version_name().."-lq", "lq" ), PUBLISH_DIR )
		end,
		hq = function()
			if not BUILT then
				os.execute_in_dir( "makewad", "bin" )
				BUILT = true
			end
			make.package( make.publish( (OS_VER_PREFIX or "")..make.version_name(), "hq" ), PUBLISH_DIR )
		end,
		drl_mod = function()
			os.execute_in_dir( "makewad drl drlhq", "bin" )
			os.copy( "bin/drl.wad", "bin/deploy/drl/drl.wad" )
			os.execute_in_dir( "drl -publish drl -god", "bin" )
		end,
		install = function() makefile.commands.installhq() end,
		installhq = function()
			if not BUILT then
				os.execute_in_dir( "makewad", "bin" )
				BUILT = true
			end
			if OS == "WINDOWS" then	
				make.generate_iss( "drl.iss", "hq", PUBLISH_DIR ) 
			elseif OS == "MACOSX" then
				make.generate_bundle( "hq", PUBLISH_DIR ) 
			end
		end,
		installlq = function()
			if not BUILT then
				os.execute_in_dir( "makewad", "bin" )
				BUILT = true
			end
			if OS == "WINDOWS" then	
				make.generate_iss( "drl.iss", "lq", PUBLISH_DIR ) 
			elseif OS == "MACOSX" then
				make.generate_bundle( "lq", PUBLISH_DIR ) 
			end
		end,
		all = function()
			makefile.commands.lq()
			makefile.commands.hq()
			makefile.commands.install()
		end,
		alllq = function()
			makefile.commands.lq()
			makefile.commands.installlq()
		end,
	},
	install = {
		guid        = "E78C63C9-9849-45FA-8315-2AE38A293E2E",
		name        = "DRL",
		publisher   = "ChaosForge",
		license     = "install\\install_license.txt",
		info_after  = "install\\install_after.txt",
		iss_icon    = "src\\icon.ico",
		iss_image   = "install\\install.bmp",
		iss_simage  = "install\\install_small.bmp",
		iss_url     = "http://www.chaosforge.org/",
		iss_nocomp  = { "wad", "mp3" },
		iss_eicons  = {
			{ name = "DRL", exe = "drl" },
			{ name = "DRL (console mode)", exe = "drl", parameters = "-console" },
			{ name = "DRL Manual", file = "manual.txt" },
			{ name = "ChaosForge Website", url = "http://www.chaosforge.org/" },
			{ name = "DRL Website", url = "https://drl.chaosforge.org/" },
			{ name = "DRL Forum", url = "http://forum.chaosforge.org/" },
		},
		dmg_size   = 128000,
		app_icon   = "bin/iconfile.icns",
		app_bg     = "background.png",
		app_fworks = {
			"Frameworks/SDL.framework",
			"Frameworks/SDL_image.framework",
			"Frameworks/SDL_mixer.framework",
		},
		app_exefix = function( file )
			os.execute("install_name_tool -change @rpath/SDL.framework/Versions/A/SDL @executable_path/../Frameworks/SDL.framework/Versions/A/SDL "..file )
		end,

	}
}

make.compile()
make.command( arg[1] )
