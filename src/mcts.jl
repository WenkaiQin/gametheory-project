# Construct a Monte Carlo search tree from the given board.
# Should accept an optional argument T which specifies the number of seconds
# spent in tree construction.
# For reference: https://en.wikipedia.org/wiki/Monte_Carlo_tree_search
function construct_search_tree(b::TicTacToeBoard; T = 1)
    start_time = time()

    # Create a root node for the tree from this board state.
    root = Node(b)

    # Check if there's still time left on the clock.
    while time() - start_time < T
        # Find a leaf of the tree using UCT.
        leaf = find_leaf(root, upper_confidence_strategy)
        over, result = is_over(leaf.b)
        if over
            backpropagate!(leaf, result)
        else
            # Not over yet, so add a new child (via rejection sampling) at random.
            ms = next_moves(leaf.b)
            m = rand(ms)
            while haskey(leaf.children, m)
                m = rand(ms)
            end
            child = Node(deepcopy(leaf.b), parent = leaf)
            push!(leaf.children, m => child)

            turn = up_next(leaf.b)
            if turn == 1
                # X is up.
                push!(child.b.Xs, m)
            else
                push!(child.b.Os, m)
            end

            # Simulate until at a terminal state.
            result = simulate(child)

            # Backpropagate result up the tree.
            backpropagate!(child, result)
        end
    end

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
        player = up_next(node.b)
        uct_val = (-1)^player*child.total_value/child.num_episodes
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
# to the function provided, whose signature is Foo(Node)::Node,
# such as the upper_confidence_strategy.
function find_leaf(root, strategy)

    curr_node = root
    while true

        # Check if each node is a leaf. If so, return.
        over, ~ = is_over(curr_node.b)
        if over
            return curr_node
        end

        num_moves = length(next_moves(curr_node.b))
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

    b = node.b
    over, result = is_over(b)

    # Find all possible next moves, and then pick a random one. Repeat until
    # the game is over.
    while !over
        moves = next_moves(b)
        rand_move = rand(moves)
        if up_next(b) == 1
            b = TicTacToeBoard(vcat(b.Xs, [rand_move]), b.Os)
        else
            b = TicTacToeBoard(b.Xs, vcat(b.Os, [rand_move]))
        end

        # Check over, get result.
        over, result = is_over(b)
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
export play_game
function play_game(; T = 0.1)
    b = TicTacToeBoard()

    result = 0
    while true
        # CPU's turn.
        root = construct_search_tree(b, T = T)
        b = upper_confidence_strategy(root).b

        # Display board.
        println(b)

        over, result = is_over(b)
        if over
            break
        end

        # Query user for move.
        println("Your move! Row = ?")
        row = parse(Int, readline())
        println("Column = ?")
        col = parse(Int, readline())

        # Construct next board state and repeat.
        m = TicTacToeMove(row, col)
        push!(b.Os, m)
        @assert is_legal(b)

        over, result = is_over(b)
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
