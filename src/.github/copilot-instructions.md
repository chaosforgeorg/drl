# DRL (DoomRL) Copilot Instructions

## Project Overview

DRL is a roguelike game built in **Object Pascal (Free Pascal Compiler)** with a dual-engine architecture:
- **Pascal engine** (`drl.exe`) - Core game logic, rendering, I/O
- **Lua scripting** (`*.wad` files) - Game content, rules, procedural generation

This is a multi-workspace project spanning 4 directories (see workspace folders).

**Multi-Module Architecture**: The engine supports multiple game modules:
- **DRL** (`bin/data/drl/`) - Open-source Doom roguelike
- **JHC** (`bin/data/jhc/`) - Jupiter Hell Classic (commercial Steam game, separate git repo)
- **Core** (`bin/data/core/`) - Shared Lua code used by both modules

Each module can have independent `.github/copilot-instructions.md` for module-specific guidance. In particular, see `bin/data/jhc/.github/copilot-instructions.md` for JHC-specific instructions.

## Architecture

### Component Structure

1. **FPC Valkyrie** (`d:\fpcvalkyrie\src`, `d:\fpcvalkyrie\libs`)
   - Low-level engine providing graphics (OpenGL), audio (SDL), console I/O
   - UI framework (VTIG - immediate mode GUI), pathfinding, Lua bindings
   - Base classes: `TNode`, `TIOLayer`, `TLuaEntityNode`, sprite engine
   - Configuration: `valkyrie.inc` sets compiler modes (`OBJFPC`, `ADVANCEDRECORDS`, `CORBA` interfaces)

2. **DRL Game Engine** (`d:\doomrl\src`)
   - Main executable: `drl.pas` (entry point)
   - Core types in `df*.pas` files:
     - `TPlayer` (extends `TBeing`) - Player state, traits, statistics
     - `TBeing` - All living entities with combat, AI, inventory
     - `TItem` - Weapons, armor, consumables with mods and properties
     - `TLevel` - Map data, visibility, pathfinding, turn processing
   - Configuration: `drl.inc` sets project-wide compiler directives
   - State machine: `TDRLState` (`DSStart`, `DSMenu`, `DSPlaying`, etc.) in `drlbase.pas`
   
3. **Lua Content Layer** (`d:\doomrl\bin\data`)
   - `core/*.lua` - Base game systems (generator, AI, blueprints) - **shared by all modules**
   - `drl/*.lua` - DRL-specific content (beings, items, levels, assemblies)
   - `jhc/*.lua` - JHC-specific content (separate game module, own git repo)
   - Modular design: Core registers storage types, modules implement content
   - Hooks system: Pascal code calls Lua hooks at runtime for extensibility
   - Module selection: `CoreModuleID` global (set in `settings.lua` or `-module` flag)

### Build Pipeline

**Critical**: Game content is compiled into `.wad` files before runtime.

1. **Build `makewad.exe`** (from `makewad.pas`) - WAD compiler tool
2. **Run `makewad.exe`** in `bin` directory - Creates `drl.wad` and `core.wad` from:
   - Lua scripts (`data/core/*.lua`, `data/drl/*.lua`)
   - ASCII art (`help/*.asc`)
   - Audio assets
3. **Build `drl.exe`** (from `drl.pas`) - Main executable
4. **Package release** - Run `lua makefile.lua <target>` for distribution builds

**VS Code Tasks**:
- Default build: `Build drl.exe (debug)` (Ctrl+Shift+B)
- Full rebuild chain: `Unit test build scripts` task
- Run without rebuild: `Run drl.exe (debug)` task

**IMPORTANT FOR COPILOT**: When compiling the project, ALWAYS use VS Code tasks via `run_task` tool:
- Use task `shell: Build drl.exe (debug)` for debug builds
- Use task `shell: Build drl.exe (release)` for release builds
- Use task `shell: Build makewad.exe (debug)` then `shell: Build drl.wad, core.wad` for WAD compilation
- NEVER run `fpc.exe` directly in terminal - always use the predefined tasks
- After running a task, use `terminal_last_command` tool to check build output (the `get_task_output` tool does not work with these tasks)

## Critical Conventions

### Pascal Specifics

```pascal
{$INCLUDE drl.inc}  // MUST be first line in every DRL source file
```

- **Naming**: `TClassName`, `FFieldName`, `aParameterName`
- **Interfaces**: CORBA-style (no reference counting, manual management)
- **Properties**: Use published properties for Lua exposure
- **Generics**: `TGArray<T>`, `TGHashMap<T>` from Valkyrie
- **Coordinates**: `TCoord2D` (1-based), `TArea` for ranges

### Lua Integration

Pascal-to-Lua registration pattern:
```pascal
class procedure TMyClass.RegisterLuaAPI();
begin
  LuaSystem.RegisterType( TMyClass, 'myclass', 'myclasses' );
  // Properties become Lua table fields automatically
end;
```

Lua calls Pascal hooks via:
```pascal
function CallHook(Hook: Byte; const Params: array of Const): Boolean;
```

### UI Architecture (VTIG)

Immediate-mode GUI - rebuild UI every frame:
```pascal
VTIG_Begin('menu_id', Point(width, height));
if VTIG_Selectable('Option') then 
  HandleSelection;
VTIG_End('Footer text');
```

## Common Tasks

### Adding New Game Content

1. **New item/being/level**: Edit Lua in `data/drl/*.lua` (or `data/core/`)
2. **Test**: Run `drl.exe` - during development, the game loads Lua files directly from disk

**Note**: WAD files (`drl.wad`, `core.wad`, `jhc.wad`) are only needed for release builds. During development, the engine reads Lua scripts directly from the `data/` directory, so there's no need to rebuild WAD files after editing Lua code.

### Debugging

- **Runtime logs**: Check `WritePath + 'runtime.log'` (configured in `settings.lua`)
- **Error logs**: `WritePath + 'error.log'`
- **God mode**: Run with `-god` parameter (loads `godmode.lua` config)
- **Console mode**: `-console` flag (ASCII rendering)

### File Locations

- **Source**: `d:\doomrl\src\*.pas`
- **Valkyrie**: `d:\fpcvalkyrie\src\*.pas`, `d:\fpcvalkyrie\libs\*.pas`
- **Build output**: `d:\doomrl\bin\` (debug and release use same dir)
- **Temporary units**: `d:\doomrl\tmp\` (compiler cache)
- **Data/Lua**: `d:\doomrl\bin\data\` (multi-workspace folder)

## Configuration Files

- **`.vscode/settings.json`**: Build paths (FPC, Lazarus, directories)
- **`.vscode/tasks.json`**: Build tasks with FPC command-line flags
- **`config.lua`**: Game configuration (data paths, modules)
- **`settings.lua`**: User settings (graphics, keybindings)

## Key Dependencies

- **Free Pascal 3.2.2+** (`fpc.exe`, `instantfpc.exe`)
- **Lazarus IDE libraries** (LCL units, required even for command-line builds)
- **Lua 5.1** (for build scripts: `makefile.lua`)
- **SDL3** (dynamically loaded at runtime via Valkyrie)

## Module System

The engine supports multiple game modules with shared core code:

**Module Structure**:
- **Core module** (`bin/data/core/`) - Base systems, always loaded first
  - Registers storage types: `register_cell`, `register_being`, `register_item`, etc.
  - Provides generator, AI toolkit, blueprint validation
- **Game modules** (`bin/data/drl/`, `bin/data/jhc/`) - Content implementations
  - Each has `main.lua` declaring `core_module` variable
  - Implements content: beings, items, levels, challenges, traits
  - Can override `core.options` for gameplay differences
  - Independent git repositories for commercial modules (JHC)

**Module Selection**:
- Default: `settings.lua` → `default_module = "drl"` (or `"jhc"`)
- Command-line: `drl.exe -module jhc`
- Runtime: `CoreModuleID` global variable in Pascal

**WAD Compilation**: Both `core.wad` and `<module>.wad` are generated by `makewad.exe`

## Testing Notes

- No automated test suite exists
- Manual testing workflow: Modify Lua → Rebuild WAD → Run game
- Use `-window` flag for easier debugging (forces windowed mode)
- GodMode config provides debug hooks and infinite health

## JHC (Jupiter Hell Classic) Module

Jupiter Hell Classic is a commercial demake of Jupiter Hell built on the DRL engine. It's a separate Steam game with its own git repository within the DRL data directory.

**Module Identity**: 
- Module ID: `"jhc"` (declared as `core_module` in `main.lua`)
- Version: Check `VERSION_MODULE` in `main.lua`
- Repository: Independent git repo at `bin/data/jhc/`
- Builds to: `jhc.wad` (alongside `core.wad`)

### JHC vs DRL Differences

**Gameplay Philosophy**:
- **Setting**: Jupiter moons (Callisto, Europa, Io, Dante) vs Mars bases
- **Classes**: Marine/Scout/Technician vs DRL's trait-based progression
- **Items**: Sci-fi weapons (plasma, gauss) vs Doom weapons (BFG, rockets)
- **Progression**: More RPG-like with klasses and active abilities

**Core Options Overrides**:
```lua
core.options.auto_glow_items = false          -- No auto-glow
core.options.klass_achievements = true        -- Class achievements
core.options.new_menu = true                  -- Modern menu system
core.options.melee_move_on_kill = true        -- Move after melee kill
core.options.full_being_description = true    -- Detailed enemy info
core.options.percent_health = false           -- Absolute health display
```

### JHC Content Structure

**Key Files**:
- **`main.lua`** - Module initialization, `jhc.OnLoad()` entry point
- **`klasses.lua`** - Marine/Scout/Technician class definitions with trait trees
- **`beings.lua`** - JHC enemies (CRI soldiers, bots, aliens)
- **`items.lua`** / **`eitems.lua`** / **`uitems.lua`** - Weapon/armor/uniques
- **`assemblies.lua`** - Crafting recipes (mods work differently than DRL)
- **`levels/`** - Campaign levels organized by moon

**Level Campaigns**:
```
levels/
  callisto/  - Starting moon, tutorial levels
  europa/    - Ice moon, mid-game
  io/        - Volcanic moon, high difficulty
  dante/     - Hell station, endgame
```

### JHC-Specific Patterns

**Class Active Abilities** - Classes have cooldown-based active abilities:
```lua
OnUseActive = function( self )
  if self:is_perk( "tired" ) then return false end
  self:add_perk( "adrenaline", duration )
  return true
end
```

**Perk System** - Unlike DRL's simpler traits, JHC uses status effect perks:
- Tracked via `being:is_perk( "perk_id" )`
- Time-based: `being:add_perk( "perk_id", ticks )`
- Stacking rules in `affects.lua`

**Item Modding** - JHC has different mod slots and rules:
- Weapons use capital letter mods (`'A'..'Z'`)
- Assemblies check mod combinations differently
- See `assemblies.lua` for assembly-specific logic

### JHC Content Tasks

**New enemy**: Edit `beings.lua`, rebuild `jhc.wad`
```lua
register_being "new_enemy"
{
  name = "Enemy Name",
  -- being properties
  OnAction = function(self) end
}
```

**New weapon**: Add to `items.lua` or `uitems.lua` (uniques)
```lua
register_item "weapon_id"
{
  name = "Weapon",
  type = ITEMTYPE_RANGED,
  -- weapon stats
}
```

**New level**: Create in `levels/<moon>/`, require in campaign file

### JHC Integration with Core

JHC relies on core systems but extends them:
- Uses `core.generator` but overrides generation functions
- Extends `core.aitk` with JHC-specific AI behaviors
- Shares blueprint validation but has different content schemas

### JHC Code Style Notes

- JHC Lua tends toward longer, more descriptive function names
- Heavy use of closures for level-specific generators
- More object-oriented patterns than DRL's procedural style
- Comments reference Jupiter Hell (the full game) mechanics

### Demo vs Full Version

`DEMO` flag in `main.lua` controls content availability:
```lua
if not DEMO then
  require( "jhc:levels/europa/europa" )
  require( "jhc:levels/io/io" )
  require( "jhc:levels/dante/dante" )
end
```

Demo builds only include Callisto content.

### Commercial Considerations

- **License**: Proprietary, separate from DRL's GPL
- **Assets**: Graphics/audio not in open-source DRL
- **Steam integration**: Uses Steam achievements, cloud saves
- **Distribution**: Steam-only, no open release
