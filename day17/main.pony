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
          let l: Location = Location(str)
          l.row = cnt
          l.col = p
          locationmap.insert(str, l)
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
    if (me.calculated) then
      return
    end
    me.calculated = true

    if (me.string == "0:0") then
      try me.cheapest = score(0)?(0)?.usize() end
      me.path.push('X')
      todo.push(locationmap("0:1")?)
      todo.push(locationmap("1:0")?)
    end
    me.debug()


    // Look Up
    if (me.row == 0) then
      None
    else
      let up: Location = locationmap((me.row - 1).string() + ":" + me.col.string())?
      if (me.path.at("X") and (me.path.substring((me.path.size() - 2).isize()).clone() != "UU")) then
        if ((me.cheapest + score(up.row)?(up.col)?.usize()) < up.cheapest) then
          up.path = me.path + "U"
          up.cheapest = me.cheapest + score(up.row)?(up.col)?.usize()
        end
      end
      todo.push(up)
    end

    // Look Down
    if (me.row == (max_row - 1)) then
      None
    else
      let down: Location = locationmap((me.row + 1).string() + ":" + me.col.string())?
      if (me.path.at("X") and (me.path.substring((me.path.size() - 2).isize()).clone() != "DD")) then
        if ((me.cheapest + score(down.row)?(down.col)?.usize()) < down.cheapest) then
          down.path = me.path + "D"
          down.cheapest = me.cheapest + score(down.row)?(down.col)?.usize()
        end
      end
      todo.push(down)
    end

    // Look Left
    if (me.col == 0) then
      None
    else
      let left: Location = locationmap(me.row.string() + ":" + (me.col - 1).string())?
      if (me.path.at("X") and (me.path.substring((me.path.size() - 2).isize()).clone() != "LL")) then
        if ((me.cheapest + score(left.row)?(left.col)?.usize()) < left.cheapest) then
          left.path = me.path + "L"
          left.cheapest = me.cheapest + score(left.row)?(left.col)?.usize()
        end
      end
      todo.push(left)
    end

    // Look Right
    if (me.col == (max_col - 1)) then
      None
    else
      let right: Location = locationmap(me.row.string() + ":" + (me.col + 1).string())?
      if (me.path.at("X") and (me.path.substring((me.path.size() - 2).isize()).clone() != "RR")) then
        if ((me.cheapest + score(right.row)?(right.col)?.usize()) < right.cheapest) then
          right.path = me.path + "R"
          right.cheapest = me.cheapest + score(right.row)?(right.col)?.usize()
        end
      end
      todo.push(right)
    end




class Location
  var row: USize = 0
  var col: USize = 0
  var cheapest: USize = -1
  var calculated: Bool = false
  var path: String ref = recover ref String end
  var string: String val

  new create(string': String val) =>
    string = string'

  fun debug() =>
    Debug.out("(" + row.string() + "," + col.string() + "): " + path + " " + cheapest.string())
