def bit_expand(source_bytes: bytes, bit_len: int) -> bytes:

    input_bits = []
    for i in range(bit_len):
        byte_idx = i // 8
        bit_idx = i % 8
        bit = (source_bytes[byte_idx] >> bit_idx) & 1
        input_bits.append(bit)

    output_bits = []
    for bit in input_bits:
        if bit == 0:
            output_bits.extend([1, 0])
        else:
            output_bits.extend([0, 1])




    result_bytes = bytearray()
    for i in range(0, len(output_bits), 8):
        byte_val = 0
        for j in range(8):
            if i + j < len(output_bits):
                if output_bits[i + j]:
                    byte_val |= (1 << j)
        result_bytes.append(byte_val)

    return bytes(result_bytes)


if __name__ == "__main__":
    source = bytes([0x15])
    n = 5
    result = bit_expand(source, n)
    print("Исходные байты:", source.hex())
    print("Результат (hex):", result.hex())
    print("Ожидаемо: 66 02 →", "✅" if result[:2] == bytes([0x66, 0x02]) else "❌")