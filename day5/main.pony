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
    stdout.print("Closest Location: " + minval.string())

  fun report_seed(seed: USize): USize =>
    let soil:  USize = apply_map(Seed2Soil, seed)
    let fert:  USize = apply_map(Soil2Fertilizer, soil)
    let water: USize = apply_map(Fertilizer2Water, fert)
    let light: USize = apply_map(Water2Light, water)
    let temp:  USize = apply_map(Light2Temperature, light)
    let humid: USize = apply_map(Temperature2Humidity, temp)
    let locat: USize = apply_map(Humidity2Location, humid)

    stdout.print("Seed: " + seed.string() + 
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
          mapp.debug(seed)
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

  fun debug(inval: USize) =>
    Debug("[Mapper:" + mytype.string() + "] inval: " + inval.string() +
          ", startb: " + startb.string() + ", endb: " + endb.string()) 

  fun in_range(inval: USize): Bool =>
    if ((inval >= startb) and (inval <= endb)) then
      true
    else
      false
    end

  fun apply(inval: USize): USize ? =>
    if (not in_range(inval)) then error end
    let offset: USize = inval - startb
    starta + offset

