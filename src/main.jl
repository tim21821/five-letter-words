using Graphs

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

isvalidword(word::AbstractString) = return length(word) == 5 && length(Set(word)) == 5

filtervalidwords!(words::Vector{String}) = filter!(isvalidword, words)

getbitrepresentation(c::Char) = one(UInt32) << (UInt8(c) - 0x61)

getbitrepresentation(str::AbstractString)::UInt32 = sum(getbitrepresentation, str)

removeanagrams!(words::Vector{String}) = unique!(getbitrepresentation, words)

function buildgraph(words::Vector{String})
    graph = SimpleDiGraph(length(words))
    for i in eachindex(words)
        bits1 = getbitrepresentation(words[i])
        for j = (i+1):lastindex(words)
            bits2 = getbitrepresentation(words[j])
            if bits1 & bits2 == 0
                add_edge!(graph, i, j)
            end
        end
    end
    return graph
end

function findanswers(graph::SimpleDiGraph{Int}, words::Vector{String})
    answers = Vector{Answer}()
    for i in vertices(graph)
        bits1 = getbitrepresentation(words[i])
        for j in neighbors(graph, i)
            bits2 = getbitrepresentation(words[j])
            if bits1 & bits2 == 0
                for k in neighbors(graph, j)
                    bits3 = getbitrepresentation(words[k])
                    if (bits1 | bits2) & bits3 == 0
                        for l in neighbors(graph, k)
                            bits4 = getbitrepresentation(words[l])
                            if (bits1 | bits2 | bits3) & bits4 == 0
                                for m in neighbors(graph, l)
                                    bits5 = getbitrepresentation(words[m])
                                    if (bits1 | bits2 | bits3 | bits4) & bits5 == 0
                                        push!(answers, Answer(i, j, k, l, m))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return answers
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
    graph = buildgraph(words)
    println("Built graph with $(nv(graph)) vertices and $(ne(graph)) edges")
    answers = findanswers(graph, words)
    println("Found $(length(answers)) valid answers")
    saveanswers("answer.txt", answers, words)
end
