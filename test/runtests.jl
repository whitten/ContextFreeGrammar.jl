using Test
using AbstractTrees
using ContextFreeGrammar
function sort_val_list(input_dict::Dict)
    """
    This is a little function to sort the list values of a dictionary.
    """
    for key in keys(input_dict)
        input_dict[key] = sort(input_dict[key])
    end
end
@testset "rule_reading" begin
    simple_rules = """
      NP -> D N
      D : dog
      """
    productions, lexicon = read_rules(simple_rules)
    res_productions = Dict("NP" => [["D", "N"]])
    res_lexicon = Dict("dog" => ["D"])
    @test res_productions == productions
    @test res_lexicon == lexicon
    multi_part_lexicon = """
      NP -> Q N
      D : {dog, cat, mouse}
      """
    productions, lexicon = read_rules(multi_part_lexicon)
    res_productions = Dict("NP" => [["Q", "N"]])
    res_lexicon = Dict("dog" => ["D"], "cat" => ["D"], "mouse" => ["D"])
    @test res_lexicon == lexicon
    @test res_productions == productions
    ambiguous_lexicon = """
      D : dog
      V : dog
      """
    res_lexicon = Dict("dog" => ["D", "V"])
    productions, lexicon = read_rules(ambiguous_lexicon)
    @test lexicon == res_lexicon
    ambiguous_production = """
                               NP -> D N
                               NP -> Adj N
                               """
    productions, lexicon = read_rules(ambiguous_production)
    res_productions = Dict("NP" => [["D", "N"], ["Adj", "N"]])
    @test productions == res_productions
    @testset "repetition" begin
        rule_w_repetition = """NP -> AP+ N"""
        productions, lexicon = read_rules(rule_w_repetition)
        expected_productions = Dict("NP" => [["AP", "N"],
                                             ["AP", "AP", "N"],
                                             ["AP", "AP", "AP", "N"],
                                             ["AP", "AP", "AP", "AP", "N"],
                                             ["AP", "AP", "AP", "AP", "AP", "N"],
                                             ["AP", "AP", "AP", "AP", "AP", "AP", "N"]])
        @test productions == expected_productions
        rule_w_repetition2 = """NP -> D AP+ N"""
        productions, lexicon = read_rules(rule_w_repetition2)
        expected_productions = Dict("NP" => [["D", "AP", "N"],
                                             ["D", "AP", "AP", "N"],
                                             ["D", "AP", "AP", "AP", "N"],
                                             ["D", "AP", "AP", "AP", "AP", "N"],
                                             ["D", "AP", "AP", "AP", "AP", "AP", "N"],
                                             ["D", "AP", "AP", "AP", "AP", "AP", "AP", "N"]])
        @test productions == expected_productions
        complex_ruleset = """S -> NP VP 
                            NP -> D AP+ N 
                            VP -> V 
                            AP -> A
                            A : wonderful
                            A : brown
                            A : adorable
                            N : dog
                            D : the
                            V: ran
                            """
        productions, lexicon = read_rules(complex_ruleset)
        expected_productions = Dict("NP" => [["D", "AP", "N"],
                                             ["D", "AP", "AP", "N"],
                                             ["D", "AP", "AP", "AP", "N"],
                                             ["D", "AP", "AP", "AP", "AP", "N"],
                                             ["D", "AP", "AP", "AP", "AP", "AP", "N"],
                                             ["D", "AP", "AP", "AP", "AP", "AP", "AP", "N"]],
                                    "AP" => [["A"]],
                                    "S" => [["NP", "VP"]],
                                    "VP" => [["V"]]
                                    )
        @test productions == expected_productions
    end
    @testset "optionality" begin
        rule_w_optionality = """NP -> (D) N"""
        productions, lexicon = read_rules(rule_w_optionality)
        res_productions = Dict("NP" => [["N"], ["D","N"]])
        @test productions == res_productions
        rule_w_multi_optionality = """NP -> (D) (Adj) N"""
        productions, lexicon = read_rules(rule_w_multi_optionality)
        res_productions = Dict("NP" => [["N"], ["D", "N"], ["Adj", "N"], ["D", "Adj", "N"]])
        @test productions == res_productions
        rule_w_opt_both_sides = """NP -> (D) (Adj) N (SC)"""
        productions, lexicon = read_rules(rule_w_opt_both_sides)
        res_productions = Dict("NP" => [
                                        ["N"], 
                                        ["D", "N"], 
                                        ["Adj", "N"], 
                                        ["D", "Adj", "N"], 
                                        ["N", "SC"], 
                                        ["D", "N", "SC"], 
                                        ["Adj", "N", "SC"], 
                                        ["D", "Adj", "N", "SC"]
                                        ])
                                        
        @test productions == res_productions
        problematic_ruleset = """
                                S -> NP VP
                                NP -> (D) (AP) N (PP)
                                PP -> P NP
                                AP -> (AdvP) A
                                AdvP -> (AdvP) Adv
                                VP -> V
                                VP -> V NP
                                VP -> V NP NP
                                VP -> V NP PP

                                A : tired
                                N : dog
                                V : ran
                                D : the
                                P : on
                                Adv : extremely
                              """
        res_productions = Dict( "S" => [
                                        ["NP", "VP"]],
                                "PP" => [
                                            ["P",
                                            "NP"]
                                        ],
                                "AP" => [
                                            ["A"],
                                            ["AdvP", "A"]
                                        ],
                                "AdvP" => [
                                            ["Adv"],
                                            ["AdvP", "Adv"]
                                ],
                                "VP" => [
                                            ["V"],
                                            ["V", "NP"],
                                            ["V", "NP", "NP"],
                                            ["V", "NP", "PP"]
                                ],
                                "NP" => [
                                        ["N"], 
                                        ["D", "N"], 
                                        ["Adj", "N"], 
                                        ["D", "Adj", "N"], 
                                        ["N", "PP"], 
                                        ["D", "N", "PP"], 
                                        ["Adj", "N", "PP"], 
                                        ["D", "Adj", "N", "PP"]
                                        ])
        productions, lexicon = read_rules(problematic_ruleset)
        productions = sort_val_list(productions)
        res_productions = sort_val_list(res_productions)
        @test productions == res_productions
    end
    @testset "syntactic_choices" begin
        rule_w_syntactic_options = """NP -> Q N | D N"""
        productions, lexicon = read_rules(rule_w_syntactic_options)
        res_productions = Dict("NP" => [["Q", "N"], ["D", "N"]])
        @test productions == res_productions
    end
end

@testset "rule_verify" begin
    productions = Dict("NP" => [["D", "N"]], "VP" => [["V", "NP"]])
    lexicon = Dict("dog" => ["N", "V"], "the" => ["D"])
    sent = ["the", "dog"]
    @test verify_productions(productions, lexicon) == true
    productions = Dict("NP" => [["D", "N"]], "VP" => [["V", "NP"]])
    lexicon = Dict("dog" => ["N", "V"])
    one_word_sent = ["dog"]
    @test verify_productions(productions, lexicon) == false
    lexicon = Dict("dog" => ["N", "D", "V"])
    @test verify_lexicon(lexicon, one_word_sent) == true
    @test verify_lexicon(lexicon, sent) == false
    # testing with phrases because that seems to cause an error 
    productions = Dict("S" => [["NP", "VP"]], "NP" => [["D", "N"]], "VP" => [["V", "NP"]])
    @testset "single_level_recursion" begin
        """
        This was a test that was causing errors for one of Hai's students
        """
        rules = """
                Noun: {dog, cat}
                Det: {the}
                NP -> Det Noun
                S -> NP VP

                Aux.prog: {is, been, be}
                V.trans.ing: {seeing}
                VP.ing -> Aux.prog V.trans.ing
                VP -> VP.ing (NP)
                VP -> VP.ing NP VP
                """
        productions, lexicon = read_rules(rules)
        @test verify_productions(productions, lexicon) == true
    end
end

@testset "earley_pieces" begin
    lexicon = Dict("dog" => ["V", "N"], "cat" => ["N", "Adj"])
    parts_of_speech = ["V", "N", "Adj"]
    @test sort(parts_of_speech) == sort(unique(collect(Iterators.flatten(values(lexicon)))))
    @testset "EarleyState" begin
        @testset "ordered_constructor" begin
            sample_state =
                ContextFreeGrammar.EarleyState(1, 2, 3, ["NP", "VP"], "S", 1, [3])
            @test sample_state.state_num == 1
            @test sample_state.start_index == 2
            @test sample_state.end_index == 3
            @test sample_state.right_hand == ["NP", "VP"]
            @test sample_state.left_hand == "S"
            @test sample_state.dot_index == 1
            @test sample_state.originating_states == [3]
            @test !(ContextFreeGrammar.is_spanning(sample_state, 4))
            spanning_state =
                ContextFreeGrammar.EarleyState(1, 1, 3, ["NP", "VP"], "S", 1, [3])
            @test ContextFreeGrammar.is_spanning(spanning_state, 2)
        end
        @testset "malformed_construction" begin
            @test_throws BoundsError ContextFreeGrammar.EarleyState(
                1,
                2,
                3,
                ["NP", "VP"],
                "S",
                4,
                [3],
            )
            @test_throws BoundsError ContextFreeGrammar.EarleyState(
                1,
                2,
                3,
                ["NP", "VP"],
                "S",
                0,
                [3],
            )
            @test ContextFreeGrammar.EarleyState(
                1,
                2,
                3,
                ["NP", "VP"],
                "S",
                3,
                [3],
            ).dot_index == 3
        end
        @testset "state_utils" begin
            initial_state = ContextFreeGrammar.EarleyState(1, 1, 1, ["S"], "γ", 1, [])
            @test ContextFreeGrammar.next_cat(initial_state) == "S"
            initial_state = ContextFreeGrammar.EarleyState(1, 1, 1, ["S"], "γ", 1, [])
            @test ContextFreeGrammar.is_incomplete(initial_state) == true
            complete_state = ContextFreeGrammar.EarleyState(1, 1, 1, ["S"], "γ", 2, [])
            @test ContextFreeGrammar.is_incomplete(complete_state) == false
        end
    end
    @testset "predictor" begin
        chart = ContextFreeGrammar.EarleyState[]
        initial_state = ContextFreeGrammar.EarleyState(1, 1, 1, ["S"], "γ", 1, [])
        push!(chart, initial_state)
        lexicon = Dict("dog" => ["N", "V"], "cat" => ["N", "Adj"])
        productions = Dict("S" => [["NP", "VP"]], "NP" => [["N"]], "VP" => [["V"]])
        step_index = 1
        charts = [chart, ContextFreeGrammar.EarleyState[]]
        ContextFreeGrammar.predictor!(
            charts,
            step_index,
            productions,
            lexicon,
            initial_state,
        )
        @test length(charts[1]) == 2
        state_res = ContextFreeGrammar.EarleyState(2, 1, 1, ["NP", "VP"], "S", 1, [])
        @test charts[1][2] == state_res
        ambiguous_productions = Dict("S" => [["CP", "VP"], ["VP"]])
        step_index = 1
        chart = ContextFreeGrammar.EarleyState[]
        push!(chart, initial_state)
        charts = [chart, ContextFreeGrammar.EarleyState[]]
        ContextFreeGrammar.predictor!(
            charts,
            step_index,
            ambiguous_productions,
            lexicon,
            initial_state,
        )
        @test length(charts[1]) == 3
    end
    @testset "scanner" begin
        @testset "no_change" begin
            chart = ContextFreeGrammar.EarleyState[]
            initial_state = ContextFreeGrammar.EarleyState(1, 1, 1, ["S"], "γ", 1, [])
            push!(chart, initial_state)
            lexicon = Dict("dog" => ["N", "V"], "the" => ["D"], "ran" => ["V"])
            productions = Dict(
                "S" => [["NP", "VP"], ["VP"]],
                "NP" => [["D", "N"], ["N"]],
                "VP" => [["VP"], ["VP", "NP"]],
            )
            state = ContextFreeGrammar.EarleyState(2, 1, 1, ["NP", "VP"], "S", 1, []) # predictor applied
            push!(chart, state)
            state = ContextFreeGrammar.EarleyState(3, 1, 1, ["VP"], "S", 1, []) # predictor applied
            push!(chart, state)
            scan_state = ContextFreeGrammar.EarleyState(4, 1, 1, ["D", "N"], "NP", 1, []) # predictor applied
            push!(chart, scan_state)
            state = ContextFreeGrammar.EarleyState(5, 1, 1, ["N"], "NP", 1, []) # predictor applied
            push!(chart, state)
            step_index = 1
            charts =
                [chart, ContextFreeGrammar.EarleyState[], ContextFreeGrammar.EarleyState[]]
            @test length(charts) == 3
            @test length(charts[1]) == 5
            sentence = ["the", "dog", "ran"]
            ContextFreeGrammar.scanner!(
                charts,
                sentence,
                step_index,
                productions,
                lexicon,
                state,
            ) # this should not change anything
            @test length(charts) == 3
            @test length(charts[1]) == 5
        end
        @testset "scan_applies" begin
            chart = ContextFreeGrammar.EarleyState[]
            initial_state = ContextFreeGrammar.EarleyState(1, 1, 1, ["S"], "γ", 1, [0])
            push!(chart, initial_state)
            lexicon = Dict("dog" => ["N", "V"], "the" => ["D"], "ran" => ["V"])
            productions = Dict(
                "S" => [["NP", "VP"], ["VP"]],
                "NP" => [["D", "N"], ["N"]],
                "VP" => [["VP"], ["VP", "NP"]],
            )
            state = ContextFreeGrammar.EarleyState(2, 1, 1, ["NP", "VP"], "S", 1, [])
            push!(chart, state)
            state = ContextFreeGrammar.EarleyState(3, 1, 1, ["VP"], "S", 1, [])
            push!(chart, state)
            scan_state = ContextFreeGrammar.EarleyState(4, 1, 1, ["D", "N"], "NP", 1, [])
            push!(chart, scan_state)
            state = ContextFreeGrammar.EarleyState(5, 1, 1, ["N"], "NP", 1, [])
            push!(chart, state)
            step_index = 1
            charts =
                [chart, ContextFreeGrammar.EarleyState[], ContextFreeGrammar.EarleyState[]]
            @test length(charts[1]) == 5
            @test length(charts) == 3
            sentence = ["the", "dog", "ran"]
            ContextFreeGrammar.scanner!(
                charts,
                sentence,
                step_index,
                productions,
                lexicon,
                scan_state,
            ) # this should not change anything
            @test length(charts[2]) == 1
            target_state = ContextFreeGrammar.EarleyState(6, 1, 2, ["the"], "D", 2, []) # come back to that last part
            @test charts[2][1] == target_state
        end
    end
    @testset "completer" begin
        chart = ContextFreeGrammar.EarleyState[]
        initial_state = ContextFreeGrammar.EarleyState(1, 1, 1, ["S"], "γ", 1, [])
        push!(chart, initial_state)
        lexicon = Dict("dog" => ["N", "V"], "the" => ["D"], "ran" => ["V"])
        productions = Dict(
            "S" => [["NP", "VP"], ["VP"]],
            "NP" => [["D", "N"], ["N"]],
            "VP" => [["VP"], ["VP", "NP"]],
        )
        state = ContextFreeGrammar.EarleyState(2, 1, 1, ["NP", "VP"], "S", 1, []) # predictor applied
        push!(chart, state)
        state = ContextFreeGrammar.EarleyState(3, 1, 1, ["VP"], "S", 1, []) # predictor applied
        push!(chart, state)
        scan_state = ContextFreeGrammar.EarleyState(4, 1, 1, ["D", "N"], "NP", 1, []) # predictor applied
        push!(chart, scan_state)
        state = ContextFreeGrammar.EarleyState(5, 1, 1, ["N"], "NP", 1, []) # predictor applied
        push!(chart, state)
        state = ContextFreeGrammar.EarleyState(6, 1, 2, ["N"], "NP", 2, []) # scanner applied
        chart2 = [state]
        charts = [chart, chart2, ContextFreeGrammar.EarleyState[]]
        step_index = 2
        ContextFreeGrammar.completer!(charts, step_index, productions, lexicon, state)
        res_state = ContextFreeGrammar.EarleyState(7, 1, 2, ["NP", "VP"], "S", 2, [6])
        @test length(charts[2]) == 2
        @test res_state == charts[2][end]
    end
end
@testset "earley" begin
    sentence = ["the", "dog", "runs"]
    productions = Dict(
        "S" => [["VP"], ["NP", "VP"]],
        "NP" => [["D", "N"], ["N"]],
        "VP" => [["V"], ["V", "NP"]],
    )
    lexicon = Dict("the" => ["D"], "dog" => ["N", "V"], "runs" => ["V", "N"])
    chart = parse_earley(productions, lexicon, sentence, debug = false)
    @test length(chart) > 1
    @test chart_recognize(chart)
    trees = chart_to_tree(chart, sentence)
    @test trees[1] == ["S", ["NP", ["D", ["the"]], ["N", ["dog"]]], ["VP", ["V", ["runs"]]]]
    @test collect(Leaves(trees[1])) ==
          ["S", "NP", "D", "the", "N", "dog", "VP", "V", "runs"]
    sentence2 = ["I", "bought", "fireworks", "in", "Pennsylvania"]
    productions = Dict(
        "S" => [["NP", "VP"]],
        "NP" => [["N"]],
        "VP" => [["V"], ["V", "NP"], ["V", "NP", "PP"]],
        "PP" => [["P", "NP"]],
    )
    lexicon = Dict(
        "I" => ["N"],
        "bought" => ["V"],
        "fireworks" => ["N"],
        "in" => ["P"],
        "Pennsylvania" => ["N"],
    )
    chart = parse_earley(productions, lexicon, sentence2, debug = false)
    trees = chart_to_tree(chart, sentence2)
    target_tree = [
        "S",
        ["NP", ["N", ["I"]]],
        [
            "VP",
            ["V", ["bought"]],
            ["NP", ["N", ["fireworks"]]],
            ["PP", ["P", ["in"]], ["NP", ["N", ["Pennsylvania"]]]],
        ],
    ]
    @test target_tree == trees[1]
    sentence = ["the", "large", "dog", "ran", "by", "the", "house"]
    lexicon = Dict(
        "the" => ["D"],
        "ran" => ["V"],
        "house" => ["N"],
        "dog" => ["N"],
        "red" => ["Adj"],
        "large" => ["Adj"],
        "to" => ["P"],
        "in" => ["P"],
        "by" => ["P"],
    )
    productions = Dict(
        "S" => [["NP", "VP"]],
        "VP" => [["V"], ["V", "PP"], ["V", "P", "PP"]],
        "NP" => [["D", "N"], ["N"], ["Adj", "N"], ["D", "Adj", "N"]],
        "PP" => [["P", "NP"]],
    )
    chart = parse_earley(productions, lexicon, sentence, debug = false)
    trees = chart_to_tree(chart, sentence)
    target_tree = [
        "S",
        ["NP", ["D", ["the"]], ["Adj", ["large"]], ["N", ["dog"]]],
        [
            "VP",
            ["V", ["ran"]],
            ["PP", ["P", ["by"]], ["NP", ["D", ["the"]], ["N", ["house"]]]],
        ],
    ]
    @test target_tree == trees[1]
    @testset "optionality" begin
        sentence = ["the", "large", "dog", "ran", "by", "the", "house"]
        lexicon = Dict(
            "the" => ["D"],
            "ran" => ["V"],
            "house" => ["N"],
            "dog" => ["N"],
            "red" => ["Adj"],
            "large" => ["Adj"],
            "to" => ["P"],
            "in" => ["P"],
            "by" => ["P"],
        )
        productions = Dict(
            "S" => [["NP", "VP"]],
            "VP" => [["V", "P", "PP"], ["V", "P"], ["V", "PP"], ["V"]],
            "NP" => [["D", "N"], ["N"], ["Adj", "N"], ["D", "Adj", "N"]],
            "PP" => [["P", "NP"]],
        )
        chart = parse_earley(productions, lexicon, sentence, debug = false)
        trees = chart_to_tree(chart, sentence)
        target_tree = [
            "S",
            ["NP", ["D", ["the"]], ["Adj", ["large"]], ["N", ["dog"]]],
            [
                "VP",
                ["V", ["ran"]],
                ["PP", ["P", ["by"]], ["NP", ["D", ["the"]], ["N", ["house"]]]],
            ],
        ]
        productions = Dict(
            "S" => [["NP", "VP"]],
            "NP" => [
                ["Det", "N.sg"],
                ["Det", "N.pl"],
                ["Det", "N.sg", "PP"],
                ["Det", "N.pl", "PP"],
                ["Det", "Adj", "N.sg"],
                ["Det", "Adj", "N.pl"],
                ["N.pl"],
                ["Det", "N.sg"],
                ["Det", "Adj", "N.sg"],
                ["Det", "N.sg", "PP"],
                ["Det", "Adj", "N.sg", "PP"],
                ["N.pl"],
                ["Det", "N.pl"],
                ["Adj", "N.pl"],
                ["Det", "Adj", "N.pl"],
                ["N.pl", "PP"],
                ["Det", "N.pl", "PP"],
                ["Adj", "N.pl", "PP"],
                ["Det", "Adj", "N.pl", "PP"],
            ],
            "PP" => [["P", "NP"]],
            "VP" => [
                ["V.trans", "S"],
                ["V.trans", "NP", "NP"],
                ["V.intrans"],
                ["V.trans", "NP"],
                ["V.stative", "Adj"],
                ["V.attrib", "NP", "Adj"],
                ["V.inf", "INF", "V.intrans.bare", "NP"],
                ["V.inf", "INF", "V.intrans.bare", "PP"],
                ["V.inf", "INF", "VP"],
                ["V.clausal.bare", "NP", "V.trans", "NP"],
                ["V.attrib.bare", "NP", "Adj"],
                ["Aux.prog", "V.trans.ing", "PP"],
                ["Aux.prog", "V.trans.ing", "NP"],
                ["Aux.prog", "VP"],
                ["V.attrib.ing", "NP", "Adj"],
                ["Aux.prog", "V.attrib.ing", "NP"],
                ["Aux.prog", "V.clausal.ing", "NP", "V.trans", "NP"],
                ["Aux.perf", "V.trans.ed", "PP"],
                ["Aux.perf", "V.trans.ed", "NP"],
                ["Aux.perf", "VP"],
                ["V.attrib.ed", "NP", "Adj"],
                ["Aux.perf", "V.clausal.ed", "S"],
                ["Aux.perf", "Perf.prog", "V.trans.ing"],
                ["VP", "PP"],
                ["Aux.perf", "Perf.prog", "V.trans.ing", "NP"],
                ["VP", "NP"],
                ["Aux.perf", "Perf.prog", "V.intrans.ing"],
                ["VP"],
            ],
        )
        lexicon = Dict(
            "woman" => ["N.sg"],
            "women" => ["N.pl"],
            "guitar" => ["N.sg"],
            "seen" => ["V.trans.ed"],
            "short" => ["Adj"],
            "thinks" => ["V.trans", "V.clausal"],
            "big" => ["Adj"],
            "a" => ["Det"],
            "thinking" => ["V.trans.ing", "V.clausal.ing"],
            "looked" => ["V.trans.ed"],
            "plumbers" => ["N.pl"],
            "yellow" => ["Adj"],
            "this" => ["Det"],
            "throws" => ["V.trans", "V.ditrans"],
            "eat" => ["V.trans.bare", "V.intrans.bare"],
            "massive" => ["Adj"],
            "look" => SubString{String}["V.intrans.bare", "V.stative.bare"],
            "under" => SubString{String}["P"],
            "called" => SubString{String}["V.attrib.ed"],
            "sleep" => SubString{String}["V.intrans.bare"],
            "the" => SubString{String}["Det"],
            "laughing" => SubString{String}["V.intrans.ing"],
            "talks" => SubString{String}["V.intrans"],
            "stone" => SubString{String}["N.sg"],
            "calls" => SubString{String}["V.attrib"],
            "house" => SubString{String}["N.sg"],
            "sleeps" => SubString{String}["V.intrans"],
            "talk" => SubString{String}["V.intrans.bare"],
            "compliments" => SubString{String}["V.trans"],
            "pulls" => SubString{String}["V.trans"],
            "pull" => SubString{String}["V.trans.bare"],
            "grab" => SubString{String}["V.trans.bare"],
            "plumber" => SubString{String}["N.sg"],
            "many" => SubString{String}["Det"],
            "that" => SubString{String}["Det"],
            "buy" => SubString{String}["V.trans.bare"],
            "three" => SubString{String}["Adj"],
            "cats" => SubString{String}["N.pl"],
            "runs" => SubString{String}["V.trans", "V.intrans"],
            "seems" => SubString{String}["V.stative"],
            "to" => SubString{String}["INF"],
            "sees" => SubString{String}["V.trans", "V.intrans"],
            "laugh" => SubString{String}["V.intrans.bare"],
            "dogs" => SubString{String}["N.pl"],
            "call" => SubString{String}["V.attrib.bare"],
            "is" => SubString{String}["V.stative", "Aux.prog"],
            "pushes" => SubString{String}["V.trans"],
            "looking" => SubString{String}["V.trans.ing"],
            "calling" => SubString{String}["V.attrib.ing"],
            "throw" => SubString{String}["V.ditrans.bare"],
            "looks" => SubString{String}["V.intrans", "V.stative"],
            "hill" => SubString{String}["N.sg"],
            "in" => SubString{String}["P"],
            "wants" => SubString{String}["V.inf"],
            "has" => SubString{String}["Aux.perf"],
            "push" => SubString{String}["V.trans.bare"],
            "buys" => SubString{String}["V.trans"],
            "dog" => SubString{String}["N.sg"],
            "catches" => SubString{String}["V.trans"],
            "cat" => SubString{String}["N.sg"],
            "foot" => SubString{String}["N.sg"],
            "on" => SubString{String}["P"],
            "run" => SubString{String}["V.trans.bare", "V.intrans.bare"],
            "see" => SubString{String}["V.trans.bare", "V.intrans.bare"],
            "eats" => SubString{String}["V.trans", "V.intrans"],
            "thought" => SubString{String}["V.clausal.ed"],
            "pasted" => SubString{String}["V.trans.ed"],
            "bought" => SubString{String}["V.trans.ed"],
            "seeing" => SubString{String}["V.trans.ing"],
            "think" => SubString{String}["V.clausal.bare"],
            "been" => SubString{String}["Perf.prog"],
            "laughs" => SubString{String}["V.intrans"],
            "grabs" => SubString{String}["V.trans"],
            "compliment" => SubString{String}["V.trans.bare"],
            "catch" => SubString{String}["V.trans.bare"],
        )
        sentence = ["the", "cat", "has", "been", "looking", "in", "the", "house"]
        chart = parse_earley(productions, lexicon, sentence, debug = false)
        trees = chart_to_tree(chart, sentence)
        #target_tree = [
        #    "S",
        #    ["NP", ["D", ["the"]], ["Adj", ["large"]], ["N", ["dog"]]],
        #    [
        #        "VP",
        #        ["V", ["ran"]],
        #        ["PP", ["P", ["by"]], ["NP", ["D", ["the"]], ["N", ["house"]]]],
        #    ],
        #]
        @test length(trees) != 0 
        @testset "rule_construction_optional_components" begin
            # test generation of rules in cases of multiple optionality
            two_opt_components = ["(D)", "N", "(PP)"]
            target_rhs = sort([["D", "N"], ["D", "N", "PP"], ["N"], ["N", "PP"]])
            res_rhs = sort(ContextFreeGrammar.gen_opt_poss(two_opt_components))
            @test res_rhs == target_rhs
            three_opt_components = ["(D)", "(Adj)", "N", "(PP)"]
            target_rhs = sort([
                ["D", "Adj", "N", "PP"],
                ["D", "Adj", "N"],
                ["D", "N"],
                ["D", "N", "PP"],
                ["N"],
                ["Adj", "N", "PP"],
                ["Adj", "N"],
                ["N", "PP"],
            ])
            res_rhs = sort(ContextFreeGrammar.gen_opt_poss(three_opt_components))
            @test res_rhs == target_rhs
        end
        problematic_ruleset = """
        S -> NP VP
        NP -> (D) (AP) N (PP)
        PP -> P NP
        AP -> (AdvP) A
        AdvP -> (AdvP) Adv
        VP -> V
        VP -> V NP
        VP -> V NP NP
        VP -> V NP PP

        A : tired
        N : dog
        V : ran
        D : the
        P : on
        Adv : extremely
        """
        sentence = ["the", "tired", "dog", "ran"]
        productions, lexicon = read_rules(problematic_ruleset)
        chart = parse_earley(productions, lexicon, sentence)
        trees = chart_to_tree(chart, sentence)
        @test length(trees) != 0
    end
end
@testset "drawing_utils" begin
    parse_tree = [
        "S",
        ["NP", ["I"]],
        ["VP", ["V", ["fireworks"]]],
        ["PP", ["P", ["in"]], ["NP", ["N", ["Pennsylvania"]]]],
    ]
    depth = 4
    @test get_depth(parse_tree) == depth
    @testset "tree_shifting" begin
        point_tree = [
            ContextFreeGrammar.TreePoint(1, 4, 0, 2),
            [
                ContextFreeGrammar.TreePoint(0, 2, 0, 0),
                ContextFreeGrammar.TreePoint(1, 2, 1, 2),
            ],
        ]
        shifted_tree = [
            ContextFreeGrammar.TreePoint(3, 4, 2, 4),
            [
                ContextFreeGrammar.TreePoint(2, 2, 2, 2),
                ContextFreeGrammar.TreePoint(3, 2, 3, 4),
            ],
        ]
        ContextFreeGrammar.shift_tree(point_tree, 2)
        @test point_tree == shifted_tree
        point_tree = [
            ContextFreeGrammar.TreePoint(1, 4, 0, 2),
            [
                ContextFreeGrammar.TreePoint(0, 2, 0, 0),
                ContextFreeGrammar.TreePoint(1, 2, 1, 2),
            ],
        ]
        neg_shifted_tree = [
            ContextFreeGrammar.TreePoint(-1, 4, -2, 0),
            [
                ContextFreeGrammar.TreePoint(-2, 2, -2, -2),
                ContextFreeGrammar.TreePoint(-1, 2, -1, 0),
            ],
        ]
        ContextFreeGrammar.shift_tree(point_tree, -2)
        @test point_tree == neg_shifted_tree
    end
end
@testset "file_draw" begin
    lexicon = Dict(
        "dog" => ["N", "V"],
        "the" => ["D"],
        "ran" => ["V"],
        "by" => ["P"],
        "my" => ["D"],
        "house" => ["N"],
        "houses" => ["N"],
    )
    productions = Dict(
        "S" => [["NP", "VP"], ["VP"]],
        "NP" => [["D", "N"], ["N"]],
        "VP" => [["V"], ["V", "NP"], ["V", "NP", "PP"]],
        "PP" => [["D", "NP"]],
    )
    sent = generate(productions, lexicon)
    z = [
        "S",
        ["NP", ["D", ["the"]], ["Adj", ["adventurous"]], ["N", ["dog"]]],
        ["VP", ["V", ["eats"]], ["NP", ["N", ["bacon"]], ["N", ["grease"]]]],
    ]
    tree_img(z, "testfile.png")
    @test filesize("testfile.png") > 0
end