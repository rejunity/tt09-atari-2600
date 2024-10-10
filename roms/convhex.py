import binascii
import sys

# Ensure there's at least one argument passed to avoid IndexError
if len(sys.argv) < 2:
    print("Usage: script.py <filename>")
    sys.exit(1)

i = 0
filename = sys.argv[1] + '.bin'
with open(filename, 'rb') as f:
    content = f.read()
    while i < 4096:
        for x in content:
            # Convert the integer to a bytes object of length 1
            # before passing it to hexlify
            print(binascii.hexlify(bytes([x])).decode('utf-8'))
            i += 1
            if i == 4096:
                break

#import binascii
#import sys
#i = 0
#filename = sys.argv[1] + '.bin'
#with open(filename, 'rb') as f:
#    content = f.read()
#    for x in content:
#        print(binascii.hexlify(x))
#        i += 1
#        if i == 4096:
#            break
