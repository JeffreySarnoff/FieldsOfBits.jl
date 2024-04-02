struct BitFieldSpecs{N, T} <: Unsigned
     specs::NTuple{N, BitFieldSpec{T}}
end

specs(x::BitFieldSpecs) = x.specs
nspecs(x::BitFieldSpecs{N,T}) where {N,T} = N
Base.eltype(x::BitFieldSpecs) = eltype(x[1])

BitFieldSpecs(structs::Vararg{BitFieldSpec}) = BitFieldSpecs(structs)

function BitFieldSpecs(masks::NTuple{N,T}) where {N, T<:Base.BitUnsigned}
     sortedmasks = Tuple(sort([masks...]))
     # check for overlapping masks
     overlap = !iszero( foldl(|, [foldl(&, sortedmasks[i:i+1]) for i=1:N-1]) )
     overlap && throw(DomainError("the bitfield masks overlap: $(sortedmasks)"))
     specs = map(BitFieldSpec, sortedmasks)
     BitFieldSpecs(specs)
end

function BitFieldSpecs(::Type{T1};nbits::NTuple[N, T2}) where {T1<:Base.BitUnsigned, N,T<:Integer}
     # highs = cumsum(nbits)
     # lows = highs .- nbits .+ 1
     # fieldspans = map((lo,hi)->lo:hi, lows, highs)
     offsets = cumsum(nbits) .- nbits
     map((offset, count)->BitFieldSpec(offset, count), offsets, nbits)
end
     
function Base.show(io::IO, x::BitFieldSpecs{N, T}) where {N, T}
    strs = join(map(string, x), '\n')
    show(io, strs) 
end
     
struct BitFields{N, T} <: Unsigned
    fields::NTuple{N, T}
end

fields(x::BitFields) = x.fields
nfields(x::BitFields{N,T}) where {N,T} = N
Base.eltype(x::BitFields) = eltype(x[1])

BitFields(fields::Vararg{BitField}) = BitFieldSpecs(fields)

function Base.show(io::IO, x::BitFields{N, T}) where {N, T}
    strs = join(map(string, x), '\n')
    show(io, strs) 
end

      
