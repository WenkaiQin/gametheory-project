# Abstract types for Board and Move.
abstract type Board end
export Board

abstract type Position end
export Position

DEFAULT_GRID_SIZE = 20
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

    function GridBoard(p1_ms, p2_ms, g_size, rng)
        new(p1_ms, p2_ms, g_size, rng)
    end

    function GridBoard()
        new([], [], DEFAULT_GRID_SIZE, DEFAULT_RANGE)
    end

    function GridBoard(p1_ms, p2_ms)
        new(p1_ms, p2_ms, DEFAULT_GRID_SIZE, DEFAULT_RANGE)
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
        after_move  = moves[ after_move_idx]

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

# # Check if the game is over. If it is over, returns the outcome.
# function is_over(b)

#     # Enumerate and check horizontal wins, then vertical wins.
#     for i in 1:3
#         winning_row = Set()
#         winning_col = Set()
#         for j in 1:3
#             push!(winning_row, GridMove(i,j))
#             push!(winning_col, GridMove(j,i))
#         end

#         if     winning_row ⊆ Set(b.Xs) || winning_col ⊆ Set(b.Xs)
#             return true, -1
#         elseif winning_row ⊆ Set(b.Os) || winning_col ⊆ Set(b.Os)
#             return true, 1
#         end
#     end

#     # Now, diagonals.
#     winning_diag_L = Set()
#     winning_diag_R = Set()

#     for i in 1:3
#         push!(winning_diag_L, GridMove(i,  i))
#         push!(winning_diag_R, GridMove(i,4-i))
#     end

#     if     winning_diag_L ⊆ Set(b.Xs) ||  winning_diag_R ⊆ Set(b.Xs)
#         return true, -1
#     elseif winning_diag_L ⊆ Set(b.Os) ||  winning_diag_R ⊆ Set(b.Os)
#         return true, 1
#     end

#     # Check for ties.
#     if length(b.Xs) + length(b.Os) ≥ 9
#         return true, 0
#     end

#     # If no ending states detected, the game is not over yet.
#     return false, NaN

# end
# export is_over

# Utility for printing boards out to the terminal.
function Base.show(io::IO, b::GridBoard)
    for x in 0:b.grid_size-1
        for y in 0:b.grid_size-1
            m = GridMove(x, y)

            p1_positions = [GridMove(p1_move.x_position, p1_move.y_position)
                                for p1_move in p1_moves]
            p2_positions = [GridMove(p2_move.x_position, p2_move.y_position)
                                for p2_move in p2_moves]

            if m ∈ p1_positions
                print(" 1 ")
            elseif m ∈ p2_positions
                print(" 2 ")
            else
                print(" . ")
            end
        end

        println()
    end
end

p1_moves = [GridMove(2,3,"right"), GridMove(4,3,"right")]
p2_moves = [GridMove(19,17,"left" ), GridMove(17,18,"down")]
b = GridBoard(p1_moves, p2_moves)

println(b)