# Construct a Monte Carlo search tree from the given board.
# Should accept an optional argument T which specifies the number of seconds
# spent in tree construction.
# For reference: https://en.wikipedia.org/wiki/Monte_Carlo_tree_search
function construct_search_tree(board::GridBoard; T = 1)

    flag_print_vals = false

    start_time = time()

    # Create a root node for the tree from this board state.
    root = Node(board)

    num_runs = 0
    my_fav_child = []

    # Check if there's still time left on the clock.
    while time() - start_time < T
        # Find a leaf of the tree using UCT.
        leaf = find_leaf(root, upper_confidence_strategy)

        over, result = is_over(leaf.board)
        if over
            backpropagate!(leaf, result)
        else
            # Not over yet, so add a new child (via rejection sampling) at random.
            ms = next_moves(leaf.board)
            m = rand(ms)
            while haskey(leaf.children, m)
                m = rand(ms)
            end
            child = Node(deepcopy(leaf.board), parent = leaf)
            push!(leaf.children, m => child)

            turn = up_next(leaf.board)
            if turn == 1
                # X is up.
                push!(child.board.p1_moves, m)
            else
                push!(child.board.p2_moves, m)
            end

            # Simulate until at a terminal state.
            result = simulate(child)

            # Backpropagate result up the tree.
            backpropagate!(child, result)
        end

        num_runs = num_runs+1

        if flag_print_vals
            println("==========")
            println(root.num_episodes)
            for (key, val) in root.children
                print(key)
                print("\t val.num_episodes: ")
                print(val.num_episodes)
                print("\t val.total_value: ")
                println(val.total_value)
            end
        end

    end # while

    return root
end
export construct_search_tree

# Upper confidence strategy. Takes in a set of Nodes and returns one
# consistent with the UCT rule (see earlier reference for details).
function upper_confidence_strategy(node)

    c = √2
    max_uct_val = -Inf
    optimal_move = nothing

    if isempty(node.children)
        error("No child nodes available.")
    end

    # Find the next best child node to explore by UCT heuristic.
    optimal_child = nothing
    for (move, child) ∈ node.children

        # Find UCT value.
        player = up_next(node.board)
        uct_val = (-1)^(player+1)*child.total_value/child.num_episodes
                   + c*√(log(node.num_episodes)/child.num_episodes)

        # Check for new maximum.
        if uct_val > max_uct_val
            max_uct_val = uct_val
            optimal_child = child
        end

    end

    # Return the node corresponding to the optimal move.
    return optimal_child

end
export upper_confidence_strategy

# Walk the tree to find a leaf Node, choosing children at each level according
# to the function provided, whose signature is Foo(Node)::Node, such as the
# upper_confidence_strategy.
function find_leaf(root, strategy)

    curr_node = root
    while true

        # Check if each node is a leaf. If so, return.
        over, ~ = is_over(curr_node.board)
        if over
            return curr_node
        end

        num_moves = length(next_moves(curr_node.board))
        num_children = length(curr_node.children)
        if num_children < num_moves
            return curr_node
        end

        # If not, continue to traverse tree according to the strategy.
        curr_node = strategy(curr_node)

    end
end
export find_leaf

# Simulate gameplay from the given (leaf) node.
function simulate(node)

    board = node.board
    over, result = is_over(board)

    # Find all possible next moves, and then pick a random one. Repeat until
    # the game is over.
    while !over
        moves = next_moves(board)
        rand_move = rand(moves)
        if up_next(board) == 1
            board = GridBoard(vcat(board.p1_moves,[rand_move]),board.p2_moves)
        else
            board = GridBoard(board.p1_moves,vcat(board.p2_moves,[rand_move]))
        end

        # Check over, get result.
        over, result = is_over(board)
    end

    return result

end
export simulate

# Backpropagate values up the tree from the given (leaf) node.
function backpropagate!(leaf, result)
    curr_node = leaf
    while curr_node != nothing
        curr_node.total_value += result
        curr_node.num_episodes += 1
        curr_node = curr_node.parent
    end
end
export backpropagate!

# Play a game! Parameterized by time given to the CPU. Assumes CPU plays first.
function play_game(; T = 2)
    p1 = [GridMove( 0,  0, "right")]
    p2 = [GridMove(19, 19, "left")]
    grid = 20
    range = [4 4]
    obstacles = [GridObstacle([3,4], [3,4])
                 GridObstacle([7,8], [7,8])
                 GridObstacle([4,7], [4,7])]
    board = GridBoard(p1, p2, grid, range, obstacles)

    result = 0
    while true

        # CPU's turn.
        root = construct_search_tree(board, T = T)
        board = upper_confidence_strategy(root).board

        # Display board.
        println(board)

        over, result = is_over(board)
        if over
            break
        end

        move_prior = board.p2_moves[end]

        # Query user for move.
        check = false

        m = GridMove(-1, -1)

        while check == false

            try
                println("Your move! X = ?")
                col = move_prior.x_position+parse(Int, readline())
                println("Y = ?")
                row = move_prior.y_position+parse(Int, readline())
                println("Direction?")
                #dir = readline()

                direction = lowercase(readline())
                if direction ∈ ("r", "right")
                    dir = "right"
                elseif direction ∈ ("l", "left")
                    dir = "left"
                elseif direction ∈ ("u", "left")
                    dir = "up"
                elseif direction ∈ ("d", "down")
                    dir = "down"
                elseif direction ∈ ("q", "quit")
                    return 1
                end

                # Construct next board state and repeat.
                m = GridMove(col,row,dir)
                board_c = GridBoard(copy(board.p1_moves), copy(board.p2_moves), grid, range, obstacles)
                push!(board_c.p2_moves, m)

                println(m)
                println(board_c.p1_moves)
                println(board_c.p2_moves)

                check = is_legal(board_c)
                @assert is_legal(board_c)

            catch e
                println("Invalid move.")
                println(e)
            end

        end
        
        push!(board.p2_moves,m)
        # @assert is_legal(board)

        over, result = is_over(board)
        if over
            break
        end
    end

    println("Game over!")
    if result == -1
        println("I won!")
    elseif result == 0
        println("Tie game.")
    else
        println("You won.")
    end

end
export play_game