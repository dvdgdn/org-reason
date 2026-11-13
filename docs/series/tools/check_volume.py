"""Checks from docs/series: rule 5 (no software in chapters), keys exist,
links resolve, typography, chapter lengths."""
import re, sys, pathlib
d = pathlib.Path(sys.argv[1]); repo = pathlib.Path(sys.argv[2])
keys_ok = set("c C i x d a e w p f o s ! m I D v M / h E A ?".split()) | {"t "+k for k in "c v n l a ? g x P".split()}
bad = 0
total = 0
for p in sorted(d.glob("[0-9][0-9]-*.org")):
    s = p.read_text()
    chap = s[s.index("* The chapter"):s.index("\n* What ")]
    rest = s[s.index("\n* What "):]
    words = len(chap.split()); total += words
    probs = []
    for w in ("Org Reason", "Emacs", "Reason Commons", "C-c", "commons"):
        if w in chap: probs.append("software word in chapter: " + w)
    if '"' in chap or re.search(r"(?<![=~])'(?![=~])", chap): probs.append("straight quote left in chapter")
    if re.search(r"“[ \n]", chap) or re.search(r"[ \n]”", chap): probs.append("quote facing the wrong way")
    for k in re.findall(r"~C-c r ([^~]+)~", rest):
        if k.strip() not in keys_ok: probs.append("unknown key: C-c r " + k)
    heads = re.findall(r"(?m)^\* (.+)$", s)
    for l in re.findall(r"\[\[file:([^\]]+)\]", s):
        if not (p.parent / l).exists(): probs.append("broken link " + l)
    if not (900 <= words <= 2200): probs.append("chapter length %d" % words)
    print("%-34s %5d words  sections=%d  %s" % (p.name, words, len(heads), "; ".join(probs) or "ok"))
    bad += len(probs)
for name in ("README.org", "appendix.org"):
    s = (d / name).read_text()
    for l in re.findall(r"\[\[file:([^\]]+)\]", s):
        if not (d / l).exists(): print(name, "broken link", l); bad += 1
print("story words:", total, " problems:", bad)
