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

function main()
    words = readfromfile("words_alpha.txt")
    filtervalidwords!(words)
end
