bitsof(x) = sizeof(x) * 8

struct BitFieldA{T<:Base.BitUnsigned}
    bitmask::T
    name::Symbol
end

struct BitFieldB{T<:Base.BitUnsigned}
    bitmask::T
    bitwidth::Int16
    bitshift::Int16
    name::Symbol
end

mutable struct BitFieldC{T<:Base.BitUnsigned}
    content::T
    const bitmask::T
    const bitwidth::Int16
    const bitshift::Int16
    const name::Symbol
end

bitmask(bitfield) = bitfield.bitmask
name(bitfield) = bitfield.name
bitwidth(bitfield) = bitfield.bitwidth
bitshift(bitfield) = bitfield.bitshift
content(bitfield) = bitfield.content

