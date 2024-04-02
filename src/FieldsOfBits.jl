module FieldsOfBits

export BitField, BitFields

using Base: BitUnsigned, BitInteger
import TupleTools as TT

include("bitops.jl")
include("bitfield.jl")
include("bitfields.jl")
include("builders.jl")

end  # BitFields

