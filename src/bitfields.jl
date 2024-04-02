struct BitFieldSpecs{N, T} <: Unsigned
     specs::NTuple{N, T}
end

specs(x::BitFieldSpecs) = x.specs
nspecs(x::BitFieldSpecs{N,T}) where {N,T} = N
Base.eltype(x::BitFieldSpecs) = eltype(x[1])

BitFieldSpecs(structs::Vararg{BitFieldSpec}) = BitFieldSpecs(structs)

struct BitFields{N, T} <: Unsigned
    fields::NTuple{N, T}
end

fields(x::BitFields) = x.fields
nfields(x::BitFields{N,T}) where {N,T} = N
Base.eltype(x::BitFields) = eltype(x[1])

BitFields(fields::Vararg{BitField}) = BitFieldSpecs(fields)


      
