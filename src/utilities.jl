module Utilities

otherside(side::Int) = (@assert side in (1,2); side == 1 ? 2 : 1)

end