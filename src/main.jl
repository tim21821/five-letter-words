struct Pair
    index1::Int
    index2::Int
    bitmask::UInt32
end

struct Quartet
    index1::Int
    index2::Int
    index3::Int
    index4::Int
    bitmask::UInt32
end

struct Answer
    index1::Int
    index2::Int
    index3::Int
    index4::Int
    index5::Int
end

combine(pair1::Pair, pair2::Pair) = Quartet(
    pair1.index1,
    pair1.index2,
    pair2.index1,
    pair2.index2,
    pair1.bitmask | pair2.bitmask,
)

combine(quartet::Quartet, i::Int) =
    Answer(quartet.index1, quartet.index2, quartet.index3, quartet.index4, i)

function readfromfile(path::AbstractString)
    lines = open(path) do f
        readlines(f)
    end

    return lines
end

isvalidword(word::AbstractString) = return length(word) == 5 && length(Set(word)) == 5

filtervalidwords!(words::Vector{String}) = filter!(isvalidword, words)

getbitrepresentation(c::Char) = one(UInt32) << (UInt8(c) - 0x61)

getbitrepresentation(str::AbstractString)::UInt32 = sum(getbitrepresentation, str)

removeanagrams!(words::Vector{String}) = unique!(getbitrepresentation, words)

function findpairs(words::Vector{String})
    pairs = Vector{Pair}()
    for i in eachindex(words)
        bits1 = getbitrepresentation(words[i])
        for j = (i+1):lastindex(words)
            bits2 = getbitrepresentation(words[j])
            if bits1 & bits2 == 0
                push!(pairs, Pair(i, j, bits1 | bits2))
            end
        end
    end
    return pairs
end

function findquartets(pairs::Vector{Pair})
    quartets = Vector{Quartet}()
    for i in eachindex(pairs)
        if i % 10_000 == 0
            println("$i, $(length(quartets))")
        end
        for j = (i+1):lastindex(pairs)
            if pairs[i].bitmask & pairs[j].bitmask == 0
                push!(quartets, combine(pairs[i], pairs[j]))
            end
        end
    end
    return unique!(q -> Set([q.index1, q.index2, q.index3, q.index4]), quartets)
end

function findanswers(quartets::Vector{Quartet}, words::Vector{String})
    answers = Vector{Answer}()
    for i in eachindex(quartets)
        if i % 100_000 == 0
            println("$i, $(length(answers))")
        end
        for j in eachindex(words)
            wordbits = getbitrepresentation(words[j])
            if quartets[i].bitmask & wordbits == 0
                push!(answers, combine(quartets[i], j))
            end
        end
    end
    return unique!(a -> Set([a.index1, a.index2, a.index3, a.index4, a.index5]), answers)
end

function saveanswers(path::AbstractString, answers::Vector{Answer}, words::Vector{String})
    s = ""
    for answer in answers
        s *= "$(words[answer.index1]), $(words[answer.index2]), $(words[answer.index3]), $(words[answer.index4]), $(words[answer.index5])\n"
    end
    open(path, "w") do f
        write(f, s)
    end
end

function main()
    words = readfromfile("words_alpha.txt")
    println("Read $(length(words)) words from file")
    filtervalidwords!(words)
    println("$(length(words)) words are five letters long and don't repeat letters")
    removeanagrams!(words)
    println("After removing anagrams, there are $(length(words)) words")
    pairs = findpairs(words)
    println("Found $(length(pairs)) pairs of words without matching letters")
    quartets = findquartets(pairs)
    println("Found $(length(quartets)) quartets of words without matching letters")
    answers = findanswers(quartets, words)
    println("Found $(length(answers)) valid answers")
    saveanswers("answer.txt", answers, words)
end
