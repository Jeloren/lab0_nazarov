def reverse_bits_simple(data, length):

    left = 0
    right = length - 1
    
    while left < right:
        left_byte = left // 8
        left_bit = left % 8
        right_byte = right // 8  
        right_bit = right % 8
        
        bit_left = (data[left_byte] >> left_bit) & 1
        bit_right = (data[right_byte] >> right_bit) & 1
        
        if bit_left != bit_right:
            data[left_byte] ^= (1 << left_bit)
            data[right_byte] ^= (1 << right_bit)
        
        left += 1
        right -= 1
    
    return data

if __name__ == "__main__":
    test_data = [0xB1, 0x95]
    bits_count = 16
    
    result = reverse_bits_simple(test_data, bits_count)
    print("Результат:", [hex(x) for x in result])