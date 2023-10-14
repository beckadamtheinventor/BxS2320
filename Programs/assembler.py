
import os, sys
from PIL import Image

if __name__=='__main__':
	if len(sys.argv) >= 3:
		srcfile = sys.argv[1]
		destfile = sys.argv[2]
	else:
		srcfile = input("Program data file? ")
		destfile = input("Program Output Image? ")

	try:
		with open(srcfile, "rb") as f:
			data = f.read()
	except FileNotFoundError:
		print(f"File \"{srcfile}\" not found.")
		exit(-1)

	o = []
	for i in range(0, len(data), 2):
		if i + 1 < len(data):
			o.append(data[i] + data[i+1]*256)
		else:
			o.append(data[i])
	data = o

	i = Image.new("I;16", (4096,4096))
	px = i.load()
	for y in range(4096):
		for x in range(4096):
			if x + y * 4096 >= len(data):
				break
			# px[x, 255-y] = data[x + y * 256] // 256 | (data[x + y * 256] & 0xff) * 256
			px[x, 4095-y] = data[x + y * 4096]
			# print(f"Set pixel at {x}, {4095-y} to {data[x + y * 4096]}")
	i.save(destfile)

	with open(destfile+".txt", "w") as f:
		f.write(", ".join([hex(c) if c>=0 else hex(0x10000+c) for c in data]))

	with open(destfile+".bin", "wb") as f:
		f.write(b"".join([bytes([c&0xff, (c//256)&0xff]) for c in data]))
		if len(data) < 65536:
			f.write(bytes([0, 0]*(65536 - len(data))))

	print(f"Success. Output size {len(data)} words.")
