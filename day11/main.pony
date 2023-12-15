use "files"
use "debug"
use "regex"
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

  var board: Array[String val] ref = recover ref Array[String val] end
  var colcnt: USize = 0
  let galaxies: Array[(USize, USize)] = Array[(USize, USize)]

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
        colcnt = colcnt + 1
      end
    else
      stdout.print("Error opening file '" + filename + "'")
    end
    display_board()
    expand_universe()
    Debug.out("")
    display_board()
    locate_galaxies()
    measure_galaxies()

  be measure_galaxies() =>
    var local_galaxies: Array[(USize, USize)] = galaxies.clone()
    var from: USize = 0
    var cnt: USize = 0

    while (from < (local_galaxies.size() - 1)) do
      for ptr in Range[USize](from + 1, local_galaxies.size()) do
        try 
         let dist: USize = (
         ((local_galaxies(from)?._1).isize() - (local_galaxies(ptr)?._1).isize()).abs() +
         ((local_galaxies(from)?._2).isize() - (local_galaxies(ptr)?._2).isize()).abs()
         ).usize()
          Debug.out((from + 1).string() + "->" + (ptr + 1).string() + ": (" +
                    local_galaxies(from)?._1.string() + "," +
                    local_galaxies(from)?._2.string() + ") -> (" + 
                    local_galaxies(ptr)?._1.string() + "," +
                    local_galaxies(ptr)?._2.string() + ") = " + dist.string())
         cnt = cnt + dist
        else
          @printf("I have a count error here\n".cstring())
          @exit(-1)
          break
        end
      end
      from = from + 1
    end
    Debug.out("Total: " + cnt.string())

  fun ref expand_universe() =>
    var rv: Array[String] = Array[String]
    for line in board.values() do
      rv.push(line)
      if (not line.contains("#")) then
        rv.push(line)
      end
    end

    let expanding: Array[USize] = Array[USize]

    try
      let initsize: USize = rv(0)?.size()
      for col in Range(0, (rv(0)?.size())) do
        var bool: Bool = true
        for row in Range(0, rv.size()) do
          try
            if (rv(row)?(col)? == '#') then
              bool = false
            end
          else
            Debug.out("Off By One")
          end
        end
        if (bool) then
          expanding.push(col) // To expand
        end
      end
    else
      Debug.out("Off by one (different)")
    end

    for row in Range(0, rv.size()) do
      try
        let str: String trn = rv(row)?.clone()
        for col in expanding.reverse().values() do
          str.insert_in_place(col.isize(), ",")
        end
        rv.update(row, consume str)?
      else
        Debug.out("Update issues")
      end
    end




    board = rv

  fun ref locate_galaxies() =>
    for (line, str) in board.pairs() do
      try
        for g in MatchIterator(Regex("#")?, str) do
          galaxies.push((line,g.start_pos()))
        end
      else
        Debug.out("Regex failed")
      end
    end
    

  fun display_board() =>
    for line in board.values() do
      Debug.out(consume line)
    end
