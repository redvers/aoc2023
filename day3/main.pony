use "files"
use "regex"
use "debug"
use "collections"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    for filename in env.args.slice(1).values() do
      let fn: FileRunner = FileRunner(env.out, FileAuth(env.root), filename)
      fn.parse_board()
		end


actor FileRunner
  let stdout: OutStream tag
  let fileauth: FileAuth val
  let filename: String val

  let board: Board = Board
  let schematics: Array[SchematicNumber] = Array[SchematicNumber]

  var sum: USize = 0
  var gearsum: USize = 0

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

  be parse_board() =>
    let path = FilePath(fileauth, filename)

    match OpenFile(path)
    | let file: File =>
      let lines: FileLines = FileLines(file)

      let rvl: Array[String val] trn = recover trn Array[String val] end
      for line in lines do
        rvl.push(consume line)
      end
      board.board = consume rvl
    else
      stdout.print("Error opening file '" + filename + "'")
    end

    try
      var cnt: USize = 0
      while (cnt < board.board.size()) do
        for sn in (board.find_numbers_in_line(cnt)?).values() do
          schematics.push(sn)
        end
        cnt = cnt + 1
      end
    else
    Debug.out("I failed on a find_number")
    end

    for sn in schematics.values() do
      if (sn.check_part()) then
        Debug.out("Detected: " + sn.number.string())
        sum = sum + sn.number
      end
    end

    Debug.out("Looking for gears")
    for sn in schematics.values() do
      Debug.out(sn.number.string())
      let gears: Array[(USize, USize)] = sn.whereis_gear()
      for (a, b) in gears.values() do
        let coord: String val = "(" + a.string() + "," + b.string() + ")"
        let sa: Array[SchematicNumber] = board.gears.get_or_else(coord, Array[SchematicNumber])
        sa.push(sn)
        board.gears.insert_if_absent(coord, sa)
      end
    end

    Debug.out("Checking Gears")
    for (coord, gears) in board.gears.pairs() do
      Debug.out(coord + " count: " + gears.size().string())
      if (gears.size() == 2) then
        let m: USize =
        try
          (gears(0)?.number * gears(1)?.number)
        else
          0
        end
        gearsum = gearsum + m
      end
          
    end

    stdout.print(filename + " Total: " + sum.string())
    stdout.print(filename + " Gearsum: " + gearsum.string())

class Board
  var board: Array[String val] val = recover val Array[String val] end
  var gears: Map[String val, Array[SchematicNumber]] = Map[String val, Array[SchematicNumber]]

  fun ref find_numbers_in_line(lineno: USize): Array[SchematicNumber] ? =>
    let line_in: String val = board(lineno)?
    Debug.out("Line: " + line_in)

    let rv: Array[SchematicNumber] = []

    for rmatch in MatchIterator(Regex("(\\d+)")?, line_in) do
      let sn: SchematicNumber = SchematicNumber
      sn.number = rmatch(0)?.usize()?
      sn.lineno = lineno
      sn.startp = rmatch.start_pos()
      sn.endpos = rmatch.end_pos()
      sn.board = board

      rv.push(sn)
    end
    rv


class SchematicNumber
  var number: USize = 0
  var lineno: USize = 0
  var startp: USize = 0
  var endpos: USize = 0

  var board: Array[String val] val = recover val Array[String val] end

  fun debug(): String val =>
    "At (" + lineno.string() + "," + startp.string() + " -> " + endpos.string() + "): " + number.string() + "\n" + above_string() + "\n" +
    middle_string() + "\n" +
    below_string() + "\n"
    

  fun above_string(): String val =>
    if (lineno == 0) then
      return "" // There is nothing above me
    end
    let lpos: USize =
      if (startp == 0) then
        0
      else
        startp - 1
      end
    try
      board(lineno - 1)?.substring(lpos.isize(), endpos.isize() + 2)
    else
      ""
    end

  fun below_string(): String val =>
    if (lineno > board.size()) then
      return "" // There is nothing below me
    end
    let lpos: USize =
      if (startp == 0) then
        0
      else
        startp - 1
      end
    try
      board(lineno + 1)?.substring(lpos.isize(), endpos.isize() + 2)
    else
      ""
    end
    
  fun middle_string(): String val =>
    let lpos: USize =
      if (startp == 0) then
        0
      else
        startp - 1
      end
    try
      board(lineno)?.substring(lpos.isize(), endpos.isize() + 2)
    else
      ""
    end

  fun check_part(): Bool =>
    try
      let tbool: Bool = matches_line(above_string())?
      let mbool: Bool = matches_line(middle_string())?
      let bbool: Bool = matches_line(below_string())?

      if (tbool or mbool or bbool) then
        return true
      else
        return false
      end
    else
      Debug.out("I failed a regex yo!")
    end
    false

  fun matches_line(line: String val): Bool ? =>
    if (Regex("#")? == line) then return true end
    if (Regex("%")? == line) then return true end
    if (Regex("&")? == line) then return true end
    if (Regex("\\*")? == line) then return true end
    if (Regex("\\+")? == line) then return true end
    if (Regex("-")? == line) then return true end
    if (Regex("/")? == line) then return true end
    if (Regex("=")? == line) then return true end
    if (Regex("@")? == line) then return true end
    if (Regex("\\$")? == line) then return true end
    false

  fun matches_gear(line: String val): Array[USize] =>
    let rv: Array[USize] = []
    try
      for f in MatchIterator(Regex("(\\*)")?, line) do
        rv.push(f.start_pos())
      end
    end
    rv
    
  fun whereis_gear(): Array[(USize, USize)] =>
    let gears: Array[(USize, USize)] = []
    let a: Array[USize] = matches_gear(above_string())
    let b: Array[USize] = matches_gear(middle_string())
    let c: Array[USize] = matches_gear(below_string())

    for aa in a.values() do
      if (startp == 0) then
        gears.push((lineno - 1, startp + aa + 1))
      else
        gears.push((lineno - 1, startp + aa))
      end
    end
    for bb in b.values() do
      if (startp == 0) then
        gears.push((lineno   , startp + bb + 1))
      else
        gears.push((lineno   , startp + bb))
      end
    end
    for cc in c.values() do
      if (startp == 0) then
        gears.push((lineno + 1, startp + cc + 1))
      else
        gears.push((lineno + 1, startp + cc))
      end
    end
    gears

