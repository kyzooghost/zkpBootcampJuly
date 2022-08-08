%builtins range_check
# from starkware.cairo.common.serialize import serialize_word

## Perform and log output of simple arithmetic operations
func simple_math{range_check_ptr}():
# func simple_math{output_ptr : felt*, range_check_ptr}():
    
    %{         
        print(13+14)         
        print(3+6)        
        print(6/2)        
        print(70/2)        
        print(7/2)        
    %}    

    ## adding 13 +  14
    tempvar a = 13 + 14 

    # ## multiplying 3 * 6
    # tempvar b = 3 * 6

    # ## dividing 6 by 2
    # tempvar c = 6 / 2

    # ## dividing 70 by 2
    # tempvar d = 70 / 2

    # ## dividing 7 by 2 
    # tempvar e = 7 / 2

    serialize_word(a)
    # serialize_word(b)
    # serialize_word(c)
    # serialize_word(d)
    # serialize_word(e)
    return ()
end