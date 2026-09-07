---
paths:
  - "**/*.drawio"
---

# Draw.io Conventions

## Background

- All diagrams must export on an opaque white background, never transparent. A transparent export inverts to unreadable on a dark background in Confluence, Slack, and PDF viewers.
- For `.drawio` files, set `background="#ffffff"` on the `mxGraphModel` element. This is the attribute draw.io writes from Format > Diagram > Background, and it is what export reads.

## Process

- Generate `.drawio` XML from a Python script, not by hand-editing. Layout is arithmetic; hand-placed coordinates drift and duplicate ids creep in.
- Render and look at every iteration before reporting: `drawio -x -f png -s 1 -o /tmp/d.png file.drawio`, then read the PNG. Never describe a diagram you have not looked at.

## Validation

- Assert unique `id` on every `mxCell` before writing the file. The `drawio` CLI renders duplicates happily; the desktop app refuses to open the file with "Duplicate ID".
- Parse the XML (`xml.dom.minidom.parseString`) before writing, not after.
- HTML in a `value` attribute must be escaped once, whole: build `<b>Name</b><br><font ...>sub</font>` then escape it. Raw `<` or `"` inside the attribute is invalid XML.
- Probe an unfamiliar stencil name before using it. An unknown `shape=` renders as a filled rectangle, silently.
- Validate the rendered file, not just its syntax: the `<diagram>` node has no non-whitespace text outside `<mxGraphModel>`; no vertex extends past `pageWidth`/`pageHeight`; no two vertices overlap; every edge `source` and `target` resolves to an existing id; every `text;` style cell has `whiteSpace=wrap`. XML well-formedness catches none of these.

## Layout

- Size cards to their text and the page to its content. Do not pad to a fixed canvas width, and do not stretch a card to three times the width of its longest line.
- A container that holds one child is not worth its border. Fold it into the child's label.
- Prefer a graphical chain of cards over a numbered prose list for a sequence.
- Never break the grid to emphasise something. Emphasis is colour, not displacement. The operator may override this in some cases.

## Edges

- Anchor edges to whole cards, never to a bare icon with text floating beside it. Icon-anchored edges dogleg around the labels.
- Give connected nodes the same centre line, then set explicit `exitX/exitY` and `entryX/entryY`. If a line bends, the two anchors disagree; fix the geometry, not the router.
- No line may travel the width of the diagram, reverse direction, or pass through a card that is not its endpoint.
- Put edge labels beside the line with `<mxPoint as="offset">`, not on it. `labelBackgroundColor` paints out a short line and leaves two stubs.
- Check that a label sits in clear space, not across a container border.

## Shapes and icons

- Prefer native stencil shapes for branded objects. For example the Azure, Kubernetes, and AWS stencil libraries.
- Respect each stencil's native aspect ratio. Forcing a square on a shape that is 0.52 or 1.62 wide squashes the art.
- Read the real ratios from the bundled stencils rather than guessing: `/Applications/draw.io.app/Contents/Resources/app.asar`, files under `stencils/`, each `<shape>` carries `w` and `h`.
- Never use an emoji as a diagram glyph. It renders differently on every machine. Use a vector stencil, or embed a PNG as a `data:` URI so the file is self-contained.

## Colour and emphasis

- To mark the current or relevant item, change its background and border only. Leave the text colour alone: recoloured body text loses contrast and reads as a second meaning.
- Keep highlights subtle and warm. One accent per diagram.
- Bind a colour to a meaning and hold it across the whole set: one colour for identity, one for data flow, one for the thing being highlighted.
