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

        @testset "LegalNonTerminal" begin
            p1_moves = [GridMove(1,3,"right"), GridMove(2,3,"right")]
            p2_moves = [GridMove(6,6,"left" ), GridMove(5,6,"left")]
            b = GridBoard(p1_moves, p2_moves)
            @test is_legal(b)
            @test up_next(b) == 1
            over,result = is_over(b)
            @test !over
        end

        @testset "LegalTerminal" begin
            p1_moves = [GridMove(1,3,"right"), GridMove(2,3,"right")]
            p2_moves = [GridMove(5,3,"up"   ), GridMove(5,4,"up"   )]
            b = GridBoard(p1_moves, p2_moves)
            @test is_legal(b)
            over,result = is_over(b)
            @test over
        end # testset

        @testset "ObstacleCollision" begin
            b = GridBoard([GridMove(2, 4, "right")],
                          [GridMove(3, 4, "left" )],
                          10, 3,
                          [GridObstacle([2,3], [4,5])] )

            @test !is_legal(b)
        end
    end # testset

    # Check next moves from a given board.
    @testset "CheckNextMoves" begin
        p1_moves = [GridMove(1,3,"right"), GridMove(1,4,"up")]
        p2_moves = [GridMove(2,2,"right")]
        b = GridBoard(p1_moves, p2_moves, 5, [1 3])

        moves = next_moves(b)

        correct_moves = GridMove[     GridMove(2, 2, "right"),
             GridMove(1, 2, "left" ), GridMove(3, 2, "right"), GridMove(2, 3, "up"   ),
             GridMove(2, 1, "down" ), GridMove(0, 2, "left" ), GridMove(1, 3, "up"   ),
             GridMove(1, 1, "down" ), GridMove(4, 2, "right"), GridMove(3, 3, "up"   ),
             GridMove(3, 1, "down" ), GridMove(1, 3, "left" ), GridMove(3, 3, "right"),
             GridMove(2, 4, "up"   ), GridMove(1, 1, "left" ), GridMove(3, 1, "right"),
             GridMove(2, 0, "down" ), GridMove(0, 3, "up"   ), GridMove(0, 1, "down" ),
             GridMove(0, 3, "left" ), GridMove(1, 4, "up"   ), GridMove(0, 1, "left" ),
             GridMove(1, 0, "down" ), GridMove(4, 3, "up"   ), GridMove(4, 1, "down" ),
             GridMove(4, 3, "right"), GridMove(3, 4, "up"   ), GridMove(4, 1, "right"),
             GridMove(3, 0, "down" ), GridMove(1, 4, "left" ), GridMove(3, 4, "right"),
             GridMove(1, 0, "left" ), GridMove(3, 0, "right")]
    
        for m ∈ moves
            @test m ∈ correct_moves
        end

        for m̂ ∈ correct_moves
            @test m̂ ∈ moves
        end

    end # testset

end # testset


@testset "MCTSTests" begin
    # Create a tree to use for these tests.
    board₀ = GridBoard([GridMove(0, 0, "right")],
                       [GridMove(9, 9, "left" )],
                       10, 3,
                       [GridObstacle([3,4], [3,4])
                        GridObstacle([7,8], [7,8])
                        GridObstacle([4,7], [4,7])])
    root = construct_search_tree(board₀, T = 0.1)

    @testset "CheckValidTree" begin
        # Walk tree with depth-first-search and check consistency.
        # Recursive implementation of depth-first-search.
        visited = Set()
        function dfs(n::Node)
            # Checks:
            # (1) Ensure that n is the parent of all its children.
            @test isempty(n.children) ||
                all(n == c.parent for (m, c) in n.children)

            # (2) Ensure that the number of episodes passing through this node
            #     is the sum of those for all children.
            @test isempty(n.children) ||
                (n != root &&
                n.num_episodes == 1 + sum(
                    c.num_episodes for (m, c) in n.children)) ||
                (n == root &&
                n.num_episodes == sum(
                    c.num_episodes for (m, c) in n.children))

            # (3) Ensure that the total value is the sum of those for all of
            #     this node's children.
            @test isempty(n.children) ||
                abs(n.total_value - sum(
                    c.total_value for (m, c) in n.children)) ≤ 1

            # Recursion. Make sure to mark as visited.
            for (m, c) in n.children
	              if !(c in visited)
                    push!(visited, c)
                    dfs(c)
                end
            end
        end

        # Run depth-first-search with checks on the root.
        dfs(root)
    end

    @testset "CheckFindLeaf" begin
        n = find_leaf(root, upper_confidence_strategy)
        @test isempty(n.children) ||
            length(n.children) < length(next_moves(n.board))
    end

    @testset "CheckMoreTimeIsBetter" begin
        # Helper function to return the result of playing MCTS with T = T1 vs.
        # MCTS with T = T2.
        function play_game(; T1, T2)

            board = board₀
            println(board)

            result = 0
            while true
                # P1 turn.
                root = construct_search_tree(board, T = T1)
                board = upper_confidence_strategy(root).board
                println(board)

                over, result = is_over(board)
                #println(over)
                if over
                    print("P1: ")
                    println(result)
                    println()
                    println(board)
                    break
                end

                # P2 turn.
                root = construct_search_tree(board, T = T2)
                board = upper_confidence_strategy(root).board
                println(board)

                over, result = is_over(board)
                if over
                    print("P2: ")
                    println(result)
                    println()
                    println(board)
                    break
                end
            end

            return result
        end

        # Run a bunch of tests to confirm that the player with more time wins.
        total_value1 = 0
        total_value2 = 0
        for ii in 1:5
            total_value1 += play_game(T1 = 0.1, T2 = 20.1)
            total_value2 += play_game(T1 = 2.1, T2 = 0.1)
        end

        println("total_value1=$total_value1")
        println("total_value2=$total_value2")

        @test total_value1 < 0
        @test total_value2 > 0
    end
end

