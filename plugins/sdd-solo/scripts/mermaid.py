#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mermaid.py — đọc khối ```mermaid trong file markdown: parse ra node/cạnh/nhãn, và lint.

Vì sao có file này (7.5.0, P-32). Tới 7.4 bốn chỗ đọc mermaid bằng grep từng dòng:
gate-check §5 (nhãn cạnh E#, id node, node kết), gate-check §6 (stateDiagram có mũi tên
gắn UC), br-check §7 (Impact Map có nhánh `-.->`), uc-steps ④ (có khối mermaid chưa).
grep không biết đâu là nhãn, đâu là tên node, đâu là chữ trong nháy kép — nên một node
`E1([Đăng nhập được])` từng làm cổng tin rằng đường lỗi E1 đã vẽ (#17), và 17/88 sơ đồ
của runxops KHÔNG RENDER ĐƯỢC mà cổng vẫn xanh (P-32).

Luật lint KHÔNG đoán: đo bằng chính mermaid (mermaid.parse + getDiagramFromText qua
jsdom, node 25) trên 88 khối thật của runxops cộng một ma trận 27 ký tự × 13 ngữ cảnh.
Hai loại hỏng, cùng một hậu quả "sơ đồ nói sai mà không ai biết":

  ① VỠ — mermaid ném lỗi, trình đọc hiện chữ đỏ thay cho hình:
     · nhãn node flowchart KHÔNG bọc nháy kép chứa ( ) [ ] { } |
     · nhãn bọc nháy kép chứa " lồng
     · dấu ; trong lời của sequenceDiagram (message · Note · alt/else/opt · participant as)
     · dấu ; trong nhãn quan hệ classDiagram; dấu : thứ hai trong nhãn quan hệ / note
  ② MẤT CHỮ IM LẶNG — parse qua nhưng nhãn không còn:
     · dấu ; trong nhãn `A --> B : lời` của stateDiagram-v2. Đo: mermaid sinh state rác
       tên ";" và "beta", còn quan hệ mang nhãn RỖNG. Sơ đồ vẫn vẽ ra, chỉ là mất lời.

KHÔNG tính là lỗi (đo được là vô hại): `;` trong nhãn flowchart (nhãn giữ nguyên) ·
`#` · `,` · `·` · `→` · `<br/>` · nháy đơn · dấu gạch · `%%` trong nháy.

Dùng:
  mermaid.py --lint  <file...>   # in <file>:<dòng>: <mã> <thông điệp>; exit 1 nếu có ✗ (mã MMD-E*)
  mermaid.py --edges <file>      # mỗi dòng một NHÃN CẠNH (chỉ nhãn, không tên node)
  mermaid.py --nodes <file>      # "<id>\t<hình>\t<nhãn>"
  mermaid.py --states <file>     # "<từ>\t<tới>\t<nhãn>" (stateDiagram · classDiagram)
  mermaid.py --kinds <file>      # mỗi dòng "<dòng bắt đầu>\t<loại>" của từng khối
Thêm --json để in JSON thay vì dòng.
"""
import sys, re, io, json

# ── tách khối ─────────────────────────────────────────────────────────────
FENCE = re.compile(r'^\s*```+\s*mermaid\s*$', re.I)
FENCE_END = re.compile(r'^\s*```+\s*$')


def blocks(path):
    """[(dòng đầu của nội dung (1-based), [dòng…])] — mọi khối ```mermaid của file."""
    try:
        L = io.open(path, encoding='utf-8').read().split('\n')
    except (IOError, OSError, UnicodeDecodeError):
        return []
    out, cur, start = [], None, 0
    for i, ln in enumerate(L):
        if cur is None:
            if FENCE.match(ln):
                cur, start = [], i + 2
        elif FENCE_END.match(ln):
            out.append((start, cur))
            cur = None
        else:
            cur.append(ln)
    if cur is not None:              # khối không đóng — vẫn trả, lint sẽ báo
        out.append((start, cur))
    return out


KIND_RE = re.compile(r'^\s*(flowchart|graph|sequenceDiagram|stateDiagram-v2|stateDiagram|'
                     r'classDiagram|erDiagram|journey|gantt|pie|mindmap|timeline|'
                     r'gitGraph|quadrantChart|requirementDiagram|C4Context|block-beta|sankey-beta)\b')


def kind_of(lines):
    for ln in lines:
        s = strip_comment(ln).strip()
        if not s or s.startswith('%%'):
            continue
        m = KIND_RE.match(s)
        return m.group(1) if m else '?'
    return '?'


def strip_comment(ln):
    """Bỏ `%%` tới hết dòng — nhưng không bỏ khi nó nằm trong nháy kép."""
    out, q, i = [], False, 0
    while i < len(ln):
        c = ln[i]
        if c == '"':
            q = not q
        if not q and ln.startswith('%%', i):
            break
        out.append(c)
        i += 1
    return ''.join(out)


def unquoted(s):
    """Thay nội dung mỗi "…" bằng khoảng trắng cùng độ dài — giữ chỉ số cột."""
    out, q = [], False
    for c in s:
        if c == '"':
            q = not q
            out.append('"')
        else:
            out.append(' ' if q else c)
    return ''.join(out)


# ── flowchart ─────────────────────────────────────────────────────────────
# Cặp mở/đóng của mọi hình, DÀI TRƯỚC NGẮN (([ phải thử trước ( và [)
SHAPES = [('(((', ')))', 'double-circle'), ('[[', ']]', 'subroutine'), ('[(', ')]', 'cylinder'),
          ('([', '])', 'stadium'), ('((', '))', 'circle'), ('{{', '}}', 'hexagon'),
          ('[/', '/]', 'parallelogram'), ('[\\', '\\]', 'parallelogram-alt'),
          ('[/', '\\]', 'trapezoid'), ('[\\', '/]', 'trapezoid-alt'),
          ('[', ']', 'rect'), ('(', ')', 'round'), ('{', '}', 'rhombus'), ('>', ']', 'asymmetric')]
ID_RE = re.compile(r'[A-Za-z0-9_][A-Za-z0-9_.-]*$')
LINK_RE = re.compile(r'(-{2,}>|={2,}>|-\.-+>|-{2,}x|-{2,}o|<-{2,}>|-{3,}|={3,}|-\.-+)')
KEYWORD = ('subgraph', 'end', 'direction', 'classDef', 'class', 'style', 'linkStyle',
           'click', 'accTitle', 'accDescr', 'flowchart', 'graph')


def fc_parse(lines):
    """→ (nodes, edges, errs). nodes: [(dòng, id, hình, nhãn, có nháy)] ·
    edges: [(dòng, nhãn)] · errs: [(dòng, mã, thông điệp)]"""
    nodes, edges, errs = [], [], []
    for n, raw in enumerate(lines, 1):
        ln = strip_comment(raw)
        s = ln.strip()
        if not s:
            continue
        w = s.split()[0] if s.split() else ''
        if w in KEYWORD:
            continue
        i = 0
        while i < len(ln):
            c = ln[i]
            # nhãn cạnh |…|  — chỉ tính khi đứng ngay sau một mũi tên
            if c == '|':
                j = ln.find('|', i + 1)
                if j < 0:
                    errs.append((n, 'MMD-E01', 'nhãn cạnh mở bằng | mà không có | đóng'))
                    break
                before = ln[:i].rstrip()
                if LINK_RE.search(before[-6:]) or before.endswith('--') or before.endswith('=='):
                    lbl = ln[i + 1:j]
                    t = lbl.strip()
                    # nhãn cạnh bọc nháy kép: -->|"lời (có ngoặc)"| — hợp lệ, và runxops dùng thường
                    if t.startswith('"') and t.endswith('"') and len(t) >= 2:
                        edges.append((n, t[1:-1]))
                        _check_label(n, t[1:-1], True, errs, 'nhãn cạnh')
                    else:
                        edges.append((n, t))
                        _check_label(n, lbl, False, errs, 'nhãn cạnh')
                i = j + 1
                continue
            hit = None
            for op, cl, shape in SHAPES:
                if not ln.startswith(op, i):
                    continue
                m = ID_RE.search(ln[:i])
                if not m:
                    continue
                body_at = i + len(op)
                if ln[body_at:].lstrip().startswith('"'):
                    # Nhãn bọc nháy kép: dấu " đóng quyết định hết nhãn, KHÔNG phải dấu ] đầu tiên —
                    # `W4["… · [VIỆC LỖI]"]` là nhãn hợp lệ, mermaid nhận (đo trên runxops br-006).
                    qs = ln.index('"', body_at)
                    qe = ln.find('"', qs + 1)
                    if qe < 0:
                        errs.append((n, 'MMD-E02', 'nhãn mở nháy kép mà không đóng: ' + ln[qs:qs + 40]))
                        hit = len(ln)
                        break
                    j = ln.find(cl, qe + 1)
                    if j < 0:
                        continue
                    label, quoted = ln[qs + 1:qe], True
                else:
                    j = ln.find(cl, body_at)
                    if j < 0:
                        continue
                    label, quoted = ln[body_at:j], False
                nodes.append((n, m.group(0), shape, label.strip(), quoted))
                _check_label(n, label, quoted, errs, 'nhãn node ' + m.group(0))
                hit = j + len(cl)
                break
            if hit is not None:
                i = hit
                continue
            i += 1
    return nodes, edges, errs


BREAK_CHARS = '()[]{}|'


def _check_label(n, label, quoted, errs, what):
    if quoted:
        if '"' in label:
            errs.append((n, 'MMD-E02', what + ': nháy kép lồng trong nhãn đã bọc nháy kép — mermaid vỡ'))
        return
    bad = sorted(set(c for c in label if c in BREAK_CHARS))
    if bad:
        errs.append((n, 'MMD-E01', what + ' chưa bọc nháy kép mà có ' + ' '.join(bad)
                     + ' — mermaid vỡ; bọc nhãn trong "…"'))


# ── sequence · state · class ──────────────────────────────────────────────
SEQ_MSG = re.compile(r'^\s*[A-Za-z0-9_"][^:]*?(->>|-->>|->|-->|-[)x]|--[)x])[^:]*:(?P<t>.*)$')
SEQ_TEXT = re.compile(r'^\s*(Note\s+(over|left of|right of)[^:]*:|participant\s+\S+\s+as\s+|'
                      r'actor\s+\S+\s+as\s+|alt\s+|else\s+|opt\s+|loop\s+|par\s+|and\s+|critical\s+|'
                      r'rect\s+|box\s+|autonumber\b)', re.I)
ST_REL = re.compile(r'^\s*(?P<a>[^\s:]+)\s*(?P<ar>-->|--)\s*(?P<b>[^\s:]+)\s*(?::\s*(?P<t>.*))?$')
ST_NOTE = re.compile(r'^\s*note\s+(left|right)\s+of\s+[^:]+:(?P<t>.*)$', re.I)
ST_DESC = re.compile(r'^\s*(?P<a>[A-Za-z0-9_]+)\s*:\s*(?P<t>.+)$')
CL_REL = re.compile(r'^\s*\S+\s*(?:"[^"]*"\s*)?(?:<\|--|--\|>|\*--|o--|--\*|--o|<--|-->|--|\.\.>|<\.\.|\.\.)'
                    r'\s*(?:"[^"]*"\s*)?\S+\s*:\s*(?P<t>.*)$')


def other_lint(kind, lines):
    """sequence · state · class — ; và : theo bảng đo."""
    errs = []
    for n, raw in enumerate(lines, 1):
        ln = strip_comment(raw)
        u = unquoted(ln)
        if kind == 'sequenceDiagram':
            m = SEQ_MSG.match(ln)
            txt = m.group('t') if m else (ln if SEQ_TEXT.match(ln) else None)
            if txt is not None and ';' in unquoted(txt):
                errs.append((n, 'MMD-E03', 'dấu ; trong lời của sequenceDiagram — mermaid coi là hết câu và VỠ; '
                                           'đổi thành — hoặc · , hoặc bọc cả lời trong "…"'))
        elif kind.startswith('stateDiagram'):
            m = ST_REL.match(ln) or ST_NOTE.match(ln) or ST_DESC.match(ln)
            txt = (m.group('t') if m and m.groupdict().get('t') else None)
            if txt and ';' in unquoted(txt):
                errs.append((n, 'MMD-E04', 'dấu ; trong nhãn của stateDiagram — nhãn MẤT TRẮNG khi render '
                                           '(mermaid cắt câu, sinh state rác); đổi thành — hoặc ·'))
            if ST_NOTE.match(ln) and ':' in unquoted(ST_NOTE.match(ln).group('t')):
                errs.append((n, 'MMD-E05', 'dấu : thứ hai trong note của stateDiagram — mermaid vỡ'))
        elif kind == 'classDiagram':
            m = CL_REL.match(ln)
            if m:
                t = unquoted(m.group('t'))
                if ';' in t:
                    errs.append((n, 'MMD-E03', 'dấu ; trong nhãn quan hệ classDiagram — mermaid vỡ'))
                if ':' in t:
                    errs.append((n, 'MMD-E05', 'dấu : thứ hai trong nhãn quan hệ classDiagram — mermaid vỡ'))
    return errs


# ── API ───────────────────────────────────────────────────────────────────
def analyze(path):
    """[(dòng đầu khối, loại, nodes, edges, states, errs)] — dòng đã quy về dòng THẬT của file."""
    out = []
    for start, lines in blocks(path):
        kind = kind_of(lines)
        nodes = edges = states = []
        errs = []
        if kind in ('flowchart', 'graph'):
            nodes, edges, errs = fc_parse(lines)
        else:
            errs = other_lint(kind, lines)
            if kind.startswith('stateDiagram') or kind == 'classDiagram':
                states = st_rels(lines)
        off = start - 1
        out.append((start, kind,
                    [(n + off,) + t[1:] for t in nodes for n in (t[0],)],
                    [(t[0] + off, t[1]) for t in edges],
                    [(t[0] + off,) + t[1:] for t in states for n in (t[0],)],
                    [(e[0] + off, e[1], e[2]) for e in errs]))
    return out


def st_rels(lines):
    out = []
    for n, raw in enumerate(lines, 1):
        ln = strip_comment(raw)
        m = ST_REL.match(ln) or CL_REL.match(ln)
        if not m:
            continue
        g = m.groupdict()
        out.append((n, g.get('a', ''), g.get('b', ''), (g.get('t') or '').strip()))
    return out


def main(argv):
    if len(argv) < 3 or argv[1] not in ('--lint', '--edges', '--nodes', '--states', '--kinds'):
        sys.stderr.write(__doc__.split('Dùng:')[-1].strip() + '\n')
        return 2
    mode, files = argv[1], [a for a in argv[2:] if a != '--json']
    as_json = '--json' in argv
    rc, acc = 0, []
    for f in files:
        for start, kind, nodes, edges, states, errs in analyze(f):
            if mode == '--lint':
                for n, code, msg in errs:
                    acc.append({'file': f, 'line': n, 'code': code, 'msg': msg})
                    if not as_json:
                        sys.stdout.write('%s:%d: %s %s\n' % (f, n, code, msg))
                    rc = 1
            elif mode == '--edges':
                for n, lbl in edges:
                    acc.append({'file': f, 'line': n, 'label': lbl})
                    if not as_json and lbl:
                        sys.stdout.write('%s\n' % lbl)
            elif mode == '--nodes':
                for n, nid, shape, lbl, q in nodes:
                    acc.append({'file': f, 'line': n, 'id': nid, 'shape': shape, 'label': lbl})
                    if not as_json:
                        sys.stdout.write('%s\t%s\t%s\n' % (nid, shape, lbl))
            elif mode == '--states':
                for n, a, b, t in states:
                    acc.append({'file': f, 'line': n, 'from': a, 'to': b, 'label': t})
                    if not as_json:
                        sys.stdout.write('%s\t%s\t%s\n' % (a, b, t))
            elif mode == '--kinds':
                acc.append({'file': f, 'line': start, 'kind': kind})
                if not as_json:
                    sys.stdout.write('%d\t%s\n' % (start, kind))
    if as_json:
        sys.stdout.write(json.dumps(acc, ensure_ascii=False) + '\n')
    return rc


if __name__ == '__main__':
    sys.exit(main(sys.argv))
