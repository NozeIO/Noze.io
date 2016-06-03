//
//  ascii.swift
//  HTTPParser
//
//  Created by Helge Hess on 25/04/16.
//  Copyright © 2016 Always Right Institute. All rights reserved.
//

// Not in Swift: let c : CChar = 'A'

// TODO: move into Literals struct
let cTAB        : CChar =   9 // \t
let cFORMFEED   : CChar =  12 // \f

let cSPACE      : CChar =  32 //
let cEXMARK     : CChar =  33 // !
let cHASH       : CChar =  35 // #
let cDOLLAR     : CChar =  36 // $
let cPERCENT    : CChar =  37 // %
let cAMP        : CChar =  38 // &
let cTICK       : CChar =  39 // '
let cSTAR       : CChar =  42 // *
let cPLUS       : CChar =  42 // +
let cCOMMA      : CChar =  44 // ,
let cDASH       : CChar =  45 // -
let cDOT        : CChar =  46 // .
let cSLASH      : CChar =  47 // /
let cCOLON      : CChar =  58 // :
let cSEMICOLON  : CChar =  59 // ;
let cQM         : CChar =  63 // ?
let cAT         : CChar =  64 // @
let cLSB        : CChar =  91 // [
let cRSB        : CChar =  93 // ]
let cCARET      : CChar =  94 // ^
let cUNDERSCORE : CChar =  95 // _
let cBACKTICK   : CChar =  96 // `
let cVDASH      : CChar = 124 // |
let cTILDE      : CChar = 126 // ~

let cA : CChar = 65 // A
let cB : CChar = 66
let cC : CChar = 67
let cD : CChar = 68
let cE : CChar = 69
let cF : CChar = 70
let cG : CChar = 71
let cH : CChar = 72
let cI : CChar = 73
let cJ : CChar = 74
let cK : CChar = 75
let cL : CChar = 76
let cM : CChar = 77
let cN : CChar = 78
let cO : CChar = 79
let cP : CChar = 80
let cQ : CChar = 81
let cR : CChar = 82
let cS : CChar = 83
let cT : CChar = 84
let cU : CChar = 85 // U

let ca : CChar =  97 // a
let cb : CChar =  98 // b
let cc : CChar =  99 // c
let cd : CChar = 100 // d
let ce : CChar = 101 // e
let cf : CChar = 102 // f
let cg : CChar = 103 // g
let ch : CChar = 104 // h
let ci : CChar = 105 // i
let cj : CChar = 106 // j
let ck : CChar = 107 // k
let cl : CChar = 108 // l
let cm : CChar = 109 // m
let cn : CChar = 110 // n
let co : CChar = 111 // o
let cp : CChar = 112 // p
let cq : CChar = 113 // q
let cr : CChar = 114 // r
let cs : CChar = 115 // s
let ct : CChar = 116 // t
let cu : CChar = 117 // u
let cv : CChar = 118 // v
let cw : CChar = 119 // w
let cx : CChar = 120 // x
let cy : CChar = 121 // y
let cz : CChar = 122 // z

let c0 : CChar = 48 // 0
let c1 : CChar = 49
let c2 : CChar = 50
let c3 : CChar = 51
let c4 : CChar = 52
let c5 : CChar = 53
let c6 : CChar = 54
let c7 : CChar = 55
let c8 : CChar = 56
let c9 : CChar = 57 // 9


/* Tokens as defined by rfc 2616. Also lowercases them.
 *        token       = 1*<any CHAR except CTLs or separators>
 *     separators     = "(" | ")" | "<" | ">" | "@"
 *                    | "," | ";" | ":" | "\" | <">
 *                    | "/" | "[" | "]" | "?" | "="
 *                    | "{" | "}" | SP | HT
 */
// Note: Swift has no neat Char=>Code conversion
// This lowercases the regular chars, and returns 0 for invalid chars.
private let tokens : [ CChar ] = [
/*   0 nul    1 soh    2 stx    3 etx    4 eot    5 enq    6 ack    7 bel  */
        0,       0,       0,       0,       0,       0,       0,       0,
/*   8 bs     9 ht    10 nl    11 vt    12 np    13 cr    14 so    15 si   */
        0,       0,       0,       0,       0,       0,       0,       0,
/*  16 dle   17 dc1   18 dc2   19 dc3   20 dc4   21 nak   22 syn   23 etb */
        0,       0,       0,       0,       0,       0,       0,       0,
/*  24 can   25 em    26 sub   27 esc   28 fs    29 gs    30 rs    31 us  */
        0,       0,       0,       0,       0,       0,       0,       0,
/*  32 sp    33  !    34  "    35  #    36  $    37  %    38  &    39  '  */
        0,   cEXMARK,     0,   cHASH,  cDOLLAR, cPERCENT,   cAMP,   cTICK,
/*  40  (    41  )    42  *    43  +    44  ,    45  -    46  .    47  /  */
        0,       0,   cSTAR,   cPLUS,      0,    cDASH,     cDOT,      0,
/*  48  0    49  1    50  2    51  3    52  4    53  5    54  6    55  7  */
       c0,      c1,      c2,      c3,      c4,      c5,      c6,      c7,
/*  56  8    57  9    58  :    59  ;    60  <    61  =    62  >    63  ?  */
       c8,      c9,       0,       0,       0,       0,       0,       0,
/*  64  @    65  A    66  B    67  C    68  D    69  E    70  F    71  G  */
        0,       ca,     cb,      cc,      cd,      ce,      cf,      cg,
/*  72  H    73  I    74  J    75  K    76  L    77  M    78  N    79  O  */
       ch,      ci,      cj,      ck,      cl,      cm,      cn,      co,
/*  80  P    81  Q    82  R    83  S    84  T    85  U    86  V    87  W  */
       cp,      cq,      cr,      cs,      ct,      cu,      cv,      cw,
/*  88  X    89  Y    90  Z    91  [    92  \    93  ]    94  ^    95  _  */
       cx,      cy,      cz,       0,       0,       0,  cCARET, cUNDERSCORE,
/*  96  `    97  a    98  b    99  c   100  d   101  e   102  f   103  g  */
 cBACKTICK,     ca,      cb,      cc,      cd,      ce,      cf,      cg,
/* 104  h   105  i   106  j   107  k   108  l   109  m   110  n   111  o  */
       ch,      ci,      cj,      ck,      cl,      cm,      cn,     co,
/* 112  p   113  q   114  r   115  s   116  t   117  u   118  v   119  w  */
       cp,      cq,      cr,      cs,      ct,      cu,      cv,     cw,
/* 120  x   121  y   122  z   123  {   124  |   125  }   126  ~   127 del */
       cx,      cy,      cz,       0,  cVDASH,      0,  cTILDE,       0 ]

// used in HTTPParser[3]
let unhex : [ Int8 ] = [
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  , 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1
  ,-1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
]

// w/o explicit casts, this takes forever in type inference
// Note: precalculating the values doesn't give any speedup
private let b0   = UInt8(0)
private let b1   = UInt8(1)
private let b2   = UInt8(2)
private let b4   = UInt8(4)
private let b8   = UInt8(8)
private let b16  = UInt8(16)
private let b32  = UInt8(32)
private let b64  = UInt8(64)
private let b128 = UInt8(128)
private let normal_url_char : [ UInt8 ] /* [32] */ = [
  /*   0 nul    1 soh    2 stx    3 etx    4 eot    5 enq    6 ack    7 bel  */
  b0    |   b0    |   b0    |   b0    |   b0    |   b0    |   b0    |   b0,
  /*   8 bs     9 ht */
  b0    | (HTTP_PARSER_STRICT ? b0 : b2)
  /*   10 nl    11 vt    12 np    13 cr */
       |   b0    |   b0    | (HTTP_PARSER_STRICT ? b0 : b16)
  /*   13 cr    14 so    15 si   */
       |   b0    |   b0    |   b0,
  /*  16 dle   17 dc1   18 dc2   19 dc3   20 dc4   21 nak   22 syn   23 etb */
  b0    |   b0    |   b0    |   b0    |   b0    |   b0    |   b0    |   b0,
  /*  24 can   25 em    26 sub   27 esc   28 fs    29 gs    30 rs    31 us  */
  b0    |   b0    |   b0    |   b0    |   b0    |   b0    |   b0    |   b0,
  /*  32 sp    33  !    34  "    35  #    36  $    37  %    38  &    39  '  */
  b0    |   b2    |   b4    |   b0    |   b16   |   b32   |   b64   | b128,
  /*  40  (    41  )    42  *    43  +    44  ,    45  -    46  .    47  /  */
  b1    |   b2    |   b4    |   b8    |   b16   |   b32   |   b64   | b128,
  /*  48  b0    49  1    50  2    51  3    52  4    53  5    54  6    55  7  */
  b1    |   b2    |   b4    |   b8    |   b16   |   b32   |   b64   | b128,
  /*  56  8    57  9    58  :    59  ;    60  <    61  =    62  >    63  ?  */
  b1    |   b2    |   b4    |   b8    |   b16   |   b32   |   b64   |   b0,
  /*  b64  @    65  A    66  B    67  C    68  D    69  E    70  F    71  G  */
  b1    |   b2    |   b4    |   b8    |   b16   |   b32   |   b64   | b128,
  /*  72  H    73  I    74  J    75  K    76  L    77  M    78  N    79  O  */
  b1    |   b2    |   b4    |   b8    |   b16   |   b32   |   b64   | b128,
  /*  80  P    81  Q    82  R    83  S    84  T    85  U    86  V    87  W  */
  b1    |   b2    |   b4    |   b8    |   b16   |   b32   |   b64   | b128,
  /*  88  X    89  Y    90  Z    91  [    92  \    93  ]    94  ^    95  _  */
  b1    |   b2    |   b4    |   b8    |   b16   |   b32   |   b64   | b128,
  /*  96  `    97  a    98  b    99  c   100  d   101  e   102  f   103  g  */
  b1    |   b2    |   b4    |   b8    |   b16   |   b32   |   b64   | b128,
  /* 104  h   105  i   106  j   107  k   108  l   109  m   110  n   111  o  */
  b1    |   b2    |   b4    |   b8    |   b16   |   b32   |   b64   | b128,
  /* 112  p   113  q   114  r   115  s   116  t   117  u   118  v   119  w  */
  b1    |   b2    |   b4    |   b8    |   b16   |   b32   |   b64   | b128,
  /* 120  x   121  y   122  z   123  {   124  |   125  }   126  ~   127 del */
  b1    |   b2    |   b4    |   b8    |   b16   |   b32   |   b64   |   b0
]

/* Macros for character classes; depends on strict-mode  */

let CR : CChar = 13
let LF : CChar = 10

#if swift(>=3.0) // #swift3-1st-arg

func LOWER   (_ c: CChar) -> CChar { return CChar(UInt8(c) | UInt8(0x20)) }
func IS_ALPHA(_ c: CChar) -> Bool  { return LOWER(c) >= ca && LOWER(c) <= cz }
func IS_NUM  (_ c: CChar) -> Bool  { return c >= c0 && c <= c9 }

func IS_ALPHANUM(_ c: CChar) -> Bool { return IS_ALPHA(c) || IS_NUM(c) }

func IS_HEX(_ c: CChar) -> Bool {
  return (IS_NUM(c) || (LOWER(c) >= ca && LOWER(c) <= cf))
}

func IS_MARK(_ c: CChar) -> Bool {
  return ((c) == cDASH || (c) ==  95 /* '_' */ || (c) == 46 /* '.' */
       || (c) == 33 /* '!'  */ || (c) == 126 /* '~' */ || (c) == 42 /* '*' */
       || (c) == 92 /* '\'' */ || (c) ==  40 /* '(' */ || (c) == 41 /* ')' */)
}

func IS_USERINFO_CHAR(_ c: CChar) -> Bool {
  return (IS_ALPHANUM(c) || IS_MARK(c)
       || (c) == 37 /* '%' */ || (c) == 59 /* ';' */ || (c) == 58 /* ':' */
       || (c) == 38 /* '&' */ || (c) == 61 /* '=' */ || (c) == 43 /* '+' */
       || (c) == 36 /* '$' */ || (c) == 44 /* ',' */)
}

func STRICT_TOKEN(_ c: CChar) -> CChar {
  return tokens[Int(c)]
}

func TOKEN(_ c: CChar) -> CChar {
  if HTTP_PARSER_STRICT {
    return tokens[Int(c)]
  }
  else {
    return (c == cSPACE) ? cSPACE : tokens[Int(c)]
  }
}

func IS_URL_CHAR(_ c: CChar) -> Bool {
  // TODO: I don't get that normal_url_char map yet.
  return c != CR && c != LF && c > 32
  // fatalError("TODO: IS_URL_CHAR")
  /*
   #define BIT_AT(a, i) \
       (!!((unsigned int) (a)[(unsigned int) (i) >> 3] & \
       (1 << ((unsigned int) (i) & 7))))
   #define BIT_AT(a, i) (!!(a[i >> 3] & (1 << (i & 7))))
   
   let normal_url_char : [ UInt8 ] /* [32] */ = [ .. ]
   
  if HTTP_PARSER_STRICT {
    return (BIT_AT(normal_url_char, (unsigned char)c))
  }
  else {
    return (BIT_AT(normal_url_char, (unsigned char)c) || CChar(UInt8(c) & UInt8(0x80)))
  }
  */
}

func IS_HOST_CHAR(_ c: CChar) -> Bool {
  if HTTP_PARSER_STRICT {
    return (IS_ALPHANUM(c) || (c) == 46 /* '.' */ || (c) == 45 /* '-' */)
  }
  else {
    return (IS_ALPHANUM(c) || (c) == 46 /* '.' */ || (c) == 45 /* '-' */
            || (c) == 95 /* '_' */)
  }
}

#else // Swift 2.2

func LOWER(c: CChar) -> CChar { return c | 0x20 } // TODO: hm: UInt8 bitcast?

func IS_ALPHA(c: CChar) -> Bool {
  return (LOWER(c) >= 97 /* 'a' */ && LOWER(c) <= 122 /* 'z' */)
}

func IS_NUM(c: CChar) -> Bool {
  return ((c) >= 48 /* '0' */ && (c) <= 57 /* '9' */)
}

func IS_ALPHANUM(c: CChar) -> Bool { return IS_ALPHA(c) || IS_NUM(c) }

func IS_HEX(c: CChar) -> Bool {
  return (IS_NUM(c) || (LOWER(c) >= 97 /*'a'*/ && LOWER(c) <= 102 /*'f'*/))
}

func IS_MARK(c: CChar) -> Bool {
  return ((c) == 45 /* '-'  */ || (c) ==  95 /* '_' */ || (c) == 46 /* '.' */
       || (c) == 33 /* '!'  */ || (c) == 126 /* '~' */ || (c) == 42 /* '*' */
       || (c) == 92 /* '\'' */ || (c) ==  40 /* '(' */ || (c) == 41 /* ')' */)
}

func IS_USERINFO_CHAR(c: CChar) -> Bool {
  return (IS_ALPHANUM(c) || IS_MARK(c)
       || (c) == 37 /* '%' */ || (c) == 59 /* ';' */ || (c) == 58 /* ':' */
       || (c) == 38 /* '&' */ || (c) == 61 /* '=' */ || (c) == 43 /* '+' */
       || (c) == 36 /* '$' */ || (c) == 44 /* ',' */)
}

func STRICT_TOKEN(c: CChar) -> CChar {
  return tokens[Int(c)]
}

func TOKEN(c: CChar) -> CChar {
  if HTTP_PARSER_STRICT {
    return tokens[Int(c)]
  }
  else {
    return ((c == 32 /* ' ' */) ? 32 /* ' ' */ : tokens[Int(c)])
  }
}

func IS_URL_CHAR(c: CChar) -> Bool {
  // TODO: I don't get that normal_url_char map yet.
  return c != CR && c != LF && c > 32
  // fatalError("TODO: IS_URL_CHAR")
  /*
   #define BIT_AT(a, i) \
       (!!((unsigned int) (a)[(unsigned int) (i) >> 3] & \
       (1 << ((unsigned int) (i) & 7))))
   #define BIT_AT(a, i) (!!(a[i >> 3] & (1 << (i & 7))))
   
   let normal_url_char : [ UInt8 ] /* [32] */ = [ .. ]
   
  if HTTP_PARSER_STRICT {
    return (BIT_AT(normal_url_char, (unsigned char)c))
  }
  else {
    return (BIT_AT(normal_url_char, (unsigned char)c) || ((c) & 0x80))
  }
  */
}

func IS_HOST_CHAR(c: CChar) -> Bool {
  if HTTP_PARSER_STRICT {
    return (IS_ALPHANUM(c) || (c) == 46 /* '.' */ || (c) == 45 /* '-' */)
  }
  else {
    return (IS_ALPHANUM(c) || (c) == 46 /* '.' */ || (c) == 45 /* '-' */
            || (c) == 95 /* '_' */)
  }
}

#endif // Swift 2.2

