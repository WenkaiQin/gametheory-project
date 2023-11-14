# Abstract types for Board and Move.
abstract type Board end
export Board

abstract type Position end
export Position

DEFAULT_BOARD_SIZE = 20
DEFAULT_RANGE = 4
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

mutable struct GridBoard <: Board

    p1_moves::AbstractArray{GridMove}
    p2_moves::AbstractArray{GridMove}
    grid_size::Int
    range::Int

    function GridBoard(p1_ms, p2_ms, g_size, ran)
        new(p1_ms, p2_ms, g_size, ran)
    end

    function GridBoard()
        new([GridMove(0,0,"right")],
            [GridMove(DEFAULT_BOARD_SIZE-1,DEFAULT_BOARD_SIZE-1,"left")],
            DEFAULT_BOARD_SIZE, DEFAULT_RANGE)
    end

    function GridBoard(g_size, ran)
        new([GridMove(0,0,"right")],
            [GridMove(DEFAULT_BOARD_SIZE-1,DEFAULT_BOARD_SIZE-1,"left")],
            g_size, ran)
    end

    function GridBoard(p1_ms, p2_ms)
        new(p1_ms, p2_ms, DEFAULT_BOARD_SIZE, DEFAULT_RANGE)
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

    # Go through all possible next moves. Check at each one if the move creates a legal board.
    all_next_m = []

    # TODO: You could construct this more intelligently per-quadrant.
    for rel_move_x in -board.range:board.range
        for rel_move_y in -board.range:board.range
            for direction in VALID_DIRECTIONS

                move_candidate = GridMove(current_pos.x_position+rel_move_x,
                                          current_pos.y_position+rel_move_y, direction)

                b_candidate = nothing

                if player == 1
                    b_candidate = GridBoard(vcat(board.p1_moves, [move_candidate]), board.p2_moves)
                elseif player == 2
                    b_candidate = GridBoard(board.p1_moves, vcat(board.p2_moves, [move_candidate]))
                end

                if is_legal(b_candidate)
                    push!(all_next_m, move_candidate)
                end

            end
        end
    end

    return all_next_m

end
export next_moves

# Check if the given board is legal. For now, this only checks if anyone is out of bounds.
function is_legal(board)

    # Check number of moves per player. Assume p1 goes first.
    if length(board.p2_moves)>length(board.p1_moves)
        return false
    end

    # Check move histories.
    if !check_history(board.p1_moves, board) || !check_history(board.p2_moves, board)
        return false
    end

    # If all tests succeed, return True.
    return true

end
export is_legal

function check_history(moves, board)

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
    end

    # Move-relative checks.
    for before_move_idx in 1:length(moves)-1

        after_move_idx = before_move_idx+1

        before_move = moves[before_move_idx]
        after_move  = moves[after_move_idx]

        rel_x = after_move.x_position-before_move.x_position
        rel_y = after_move.y_position-before_move.y_position

        # Check distance between moves by 1-norm.
        if (abs(rel_x)+abs(rel_y)) > board.range
            return false
        end

        # Check that the directions match the moves made. But don't bother
        # checking if the player stood still.
        if !(rel_x==0 && rel_y==0)

            compatible_directions = []
            if rel_x>0
                push!(compatible_directions, "right")
            end
            if rel_y>0
                push!(compatible_directions, "up")
            end
            if rel_x<0
                push!(compatible_directions, "left")
            end
            if rel_y<0
                push!(compatible_directions, "down")
            end

            if after_move.direction ∉ compatible_directions
                return false
            end

        end
    end

    # If all tests pass, return true.
    return true

end
export check_history

# Which player is up?
function up_next(board)

    if length(board.p1_moves)<=length(board.p2_moves)
        return 1
    else
        return 2
    end

end
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
end
export strike_zone

# Check if the game is over. If it is over, returns the outcome.
function is_over(board)

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
end
export is_over

# Utility for printing boards out to the terminal.
function Base.show(io::IO, board::GridBoard)

    border_base = repeat("━", 3*board.grid_size)
    top_border = "┏"*border_base*"┓"
    bot_border = "┗"*border_base*"┛"

    println(top_border)

    for y in 0:board.grid_size-1
        print("┃")

        for x in 0:board.grid_size-1

            m = GridMove(x, y)

            # p1_positions = [GridMove(p1_move.x_position, p1_move.y_position)
            #                     for p1_move in board.p1_moves]
            # p2_positions = [GridMove(p2_move.x_position, p2_move.y_position)
            #                     for p2_move in board.p2_moves]

            p1_positions = [GridMove(board.p1_moves[end].x_position, board.p1_moves[end].y_position)]
            p2_positions = [GridMove(board.p2_moves[end].x_position, board.p2_moves[end].y_position)]

            p1_strike = strike_zone(board.p1_moves[end].x_position,
                                    board.p1_moves[end].y_position,
                                    board.p1_moves[end].direction)
            p2_strike = strike_zone(board.p2_moves[end].x_position,
                                    board.p2_moves[end].y_position,
                                    board.p2_moves[end].direction)

            # TODO: Make a conversion from [x,y] to GridMove.
            if m ∈ p1_positions
                printstyled(" 1 "; color = :red)
            elseif m ∈ p2_positions
                printstyled(" 2 "; color = :blue)
            elseif [x y] ∈ p1_strike && [x y] ∈ p2_strike
                printstyled(" ½ "; color = :magenta)
            elseif [x y] ∈ p1_strike
                printstyled(" ₁ "; color = :red)
            elseif [x y] ∈ p2_strike
                printstyled(" ₂ "; color = :blue)
            else
                print("   ")
            end
        end # end for x
        print("┃")
        println()

    end # end for y

    println(bot_border)


end

