"""Add titles and navigation to a novella's chapter files and typeset the
chapter prose (curly quotes, scene breaks).  Idempotent.

usage: finish_volume.py DIR "Novella Title" spec.txt
spec.txt lines:  NN-slug.org|Chapter title|Part One: Name
"""
import re, sys, pathlib

def smart(text):
    OPEN_D, CLOSE_D, OPEN_S, CLOSE_S, DASH = "“", "”", "‘", "’", "—"
    out = []
    for i, ch in enumerate(text):
        prev = text[i - 1] if i else "\n"
        nxt = text[i + 1] if i + 1 < len(text) else "\n"
        if ch == '"':
            if prev in DASH + "/":
                out.append(CLOSE_D if nxt in " \n.,;:!?)" else OPEN_D)
            else:
                out.append(OPEN_D if prev in " \n\t([" + OPEN_S else CLOSE_D)
        elif ch == "'":
            if text[i + 1:i + 3] == "em" and prev in " \n":
                out.append(CLOSE_S)
            elif prev in " \n\t([" + OPEN_D + DASH and (nxt.isalnum() or nxt == "/"):
                out.append(OPEN_S)
            else:
                out.append(CLOSE_S)
        else:
            out.append(ch)
    return "".join(out)

def main(directory, novella, spec):
    d = pathlib.Path(directory)
    rows = [l.strip().split("|") for l in open(spec) if l.strip()]
    for n, (fname, title, part) in enumerate(rows):
        p = d / fname
        s = p.read_text()
        if s.startswith("#+title"):
            s = s[s.index("* The chapter"):]
        head, sep, rest = s.partition("\n* What ")
        assert sep, fname
        head = re.sub(r"(?m)^\*$", "-----", head)
        body = head[len("* The chapter"):]
        body = smart(body.replace("“", '"').replace("”", '"')
                         .replace("‘", "'").replace("’", "'"))
        s = "* The chapter" + body + sep + rest
        num = n + 1
        link = lambda r, k: "[[file:%s][%d. %s]]" % (r[0], k, r[1])
        nav = []
        if n: nav.append("Previous: " + link(rows[n - 1], num - 1))
        nav.append("[[file:README.org][Contents]]")
        nav.append("Next: " + (link(rows[n + 1], num + 1) if n + 1 < len(rows)
                               else "[[file:appendix.org][How the story was built]]"))
        header = ("#+title: %d. %s\n#+subtitle: %s · %s\n#+startup: showall\n"
                  "#+options: toc:nil num:nil\n\n%s\n\n" % (num, title, novella, part, " · ".join(nav)))
        p.write_text(header + s)
    print("finished", len(rows), "chapters")

if __name__ == "__main__":
    main(*sys.argv[1:4])
