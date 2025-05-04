function readfromfile(path::AbstractString)
    lines = open(path) do f
        readlines(f)
    end

    return lines
end

function isvalidword(word::AbstractString)
    return length(word) == 5 && length(Set(word)) == 5
end

filtervalidwords!(words::Vector{String}) = filter!(isvalidword, words)

getbitrepresentation(c::Char) = one(UInt32) << (UInt8(c) - 0x61)

getbitrepresentation(str::AbstractString)::UInt32 = sum(getbitrepresentation, str)

removeanagrams!(words::Vector{String}) = unique!(getbitrepresentation, words)

function main()
    words = readfromfile("words_alpha.txt")
    filtervalidwords!(words)
    removeanagrams!(words)
end
