# Abstract types for Board and Move.
abstract type Board end
export Board

abstract type Position end
export Position

abstract type Obstacle end
export Obstacle

DEFAULT_BOARD_SIZE = 20
DEFAULT_RANGE = [3 4]
VALID_DIRECTIONS = ["left","right","up","down"]

struct GridMove <: Position

    x_position::Int
    y_position::Int
    direction::String

    function GridMove(x_pos, y_pos, dir)
        new(x_pos, y_pos, dir)
    end

    # Assume right if no position defined.
    function GridMove(x_pos, y_pos)
        new(x_pos, y_pos, "right")
    end

end # struct
export GridMove

struct GridObstacle<:Obstacle

    x_bounds::Array
    y_bounds::Array

end # struct
export GridObstacle

# TODO: Check documentation for mutable struct - could invoke a malloc(). Stack vs. heap.
mutable struct GridBoard <: Board

    p1_moves::AbstractArray{GridMove}
    p2_moves::AbstractArray{GridMove}
    grid_size::Int
    range::Array
    obstacles::AbstractArray{GridObstacle}

    function GridBoard(p1_ms::Vector{GridMove}, p2_ms::Vector{GridMove}, g_size::Int, ran::Array, obs::Vector{GridObstacle})
        new(p1_ms, p2_ms, g_size, ran, obs)
    end

    function GridBoard(p1_ms::Vector{GridMove}, p2_ms::Vector{GridMove}, g_size::Int, ran::Int, obs::Vector{GridObstacle})
        new(p1_ms, p2_ms, g_size, [ran ran], obs)
    end

    function GridBoard(p1_ms::Vector{GridMove}, p2_ms::Vector{GridMove}, g_size::Int, ran::Array)
        new(p1_ms, p2_ms, g_size, ran, Vector{GridObstacle}())
    end

    function GridBoard()
        new([GridMove(0                   , 0                   , "right")],
            [GridMove(DEFAULT_BOARD_SIZE-1, DEFAULT_BOARD_SIZE-1, "left" )],
            DEFAULT_BOARD_SIZE, DEFAULT_RANGE,
            Vector{GridObstacle}())
    end

    function GridBoard(g_size::Int, ran::Array)
        new([GridMove(0                   , 0                   , "right")],
            [GridMove(DEFAULT_BOARD_SIZE-1, DEFAULT_BOARD_SIZE-1, "left" )],
            g_size, ran,
            Vector{GridObstacle}())
    end

    function GridBoard(p1_ms::Vector{GridMove}, p2_ms::Vector{GridMove})
        new(p1_ms, p2_ms, DEFAULT_BOARD_SIZE, DEFAULT_RANGE, Vector{GridObstacle}())
    end

end # struct
export GridBoard


# Enumerate all possible next moves.
function next_moves(board)

    # Pick next player.
    player = up_next(board)
    if player==1
        current_pos = board.p1_moves[end]
    else
        current_pos = board.p2_moves[end]
    end

    # Use a depth-first search to find the set of next possible moves.
    # Start with null move.
    all_next_m = [current_pos]
    for i_range = 1:board.range[player]

        # Save off the next moves at this moment to iterate, otherwise we end
        # up self iterating.
        all_next_m_cache = copy(all_next_m)

        for move_base ∈ all_next_m_cache

            for direction ∈ VALID_DIRECTIONS

                if direction == "up"
                    inc_x =  0
                    inc_y = +1
                elseif direction == "down"
                    inc_x =  0
                    inc_y = -1
                elseif direction == "left"
                    inc_x = -1
                    inc_y =  0
                elseif direction == "right"
                    inc_x = +1
                    inc_y =  0
                end # if direction

                move_candidate = GridMove(move_base.x_position+inc_x,
                                          move_base.y_position+inc_y, direction)

                # If this move already exists in the list of possible next moves, don't consider it.
                if move_candidate ∈ all_next_m
                    continue
                end

                if player == 1
                    # This is more costly but more verbose. Good for debugging more efficient renditions.
                    # board_candidate = GridBoard([board.p1_moves; move_candidate],
                                                 # board.p2_moves,
                                                 # board.grid_size,
                                                 # board.range)
                    board_candidate = GridBoard([board.p1_moves[end]; move_candidate],
                                                [board.p2_moves[end]],
                                                 board.grid_size,
                                                 board.range,
                                                 board.obstacles)
                elseif player == 2
                    # board_candidate = GridBoard( board.p1_moves,
                                                # [board.p2_moves; move_candidate],
                                                #  board.grid_size,
                                                #  board.range)
                    board_candidate = GridBoard( board.p1_moves[end-1:end],
                                                [board.p2_moves[end]; move_candidate],
                                                 board.grid_size,
                                                 board.range,
                                                 board.obstacles)
                end # if player

                if is_legal(board_candidate)
                    push!(all_next_m, move_candidate)
                end # if is_legal

            end # for direction
        end # for move_base
    end # for i_range

    return all_next_m

end # function
export next_moves

# Check if the given board is legal.
function is_legal(board)

    # Check number of moves per player. Assume p1 goes first.
    if length(board.p2_moves)>length(board.p1_moves)
        return false
    end

    # Check move histories.
    if !check_history(board.p1_moves, board, 1) || !check_history(board.p2_moves, board, 2)
        return false
    end

    # If all tests succeed, return True.
    return true

end # function
export is_legal

function check_history(moves, board, player)

    flag_debug = false

    # Per-move checks.
    for position in moves

        # Check out of bounds.
        if     ~(0 ≤ position.x_position ≤ board.grid_size-1)
            return false
        elseif ~(0 ≤ position.y_position ≤ board.grid_size-1)
            return false
        end

        # Check that the directions are valid.
        if position.direction ∉ VALID_DIRECTIONS
            return false
        end

        # Check obstacle collision.
        if is_obstructed(position, board)
            return false
        end

    end

    # Move-relative checks.
    for before_move_idx in 1:length(moves)-1

        after_move_idx = before_move_idx+1

        before_move = moves[before_move_idx]
        after_move  = moves[after_move_idx]

        rel_x = after_move.x_position-before_move.x_position
        rel_y = after_move.y_position-before_move.y_position

        # Check distance between moves by 1-norm.
        # player = up_next(board) # Comment out if symmetric ranges
        # if (abs(rel_x))+abs(rel_y)) > board.range
        if (abs(rel_x)+abs(rel_y)) > board.range[player]
            if flag_debug
                println("reason: out of range")
                print("player = ")
                println(player)
            end
            return false
        end

        # Check that the directions match the moves made. If the player did
        # not move, no direction change is permitted.
        if !(rel_x==0 && rel_y==0)
            compatible_directions = []

            if rel_x>0
                push!(compatible_directions, "right")
            elseif rel_x<0
                push!(compatible_directions, "left")
            end

            if rel_y>0
                push!(compatible_directions, "up")
            elseif rel_y<0
                push!(compatible_directions, "down")
            end

            if after_move.direction ∉ compatible_directions
                if flag_debug
                    println("reason: direction incompatible")
                    println(before_move)
                    println(after_move)
                    println(direction)
                end
                return false
            end

        elseif after_move.direction ≠ before_move.direction
            return false
        end
    end

    # If all tests pass, return true.
    return true

end # function
export check_history

# Which player is up?
function up_next(board)

    if length(board.p1_moves)<=length(board.p2_moves)
        return 1
    else
        return 2
    end

end # function
export up_next

function strike_zone(x,y,dir)
    # Strike zone is a "cone" that follows a 1-3-3-5-5 grid sequence
    # dir is a string 

    # Construct grid relative to [0 0] (origin)
    augmented_grid = [[ii jj] for ii ∈ 1:5, jj ∈ -2:2]
    reshape_grid = reshape(augmented_grid,(5^2,1))
    for ii ∈ 1:3
        for jj ∈ -2:2
            if ii == 1 && jj ≠ 0
                reshape_grid = filter(x->x ≠ [ii jj],reshape_grid)
            elseif (ii == 2 || ii == 3) && (jj == 2 || jj == -2)           
                reshape_grid = filter(x->x ≠ [ii jj],reshape_grid)
            end
        end
    end

    # Rotate grid according to strike direction
    if dir == "right"
        reshape_grid = reshape_grid
    elseif dir == "left"
        reshape_grid = [[-point[1] point[2]] for point ∈ reshape_grid]
    elseif dir == "up"
        reshape_grid = [[point[2] point[1]] for point ∈ reshape_grid]
    elseif dir == "down"
        reshape_grid = [[point[2] -point[1]] for point ∈ reshape_grid]
    end

    # Translate grid to being relative to current position of player
    reshape_grid .+= [[x y]]

    return reshape_grid
end # function
export strike_zone

function is_obstructed(position::GridMove, board::GridBoard)

    for obstacle in board.obstacles
        if ((obstacle.x_bounds[1] ≤ position.x_position ≤ obstacle.x_bounds[2])
            && (obstacle.y_bounds[1] ≤ position.y_position ≤ obstacle.y_bounds[2]))
            # println('a')
            return true
        end
    end

    return false

end # function
export is_obstructed

# Check if the game is over. If it is over, returns the outcome.
function is_over(board::GridBoard)

    # If player i is in player j's strike zone and player j is not in player
    # i's strike zone, then player i loses.

    # Current moves for both players:
    pos_p1 = board.p1_moves[end]
    pos_p2 = board.p2_moves[end]

    x1 = pos_p1.x_position
    x2 = pos_p2.x_position
    y1 = pos_p1.y_position
    y2 = pos_p2.y_position
    
    # Strike zones of each player based on their direction in current moves:
    strikeZone_p1 = strike_zone(x1,y1,pos_p1.direction)
    strikeZone_p2 = strike_zone(x2,y2,pos_p2.direction)

    # Check conditions:
    if [x1 y1] ∈ strikeZone_p2 && [x2 y2] ∉ strikeZone_p1
        return true,-1
    elseif [x1 y1] ∉ strikeZone_p2 && [x2 y2] ∈ strikeZone_p1
        return true,1
    elseif [x1 y1] ∈ strikeZone_p2 && [x2 y2] ∈ strikeZone_p1
        return true,0
    else
        return false,NaN
    end
end # function
export is_over

# Utility for printing boards out to the terminal.
function Base.show(io::IO, board::GridBoard)

    border_base = repeat("━", 3*board.grid_size)
    top_border = "┏"*border_base*"┓"
    bot_border = "┗"*border_base*"┛"

    println(top_border)

    for y in board.grid_size-1:-1:0
        print("┃")

        for x in 0:board.grid_size-1

            m = GridMove(x, y)

            p1_positions = [GridMove(board.p1_moves[end].x_position, board.p1_moves[end].y_position)]
            p2_positions = [GridMove(board.p2_moves[end].x_position, board.p2_moves[end].y_position)]

            # Draw strike zone.
            p1_strike = strike_zone(board.p1_moves[end].x_position, board.p1_moves[end].y_position,
                                    board.p1_moves[end].direction)
            p2_strike = strike_zone(board.p2_moves[end].x_position, board.p2_moves[end].y_position,
                                    board.p2_moves[end].direction)

            # Draw players.
            # TODO: Make a conversion from [x,y] to GridMove.
            if m ∈ p1_positions
                printstyled(" 1 "; color = :red)
            elseif m ∈ p2_positions
                printstyled(" 2 "; color = :blue)

            # Draw obstacles.
            elseif is_obstructed(m, board)
                print(" ▧ ")

            # Draw strike zones.
            elseif [x y] ∈ p1_strike && [x y] ∈ p2_strike
                printstyled(" ½ "; color = :magenta)
            elseif [x y] ∈ p1_strike
                printstyled(" ₁ "; color = :red)
            elseif [x y] ∈ p2_strike
                printstyled(" ₂ "; color = :blue)

            # Draw empty space.
            else
                print("   ")
            end

        end # for x
        print("┃")
        println()

    end # for y

    println(bot_border)

end # function

