## I AM NOT DONE

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_unsigned_div_rem, uint256_sub
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import unsigned_div_rem, assert_le_felt

from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_nn,
    assert_le,
    assert_lt,    
    assert_in_range,
)


from exercises.contracts.erc20.ERC20_base import (
    ERC20_name,
    ERC20_symbol,
    ERC20_totalSupply,
    ERC20_decimals,
    ERC20_balanceOf,
    ERC20_allowance,
    ERC20_mint,

    ERC20_initializer,       
    ERC20_transfer,    
    ERC20_burn
)

#
# Variables
#

@storage_var
func whitelist(address : felt) -> (whitelisted: felt):
end

@storage_var
func admin_address() -> (admin_address: felt):
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        initial_supply_0: felt,
        initial_supply_1: felt,
        recipient: felt,
    ):
    ERC20_initializer(name, symbol, Uint256(initial_supply_0, initial_supply_1), recipient)    
    admin_address.write(recipient)
    return ()
end

#
# Getters
#

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC20_name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC20_symbol()
    return (symbol)
end

@view
func totalSupply{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (totalSupply: Uint256):
    let (totalSupply: Uint256) = ERC20_totalSupply()
    return (totalSupply)
end

@view
func decimals{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (decimals: felt):
    let (decimals) = ERC20_decimals()
    return (decimals)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC20_balanceOf(account)
    return (balance)
end

@view
func allowance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, spender: felt) -> (remaining: Uint256):
    let (remaining: Uint256) = ERC20_allowance(owner, spender)
    return (remaining)
end

#
# Externals
#

@external
func transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient: felt, amount: Uint256) -> (success: felt):
    let (_,r) = unsigned_div_rem(amount.low, 2)
    assert r = 0
    ERC20_transfer(recipient, amount)    
    return (1)
end

@external
func faucet{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(amount: Uint256) -> (success: felt):
    let (caller) = get_caller_address()
    assert_le_felt(amount.low, 10000)
    ERC20_mint(caller, amount)
    return (1)
end

@external
func burn{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(amount: Uint256) -> (success: felt):   
    let (caller) = get_caller_address()
    ERC20_burn(caller, amount)
    let (admin_addr) = admin_address.read()
    ERC20_mint(admin_addr, Uint256(50, 0))
    return (1)
end

##

@view
func check_whitelist{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (allowed_v: felt):
    let (allowed_v) = whitelist.read(account)
    return (allowed_v)
end

@external
func request_whitelist{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (level_granted: felt):   
    let (caller_address) = get_caller_address()
    whitelist.write(caller_address, 1)
    return (1)
end

@view
func get_admin{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (admin_address: felt):
    let (admin_addr) = admin_address.read()
    return (admin_addr)
end

@external
func exclusive_faucet{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(amount : Uint256) -> (success: felt):   
    let (caller) = get_caller_address()
    let (allowed_v) = check_whitelist(caller)
    assert allowed_v = 1
    let (admin_addr) = admin_address.read()
    ERC20_mint(caller, amount)
    ERC20_mint(admin_addr, amount)
    return (1)
end

