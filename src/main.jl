using Graphs
using ThreadsX

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

function buildgraph(bits::Vector{UInt32})
    graph = SimpleDiGraph(length(bits))
    for (i, bits1) in enumerate(bits)
        @simd for j = (i+1):lastindex(bits)
            @inbounds bits2 = bits[j]
            if bits1 & bits2 == 0
                add_edge!(graph, i, j)
            end
        end
    end
    return graph
end

function findanswers(graph::SimpleDiGraph{Int}, bits::Vector{UInt32})
    all_answers = [Vector{NTuple{5,Int}}() for _ = 1:Threads.nthreads()]
    hasntworked = BitSet()
    u = Threads.SpinLock()
    Threads.@threads :dynamic for i in vertices(graph)
        tid = Threads.threadid()
        answers = all_answers[tid]
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
                        push!(answers, (i, j, k, l, m))
                        bits1worked = true
                        bitmask2worked = true
                        bitmask3worked = true
                        bitmask4worked = true
                    end
                    if !bitmask4worked
                        Threads.lock(u) do
                            push!(hasntworked, bitmask4)
                        end
                    end
                end
                if !bitmask3worked
                    Threads.lock(u) do
                        push!(hasntworked, bitmask3)
                    end
                end
            end
            if !bitmask2worked
                Threads.lock(u) do
                    push!(hasntworked, bitmask2)
                end
            end
        end
        if !bits1worked
            Threads.lock(u) do
                push!(hasntworked, bits1)
            end
        end
    end
    return reduce(vcat, all_answers)
end

function saveanswers(
    path::AbstractString,
    answers::Vector{NTuple{5,Int}},
    words::Vector{String},
)
    open(path, "w") do f
        for answer in answers
            println(
                f,
                "$(words[answer[1]]), $(words[answer[2]]), $(words[answer[3]]), $(words[answer[4]]), $(words[answer[5]])",
            )
        end
    end
end

function main()
    words = readfromfile("words_alpha.txt")
    println("Read $(length(words)) words from file")
    filtervalidwords!(words)
    println("$(length(words)) words are five letters long and don't repeat letters")
    removeanagrams!(words)
    println("After removing anagrams, there are $(length(words)) words")
    ThreadsX.sort!(words; by = lowestletterfrequency, rev = true)
    bits = ThreadsX.map(getbitrepresentation, words)
    graph = buildgraph(bits)
    println("Built graph with $(nv(graph)) vertices and $(ne(graph)) edges")
    answers = findanswers(graph, bits)
    println("Found $(length(answers)) valid answers")
    saveanswers("answer.txt", answers, words)
end
