using Graphs

const LETTERS = [
    'q',
    'x',
    'j',
    'z',
    'v',
    'f',
    'w',
    'b',
    'k',
    'g',
    'p',
    'm',
    'h',
    'd',
    'c',
    'y',
    't',
    'l',
    'n',
    'u',
    'r',
    'o',
    'i',
    's',
    'e',
    'a',
]

struct Answer
    index1::Int
    index2::Int
    index3::Int
    index4::Int
    index5::Int
end

function readfromfile(path::AbstractString)
    lines = open(path) do f
        readlines(f)
    end

    return lines
end

isvalidword(word::AbstractString) =
    return length(word) == 5 && count_ones(getbitrepresentation(word)) == 5

filtervalidwords!(words::Vector{String}) = filter!(isvalidword, words)

getbitrepresentation(c::Char) = one(UInt32) << (UInt8(c) - 0x61)

getbitrepresentation(str::AbstractString)::UInt32 = sum(getbitrepresentation, str)

removeanagrams!(words::Vector{String}) = unique!(getbitrepresentation, words)

lowestletterfrequency(str::AbstractString) =
    minimum(c -> findfirst(x -> x == c, LETTERS), str)

function buildgraph(words::Vector{String})
    graph = SimpleDiGraph(length(words))
    bits = [getbitrepresentation(word) for word in words]
    for i in eachindex(words)
        bits1 = bits[i]
        for j = (i+1):lastindex(words)
            bits2 = bits[j]
            if bits1 & bits2 == 0
                add_edge!(graph, i, j)
            end
        end
    end
    return graph
end

function findanswers(graph::SimpleDiGraph{Int}, words::Vector{String})
    bits = [getbitrepresentation(word) for word in words]
    all_answers = [Vector{Answer}() for _ in 1:Threads.nthreads()]
    all_hasntworked = [BitSet() for _ in 1:Threads.nthreads()]
    Threads.@threads for i in vertices(graph)
        tid = Threads.threadid()
        answers = all_answers[tid]
        hasntworked = all_hasntworked[tid]
        bits1 = bits[i]
        bits1worked = false
        if bits1 in hasntworked
            continue
        end
        for j in neighbors(graph, i)
            bits2 = bits[j]
            bitmask2 = bits1 | bits2
            bitmask2worked = false
            if bits1 & bits2 != 0 || bitmask2 in hasntworked
                continue
            end
            for k in neighbors(graph, j)
                bits3 = bits[k]
                bitmask3 = bitmask2 | bits3
                bitmask3worked = false
                if (bitmask2) & bits3 != 0 || bitmask3 in hasntworked
                    continue
                end
                for l in neighbors(graph, k)
                    bits4 = bits[l]
                    bitmask4 = bitmask3 | bits4
                    bitmask4worked = false
                    if (bitmask3) & bits4 != 0 || bitmask4 in hasntworked
                        continue
                    end
                    for m in neighbors(graph, l)
                        bits5 = bits[m]
                        if (bitmask4) & bits5 != 0
                            continue
                        end
                        push!(answers, Answer(i, j, k, l, m))
                        bits1worked = true
                        bitmask2worked = true
                        bitmask3worked = true
                        bitmask4worked = true
                    end
                    if !bitmask4worked
                        push!(hasntworked, bitmask4)
                    end
                end
                if !bitmask3worked
                    push!(hasntworked, bitmask3)
                end
            end
            if !bitmask2worked
                push!(hasntworked, bitmask2)
            end
        end
        if !bits1worked
            push!(hasntworked, bits1)
        end
    end
    return reduce(vcat, all_answers)
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
    sort!(words; by = lowestletterfrequency, rev = true)
    graph = buildgraph(words)
    println("Built graph with $(nv(graph)) vertices and $(ne(graph)) edges")
    answers = findanswers(graph, words)
    println("Found $(length(answers)) valid answers")
    saveanswers("answer.txt", answers, words)
end
