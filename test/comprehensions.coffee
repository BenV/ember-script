suite 'Comprehensions', ->

  test 'comprehensions with no body produce `undefined` for each entry', ->
    arrayEq (undefined for a in [0..9]), for b in [0..9] then

  test '#66: `throw` as the final expression in the body of a comprehension', ->
    (->) -> for a in [0..9] then throw {}

  test 'comprehensions over static, integral ranges', ->
    arrayEq [0..9], (a for a in [0..9])
    arrayEq [0...9], (a for a in [0...9])

  test '#234: value may be omitted in for-in comprehensions', ->
    arrayEq [0, 0, 0, 0], (0 for in [0..3])
    c = 0
    fn = -> c++
    arrayEq [0..9], (fn() for in [0..9])
    a = 0
    b = 9
    c = 0
    arrayEq [a..b], (fn() for in [a..b])
    c = 0
    arrayEq [a...b], (fn() for in [a...b])
