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
  var galaxies: Map[USize, Set[USize]] = Map[USize, Set[USize]]
  var expand_row: Set[USize] = Set[USize]
  var expand_col: Set[USize] = Set[USize]

  var row_max: USize = 0
  var col_max: USize = 0

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

    row_max = board.size()
    col_max = try board(0)?.size() else 0 end
    display_board_a()
    locate_galaxies_a()
    Debug.out("")
    display_board_b(galaxies)
    expand_universe_b(999999)
    display_board_b(galaxies)

    measure_galaxies()


  fun ref expand_universe_b(expand_size: USize = 1) =>
    let newgalaxy: Map[USize, Set[USize]] = Map[USize, Set[USize]]
    for f in Range(0, row_max) do
      if (not galaxies.contains(f)) then
        expand_row.set(f)
      end
    end

    for f in Range(0, col_max) do
      expand_col.set(f)
    end

    for f in galaxies.values() do
      for g in f.values() do
        expand_col.unset(g)
      end
    end
    Debug.out(expand_row.size().string() + " rows remaining")
    Debug.out(expand_col.size().string() + " columns remaining")


    for (row, colset) in galaxies.pairs() do
      let newset: Set[USize] = Set[USize]
      for col in colset.values() do
        newset.set(increment_col(col, expand_size))
      end

      newgalaxy.insert(increment_row(row, expand_size), newset)
    end

    galaxies = newgalaxy
    row_max = row_max + expand_row.size()
    col_max = col_max + expand_col.size()

  fun increment_col(col': USize, expand_size': USize): USize =>
    var inc: USize = 0
    for ecol in expand_col.values() do
      if (col' > ecol) then
        inc = inc + expand_size'
      end
    end
    col' + inc
    
  fun increment_row(row': USize, expand_size': USize): USize =>
    var inc: USize = 0
    for erow in expand_row.values() do
      if (row' > erow) then
        inc = inc + expand_size'
      end
    end
    row' + inc

  fun ref display_board_b(galaxies': Map[USize, Set[USize]]) =>
    for row in Range(0, row_max) do
      let rv: String trn = recover trn String end
      let galcols: Set[USize] = galaxies'.get_or_else(row, Set[USize])
      for col in Range(0, col_max) do
        if (galcols.contains(col)) then
          rv.push('#')
        else
          rv.push('.')
        end
      end
      Debug.out(consume rv)
    end

  fun ref locate_galaxies_a() =>
    for (line, str) in board.pairs() do
      let cols: Set[USize] = Set[USize]
      try
        var has_galaxy: Bool = false
        for g in MatchIterator(Regex("#")?, str) do
          has_galaxy = true
          cols.set(g.start_pos())
        end
        if (has_galaxy) then
          galaxies.insert(line, cols)
        end
      else
        Debug.out("Regex failed")
      end
    end
    

  fun display_board_a() =>
    for line in board.values() do
      Debug.out(consume line)
    end


  be measure_galaxies() =>
    var local_galaxies: Array[(USize, USize)] = Array[(USize, USize)]

    for (row, colset) in galaxies.pairs() do
      for col in colset.values() do
        local_galaxies.push((row, col))
      end
    end


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
