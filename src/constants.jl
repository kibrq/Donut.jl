module Constants

export Side, LEFT, RIGHT, ForwardOrBackward, FORWARD, BACKWARD, otherside

@enum Side::Int8 LEFT=1 RIGHT=2
otherside(side::Side) = side == LEFT ? RIGHT : LEFT

@enum ForwardOrBackward::Int8 FORWARD=1 BACKWARD=2
otherside(direction::ForwardOrBackward) = direction == FORWARD ? BACKWARD : FORWARD


const CENTRAL = 3





end