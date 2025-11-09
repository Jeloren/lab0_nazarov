def bit_expand_proc(source_bytes, result_bytes, bit_length):
    dest_abs_bit_pos = 0

    for i in range(bit_length):
        src_byte_idx = i // 8
        src_bit_pos = i % 8

        if src_byte_idx >= len(source_bytes):
            source_bit = 0
        else:
            source_byte = source_bytes[src_byte_idx]
            source_bit = (source_byte >> src_bit_pos) & 1

        if source_bit == 0:
            expanded_bits = [0, 1]
        else:
            expanded_bits = [1, 0]

        for bit_val in expanded_bits:
            dest_byte_idx = dest_abs_bit_pos // 8
            dest_bit_offset = dest_abs_bit_pos % 8

            if dest_byte_idx < len(result_bytes):
                if bit_val == 1:
                    result_bytes[dest_byte_idx] |= (1 << dest_bit_offset)
                else:
                    result_bytes[dest_byte_idx] &= ~(1 << dest_bit_offset)

            dest_abs_bit_pos += 1

    return result_bytes

source_data = [0x15, 0x00]
result_buffer = [0, 0, 0]

final_result = bit_expand_proc(source_data, result_buffer, 5)

print(f"Исходные данные: {[hex(b) for b in source_data]}, Длина: 5 бит")
print(f"Полученный результат: {[hex(b) for b in final_result]}")