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
      fn.parse_file()
		end


actor FileRunner
  let stdout: OutStream tag
  let fileauth: FileAuth val
  let filename: String val

  let seeds: Array[USize] = Array[USize]
  let maps: MapIs[ParseState, Array[Mapper]] = MapIs[ParseState, Array[Mapper]]

  var state: ParseState = Seeds

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

    maps.insert(Seeds, Array[Mapper])
    maps.insert(Seed2Soil, Array[Mapper])
    maps.insert(Soil2Fertilizer, Array[Mapper])
    maps.insert(Fertilizer2Water, Array[Mapper])
    maps.insert(Water2Light, Array[Mapper])
    maps.insert(Light2Temperature, Array[Mapper])
    maps.insert(Temperature2Humidity, Array[Mapper])
    maps.insert(Humidity2Location, Array[Mapper])

  be parse_file() =>
    let path = FilePath(fileauth, filename)

    match OpenFile(path)
    | let file: File =>
      let lines: FileLines = FileLines(file)

      for line in lines do
        parse_line(consume line)
      end
      report_map_sizes()
      recurse_seeds()
    else
      stdout.print("Error opening file '" + filename + "'")
    end

  be parse_line(line: String val) => None
    match state
    | let t: Seeds => parse_seeds(line)
    else
      parse_table(line)
    end

  fun ref parse_seeds(line: String val) =>
    if (line == "") then
      Debug.out("Seeds -> Seed2Soil")
      state = Seed2Soil
    else
      Debug.out("Seeds: " + line)
      try
        for rmatch in MatchIterator(Regex("(\\d+)")?, line) do
          let v: USize = rmatch(1)?.usize()?
          Debug.out("Parsed seed#: " + v.string())
          seeds.push(v)
        end
      end
    end

  fun ref parse_table(line: String val) =>
    if (line == "") then
      Debug.out("Transition out of " + state.string())
      state = nextState(state)
      Debug.out("... and into " + state.string())
    else
      try
        if (Regex(".*map:$")? == line) then
          return
        end
        let rmatch: Match = Regex("^(\\d+)\\s+(\\d+)\\s+(\\d+)")?(line)?
        let v: Mapper = Mapper
        v.mytype = state
        v.starta = rmatch(1)?.usize()?
        v.startb = rmatch(2)?.usize()?
        v.length = rmatch(3)?.usize()?
        v.endb = (v.startb + v.length) - 1
        let mm: Array[Mapper] = maps(state)?
        mm.push(v)
        Debug.out(state.string() + ": " + line)
      else
        Debug.out("I failed to regex this line: " + line)
      end
    end

  fun nextState(tin: ParseState): ParseState =>
    match tin
    | let t: Seeds => Seed2Soil
    | let t: Seed2Soil => Soil2Fertilizer
    | let t: Soil2Fertilizer => Fertilizer2Water
    | let t: Fertilizer2Water => Water2Light
    | let t: Water2Light => Light2Temperature
    | let t: Light2Temperature => Temperature2Humidity
    | let t: Temperature2Humidity => Humidity2Location
    | let t: Humidity2Location => Humidity2Location
    end

  be report_map_sizes() =>
    for (t, a) in maps.pairs() do
      Debug.out(t.string() + ": " + a.size().string())
    end

  be recurse_seeds() =>
    var minval: USize = -1
    for seed in seeds.values() do
      let fval: USize = report_seed(seed)
      if (fval < minval) then minval = fval end
    end
    stdout.print("Closest Location A: " + minval.string())
    part2()

  be part2() =>
    let s: Array[USize] = seeds.clone()
    let rv: Array[(USize, USize)] = Array[(USize, USize)]
    try
      while (s.size() > 0) do
        var a: USize = s.shift()?
        var b: USize = s.shift()?
        let inb: USize = (a + b) - 1
        rv.push((a, inb))
      end
    end

    let soil: Array[(USize, USize)] = run_ranges(Seed2Soil, rv)
    show_ranges("Soil: ", soil)
    let fert: Array[(USize, USize)] = run_ranges(Soil2Fertilizer, soil)
    show_ranges("Fertilizer: ", fert)
    let water: Array[(USize, USize)] = run_ranges(Fertilizer2Water, fert)
    show_ranges("Water: ", water)
    let light: Array[(USize, USize)] = run_ranges(Water2Light, water)
    show_ranges("Light: ", light)
    let temp: Array[(USize, USize)] = run_ranges(Light2Temperature, light)
    show_ranges("Temp: ", temp)
    let humid: Array[(USize, USize)] = run_ranges(Temperature2Humidity, temp)
    show_ranges("Humid: ", humid)
    let locat: Array[(USize, USize)] = run_ranges(Humidity2Location, humid)
    show_ranges("Locations: ", locat)

    minimal_location(locat)

  fun ref minimal_location(locat: Array[(USize, USize)]) =>
    var min: USize = -1
    for f in locat.values() do
      if (f._1 < min) then min = f._1 end
    end
    stdout.print("Closest Location B: " + min.string())
      

  fun ref run_ranges(ps: ParseState, x: Array[(USize, USize)]): Array[(USize, USize)] =>
    var rv: Array[(USize, USize)] = Array[(USize, USize)]
    for f in x.values() do
      for g in report_range(ps, f._1, f._2).values() do
        rv.push(g)
      end
    end
    rv

    fun ref show_ranges(str: String val, ss: Array[(USize, USize)]) =>
      for f in ss.values() do
        Debug.out(str + "[" + f._1.string() + "->" + f._2.string() + "]")
      end

  
  fun ref report_range(ps: ParseState, a: USize, inb: USize): Array[(USize, USize)] =>
    Debug.out("report_range: " + a.string() + "->" + inb.string())
    let rv: Array[(USize, USize)] = Array[(USize, USize)]
    var lowerbound: USize = a
    var cleanup: Bool = true
    try
      let sortedmappers: Array[Mapper] = Sort[Array[Mapper], Mapper](maps(ps)?)
        for currentmapper in sortedmappers.values() do
          var clow: USize = 0
          var chigh: USize = 0

          /* Case 1: Both lower and upper bounds are less than our current
                     Mapper                                                */
          currentmapper.debug()
          if ((lowerbound < currentmapper.startb) and 
              (inb < currentmapper.startb)) then
                Debug.out("1:[Mapper:Direct]: InOutMap: " + lowerbound.string() +
                          "->" + inb.string())
                rv.push((lowerbound, inb))
          currentmapper.debug()
              cleanup = false
              break
          end

          /* Case 2: Range goes from under to inside the Mapper            */
          if ((lowerbound < currentmapper.startb) and
              (inb >= currentmapper.startb) and
              (inb <= currentmapper.endb)) then
                Debug.out("2[Mapper:Direct]: InOutMap: " + lowerbound.string() +
                          "->" + (currentmapper.startb -1).string())
                rv.push((lowerbound, (currentmapper.startb - 1)))
                rv.push(currentmapper.in_actual_range(currentmapper.startb, inb)?)
              cleanup = false
            break
          end

          /* Case 2.5: Range goes from under to over the Mapper            */
          if ((lowerbound < currentmapper.startb) and
              (inb >= currentmapper.startb) and
              (inb > currentmapper.endb)) then
                Debug.out("2.5[Mapper:Direct]: InOutMap: " + lowerbound.string() +
                          "->" + (currentmapper.startb -1).string())
                rv.push((lowerbound, currentmapper.startb - 1))
                rv.push(currentmapper.in_actual_range(currentmapper.startb, inb)?)
              lowerbound = currentmapper.endb + 1
              cleanup = true
              continue
          end
          
          /* Case 3: Range goes from inside to inside the Mapper           */
          if ((lowerbound >= currentmapper.startb) and
              (inb <= currentmapper.endb)) then
              Debug.out("3: " + lowerbound.string() + "->" + inb.string())
              rv.push(currentmapper.in_actual_range(lowerbound, inb)?)
              cleanup = false
              break
          end

          /* Case 4: Range goes from inside to above the Mapper           */
          if ((lowerbound >= currentmapper.startb) and
              (lowerbound <= currentmapper.endb) and
              (inb > currentmapper.endb)) then
              Debug.out("4: " + lowerbound.string() + "->" + inb.string())
              rv.push(currentmapper.in_actual_range(lowerbound, currentmapper.endb)?)
              lowerbound = currentmapper.endb + 1
              continue
          end

        end
      if (cleanup) then
        rv.push((lowerbound, inb))
        Debug.out("Cleanup: " + lowerbound.string() + "->" + inb.string())
      end
    else
      Debug.out("Something failed")
      rv
    end
    rv


  fun report_seed(seed: USize): USize =>
    let soil:  USize = apply_map(Seed2Soil, seed)
    let fert:  USize = apply_map(Soil2Fertilizer, soil)
    let water: USize = apply_map(Fertilizer2Water, fert)
    let light: USize = apply_map(Water2Light, water)
    let temp:  USize = apply_map(Light2Temperature, light)
    let humid: USize = apply_map(Temperature2Humidity, temp)
    let locat: USize = apply_map(Humidity2Location, humid)

    Debug.out("Seed: " + seed.string() + 
            ", Soil: " + soil.string() +
            ", Fert: " + fert.string() +
            ", Water: " + water.string() +
            ", Light: " + light.string() +
            ", Temp: " + temp.string() +
            ", Humid: " + humid.string() +
            ", Location: " + locat.string())

    locat

  fun apply_map(maptype: ParseState, seed: USize): USize =>
    var rv: USize = seed
    try
      for mapp in maps(maptype)?.values() do
        if (mapp.in_range(seed)) then
          rv = mapp(seed)?
          break
        end
      end
    end
    rv



type ParseState is (Seeds | Seed2Soil | Soil2Fertilizer | Fertilizer2Water |
                    Water2Light | Light2Temperature | Temperature2Humidity |
                    Humidity2Location)

primitive Seeds                fun string(): String val => "Seeds"
primitive Seed2Soil            fun string(): String val => "Seed2Soil"
primitive Soil2Fertilizer      fun string(): String val => "Soil2Fertilizer"
primitive Fertilizer2Water     fun string(): String val => "Fertilizer2Water"
primitive Water2Light          fun string(): String val => "Water2Light"
primitive Light2Temperature    fun string(): String val => "Light2Temperature"
primitive Temperature2Humidity fun string(): String val => "Temperature2Humidity"
primitive Humidity2Location    fun string(): String val => "Humidity2Location"

class Mapper
  var mytype: ParseState = Seeds
  var starta: USize = 0
  var startb: USize = 0
  var endb: USize = 0
  var length: USize = 0

  fun debug() =>
    let offset: USize = starta - startb

    Debug.out("[Mapper:" + mytype.string() + "]: " +
              "InMap: " + startb.string() + "->" + endb.string() +
              ", OutRange: " + (startb+offset).string() + "->" + (endb + offset).string())

  fun in_range(inval: USize): Bool =>
    if ((inval >= startb) and (inval <= endb)) then
      true
    else
      false
    end


  fun in_actual_range(a: USize, b: USize): (USize, USize)? =>
    var lower: USize = 0
    var upper: USize = 0
    if (startb > b) then
    Debug.out("in: " + a.string() + "->" + b.string() +
              ", InMap: " + startb.string() + "->" + endb.string() +
              ", EndRange: " + lower.string() + "->" + upper.string())
      Debug.out("Out of range - too low")
      error
    end
    if (a > endb) then
    Debug.out("in: " + a.string() + "->" + b.string() +
              ", InMap: " + startb.string() + "->" + endb.string() +
              ", EndRange: " + lower.string() + "->" + upper.string())
      Debug.out("Out of range - too high")
      error
    end

    if (a <= startb) then
      lower = startb
    else
      lower = a
    end

    if (b >= endb) then
      upper = endb
    else
      upper = b
    end

    let offset: USize = starta - startb

    Debug.out("[Mapper:" + mytype.string() + "]: in: " + a.string() + "->" + b.string() +
              ", InMap: " + startb.string() + "->" + endb.string() +
              ", InRange: " + lower.string() + "->" + upper.string() +
              ", OutRange: " + (lower+offset).string() + "->" + (upper + offset).string())

    (lower + offset, upper + offset)



  fun apply(inval: USize): USize ? =>
    if (not in_range(inval)) then error end
    let offset: USize = inval - startb
    starta + offset

  fun le(m: Mapper box): Bool => (startb.le(m.startb))
  fun lt(m: Mapper box): Bool => (startb.lt(m.startb))
  fun ge(m: Mapper box): Bool => (startb.ge(m.startb))
  fun gt(m: Mapper box): Bool => (startb.gt(m.startb))
  fun compare(m: Mapper box): Compare => (startb.compare(m.startb))
  fun eq(m: Mapper box): Bool => (startb.eq(m.startb))
  fun ne(m: Mapper box): Bool => (startb.ne(m.startb))
