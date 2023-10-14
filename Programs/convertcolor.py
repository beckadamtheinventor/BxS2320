
import sys

def convertColorTo1555(r, g, b, i=False):
	r = min(255, max(0, r))
	g = min(255, max(0, g))
	b = min(255, max(0, b))
	rgb = (r // 8) * 2**10 + (g // 8) * 2**5 + (b // 8)
	if i:
		return 0x8000 + rgb
	return rgb

if __name__=='__main__':
	if len(sys.argv) >= 4:
		if len(sys.argv) >= 5:
			color = convertColorTo1555(int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), (sys.argv[4] in ("inverted", "true", "1")))
		else:
			color = convertColorTo1555(int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]))
		print(f"1555 color value: {color} ({hex(color)})")
	else:
		print(f"Usage: {sys.argv[0]} r g b [inverted]")

