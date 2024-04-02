function bitfield(::Type{T}, spec::NamedTuple{(:name, :nbits, :offset), Tuple{Symbol, Int, Int}) where {T<:Base.BitUnsigned}
    fieldspec = BitFieldSpec(T; spec.nbits, spec.offset)
    NamedBitFieldSpec(spec.name, fieldspec)
end
