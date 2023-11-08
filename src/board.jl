# Abstract types for Board and Move.
# NOTE: in this assignment we will assume that the game being played has
#       two players and that outcomes of the game are
#       P1 win (P2 loss), P1 loss (P2 win), tie.
abstract type Board end
export Board

abstract type Move end
export Move

# Specialization of Move to TicTacToe.
struct TicTacToeMove <: Move
    row::Int
    col::Int
end # struct
export TicTacToeMove

# A Board specialized for TicTacToe. Stores locations of the Xs and Os as
# tuples of integers. Presuming that X plays first, the size of these lists
# determines which player's turn it is.
mutable struct TicTacToeBoard <: Board
    Xs::AbstractArray{TicTacToeMove}
    Os::AbstractArray{TicTacToeMove}
end # struct

# Custom initialization to empty.
TicTacToeBoard() = TicTacToeBoard([], [])
export TicTacToeBoard

# Enumerate all possible next moves.
function next_moves(b)

    # Pick next player.
    player = up_next(b)

    # Go through all possible next moves. Check at each one if the move creates a legal board.
    all_next_m = []

    for row in 1:3
        for col in 1:3

            move_candidate = TicTacToeMove(row, col)
            b_candidate = nothing
            if     player == 1
                b_candidate = TicTacToeBoard(vcat(b.Xs, [move_candidate]), b.Os)
            elseif player == 2
                b_candidate = TicTacToeBoard(b.Xs, vcat(b.Os, [move_candidate]))
            end

            if is_legal(b_candidate)
                push!(all_next_m, move_candidate)
            end
        end
    end

    return all_next_m

end
export next_moves

# Check if the given board is legal.
function is_legal(b)

    # Check number of moves per player. Assume X goes first.
    if length(b.Os)>length(b.Xs)
        return false
    end

    # Check out of bounds.
    all_moves = [b.Xs; b.Os]
    for move in all_moves
        if     ~(1 ≤ move.row ≤ 3)
            return false
        elseif ~(1 ≤ move.col ≤ 3)
            return false
        end
    end

    # Check for repeated moves.
    unique_moves = unique(all_moves)
    if length(unique_moves) != length(all_moves)
        return false
    end

    # If all tests succeed, return True.
    return true

end
export is_legal

# Which player is up?
function up_next(b)

    if     length(b.Os)==length(b.Xs)
        return 1
    elseif length(b.Os)==length(b.Xs)-1
        return 2
    else
        error("Invalid moveset.")
    end

end
export up_next

# Check if the game is over. If it is over, returns the outcome.
function is_over(b)

    # Enumerate and check horizontal wins, then vertical wins.
    for i in 1:3
        winning_row = Set()
        winning_col = Set()
        for j in 1:3
            push!(winning_row, TicTacToeMove(i,j))
            push!(winning_col, TicTacToeMove(j,i))
        end

        if     winning_row ⊆ Set(b.Xs) || winning_col ⊆ Set(b.Xs)
            return true, -1
        elseif winning_row ⊆ Set(b.Os) || winning_col ⊆ Set(b.Os)
            return true, 1
        end
    end

    # Now, diagonals.
    winning_diag_L = Set()
    winning_diag_R = Set()

    for i in 1:3
        push!(winning_diag_L, TicTacToeMove(i,  i))
        push!(winning_diag_R, TicTacToeMove(i,4-i))
    end

    if     winning_diag_L ⊆ Set(b.Xs) ||  winning_diag_R ⊆ Set(b.Xs)
        return true, -1
    elseif winning_diag_L ⊆ Set(b.Os) ||  winning_diag_R ⊆ Set(b.Os)
        return true, 1
    end

    # Check for ties.
    if length(b.Xs) + length(b.Os) ≥ 9
        return true, 0
    end

    # If no ending states detected, the game is not over yet.
    return false, NaN

end
export is_over

# Utility for printing boards out to the terminal.
function Base.show(io::IO, b::TicTacToeBoard)
    for ii in 1:3
        for jj in 1:3
            m = TicTacToeMove(ii, jj)
            if m ∈ b.Xs
                print(" X ")
            elseif m ∈ b.Os
                print(" O ")
            else
                print(" - ")
            end
        end

        println()
    end
end
