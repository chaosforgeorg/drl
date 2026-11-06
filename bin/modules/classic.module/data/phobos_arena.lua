register_level "phobos_arena"
{
  name = "Phobos Arena",
  entry = "Then at last he found the Phobos Arena!",
  welcome = "You enter a big arena. There's blood everywhere. You hear heavy mechanical footsteps...",

  Create = function ()
    level:fill( "wall" )
    level:fill( "floor", level:get_area():shrinked() )
    local scatter_area = area( 5,3,68,15 )
    local translation = {
        ['.'] = { "floor", flags = { LFBLOOD } },
        ['#'] = "gwall",
        ['>'] = "stairs",
    }
    generator.scatter_put(scatter_area,translation, [[
      .....
      .###.
      .###.
      .###.
      .....
    ]],"floor",12)

    level.flags[ LF_NOHOMING ] = true
    generator.scatter_blood(level:get_area():shrinked(),"floor",100)
    generator.set_permanence( level:get_area() )
  end,

  OnEnter = function ()
    local boss = level:summon("cyberdemon")
    boss.flags[ BF_BOSS ] = true
  end, 
}
