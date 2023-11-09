# Abstract types for Board and Move.
abstract type Board end
export Board

abstract type Position end
export Position

MOVEMENT_PER_TURN = 4
GRID_SIZE = 20

struct GridPosition <: Position
    x_position::Int
    y_position::Int
end # struct
export GridPosition

mutable struct GridBoard <: Board

    p1_moves::AbstractArray{GridPosition}
    p2_moves::AbstractArray{GridPosition}

    # function GridBoard()
    #     new([],[])
    # end

    # function GridBoard(p1_ms, p2_ms)
    #     new(p1_ms, p2_ms)
    # end

end # struct

# Initialize to starting with no history and the following moves.
GridBoard() = GridBoard([], [])
export GridBoard

# Enumerate all possible next moves.
# function next_moves(b)

#     # Pick next player.
#     player = up_next(b)

#     # Go through all possible next moves. Check at each one if the move creates a legal board.
#     all_next_m = []

#     for move_ud in -MOVEMENT_PER_TURN:MOVEMENT_PER_TURN
#         for move_lr in -MOVEMENT_PER_TURN:MOVEMENT_PER_TURN

#             move_candidate = GridMove(row, col)
#             b_candidate = nothing
#             if     player == 1
#                 b_candidate = TicTacToeBoard(vcat(b.Xs, [move_candidate]), b.Os)
#             elseif player == 2
#                 b_candidate = TicTacToeBoard(b.Xs, vcat(b.Os, [move_candidate]))
#             end

#             if is_legal(b_candidate)
#                 push!(all_next_m, move_candidate)
#             end
#         end
#     end

#     return all_next_m

# end
# export next_moves


# Check if the given board is legal. For now, this only checks if anyone is out of bounds.
function is_legal(board)

    # Check number of moves per player. Assume p1 goes first.
    if length(board.p2_moves)>length(board.p1_moves)
        return false
    end

    # Check out of bounds.
    histories = [board.p1_moves; board.p2_moves]
    if !check_history(board.p1_moves) || !check_history(p2_moves)
        return false
    end

    # If all tests succeed, return True.
    return true

end
export is_legal

function check_history(moves)

    # Check out of bounds.
    for position in moves
        if     ~(0 ≤ position.x_position ≤ GRID_SIZE-1)
            return false
        elseif ~(0 ≤ position.y_position ≤ GRID_SIZE-1)
            return false
        end
    end

    # Check distance between moves by 1-norm.
    for before_move_idx in 1:length(moves)-1

        after_move = before_move_idx+1

        before_move = moves[before_move_idx]
        after_move  = moves[ after_move_idx]

        if (abs(after_move.x_position-before_move.x_position)
            + abs(after_move.y_position-before_move.y_position)) > MOVEMENT_PER_TURN
        return false
    end

end

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

# # Utility for printing boards out to the terminal.
# function Base.show(io::IO, b::TicTacToeBoard)
#     for ii in 1:3
#         for jj in 1:3
#             m = GridMove(ii, jj)
#             if m ∈ b.Xs
#                 print(" X ")
#             elseif m ∈ b.Os
#                 print(" O ")
#             else
#                 print(" - ")
#             end
#         end

#         println()
#     end
# end
