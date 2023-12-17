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

  let board: Array[String val] = Array[String val]
  var score: Array[Array[USize]] = Array[Array[USize]]
  var row_max: USize = 0
  var col_max: USize = 0

  var beams: SetIs[Beam] = SetIs[Beam]
  var loopdetect: Array[Array[U8]] = Array[Array[U8]]

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
        var scoreline: Array[USize] = Array[USize].init(0, line'.size())
        var loopdline: Array[U8] = Array[U8].init(0, line'.size())
        score.push(scoreline)
        loopdetect.push(loopdline)
        board.push(consume line')
      end
    else
      stdout.print("Error opening file '" + filename + "'")
    end

    try
      row_max = board.size()
      col_max = board(0)?.size()
    else
      Debug.out("I have no board data")
    end

    beams.set(Beam) // Our initial beam, from 0,0 - heading Right

    while (beams.size() > 0) do
      Debug.out("")
      
      for beam in beams.values() do
        tick(beam)
      end
      display_board_score()
      Debug.out("Beam Count: " + beams.size().string() + ", Score: " + score_board().string())
    end


  fun ref tick(beam: Beam) =>
    if ((beam.row == -1) or (beam.row == row_max) or
        (beam.col == -1) or (beam.col == col_max)) then
      beams.unset(beam)
      Debug("beam deleted")
      return
    end
    //Array[Array[USize]] = Array[Array[USize]]

    try
      if ((loopdetect(beam.row)?(beam.col)? and beam.direction.enum()) > 0) then beams.unset(beam) ; Debug.out("loop removed") end
    end


    try
      score(beam.row)?.update(beam.col, score(beam.row)?(beam.col)? + 1)?
      loopdetect(beam.row)?.update(beam.col, 
        loopdetect(beam.row)?(beam.col)? or beam.direction.enum()
      )?
    else
      Debug.out("I should never happen")
    end
    match beam.direction
    | let d: Up => move_up(beam)
    | let d: Down => move_down(beam)
    | let d: Left => move_left(beam)
    | let d: Right => move_right(beam)
    end

  fun ref move_right(beam: Beam) => None
    Debug.out("R(" + beam.row.string() + "," + beam.col.string() + ")")
    try
      match board(beam.row)?(beam.col)?
      | let t: U8 if (t == '.') => beam.col = beam.col + 1
      | let t: U8 if (t == '-') => beam.col = beam.col + 1
      | let t: U8 if (t == '\\') => beam.row = beam.row + 1 ; beam.direction = Down
      | let t: U8 if (t == '/') => beam.row = beam.row - 1 ; beam.direction = Up
      | let t: U8 if (t == '|') =>
        let bup: Beam = Beam
        bup.direction = Up
        bup.row = beam.row - 1
        bup.col = beam.col

        let bdown: Beam = Beam
        bdown.direction = Down
        bdown.row = beam.row + 1
        bdown.col = beam.col

        beams.set(bup)
        beams.set(bdown)

        beams.unset(beam)
      end
    else
      Debug.out("I ran off the board(R)")
      beams.unset(beam)
      Debug("beam deleted")
    end
    
  fun ref move_left(beam: Beam) => None
    Debug.out("L(" + beam.row.string() + "," + beam.col.string() + ")")
    try
      match board(beam.row)?(beam.col)?
      | let t: U8 if (t == '.') => beam.col = beam.col - 1
      | let t: U8 if (t == '-') => beam.col = beam.col - 1
      | let t: U8 if (t == '\\') => beam.row = beam.row - 1 ; beam.direction = Up
      | let t: U8 if (t == '/') => beam.row = beam.row + 1 ; beam.direction = Down
      | let t: U8 if (t == '|') =>
        let bup: Beam = Beam
        bup.direction = Up
        bup.row = beam.row - 1
        bup.col = beam.col

        let bdown: Beam = Beam
        bdown.direction = Down
        bdown.row = beam.row + 1
        bdown.col = beam.col

        beams.set(bup)
        beams.set(bdown)

        beams.unset(beam)
      end
    else
      Debug.out("I ran off the board(L)")
      beams.unset(beam)
      Debug("beam deleted")
    end

  fun ref move_down(beam: Beam) => None
    Debug.out("D(" + beam.row.string() + "," + beam.col.string() + ")")
    try
      match board(beam.row)?(beam.col)?
      | let t: U8 if (t == '.') => beam.row = beam.row + 1
      | let t: U8 if (t == '|') => beam.row = beam.row + 1
      | let t: U8 if (t == '\\') => beam.col = beam.col + 1 ; beam.direction = Right
      | let t: U8 if (t == '/') =>  beam.col = beam.col - 1 ; beam.direction = Left
      | let t: U8 if (t == '-') =>
        let bleft: Beam = Beam
        bleft.direction = Left
        bleft.row = beam.row
        bleft.col = beam.col - 1

        let bright: Beam = Beam
        bright.direction = Right
        bright.row = beam.row
        bright.col = beam.col + 1

        beams.set(bleft)
        beams.set(bright)

        beams.unset(beam)
      end
    else
      Debug.out("I ran off the board(D)")
      beams.unset(beam)
      Debug("beam deleted")
    end

  fun display_board_score() =>
    var rvline: String ref = recover ref String end
    var dirn: String ref = recover ref String end
    for (row, line) in score.pairs() do
      var rvline2: String ref = ".".mul(col_max)
      for char in line.values() do
        if (char > 0) then
          rvline.push('#')// + char.u8())
        else
          rvline.push('.')
        end
      end
      try
        for e in loopdetect(row)?.values() do
          dirn.push(if ((e and Up.enum())    > 0) then 'U' else '.' end)
          dirn.push(if ((e and Down.enum())  > 0) then 'D' else '.' end)
          dirn.push(if ((e and Left.enum())  > 0) then 'L' else '.' end)
          dirn.push(if ((e and Right.enum()) > 0) then 'R' else '.' end)
        end
      end

      for beam in beams.values() do
        if (beam.row == row) then
          try
            rvline2.update(beam.col, beam.direction.u8())?
          else
            None
          end
        end
      end
      Debug.out(rvline.clone() + "  " +
                rvline2.clone() + "  " +
                try board(row)? else "" end + "  " +
                dirn.clone())
      rvline.clear()
      dirn.clear()
    end

  fun score_board(): USize =>
    var s: USize = 0
    for line in score.values() do
      for char in line.values() do
        if (char > 0) then
          s = s + 1
        end
      end
    end
    s

  

  fun ref move_up(beam: Beam) => None
    Debug.out("U(" + beam.row.string() + "," + beam.col.string() + ")")
    try
      match board(beam.row)?(beam.col)?
      | let t: U8 if (t == '.') => beam.row = beam.row - 1
      | let t: U8 if (t == '|') => beam.row = beam.row - 1
      | let t: U8 if (t == '\\') => beam.col = beam.col - 1 ; beam.direction = Left
      | let t: U8 if (t == '/') => beam.col = beam.col + 1 ; beam.direction = Right
      | let t: U8 if (t == '-') =>
        let bleft: Beam = Beam
        bleft.direction = Left
        bleft.row = beam.row
        bleft.col = beam.col - 1

        let bright: Beam = Beam
        bright.direction = Right
        bright.row = beam.row
        bright.col = beam.col + 1

        beams.set(bleft)
        beams.set(bright)

        beams.unset(beam)
      end
    else
      Debug.out("I ran off the board(U)")
      beams.unset(beam)
    end


class Beam
  var row: USize = 0
  var col: USize = 0

  var direction: Direction = Right

primitive Up
  fun u8(): U8 => '^'
  fun enum(): U8 => 0b0001

primitive Down
  fun u8(): U8 => 'v'
  fun enum(): U8 => 0b0010

primitive Left
  fun u8(): U8 => '<'
  fun enum(): U8 => 0b0100

primitive Right
  fun u8(): U8 => '>'
  fun enum(): U8 => 0b1000

type Direction is (Up | Down | Left | Right)
  






