## I AM NOT DONE

from starkware.cairo.common.math import abs_value

## Implement a funcion that returns: 
## - 1 when magnitudes of inputs are equal
## - 0 otherwise
func abs_eq{range_check_ptr}(x : felt, y : felt) -> (bit : felt):
    let (a) = abs_value(x)
    let (b) = abs_value(y)
        
    # if x * x == y * y:
    #     return (1)
    # end

    if a == b:
        return (1)
    end

    return (0)    
end
