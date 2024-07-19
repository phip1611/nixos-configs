import sys

FILE = sys.argv[1]
SEARCH = sys.argv[2].strip()  # remove trailing newline
REPLACE = sys.argv[3].strip()  # remove trailing newline

with open(FILE, mode="r+") as f:
    content = f.read()
    if REPLACE in content:
        print(f".direnv seems to be already excluded {FILE}")
    else:
        f.seek(0)
        f.write(content.replace(SEARCH, REPLACE))
        print(f".direnv is now marked as excluded in {FILE}")
