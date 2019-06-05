module CFG
"""
This will be the building block that trees are constructed
from
Rather than specifying that all nodes must have two daughters
(as would be required for most parser implementations), this utilizes 
an array of daughters so that the same structure can be used to represent flattened tree structures as well. 
"""
mutable struct Node
    root::Union{Node, Nothing}
    daughters::Array{Node}
end
Node(root=nothing, daughters=Array{Node}[]) = Node(root, daughters)

mutable struct EarleyState
    state_num::Int
    start_index::Int 
    end_index::Int
    right_hand::Array{String}
    left_hand::String
    dot_index::Int
    originating_state_index::Int
    
    function EarleyState(state_num::Int,
                        start_index::Int,
                        end_index::Int,
                        right_hand::Array{String},
                        left_hand::String,
                        dot_index::Int,
                        originating_state_index::Int)
        if dot_index > (length(right_hand) + 1)
            throw(BoundsError("Unable to declare a state with the given dot index"))
        elseif dot_index < 1
            throw(BoundsError("Unable to declare a state with the given dot index"))
        else
            new(state_num, 
                start_index, 
                end_index,
                right_hand, 
                left_hand, 
                dot_index,
                originating_state_index)
        end
    end
end

"""
Add keyword version of EarleyState
"""
function EarleyState(;state_num, start_index, end_index, right_hand, left_hand, dot_index, originating_state_index)
    EarleyState(state_num, start_index, end_index, right_hand, left_hand, dot_index, originating_state_index)
end

"""
Overload equality for EarleyStates
"""
function Base.:(==)(x::EarleyState, y::EarleyState)
    if x.state_num == y.state_num &&
        x.start_index == y.start_index &&
        x.end_index == y.end_index && 
        x.right_hand == y.right_hand && 
        x.left_hand == y.left_hand && 
        x.dot_index == y.dot_index && 
        x.originating_state_index == y.originating_state_index
        return true
    else
        return false
    end
end

"""
This is a simple uitlity to determine whether a rule is complete
(e.g. whether the dot has advanced all the way to the right)
"""
function is_incomplete(state::EarleyState)
    if state.dot_index < (length(state.right_hand) + 1)
        return true
    else 
        return false
    end
end

"""
This is a simple utility that returns the next next category 
(whether terminal or non-terminal), given the current dot location
"""
function next_cat(state::EarleyState)
    if is_incomplete(state)
        return state.right_hand[state.dot_index]
    else
        return "NFound"
    end
end

"""
This is the completer from Earley's algorithm as described in 
Jurafsky & Martin (2009). 

In essence, this takes a rule which has been completed and
moves the parse along for all the states that were waiting on the constituent
produced by this rule.

e.g. if I have S => * NP VP in my chart and I also have NP => D N *,
then I can move the dot across the NP
"""
function completer!(charts, i, productions::Dict, lexicon::Dict, state::EarleyState)
    obtained_constituent = state.left_hand
    next_state_num = charts[end][end].state_num + 1
    for chart in charts
        for old_state in chart
            # if the right hand side has the dot just before something that matches
            # the constituent that we just found,
            # then we should move the dot to the right in a new state
            if is_incomplete(old_state) && old_state.right_hand[old_state.dot_index] == obtained_constituent
                if old_state.end_index == state.start_index # may need to check this
                    new_state = EarleyState(next_state_num, old_state.start_index, 
                                            i, old_state.right_hand, old_state.left_hand,
                                            old_state.dot_index + 1, state.state_num)
                    push!(charts[i], new_state)
                end
            end
        end
    end 
end
function predictor!(charts, i, productions::Dict, lexicon::Dict, state::EarleyState)
    next_category = next_cat(state)
    right_hands = productions[next_category]
    next_state_num = charts[end][end].state_num + 1
    for right_hand in right_hands
        new_state = EarleyState(next_state_num,
                                i, i, right_hand, 
                                next_category, 1, 0) 
        # check on originating_state_index once I write completer
        push!(charts[i], new_state)
    end
end

function scanner!(charts, sent::Array{String}, i::Int, productions::Dict,
                    lexicon::Dict, state::EarleyState)
    next_category = next_cat(state)
    next_word = sent[state.end_index]
    next_state_num = charts[end][end].state_num + 1
    if next_category in lexicon[next_word]
        new_state = EarleyState(next_state_num, i, i+1, [next_word], next_category, 2, 0)
        chart = EarleyState[new_state]
        push!(charts, chart)
    end
end
    
function parse_earley(productions, lexicon, sent, start_symbol="S")
    parts_of_speech = unique(collect(Iterators.flatten(values(lexicon))))
    charts = []
    chart = EarleyState[]
    states = EarleyState[]
    push!(charts, chart)
    # add initial state
    push!(charts[1], EarleyState(1,1, 1, ["S"], "γ", 1, 0))
    for i=1:(length(sent) + 1)
        for state in charts[i]
            next_category = next_cat(state)
            if is_incomplete(state) && !(next_category in parts_of_speech)
                println("-" ^ 32)
                println("predictor")
                predictor!(charts, i, productions, lexicon, state)
                println(charts)
            elseif is_incomplete(state) && next_category in parts_of_speech 
                println("-" ^ 32)
                println("Scanner" * next_category)
                scanner!(charts, sent, i, productions, lexicon, state)
                println(charts)
            else
                println("-" ^ 32)
                println("Completer")
                println(charts)
                completer!(charts, i, productions, lexicon, state)
                println(charts)
            end
        end
    end
    return chart
end
"""
This function prints the lattice from its strange boolean format
"""
function print_lattice(lattice, non_terminals, tokens)
    n_rows, n_cols, n_non_terminals = size(lattice)
    tok_row = ""
    for token in tokens
        tok_row *= rpad(token, 6)
    end 
    println(tok_row)
    println("-" ^ (1 + n_cols * 6))
    for row = 1:n_rows
        row_string = "|"
        for col = 1:n_cols
            items = lattice[row, col, :]
            cell_pieces = non_terminals[items]
            cell = join(cell_pieces, ",")
            
            cell = rpad(cell, 5)
            cell = cell * "|"
            row_string = row_string * cell
        end
        println(row_string)
    end
    println("-" ^ (1 + n_cols * 6))
end
"""
This function parses a single sentence using the lexicon 
and production rules provided
"""
function parse_sent(productions, lexicon, sent)
    
end
function parse(productions, lexicon, text)
    # split sentences
    # call parse_sent on each sentence
    pass
end
"""
This function reads in a piece of text that contains various rules 
where the form of syntactic rules is X -> Y Z

and the form of lexical rules is V : X

todo: 
    - optionality using parenthesis
    - repetition using *
    - features
    
the lexicon returned takes in words and yields the part of speech 
candidates. the productions returned take in the left hand side of a rule
and return the right hand side.

These hash directions are ideal for the earley parsing algorithm
"""
function read_rules(rule_text)
    # each rule should be on a new line
    lines = split(rule_text, "\n", keepempty=false) 
    productions = Dict()#"null" => ["null"])
    lexicon = Dict()#"null" => ["null"]) # doing this as a cludge to 
    # get dictionaries initialized
    for line in lines
        if occursin(":", line)
            # we have a lexical rule
            pieces = split(line, ":")
            if length(pieces) != 2
                error("Multiple ':' symbols in input string")
            end
            left_hand = strip(pieces[1])
            right_hand = strip(pieces[2])
            # check to see if we have a multi-part right hand 
            if occursin("{", right_hand)
                tokens = split(right_hand, r"({|,|}) ?", keepempty=false)
                left_hand = strip(left_hand)
                for token in tokens
                    token = string(token)
                    if token in keys(lexicon)
                        lexicon[token] = push!(lexicon[token],
                                                    left_hand)
                    else
                        lexicon[token] = [left_hand]
                    end
                end
            else
                if right_hand in keys(lexicon)
                    lexicon[right_hand] = push!(lexicon[right_hand], left_hand)
                else
                    lexicon[right_hand] = [left_hand]
                end
            end
        elseif occursin("->", line)
            # we have a syntactic rule
            pieces = split(line, "->")
            if length(pieces) != 2
                error("Mutiple -> symbols in input string")
            end
            left_hand = strip(pieces[1])
            right_hand = strip(pieces[2])
            components = split(right_hand)
            components = [string(component) for component in components]
            # need to check if any of the components are optional 
            if left_hand in keys(productions)
                push!(productions[left_hand], Tuple(components))
            else
                productions[left_hand] = [Tuple(components)]
            end
        else
            println(line)
            error("Incorrect line format")
        end
    end
    return productions, lexicon
end
"""
This function creates binary rules from the flat rules presented
e.g. if we have an input rule `NP -> D Adj N` then this will 
create two rules:
    - NPbar -> Adj N
    - NP -> D NPbar
    
If a unary rule is found (e..g NP -> D) then it will first try to 
substitute out the intermediate e.g. if D pointed to a word, then the
NP would go to the word
"""
function binarize!(productions, lexicon)
    revised_prod = Dict()
    pairings = 0
    for rhs in keys(productions)
        lhs = productions[rhs]
        if length(rhs) > 2
            rhs_mod = rhs
            while length(rhs_mod) > 2
                lhsbar = lhs * "bar"
            end
        elseif length(rhs) == 1
            for word in keys(lexicon)
                poss_pos = lexicon[word]
                if rhs[1] in poss_pos
                    sub_ind = findfirst(x -> x == rhs[1], poss_pos)
                    lexicon[word][sub_ind] = lhs
                end
            end
            for input_tup in keys(productions)
                productions[input_tup] = lhs
                delete!(productions, rhs)
            end
        else
            continue
        end
    end
    return productions, lexicon, pairings
end
"""
This function checks to make sure that the set of rules are compatible. 

In essence, it is checking to see that there are no symbols that occur on the right hand side that
are nowhere on the left hand side

the following is an incompatible set: 

    NP => D N
    N : {dog, mouse}
    
because of the lack of specification for D in any of the lexical rules
"""
function verify_system(productions, lexicon)::Bool
    prod_items = collect(Iterators.flatten(values(productions)))
    prod_items = unique(prod_items)
    lex_items = collect(Iterators.flatten(values(lexicon)))
    lex_items = unique(lex_items)
    for item in prod_items
        if !haskey(productions, item) && !(item in lex_items)
            return false
        else 
            return true
        end
    end
end
end # module


