function bitfield(::Type{T}, spec::NamedTuple{(:name, :nbits, :offset), Tuple{Symbol, Int, Int}) where {T<:Base.BitUnsigned}
    namenum = encode(spec.name)
end

function encode(name::Symbol)
    str = String(name)
    n = length(str)
    n > 15 && throw(DomainError("cannot encode names with more than 15 characters"))
    chrvals = [UInt8(Int(str[i][1]) - 0x1f) for i=1:length(str)]
    shifts = [8*i for i=0:n-1]
    T = (n <= 8 ? UInt64 : UInt128)
    shiftedvals = map((val,shift)->T(val)<<shift, chrvals, shifts)
    foldl(|, shiftedvals)
end

function decode(num::Union{UInt64, UInt128})
    nbytes = fld(bitsof(num) - leading_zeros(num) + 7, 8)
    nums = zeros(UInt8, nbytes)
    for i=1:nbytes
        nums[i] = ((num >> (8*(i-1))) + 0x1f) % UInt8
    end
    Symbol(join(map(Char,nums)))
end
