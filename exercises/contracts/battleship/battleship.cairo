
## I AM NOT DONE

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_unsigned_div_rem, uint256_sub
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import unsigned_div_rem, assert_le_felt, assert_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.hash_state import hash_init, hash_update 
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor

struct Square:    
    member square_commit: felt
    member square_reveal: felt
    member shot: felt
end

struct Player:    
    member address: felt
    member points: felt
    member revealed: felt
end

struct Game:        
    member player1: Player
    member player2: Player
    member next_player: felt
    member last_move: (felt, felt)
    member winner: felt
end

@storage_var
func grid(game_idx : felt, player : felt, x : felt, y : felt) -> (square : Square):
end

@storage_var
func games(game_idx : felt) -> (game_struct : Game):
end

@storage_var
func game_counter() -> (game_counter : felt):
end

func hash_numb{pedersen_ptr : HashBuiltin*}(numb : felt) -> (hash : felt):

    alloc_locals
    
    let (local array : felt*) = alloc()
    assert array[0] = numb
    assert array[1] = 1
    let (hash_state_ptr) = hash_init()
    let (hash_state_ptr) = hash_update{hash_ptr=pedersen_ptr}(hash_state_ptr, array, 2)   
    tempvar pedersen_ptr :HashBuiltin* = pedersen_ptr       
    return (hash_state_ptr.current_hash)
end


## Provide two addresses
@external
func set_up_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player1 : felt, player2 : felt):
    # Read current game index
    let (gc) = game_counter.read()

    # Create Game struct
    let player1_struct = Player(player1, 0, 0)
    let player2_struct = Player(player2, 0, 0)
    let game = Game(player1_struct, player2_struct, 0, (0, 0), 0)
    
    # Write to games mapping
    games.write(gc, game)

    # Increment game_counter
    game_counter.write(gc + 1)

    return ()
end

@view 
func check_caller{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(caller : felt, game : Game) -> (valid : felt):
    if game.player1.address == caller:
        return(1)
    end

    if game.player2.address == caller:
        return(1)
    end

    return(0)  
end
 
@view
func check_hit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(square_commit : felt, square_reveal : felt) -> (hit : felt):
    let (hashed_square_reveal) = hash_numb(square_reveal)
    assert hashed_square_reveal = square_commit
    let (_,r) = unsigned_div_rem(square_reveal, 2)

    if r == 0:
        return (0)
    else:
        return (1)
    end
end

@view
func get_other_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(game_idx : felt) -> (other_player : felt):
    let (game) = games.read(game_idx)
    if game.player1.address == game.next_player:
        return (game.player2.address)
    else:
        return (game.player1.address)
    end
end

@external
func bombard{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(game_idx : felt, x : felt, y : felt, square_reveal : felt):
    alloc_locals
    # Check whether caller is one of the players
    let (caller_address) = get_caller_address()
    let (game) = games.read(game_idx)
    let (caller_authentified) = check_caller(caller_address, game)
    assert caller_authentified = 1

    # Check that game has not finished
    assert game.winner = 0

    # Check whether it is caller's turn
    # First move can be by anyone
    if game.next_player != 0:
        assert caller_address = game.next_player
    end

    let (other_player) = get_other_player(game_idx)

    # Declare hit on (x, y)
    let (square) = grid.read(game_idx, caller_address, x, y)
    let new_square = Square(square.square_commit, square.square_reveal, 1)
    grid.write(game_idx, caller_address, x, y, new_square)

    # If first move, update move and return
    if game.next_player == 0:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar bitwise_ptr = bitwise_ptr
        let updated_game = Game(game.player1, game.player2, other_player, (x, y), game.winner)        
        games.write(game_idx, updated_game)
        return ()
    # Else not first move, need to check `square_reveal` with `square_commit` of last hit
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar bitwise_ptr = bitwise_ptr
        let (last_hit_square) = grid.read(game_idx, other_player, game.last_move[0], game.last_move[1])
        let (check_hit_result) = check_hit(last_hit_square.square_commit, square_reveal)

        # No hit
        if check_hit_result == 0:
            let updated_game = Game(game.player1, game.player2, other_player, (x, y), game.winner)        
            games.write(game_idx, updated_game)
            return ()
        # Hit
        else:
            # This is really cumbersome logic, can we reduce it?
            if other_player == game.player1.address:
                let updated_player1 = Player(game.player1.address, game.player1.points + 1, game.player1.revealed)
                if game.player1.points + 1 == 4:
                    let updated_game = Game(updated_player1, game.player2, other_player, (x, y), game.player1.address)
                    games.write(game_idx, updated_game)
                    return ()
                else:
                    let updated_game = Game(updated_player1, game.player2, other_player, (x, y), game.winner)
                    games.write(game_idx, updated_game)
                    return ()
                end
            else:
                let updated_player2 = Player(game.player2.address, game.player2.points + 1, game.player2.revealed)
                if game.player2.points + 1 == 4:
                    let updated_game = Game(game.player1, updated_player2, other_player, (x, y), game.player1.address)
                    games.write(game_idx, updated_game)
                    return ()
                else:
                    let updated_game = Game(game.player1, updated_player2, other_player, (x, y), game.winner)
                    games.write(game_idx, updated_game)
                    return ()
                end
            end
        end
    end
end

## Check malicious call
@external
func add_squares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(idx : felt, game_idx : felt, hashes_len : felt, hashes : felt*, player : felt, x: felt, y: felt):
    let (caller_address) = get_caller_address()
    let (game) = games.read(game_idx)
    let (caller_authentified) = check_caller(caller_address, game)
    assert caller_authentified = 1
    load_hashes(idx, game_idx, hashes_len, hashes, player, x, y)
    return ()
end

## loops until array length
func load_hashes{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(idx : felt, game_idx : felt, hashes_len : felt, hashes : felt*, player : felt, x: felt, y: felt):
    # Recursion base case
    if hashes_len == 0:
        return()
    end

    let (square) = grid.read(game_idx, player, x, y)
    let new_square = Square([hashes], square.square_reveal, square.shot)
    grid.write(game_idx, player, x, y, new_square)

    # Recursive call
    if x == 4:
        load_hashes(idx, game_idx, hashes_len - 1, hashes + 1, player, x = 0, y = y + 1)
    else:
        load_hashes(idx, game_idx, hashes_len - 1, hashes + 1, player, x = x + 1, y = y)
    end

    return()
end