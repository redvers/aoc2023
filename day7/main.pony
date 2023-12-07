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

  let results: Array[Hand] = Array[Hand]

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

  be parse_file() =>
    let path = FilePath(fileauth, filename)

    match OpenFile(path)
    | let file: File =>
      let lines: FileLines = FileLines(file)

      for line in lines do
        parse_line(consume line)
      end
    else
      stdout.print("Error opening file '" + filename + "'")
    end
    reporta()

  be reporta() =>
    var sorted: Array[Hand] = Sort[Array[Hand], Hand](results)
    var ascore: USize = 0
    for (r, hando) in sorted.pairs() do
      let rank: USize = r + 1
      Debug(hando.str + ": " + hando.bid.string() + " * " + rank.string())
      ascore = ascore + (hando.bid * rank)
    end
    Debug.out("AScore: " + ascore.string())

  be parse_line(line: String val) =>
    let hand: String = line.substring(0,5)
    try
      let hando: Hand = classify(hand)?
      hando.bid = line.substring(6).usize()?
      results.push(hando)
      Debug.out(hand + ": " + hando.score.string())
    else
      @printf("Died in parsing - alert!\n".cstring())
      @exit(-1)
    end

  fun classify(hand: String): Hand ? =>
    let t: Map[U8, U8] = Map[U8, U8]
    let cc: Array[U8] = Array[U8]
    var handscore: U64 = 0
    for (r,f) in hand.array().pairs() do
      let pp: U64 = F64(20).powi(6-r.i32()).u64()

/*    A, K, Q, J, T, 9, 8, 7, 6, 5, 4, 3, or 2    */
      let cardval: U8 = 
        if    ((f >= '2') and (f <= '9')) then f - '0'
        elseif (f == 'T') then 10
        elseif (f == 'J') then 11
        elseif (f == 'Q') then 12
        elseif (f == 'K') then 13
        elseif (f == 'A') then 14
        else error
        end

//      Debug.out("[" + pp.string() + "]" + cardval.string())
      handscore = handscore + (pp * cardval.u64())
      t.upsert(f, 1, {(c,p) => c + p})
    end
//    Debug.out("Handscore: " + handscore.string())

    for (a,b) in t.pairs() do
      cc.push(b)
    end

    let ccs: Array[U8] = Sort[Array[U8], U8](cc).>reverse_in_place()
//    Debug.out(",".join(ccs.values()))

    let hando: Hand = Hand
    hando.handtype = 
    if      (ccs(0)? == 5) then FiveOfAKind
    elseif  (ccs(0)? == 4) then FourOfAKind
    elseif ((ccs(0)? == 3) and (ccs(1)? == 2)) then FullHouse
    elseif ((ccs(0)? == 3) and (ccs(1)? == 1)) then ThreeOfAKind
    elseif ((ccs(0)? == 2) and (ccs(1)? == 2)) then TwoPair
    elseif ((ccs(0)? == 2) and (ccs(1)? == 1)) then OnePair
    elseif  (ccs(0)? == 1) then HighCard
    else error
    end
    hando.str = hand
    hando.score = hando.handtype.apply() + handscore

    hando

class Hand
  var handtype: HandType = HighCard
  var score: U64 = 0
  var str: String = ""
  var bid: USize = 0


  fun le(m: Hand box): Bool => (score.le(m.score))
  fun lt(m: Hand box): Bool => (score.lt(m.score))
  fun ge(m: Hand box): Bool => (score.ge(m.score))
  fun gt(m: Hand box): Bool => (score.gt(m.score))
  fun compare(m: Hand box): Compare => (score.compare(m.score))
  fun eq(m: Hand box): Bool => (score.eq(m.score))
  fun ne(m: Hand box): Bool => (score.ne(m.score))




type HandType is (FiveOfAKind | FourOfAKind | FullHouse | ThreeOfAKind |
                  TwoPair | OnePair | HighCard)
primitive FiveOfAKind fun apply(): U64 => (F64(20).powi(10).u64() * 10)
primitive FourOfAKind fun apply(): U64 => (F64(20).powi(10).u64() * 9)
primitive FullHouse fun apply(): U64 => (F64(20).powi(10).u64() * 8)
primitive ThreeOfAKind fun apply(): U64 => (F64(20).powi(10).u64() * 7)
primitive TwoPair fun apply(): U64 => (F64(20).powi(10).u64() * 6)
primitive OnePair fun apply(): U64 => (F64(20).powi(10).u64() * 5)
primitive HighCard fun apply(): U64 => (F64(20).powi(10).u64() * 4)

