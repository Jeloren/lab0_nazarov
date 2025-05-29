start_str = "Hello world asm"
length = 30

def len_start_str(stroka):
    return len(stroka)

def insblanks(start_str, length):
    lenght_start_str = len_start_str(start_str)
    if (length <= lenght_start_str) or (lenght_start_str == 0):
        return 0
    need_spaces = length - lenght_start_str
    for ch in range():
        print(start_str[ch])
        if start_str[ch] == ' ':
            print(start_str[ch:], start_str[:ch])
            pr_str = start_str
            start_str = pr_str[:ch] + ' ' + pr_str[ch:]
    return start_str

print(start_str)
print(insblanks(start_str, length))

