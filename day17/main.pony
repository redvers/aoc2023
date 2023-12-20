use "files"
use "debug"
use "collections"
use @exit[None](i: USize)
use @printf[U8](fmt: Pointer[U8] tag, ...)

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    for filename in env.args.slice(1).values() do
      let fn: FileReader = FileReader(env.out, FileAuth(env.root), filename)
      fn.parse_file()
		end


actor FileReader
  let stdout: OutStream tag
  let fileauth: FileAuth val
  let filename: String val

  var score: Array[Array[U8] val] val = recover val Array[Array[U8] val] end
  var max_row: USize = 0
  var max_col: USize = 0

  var locationmap: Map[String, Location] = Map[String, Location]
  var todo: Array[Location] = Array[Location]

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

  be parse_file() =>
    let path = FilePath(fileauth, filename)

    match OpenFile(path)
    | let file: File =>
      let lines: FileLines = FileLines(file)

      let t: Array[Array[U8] val] trn = recover trn Array[Array[U8] val] end
      var cnt: USize = 0
      for line' in lines do
        let a: Array[U8] trn = recover trn Array[U8] end
        for p in Range(0, line'.size()) do
          try a.push(line'(p)? - '0') else Debug.out("oof") end
          let str: String val = cnt.string() + ":" + p.string()
          try
            let l: Location = Location(str, line'.size(), line'(p)? - '0', locationmap)
            l.row = cnt
            l.col = p
            locationmap.insert(str, l)
          else
            Debug.out("Critical Error")
          end
        end
        t.push(consume a)
        cnt = cnt + 1
      end
      score = consume t
    else
      stdout.print("Error opening file '" + filename + "'")
    end

    try
      max_row = score.size()
      max_col = score(0)?.size()
    else
      None
    end
    stdout.print("Total# Locations: " + locationmap.size().string() + ":" +
                 max_row.string() + "x" + max_col.string())

    try
      todo.push(locationmap("0:0")?)
    else
      Debug.out("Can't prime")
    end

    while (todo.size() > 0) do
      try
        assess_local()?
      else
        Debug.out("ooof")
        break
      end
    end

  fun ref assess_local() ? =>
    let me: Location = todo.shift()?
    me.debug()

    try todo.push(me.get_north()?) end
    try todo.push(me.get_south()?) end
    try todo.push(me.get_east()?) end
    try todo.push(me.get_west()?) end


class Location
  var row: USize = 0
  var col: USize = 0
  var string: String val
  var max_row: USize = 0
  var locationmap: Map[String, Location]

  var paths: MapIs[FromDirection, (Illegal | USize)] = MapIs[FromDirection, (Illegal | USize)]

  new create(string': String val, row_max: USize, temp: U8, locationmap': Map[String, Location]) =>
    string = string'
    paths.insert(FromSelf, temp.usize())
    max_row = row_max
    locationmap = locationmap'

  fun ref get_north(): Location ? =>
    let n: Location = locationmap((row - 1).string() + ":" + col.string())?
    if (not n.paths.contains(FromSouth)) then
      n.paths.insert(FromSouth, 0)
    else error end
    n
  fun ref get_south(): Location ? =>
    let s: Location = locationmap((row + 1).string() + ":" + col.string())?
    if (not s.paths.contains(FromNorth)) then
      s.paths.insert(FromNorth, 0)
    else error end
    s
  fun ref get_east(): Location ? =>
    let e: Location = locationmap(row.string() + ":" + (col + 1).string())?
    if (not e.paths.contains(FromWest)) then
      e.paths.insert(FromWest, 0)
    else error end
    e
  fun ref get_west(): Location ? =>
    let w: Location = locationmap(row.string() + ":" + (col - 1).string())?
    if (not w.paths.contains(FromEast)) then
      w.paths.insert(FromEast, 0)
    else error end
    w

  fun debug() =>
    Debug.out("(" + row.string() + "," + col.string() + "): " +
              if (paths.contains(FromSelf)) then "X" else "x" end +
              if (paths.contains(FromNorth)) then "N" else "n" end +
              if (paths.contains(FromSouth)) then "S" else "s" end +
              if (paths.contains(FromEast)) then "E" else "e" end +
              if (paths.contains(FromWest)) then "W" else "w" end)

primitive Illegal fun string(): String => "Illegal"

primitive FromSelf
primitive FromNorth
primitive FromSouth
primitive FromEast
primitive FromWest
type FromDirection is (FromNorth | FromSouth | FromEast | FromWest | FromSelf)
