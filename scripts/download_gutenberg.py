#!/usr/bin/env python3
"""Download Project Gutenberg / CCEL texts and split into chapter files."""

import os
import re
import urllib.request

BASE = "/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Resources"


def download(url):
    """Download text from URL."""
    print(f"  Downloading {url} ...")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        raw = resp.read()
        for enc in ["utf-8", "latin-1"]:
            try:
                return raw.decode(enc)
            except UnicodeDecodeError:
                continue
        return raw.decode("utf-8", errors="replace")


def strip_gutenberg(text):
    """Remove PG header and footer."""
    for marker in [
        "*** START OF THE PROJECT GUTENBERG EBOOK",
        "*** START OF THIS PROJECT GUTENBERG EBOOK",
    ]:
        idx = text.upper().find(marker.upper())
        if idx != -1:
            nl = text.find("\n", idx)
            text = text[nl + 1:] if nl != -1 else text[idx + len(marker):]
            break
    for marker in [
        "*** END OF THE PROJECT GUTENBERG EBOOK",
        "*** END OF THIS PROJECT GUTENBERG EBOOK",
        "End of the Project Gutenberg EBook",
        "End of Project Gutenberg",
    ]:
        idx = text.upper().find(marker.upper())
        if idx != -1:
            text = text[:idx]
            break
    return text.strip()


def strip_ccel_header(text):
    """Remove CCEL metadata header. Content starts after 3rd ____ divider."""
    divider = "_" * 40
    parts = text.split(divider)
    if len(parts) >= 4:
        return divider.join(parts[3:]).strip()
    return text.strip()


def strip_ccel_footer(text):
    """Remove CCEL index/footer."""
    for marker in ["\nIndex of Scripture References", "\nIndexes\n"]:
        idx = text.find(marker)
        if idx != -1:
            text = text[:idx]
    return text.strip()


def clean_text(text):
    """Normalize whitespace, fix encoding, join broken paragraphs."""
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = text.replace("\u00a0", " ")
    text = text.replace("\u2018", "'").replace("\u2019", "'")
    text = text.replace("\u201c", '"').replace("\u201d", '"')
    text = text.replace("\u2014", "--").replace("\u2013", "-")
    # Remove CCEL divider lines and standalone underscore lines
    text = re.sub(r"\n\s*_{10,}\s*\n", "\n\n", text)
    text = re.sub(r"^\s*_{10,}\s*$", "", text, flags=re.MULTILINE)

    paragraphs = re.split(r"\n\s*\n", text)
    cleaned = []
    for para in paragraphs:
        para = para.strip()
        if not para:
            continue
        lines = [l.strip() for l in para.split("\n")]
        if len(lines) <= 1:
            cleaned.append(lines[0] if lines else "")
            continue
        short_lines = sum(1 for l in lines if len(l) < 50)
        if short_lines > len(lines) * 0.7:
            cleaned.append("\n".join(lines))
        else:
            joined = " ".join(lines)
            joined = re.sub(r"  +", " ", joined)
            cleaned.append(joined)
    return "\n\n".join(cleaned)


def write_chapter(filepath, header_lines, body):
    """Write a chapter file with 4-line header and body."""
    body = clean_text(body)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header_lines) + "\n\n" + body + "\n")
    print(f"    Written: {os.path.basename(filepath)} ({len(body)} chars)")


# ═══════════════════════════════════════════════════════
# 1. Augustine's Confessions (PG #3296)
# ═══════════════════════════════════════════════════════
def process_confessions():
    print("\n=== Augustine's Confessions (PG #3296) ===")
    text = download("https://www.gutenberg.org/cache/epub/3296/pg3296.txt")
    text = strip_gutenberg(text)
    outdir = os.path.join(BASE, "Confessions")

    roman = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII"]
    roman_lower = ["i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x", "xi", "xii", "xiii"]

    pattern = r"(?=\bBOOK\s+(?:" + "|".join(roman) + r")\b)"
    parts = re.split(pattern, text, flags=re.IGNORECASE)

    chapters = []
    for part in parts:
        m = re.match(r"\s*BOOK\s+(" + "|".join(roman) + r")\b", part, re.IGNORECASE)
        if m:
            idx = roman.index(m.group(1).upper())
            chapters.append((idx, m.group(1).upper(), part))

    titles = []
    for idx, num_roman, body in chapters:
        num = idx + 1
        fname = f"{num:02d}-book-{roman_lower[idx]}.txt"
        title = f"Book {num_roman}"
        titles.append(title)
        header = [
            "# Confessions, by Augustine of Hippo",
            f"# Section: {title}",
            "# Translator: Edward Bouverie Pusey",
            "# Source: Project Gutenberg #3296",
        ]
        write_chapter(os.path.join(outdir, fname), header, body)

    print(f"  Total: {len(chapters)} files")
    return titles


# ═══════════════════════════════════════════════════════
# 2. Humility by Andrew Murray (PG #57121)
# ═══════════════════════════════════════════════════════
def process_humility():
    print("\n=== Humility by Andrew Murray (PG #57121) ===")
    text = download("https://www.gutenberg.org/cache/epub/57121/pg57121.txt")
    text = strip_gutenberg(text)
    outdir = os.path.join(BASE, "Humility")

    toc_titles = [
        "Humility: The Glory of the Creature",
        "Humility: The Secret of Redemption",
        "The Humility of Jesus",
        "Humility in the Teaching of Jesus",
        "Humility in the Disciples of Jesus",
        "Humility in Daily Life",
        "Humility and Holiness",
        "Humility and Sin",
        "Humility and Faith",
        "Humility and Death to Self",
        "Humility and Happiness",
        "Humility and Exaltation",
    ]
    roman_labels = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]

    # Find positions of each "^X." marker on its own line
    positions = []
    for label in roman_labels:
        # Match the roman numeral on its own line (possibly with a period)
        pattern = rf"(?m)^{re.escape(label)}\.\s*$"
        m = re.search(pattern, text)
        if m:
            positions.append(m.start())

    # Sort and extract chapters
    positions.sort()
    chapters = []
    for i, pos in enumerate(positions):
        end = positions[i + 1] if i + 1 < len(positions) else len(text)
        chapters.append(text[pos:end])

    titles = []
    for i, body in enumerate(chapters):
        num = i + 1
        title = toc_titles[i] if i < len(toc_titles) else f"Chapter {num}"
        fname = f"{num:02d}-chapter-{num:02d}.txt"
        titles.append(f"Chapter {num}: {title}")
        header = [
            "# Humility, by Andrew Murray",
            f"# Section: Chapter {num}: {title}",
            "# Source: Project Gutenberg #57121",
            "#",
        ]
        write_chapter(os.path.join(outdir, fname), header, body)

    print(f"  Total: {len(chapters)} files")
    return titles


# ═══════════════════════════════════════════════════════
# 3. Absolute Surrender by Andrew Murray (CCEL)
# ═══════════════════════════════════════════════════════
def process_absolute_surrender():
    print("\n=== Absolute Surrender by Andrew Murray (CCEL) ===")
    text = download("https://ccel.org/ccel/m/murray/surrender/cache/surrender.txt")
    text = strip_ccel_header(text)
    text = strip_ccel_footer(text)
    outdir = os.path.join(BASE, "AbsoluteSurrender")

    # Known chapter titles from the text (in order of appearance)
    known_titles = [
        "Absolute Surrender",
        "The Fruit of the Spirit Is Love",
        "Separated Unto the Holy Ghost",
        "Peter's Repentance",
        "Impossible with Man, Possible with God",
        "O Wretched Man That I Am!",
        "Having Begun in the Spirit",
        "Kept by the Power of God",
        "Ye Are the Branches",
    ]

    # Split on ____ dividers
    divider_re = r"\n\s*_{20,}\s*\n"
    sections = re.split(divider_re, text)

    chapters = []
    for section in sections:
        section = section.strip()
        if not section or len(section) < 100:
            continue
        # Skip index sections
        first_line = ""
        for line in section.split("\n")[:5]:
            line = line.strip()
            if line:
                first_line = line
                break
        if "index" in first_line.lower() or "indexes" in first_line.lower():
            continue
        chapters.append(section)

    titles = []
    for i, body in enumerate(chapters):
        num = i + 1
        title = known_titles[i] if i < len(known_titles) else f"Chapter {num}"

        fname = f"{num:02d}-chapter-{num:02d}.txt"
        titles.append(f"Chapter {num}: {title}")
        header = [
            "# Absolute Surrender, by Andrew Murray",
            f"# Section: Chapter {num}: {title}",
            "# Source: CCEL (Public Domain)",
            "#",
        ]
        write_chapter(os.path.join(outdir, fname), header, body)

    print(f"  Total: {len(titles)} files")
    return titles


# ═══════════════════════════════════════════════════════
# 4. With Christ in the School of Prayer (CCEL)
# ═══════════════════════════════════════════════════════
def process_school_of_prayer():
    print("\n=== With Christ in the School of Prayer (CCEL) ===")
    text = download("https://ccel.org/ccel/m/murray/prayer/cache/prayer.txt")
    text = strip_ccel_header(text)
    text = strip_ccel_footer(text)
    # Strip the George Muller appendix at the end
    for marker in ["GEORGE MULLER, AND THE SECRET", "GEORGE MÜLLER"]:
        idx = text.find(marker)
        if idx != -1:
            # Back up to the preceding divider
            divider_idx = text.rfind("_" * 20, 0, idx)
            if divider_idx != -1:
                text = text[:divider_idx]
            else:
                text = text[:idx]
            break
    outdir = os.path.join(BASE, "SchoolOfPrayer")

    # The text has "FIRST LESSON.", "SECOND LESSON.", etc. on their own lines.
    # Use line-based detection to find positions.
    ordinal_map = {
        "FIRST": 1, "SECOND": 2, "THIRD": 3, "FOURTH": 4, "FIFTH": 5,
        "SIXTH": 6, "SEVENTH": 7, "EIGHTH": 8, "NINTH": 9, "TENTH": 10,
        "ELEVENTH": 11, "TWELFTH": 12, "THIRTEENTH": 13, "FOURTEENTH": 14,
        "FIFTEENTH": 15, "SIXTEENTH": 16, "SEVENTEENTH": 17, "EIGHTEENTH": 18,
        "NINTEENTH": 19, "NINETEENTH": 19,  # Handle typo
        "TWENTIETH": 20, "TWENTY-FIRST": 21, "TWENTY-SECOND": 22,
        "TWENTY-THIRD": 23, "TWENTY-FOURTH": 24, "TWENTY-FIFTH": 25,
        "TWENTY-SIXTH": 26, "TWENTY-SEVENTH": 27, "TWENTY-EIGHTH": 28,
        "TWENTY-NINTH": 29, "THIRTIETH": 30, "THIRTY-FIRST": 31,
    }

    # Find all lesson markers and their positions
    lessons = {}  # lesson_num -> (start_pos, ordinal_text)
    for ordinal, num in ordinal_map.items():
        pattern = rf"(?m)^{ordinal}\s+LESSON\.?"
        m = re.search(pattern, text, re.IGNORECASE)
        if m:
            if num not in lessons or m.start() < lessons[num][0]:
                lessons[num] = (m.start(), ordinal)

    # Sort by position
    sorted_lessons = sorted(lessons.items(), key=lambda x: x[1][0])

    chapters = []
    for i, (num, (start, ordinal)) in enumerate(sorted_lessons):
        end = sorted_lessons[i + 1][1][0] if i + 1 < len(sorted_lessons) else len(text)
        body = text[start:end]

        # Extract title: look for the line after "XXTH LESSON." that contains the lesson subtitle
        lines = body.strip().split("\n")
        title = ""
        for line in lines[1:10]:
            line = line.strip()
            if not line:
                continue
            # The subtitle is typically a short line, possibly starting with "Or,"
            # or a quoted phrase like "'Lord, teach us to pray;'"
            if line.startswith("Or,"):
                title = line[3:].strip().strip("'\"")
                break
            if len(line) < 80 and not re.match(r"^(CHAPTER|LESSON)", line, re.IGNORECASE):
                title = line.strip("'\"").strip(".")
                break

        chapters.append((num, title, body))

    titles = []
    for num, title, body in chapters:
        fname = f"{num:02d}-lesson-{num:02d}.txt"
        section = f"Lesson {num}"
        if title:
            section += f": {title}"
        titles.append(section)
        header = [
            "# With Christ in the School of Prayer, by Andrew Murray",
            f"# Section: {section}",
            "# Source: CCEL (Public Domain)",
            "#",
        ]
        write_chapter(os.path.join(outdir, fname), header, body)

    print(f"  Total: {len(chapters)} files")
    return titles


# ═══════════════════════════════════════════════════════
# 5. Waiting on God by Andrew Murray (CCEL)
# ═══════════════════════════════════════════════════════
def process_waiting_on_god():
    print("\n=== Waiting on God by Andrew Murray (CCEL) ===")
    text = download("https://ccel.org/ccel/m/murray/waiting/cache/waiting.txt")
    text = strip_ccel_header(text)
    text = strip_ccel_footer(text)
    outdir = os.path.join(BASE, "WaitingOnGod")

    ordinal_map = {
        "First": 1, "Second": 2, "Third": 3, "Fourth": 4, "Fifth": 5,
        "Sixth": 6, "Seventh": 7, "Eighth": 8, "Ninth": 9, "Tenth": 10,
        "Eleventh": 11, "Twelfth": 12, "Thirteenth": 13, "Fourteenth": 14,
        "Fifteenth": 15, "Sixteenth": 16, "Seventeenth": 17, "Eighteenth": 18,
        "Nineteenth": 19, "Twentieth": 20, "Twenty-First": 21, "Twenty-Second": 22,
        "Twenty-Third": 23, "Twenty-Fourth": 24, "Twenty-Fifth": 25,
        "Twenty-Sixth": 26, "Twenty-Seventh": 27, "Twenty-Eighth": 28,
        "Twenty-Ninth": 29, "Thirtieth": 30,
        "Thirtieth-First": 31, "Thirty-First": 31,  # Handle typo
    }

    days = {}  # day_num -> (start_pos, ordinal_text)
    for ordinal, num in ordinal_map.items():
        pattern = rf"(?m)^\s*{re.escape(ordinal)}\s+Day\.?"
        m = re.search(pattern, text, re.IGNORECASE)
        if m:
            if num not in days or m.start() < days[num][0]:
                days[num] = (m.start(), ordinal)

    sorted_days = sorted(days.items(), key=lambda x: x[1][0])

    chapters = []
    for i, (num, (start, ordinal)) in enumerate(sorted_days):
        end = sorted_days[i + 1][1][0] if i + 1 < len(sorted_days) else len(text)
        body = text[start:end]

        # Extract subtitle: after "WAITING ON GOD:" line there's typically a short title
        lines = body.strip().split("\n")
        subtitle = ""
        found_waiting = False
        for line in lines[1:10]:
            line = line.strip()
            if not line:
                continue
            if re.match(r"WAITING\s+(ON|FOR)\s+(GOD|THE LORD)", line, re.IGNORECASE):
                found_waiting = True
                continue
            if found_waiting and len(line) < 80:
                subtitle = line.strip(".")
                break
            if not found_waiting and len(line) < 60 and line[0].isupper():
                subtitle = line.strip(".")
                break

        chapters.append((num, subtitle, body))

    titles = []
    for num, subtitle, body in chapters:
        fname = f"{num:02d}-day-{num:02d}.txt"
        section = f"Day {num}"
        if subtitle:
            section += f": {subtitle}"
        titles.append(section)
        header = [
            "# Waiting on God, by Andrew Murray",
            f"# Section: {section}",
            "# Source: CCEL (Public Domain)",
            "#",
        ]
        write_chapter(os.path.join(outdir, fname), header, body)

    print(f"  Total: {len(chapters)} files")
    return titles


# ═══════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════
if __name__ == "__main__":
    all_titles = {}
    all_titles["Confessions"] = process_confessions()
    all_titles["Humility"] = process_humility()
    all_titles["AbsoluteSurrender"] = process_absolute_surrender()
    all_titles["SchoolOfPrayer"] = process_school_of_prayer()
    all_titles["WaitingOnGod"] = process_waiting_on_god()

    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    for book, titles in all_titles.items():
        print(f"\n{book} ({len(titles)} sections):")
        for t in titles:
            print(f"  - {t}")
