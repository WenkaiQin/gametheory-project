using gametheory_project
using Test: @testset, @test
using Random: seed!

seed!(0)

@testset "GridBoardTests" begin
    @testset "CheckBoardClassification" begin
        @testset "OutOfBounds" begin
            p1_moves = [GridMove(-1, -1)]
            p2_moves = [GridMove(20, 20)]
            b = GridBoard(p1_moves, p2_moves)
            @test !is_legal(b)
        end # testset

        @testset "LongMove" begin
            p1_moves = [GridMove(2,3), GridMove(3,7)]
            p2_moves = [GridMove(2,3), GridMove(6,4)]
            b = GridBoard(p1_moves, p2_moves)
            @test !is_legal(b)
        end # testset

        @testset "DirectionTypo" begin
            p1_moves = [GridMove(2,3,"elft")]
            p2_moves = [GridMove(2,3,"rigth")]
            b = GridBoard(p1_moves, p2_moves)
            @test !is_legal(b)
        end # testset

        @testset "DirectionCompatibilityTrue" begin
            p1_moves = [GridMove(2,3,"right"), GridMove(4,3,"right")]
            p2_moves = [GridMove(2,3,"left" ), GridMove(2,2,"down" )]
            b = GridBoard(p1_moves, p2_moves)
            @test is_legal(b)
        end # testset

        @testset "DirectionCompatibilityFalse" begin
            p1_moves = [GridMove(2,3,"right"), GridMove(4,5,"down" )]
            p2_moves = [GridMove(2,3,"left" ), GridMove(1,1,"right")]
            b = GridBoard(p1_moves, p2_moves)
            @test !is_legal(b)
        end # testset

        # @testset "RepeatedMove" begin
        #     Xs = [TicTacToeMove(1, 3), TicTacToeMove(1, 2)]
        #     Os = [TicTacToeMove(2, 2), TicTacToeMove(1, 3)]
        #     b = TicTacToeBoard(Xs, Os)
        #     @test !is_legal(b)
        # end # testset

        @testset "UnbalancedMoves" begin
            p1_moves = [GridMove(1,3), GridMove(1,3)]
            p2_moves = [GridMove(2,2), GridMove(2,2), GridMove(2,2)]
            b = GridBoard(p1_moves, p2_moves)
            @test !is_legal(b)
        end # testset

        @testset "NextPlayer" begin
            p1_moves = [GridMove(1,3), GridMove(1,3)]
            p2_moves = [GridMove(2,2), GridMove(2,2)]
            b = GridBoard(p1_moves, p2_moves)
            @test up_next(b)==1
        end # testset

        # @testset "LegalNonTerminal" begin
        #     Xs = [TicTacToeMove(1, 3), TicTacToeMove(1, 2)]
        #     Os = [TicTacToeMove(2, 2), TicTacToeMove(2, 3)]
        #     b = TicTacToeBoard(Xs, Os)
        #     @test is_legal(b)
        #     @test up_next(b) == 1

        #     over, result = is_over(b)
        #     @test !over
        # end # testset

        # @testset "LegalTerminal" begin
        #     Xs = [TicTacToeMove(1, 3), TicTacToeMove(1, 2), TicTacToeMove(1, 1)]
        #     Os = [TicTacToeMove(2, 2), TicTacToeMove(2, 3)]
        #     b = TicTacToeBoard(Xs, Os)
        #     @test is_legal(b)
        #
        #    over, result = is_over(b)
        #    @test over
        # end # testset
    end # testset

    # Check next moves from a given board.
    @testset "CheckNextMoves" begin
        p1_moves = [GridMove(1,3), GridMove(1,4,"up")]
        p2_moves = [GridMove(2,2)]
        b = GridBoard(p1_moves, p2_moves, 20, 4)

        moves = next_moves(b)
        correct_moves = [
            GridMove(0, 0, "left" ), GridMove(0, 0, "down" ), GridMove(1, 0, "left" ),
            GridMove(1, 0, "down" ), GridMove(2, 0, "down" ), GridMove(3, 0, "right"),
            GridMove(3, 0, "down" ), GridMove(4, 0, "right"), GridMove(4, 0, "down" ),
            GridMove(0, 1, "left" ), GridMove(0, 1, "down" ), GridMove(1, 1, "left" ),
            GridMove(1, 1, "down" ), GridMove(2, 1, "down" ), GridMove(3, 1, "right"),
            GridMove(3, 1, "down" ), GridMove(4, 1, "right"), GridMove(4, 1, "down" ),
            GridMove(5, 1, "right"), GridMove(5, 1, "down" ), GridMove(0, 2, "left" ),
            GridMove(1, 2, "left" ), GridMove(2, 2, "left" ), GridMove(2, 2, "right"),
            GridMove(2, 2, "up"   ), GridMove(2, 2, "down" ), GridMove(3, 2, "right"),
            GridMove(4, 2, "right"), GridMove(5, 2, "right"), GridMove(6, 2, "right"),
            GridMove(0, 3, "left" ), GridMove(0, 3, "up"   ), GridMove(1, 3, "left" ),
            GridMove(1, 3, "up"   ), GridMove(2, 3, "up"   ), GridMove(3, 3, "right"),
            GridMove(3, 3, "up"   ), GridMove(4, 3, "right"), GridMove(4, 3, "up"   ),
            GridMove(5, 3, "right"), GridMove(5, 3, "up"   ), GridMove(0, 4, "left" ),
            GridMove(0, 4, "up"   ), GridMove(1, 4, "left" ), GridMove(1, 4, "up"   ),
            GridMove(2, 4, "up"   ), GridMove(3, 4, "right"), GridMove(3, 4, "up"   ),
            GridMove(4, 4, "right"), GridMove(4, 4, "up"   ), GridMove(1, 5, "left" ),
            GridMove(1, 5, "up"   ), GridMove(2, 5, "up"   ), GridMove(3, 5, "right"),
            GridMove(3, 5, "up"   ), GridMove(2, 6, "up"   )
        ]

        for m ∈ moves
            @test m ∈ correct_moves
        end

        for m̂ ∈ correct_moves
            @test m̂ ∈ moves
        end

    end # testset

end # testset


# @testset "MCTSTests" begin
#     # Create a tree to use for these tests.
#     b₀ = TicTacToeBoard()
#     root = construct_search_tree(b₀, T = 0.1)

#     @testset "CheckValidTree" begin
#         # Walk tree with depth-first-search and check consistency.
#         # Recursive implementation of depth-first-search.
#         visited = Set()
#         function dfs(n::Node)
#             # Checks:
#             # (1) Ensure that n is the parent of all its children.
#             @test isempty(n.children) ||
#                 all(n == c.parent for (m, c) in n.children)

#             # (2) Ensure that the number of episodes passing through this node
#             #     is the sum of those for all children.
#             @test isempty(n.children) ||
#                 (n != root &&
#                 n.num_episodes == 1 + sum(
#                     c.num_episodes for (m, c) in n.children)) ||
#                 (n == root &&
#                 n.num_episodes == sum(
#                     c.num_episodes for (m, c) in n.children))

#             # (3) Ensure that the total value is the sum of those for all of
#             #     this node's children.
#             @test isempty(n.children) ||
#                 abs(n.total_value - sum(
#                     c.total_value for (m, c) in n.children)) ≤ 1

#             # Recursion. Make sure to mark as visited.
#             for (m, c) in n.children
# 	              if !(c in visited)
#                     push!(visited, c)
#                     dfs(c)
#                 end
#             end
#         end

#         # Run depth-first-search with checks on the root.
#         dfs(root)
#     end

#     @testset "CheckFindLeaf" begin
#         n = find_leaf(root, upper_confidence_strategy)
#         @test isempty(n.children) ||
#             length(n.children) < length(next_moves(n.b))
#     end

#     # NOTE: It turns out that *any* first move results in a draw if both
#     # players act optimally. Playing one of the moves listed here is "best" in
#     # the sense that it allows P1 to win if P2 messes up on the next move.
#     # @testset "CheckReasonableMove" begin
#     #     reasonable_first_moves = [
#     #         TicTacToeMove(1, 1), TicTacToeMove(1, 3), TicTacToeMove(3, 1),
#     #         TicTacToeMove(3, 3), TicTacToeMove(2, 2)
#     #     ]

#     #     # Find the UCT move and confirm it is reasonable.
#     #     next_node = upper_confidence_strategy(root)
#     #     @test only(next_node.b.Xs) in reasonable_first_moves
#     # end

#     @testset "CheckMoreTimeIsBetter" begin
#         # Helper function to return the result of playing MCTS with T = T1 vs.
#         # MCTS with T = T2.
#         function play_game(; T1, T2)
#             b = TicTacToeBoard()

#             result = 0
#             while true
#                 # P1 turn.
#                 root = construct_search_tree(b, T = T1)
#                 b = upper_confidence_strategy(root).b

#                 over, result = is_over(b)
#                 if over
#                     break
#                 end

#                 # P2 turn.
#                 root = construct_search_tree(b, T = T2)
#                 b = upper_confidence_strategy(root).b

#                 over, result = is_over(b)
#                 if over
#                     break
#                 end
#             end

#             return result
#         end

#         # Run a bunch of tests to confirm that the player with more time wins.
#         total_value1 = 0
#         total_value2 = 0
#         for ii in 1:100
#             total_value1 += play_game(T1 = 0.001, T2 = 0.0001)
#             total_value2 += play_game(T1 = 0.0001, T2 = 0.001)
#         end

#         println("total_value1=$total_value1")
#         println("total_value2=$total_value2")

#         @test total_value1 < 0
#         @test total_value2 > 0
#     end
# end
