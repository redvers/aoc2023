use "files"
use "debug"
use "crypto"
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

  var dish: Array[String ref] = Array[String ref]
  var disht: Array[String ref] = Array[String ref]

  var cnt: USize = 1
  var hh: Array[U8] val = recover val Array[U8] end

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
        var s: String ref = consume line'
        dish.push(s.clone())
        disht.push(s.clone())
      end
    else
      stdout.print("Error opening file '" + filename + "'")
    end
    display_dish()
    try
      slide_north()?
    else
      Debug("Can't slide north")
    end

    while (cnt < 10000) do
      run_loop()
      cnt = cnt + 1
    end

  be run_loop() =>
    try
      var digest: Digest = Digest.md5()
      cycle()
      for f in dish.values() do
        digest.append(f.clone())?
      end
      hh = digest.final()
      Debug.out(ToHexString(hh))
      score_dish()
    else
      Debug.out("Digesting failed")
    end


  fun ref cycle() =>
    try
      slide_north()?
      rotate_right()
      slide_north()?
      rotate_right()
      slide_north()?
      rotate_right()
      slide_north()?
      rotate_right()
    else
      Debug.out("Boom")
    end

  fun ref rotate_right() =>
    for (row, cols) in dish.pairs() do
      for col in Range(0, cols.size()) do
        try
          disht(col)?.update((disht(col)?.size() - 1) - row, cols(col)?)?
        else
          Debug.out("Could not rotate")
        end
      end
    end
    disht = dish = disht

  fun score_dish() =>
    var score: USize = 0
    for (row, cols) in dish.pairs() do
      for col in cols.values() do
        if (col == 'O') then
          score = (score + dish.size()) - row 
        end
      end
    end
    Debug.out(cnt.string() + " -> " + score.string())


  fun ref slide_north() ? =>
    var any_changes: Bool = false
    for row in Range(1, dish.size()) do
      for col in Range(0, dish(row)?.size()) do
        if (dish(row)?(col)? == 'O') then
          // Check North
          if (dish(row - 1)?(col)? == '.') then
            // Roll with it.
            dish(row)?.update(col, '.')?
            dish(row - 1)?.update(col, 'O')?
            any_changes = true
          end
        end
      end
    end
    if (any_changes) then
      slide_north()?
    end








  fun display_dish() =>
    for line in dish.values() do
      Debug.out(line.clone())
    end

/*
96061 -- Boogie (rem 6)
96064
96063
96064
96077
96079
96078
*/
