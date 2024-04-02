function bitfield(::Type{T}, spec::NamedTuple{(:name, :nbits, :offset), Tuple{Symbol, Int, Int}) where {T<:Base.BitUnsigned}
    fieldspec = BitFieldSpec(T; spec.nbits, spec.offset)
    NamedBitFieldSpec(spec.name, fieldspec)
end

function Base.sort(nt::NamedTuple)
    syms = keys(nt)
    vals = values(nt)
    sperm = TT.sortperm(vals)
    sortedsyms = Tuple([syms[i] for i in sperm])
    sortedvals = [vals[i] for i in sperm]
    NamedTuple{sortedsyms}(sortedvals)
end

# UNCHECKED PRECONDITION nt = sort(nt)
function unsafe_overlap(nt::NamedTuple)
    increments = first.(values(snt))[2:end] .- last.(values(snt))[1:end-1]
    any(map(x->(x<1), increments))
end

const UINTs = (UInt8, UInt8, UInt8, UInt16, UInt32, UInt64, UInt128)
        
function uintfor(nt::NamedTuple)
    mx = last(values(snt)[end])
    UINTs[ceil(Int, log2(mx))]
end

function BitFieldSpecs(nt::NamedTuple)
   snt = sort(nt)
   unsafe_overlap(snt) && throw(ErrorException("bitfields must not overlap"))
   uint = uintfor(snt)
   symbols = keys(snt)
   uints = fill(uint, length(symbols))
   bitwidths = map(length, values(snt))
   offsets = map(first, values(snt)) .- 1
   znt = zip(uints, symbols, bitwidths, offsets)
   fieldspecs = Tuple(map(a->BitFieldSpec(a[1]; name=a[2], nbits=a[3], offset=a[4]), znt))
   BitFieldSpecs(fieldspecs)
end

function BitFields(nt::NamedTuple)
   fieldspecs = BitFieldSpecs(nt)
end
