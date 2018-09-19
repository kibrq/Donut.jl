
module UtilsTest

using Test
using Donut.Utils: otherside, nextindex, previndex
using Donut.Constants: LEFT, RIGHT, FORWARD, BACKWARD, START, END

@test otherside(LEFT) == RIGHT
@test otherside(RIGHT) == LEFT
@test otherside(FORWARD) == BACKWARD
@test otherside(BACKWARD) == FORWARD
@test otherside(END) == START
@test otherside(START) == END

@test nextindex(1, 3) == 2
@test nextindex(2, 3) == 3
@test nextindex(3, 3) == 1

@test previndex(1, 3) == 3
@test previndex(2, 3) == 1
@test previndex(3, 3) == 2

end
