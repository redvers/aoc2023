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
      let fn: FileRunner = FileRunner(env.out, FileAuth(env.root), filename)
      fn.parse_file()
		end


actor FileRunner
  let stdout: OutStream tag
  let fileauth: FileAuth val
  let filename: String val

  let board: Array[String val] ref = recover ref Array[String val] end
  let score: Array[Array[USize]] ref = recover ref Array[Array[USize]] end
  var sl: USize = 0   // Line for S
  var sc: USize = 0   // Column for S
  var colcnt: USize = 0

  var rabbits: Array[(USize, USize)] = Array[(USize, USize)]
  var potato_counter: USize = 1

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

  be parse_file() =>
    let path = FilePath(fileauth, filename)

    match OpenFile(path)
    | let file: File =>
      let lines: FileLines = FileLines(file)

      for line' in lines do
        var line: String val = consume line'
        board.push(line)
        score.push(Array[USize].init(0, line.size()))
        if (line.contains("S")) then
          sl = colcnt
          try
            sc = line.find("S")?.usize()
          end
        end
        colcnt = colcnt + 1
      end
    else
      stdout.print("Error opening file '" + filename + "'")
    end
    Debug.out("Location: " + sl.string() + ", " + sc.string())
    navigate_maze()

  be navigate_maze() => None
    /*
    | is a vertical pipe connecting north and south.
    - is a horizontal pipe connecting east and west.
    L is a 90-degree bend connecting north and east.
    J is a 90-degree bend connecting north and west.
    7 is a 90-degree bend connecting south and west.
    F is a 90-degree bend connecting south and east.
    . is ground; there is no pipe in this tile.
    S is the starting position of the animal; there is a pipe on this tile, but your sketch doesn't show what shape the pipe has.

..F7.
.FJ|.
SJ.L7
|F--J
LJ...
    */
    let scorecount: USize = 0
    var potatoes: Array[(USize, USize)] = Array[(USize, USize)]
    potatoes.push((sl, sc))

    let newpotatoes: Array[(USize, USize)] = Array[(USize, USize)]
    while (true) do
      for potato in potatoes.values() do
        try
          let s: Array[(USize, USize)] = find_connectors(potato._1, potato._2)?
          for t in s.values() do
            newpotatoes.push(t)
            Debug.out("Potato at: " + t._1.string() + ", " + t._2.string())
          end
        else
          @printf("Potato Fail\n".cstring())
          @exit(-1)
        end
      end
      Debug.out("Newpotatocount: " + newpotatoes.size().string())
      if (newpotatoes.size() == 0) then
        break
      end
      potatoes.clear()
      for f in newpotatoes.values() do
        potatoes.push(f)
      end
      newpotatoes.clear()
      potato_counter = potato_counter + 1
//      execcnt = execcnt - 1
    end
    Debug.out("MaxDist: " + (potato_counter - 1).string())


  fun ref find_connectors(rl: USize, rc: USize): Array[(USize, USize)] ? =>
    let rv: Array[(USize, USize)] = Array[(USize, USize)]
    match board(rl)?(rc)?
    | let t: U8 if (t == NoPipe()) => error
    | let t: U8 if (t == ThePotato()) =>
        if (check_north(rl, rc)) then rv.push((rl - 1, rc    )) end
        if (check_south(rl, rc)) then rv.push((rl + 1, rc    )) end
        if (check_east(rl, rc))  then rv.push((rl    , rc + 1)) end
        if (check_west(rl, rc))  then rv.push((rl    , rc - 1)) end
    | let t: U8 if (t == NorthSouth()) =>
        if (check_north(rl, rc)) then rv.push((rl - 1, rc    )) end
        if (check_south(rl, rc)) then rv.push((rl + 1, rc    )) end
    | let t: U8 if (t == EastWest()) =>
        if (check_east(rl, rc))  then rv.push((rl    , rc + 1)) end
        if (check_west(rl, rc))  then rv.push((rl    , rc - 1)) end
    | let t: U8 if (t == NorthEast()) =>
        if (check_north(rl, rc)) then rv.push((rl - 1, rc    )) end
        if (check_east(rl, rc))  then rv.push((rl    , rc + 1)) end
    | let t: U8 if (t == NorthWest()) =>
        if (check_north(rl, rc)) then rv.push((rl - 1, rc    )) end
        if (check_west(rl, rc))  then rv.push((rl    , rc - 1)) end
    | let t: U8 if (t == SouthEast()) =>
        if (check_south(rl, rc)) then rv.push((rl + 1, rc    )) end
        if (check_east(rl, rc))  then rv.push((rl    , rc + 1)) end
    | let t: U8 if (t == SouthWest()) =>
        if (check_south(rl, rc)) then rv.push((rl + 1, rc    )) end
        if (check_west(rl, rc))  then rv.push((rl    , rc - 1)) end
    end
    rv



  fun ref check_north(rl: USize, rc: USize): Bool =>
    try
      if (score(rl - 1)?(rc)? == 0) then
        if ((board(rl - 1)?(rc)? == NorthSouth()) or
            (board(rl - 1)?(rc)? == SouthWest()) or
            (board(rl - 1)?(rc)? == SouthEast())) then
            score(rl - 1)?.update(rc, potato_counter)?
          return true
        else
          return false
        end
      end
    else
      false
    end
    false

  fun ref check_south(rl: USize, rc: USize): Bool =>
    try
      if (score(rl + 1)?(rc)? == 0) then
        if ((board(rl + 1)?(rc)? == NorthSouth()) or
            (board(rl + 1)?(rc)? == NorthWest()) or
            (board(rl + 1)?(rc)? == NorthEast())) then
            score(rl + 1)?.update(rc, potato_counter)?
          return true
        else
          return false
        end
      end
    else
      false
    end
    false

  fun ref check_east(rl: USize, rc: USize): Bool =>
    try
      if (score(rl)?(rc + 1)? == 0) then
        if ((board(rl)?(rc + 1)? == NorthWest()) or
            (board(rl)?(rc + 1)? == SouthWest()) or
            (board(rl)?(rc + 1)? == EastWest())) then
            score(rl)?.update(rc + 1, potato_counter)?
          return true
        else
          return false
        end
      end
    else
      false
    end
    false

  fun ref check_west(rl: USize, rc: USize): Bool =>
    try
      if (score(rl)?(rc - 1)? == 0) then
        if ((board(rl)?(rc - 1)? == NorthEast()) or
            (board(rl)?(rc - 1)? == SouthEast()) or
            (board(rl)?(rc - 1)? == EastWest())) then
            score(rl)?.update(rc - 1, potato_counter)?
          return true
        else
          return false
        end
      end
    else
      false
    end
    false


primitive NorthSouth fun apply(): U8 => '|'
primitive EastWest   fun apply(): U8 => '-'
primitive NorthEast  fun apply(): U8 => 'L'
primitive NorthWest  fun apply(): U8 => 'J'
primitive SouthWest  fun apply(): U8 => '7'
primitive SouthEast  fun apply(): U8 => 'F'
primitive ThePotato  fun apply(): U8 => 'S'
primitive NoPipe     fun apply(): U8 => '.'




