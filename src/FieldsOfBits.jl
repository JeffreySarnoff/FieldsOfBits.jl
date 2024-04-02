module FieldsOfBits

export BitField, BitFields

using Base: BitUnsigned, BitInteger

include("bitops.jl")
include("bitfield.jl")
include("bitfields.jl")
include("builders.jl")

end  # BitFields

