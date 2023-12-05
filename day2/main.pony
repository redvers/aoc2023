use "files"
use "regex"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    for filename in env.args.slice(1).values() do
      let fn: FileRunner = FileRunner(env.out, FileAuth(env.root), filename)
      fn.runa()
		end


actor FileRunner
  let stdout: OutStream tag
  let fileauth: FileAuth val
  let filename: String val

  var score: ISize = 0
  var power: ISize = 0

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

  be runa() =>
    let path = FilePath(fileauth, filename)

    match OpenFile(path)
    | let file: File =>
      let lines: FileLines = FileLines(file)

      for line in lines do
        process_game(consume line)
      end
      reporta()
    else
      stdout.print("Error opening file '" + filename + "'")
    end

  be process_game(line': String val) =>
    let gamestate: GameState =
    try
      let gameregex: Regex = Regex("^Game (\\d+):")?
      GameState(gameregex(line')?(1)?.isize()?)
    else
      stdout.print("Unable to extract gameid from line: " + line')
      return
    end

    try
      check_bag(gamestate, Red, line')?
      check_bag(gamestate, Green, line')?
      check_bag(gamestate, Blue, line')?
    else
      stdout.print("This should never happen Pt2")
    end

//  stdout.print(gamestate.debug())
    score = gamestate.parta_score(score)
    power = gamestate.partb_score(power)


  fun ref check_bag(gamestate: GameState, color: Color, line: String val) ? =>
    for rmatch in MatchIterator(color.regex()?, line) do
      let v: ISize = rmatch(1)?.isize()?
      color.find_min(gamestate, v)
    else
      stdout.print("This should never happen[tm]")
    end

  be reporta() =>
    stdout.print(filename + ", Part 1: " + score.string())
    stdout.print(filename + ", Part 2: " + power.string())

primitive Red
  fun regex(): Regex ? => Regex("(\\d+) red")?

  fun find_min(gs: GameState, v: ISize) =>
    if (v > gs.rmin) then gs.rmin = v end

  fun parta(v: ISize): Bool => not (v > 12)

primitive Green
  fun regex(): Regex ? => Regex("(\\d+) green")?
  fun find_min(gs: GameState, v: ISize) =>
    if (v > gs.gmin) then gs.gmin = v end

  fun parta(v: ISize): Bool => not (v > 13)

primitive Blue
  fun regex(): Regex ? => Regex("(\\d+) blue")?
  fun find_min(gs: GameState, v: ISize) =>
    if (v > gs.bmin) then gs.bmin = v end

  fun parta(v: ISize): Bool => not (v > 14)

type Color is (Red | Green | Blue)

class GameState
  var rmin: ISize = 0
  var gmin: ISize = 0
  var bmin: ISize = 0

  let gameid: ISize

  new create(gameid': ISize) =>
    gameid = gameid'

  fun debug(): String val =>
    "RedMin: " + rmin.string() + ": " + Red.parta(rmin).string() + ", " +
    "GrnMin: " + bmin.string() + ": " + Green.parta(gmin).string() + ", " +
    "BluMin: " + bmin.string() + ": " + Blue.parta(bmin).string()

  fun parta_score(score: ISize): ISize =>
    if (Red.parta(rmin) and Green.parta(gmin) and Blue.parta(bmin)) then
      score + gameid
    else
      score
    end

  fun partb_score(power: ISize): ISize =>
    power + (rmin * gmin * bmin)
