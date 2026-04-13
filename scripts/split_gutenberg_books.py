#!/usr/bin/env python3
"""
Download 6 Project Gutenberg books and split them into chapter files
for the Regal Recovery iOS app.
"""

import os
import re
import urllib.request
import urllib.error
import unicodedata

BASE_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "ios", "RegalRecovery", "RegalRecovery", "Resources"
)


def download_text(pg_id):
    """Download plain text from Project Gutenberg, trying multiple URL patterns."""
    urls = [
        f"https://www.gutenberg.org/cache/epub/{pg_id}/pg{pg_id}.txt",
        f"https://www.gutenberg.org/files/{pg_id}/{pg_id}-0.txt",
        f"https://www.gutenberg.org/files/{pg_id}/{pg_id}.txt",
    ]
    for url in urls:
        try:
            print(f"  Trying {url}...")
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as resp:
                raw = resp.read()
                try:
                    text = raw.decode("utf-8")
                except UnicodeDecodeError:
                    text = raw.decode("latin-1")
                print(f"  Downloaded {len(text)} chars from {url}")
                return text
        except urllib.error.HTTPError as e:
            print(f"  HTTP {e.code} for {url}")
        except Exception as e:
            print(f"  Error: {e}")
    raise RuntimeError(f"Could not download PG #{pg_id}")


def strip_gutenberg_boilerplate(text):
    """Remove PG header and footer."""
    start_patterns = [
        r"\*\*\* ?START OF TH(?:IS|E) PROJECT GUTENBERG EBOOK[^\n]*\*\*\*",
    ]
    start_pos = 0
    for pat in start_patterns:
        m = re.search(pat, text, re.IGNORECASE)
        if m:
            start_pos = m.end()
            break

    end_patterns = [
        r"\*\*\* ?END OF TH(?:IS|E) PROJECT GUTENBERG EBOOK[^\n]*\*\*\*",
        r"End of (?:the )?Project Gutenberg",
    ]
    end_pos = len(text)
    for pat in end_patterns:
        m = re.search(pat, text, re.IGNORECASE)
        if m:
            end_pos = m.start()
            break

    return text[start_pos:end_pos].strip()


def clean_text(text):
    """Normalize whitespace and clean up text."""
    text = unicodedata.normalize("NFC", text)
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"[ \t]+\n", "\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def join_broken_paragraphs(text):
    """Join lines that were broken at ~70 chars (typical PG line wrapping)."""
    lines = text.split("\n")
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.strip() == "":
            result.append("")
            i += 1
            continue
        para = line
        i += 1
        while i < len(lines):
            next_line = lines[i]
            if next_line.strip() == "":
                break
            if next_line.startswith("  ") and not para.endswith("-"):
                break
            if next_line.strip().isupper() and len(next_line.strip()) > 3:
                break
            if para.endswith("-"):
                para = para[:-1] + next_line.strip()
            else:
                para = para + " " + next_line.strip()
            i += 1
        result.append(para)
    return "\n".join(result)


def slugify(title):
    """Convert a title to a filename-safe slug."""
    s = title.lower().strip()
    s = re.sub(r"[^\w\s-]", "", s)
    s = re.sub(r"[\s_]+", "-", s)
    s = re.sub(r"-+", "-", s)
    return s.strip("-")[:60]


def write_chapter(output_dir, filename, header_lines, body):
    """Write a chapter file with header."""
    filepath = os.path.join(output_dir, filename)
    body = clean_text(body)
    body = join_broken_paragraphs(body)
    if len(body.strip()) < 100:
        print(f"    SKIPPING {filename} (too short: {len(body.strip())} chars)")
        return None
    with open(filepath, "w", encoding="utf-8") as f:
        for line in header_lines:
            f.write(line + "\n")
        f.write("\n")
        f.write(body + "\n")
    return filepath


# ============================================================
# Book 1: The Imitation of Christ
# ============================================================
def process_imitation_of_christ():
    print("\n=== The Imitation of Christ (PG #1653) ===")
    text = download_text(1653)
    text = strip_gutenberg_boilerplate(text)
    text = clean_text(text)

    output_dir = os.path.join(BASE_DIR, "ImitationOfChrist")
    files_created = []
    chapter_titles = []

    book_pattern = re.compile(
        r"^(THE\s+(?:FIRST|SECOND|THIRD|FOURTH)\s+BOOK)\s*$",
        re.MULTILINE | re.IGNORECASE
    )
    book_matches = list(book_pattern.finditer(text))

    book_names = {
        "FIRST": "I", "SECOND": "II", "THIRD": "III", "FOURTH": "IV",
    }

    if book_matches:
        print(f"  Found {len(book_matches)} books")
        seq = 1
        for bidx, bm in enumerate(book_matches):
            book_start = bm.start()
            book_end = book_matches[bidx + 1].start() if bidx + 1 < len(book_matches) else len(text)
            book_text = text[book_start:book_end]
            book_label = bm.group(1).strip().upper()

            book_num = "I"
            for key, val in book_names.items():
                if key in book_label:
                    book_num = val
                    break

            chap_pattern = re.compile(
                r"^(CHAPTER\s+[IVXLC]+)\s*\n+\s*(.+?)$",
                re.MULTILINE
            )
            chap_matches = list(chap_pattern.finditer(book_text))

            if chap_matches:
                print(f"  Book {book_num}: {len(chap_matches)} chapters")
                for cidx, cm in enumerate(chap_matches):
                    chap_start = cm.start()
                    chap_end = chap_matches[cidx + 1].start() if cidx + 1 < len(chap_matches) else len(book_text)
                    chap_body = book_text[chap_start:chap_end]
                    chap_num_str = cm.group(1).replace("CHAPTER", "").strip()
                    chap_title = cm.group(2).strip().rstrip(".")
                    chap_title = re.sub(r"\s+", " ", chap_title)

                    filename = f"{seq:02d}-book{book_num.lower()}-ch{chap_num_str.lower()}.txt"
                    section = f"Book {book_num}, Chapter {chap_num_str}: {chap_title}"
                    header = [
                        "# The Imitation of Christ, by Thomas a Kempis",
                        f"# Section: {section}",
                        "# Source: Project Gutenberg #1653",
                        "# Translator: William Benham",
                    ]
                    result = write_chapter(output_dir, filename, header, chap_body)
                    if result:
                        files_created.append(filename)
                        chapter_titles.append(section)
                        seq += 1

    print(f"\n  Created {len(files_created)} files in ImitationOfChrist/")
    for t in chapter_titles:
        print(f"    - {t}")
    return files_created, chapter_titles


# ============================================================
# Book 2: The Practice of the Presence of God
# ============================================================
def process_practice_presence():
    print("\n=== The Practice of the Presence of God (PG #5657) ===")
    text = download_text(5657)
    text = strip_gutenberg_boilerplate(text)
    text = clean_text(text)

    output_dir = os.path.join(BASE_DIR, "PracticePresenceOfGod")
    files_created = []
    chapter_titles = []

    section_pattern = re.compile(
        r"^((?:FIRST|SECOND|THIRD|FOURTH|FIFTH|SIXTH|SEVENTH|EIGHTH|NINTH|TENTH|"
        r"ELEVENTH|TWELFTH|THIRTEENTH|FOURTEENTH|FIFTEENTH|SIXTEENTH)\s+"
        r"(?:CONVERSATION|LETTER))\s*$",
        re.MULTILINE | re.IGNORECASE
    )
    matches = list(section_pattern.finditer(text))

    if not matches:
        section_pattern = re.compile(
            r"^((?:FIRST|SECOND|THIRD|FOURTH|FIFTH|SIXTH|SEVENTH|EIGHTH|NINTH|TENTH|"
            r"ELEVENTH|TWELFTH|THIRTEENTH|FOURTEENTH|FIFTEENTH|SIXTEENTH)\s+"
            r"(?:CONVERSATION|LETTER))",
            re.MULTILINE | re.IGNORECASE
        )
        matches = list(section_pattern.finditer(text))

    seq = 1
    if matches:
        pre_text = text[:matches[0].start()].strip()
        if len(pre_text) > 500:
            filename = f"{seq:02d}-preface.txt"
            header = [
                "# The Practice of the Presence of God, by Brother Lawrence",
                "# Section: Preface",
                "# Source: Project Gutenberg #5657",
                "# Translator: Unknown",
            ]
            result = write_chapter(output_dir, filename, header, pre_text)
            if result:
                files_created.append(filename)
                chapter_titles.append("Preface")
                seq += 1

        print(f"  Found {len(matches)} sections")
        for idx, m in enumerate(matches):
            start = m.start()
            end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
            section_name = m.group(1).strip().title()
            body = text[start:end]
            slug = slugify(section_name)
            filename = f"{seq:02d}-{slug}.txt"
            header = [
                "# The Practice of the Presence of God, by Brother Lawrence",
                f"# Section: {section_name}",
                "# Source: Project Gutenberg #5657",
                "# Translator: Unknown",
            ]
            result = write_chapter(output_dir, filename, header, body)
            if result:
                files_created.append(filename)
                chapter_titles.append(section_name)
                seq += 1

    print(f"\n  Created {len(files_created)} files in PracticePresenceOfGod/")
    for t in chapter_titles:
        print(f"    - {t}")
    return files_created, chapter_titles


# ============================================================
# Book 3: The Pursuit of God
# ============================================================
def process_pursuit_of_god():
    print("\n=== The Pursuit of God (PG #25141) ===")
    text = download_text(25141)
    text = strip_gutenberg_boilerplate(text)
    text = clean_text(text)

    output_dir = os.path.join(BASE_DIR, "PursuitOfGod")
    files_created = []
    chapter_titles = []

    # Structure: Roman numeral alone on a line, then _Title in italics_ on next line
    # Also "Introduction" and "Preface" sections before chapters
    valid_romans = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
    lines = text.split("\n")

    # Find all chapter starts: a line that is exactly a roman numeral,
    # with _Title_ on a nearby line
    chapter_starts = []

    # First find Introduction and Preface
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped == "Introduction":
            chapter_starts.append((i, "Introduction", "Introduction"))
        elif stripped == "Preface":
            chapter_starts.append((i, "Preface", "Preface"))

    # Then find Roman numeral chapters
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped in valid_romans:
            # Check this isn't the table of contents (look for page numbers on same line)
            # and isn't part of a paragraph. Should have blank line before it.
            if i > 0 and lines[i-1].strip() != "":
                continue
            # Look for title in italic markers on next non-empty line
            for j in range(i+1, min(i+4, len(lines))):
                title_line = lines[j].strip()
                if title_line.startswith("_") and title_line.endswith("_"):
                    title = title_line.strip("_").strip()
                    chapter_starts.append((i, stripped, title))
                    break

    # Deduplicate - keep only the body chapters (skip TOC entries)
    # TOC entries have page numbers. Body chapters are after the TOC.
    # Find where actual content begins (after "Introduction" header in body)
    # The chapters in the TOC have numbers after them; body chapters don't.
    # Strategy: only keep chapters that appear after a certain point.
    # The TOC lines like "I Following Hard after God    11" have numbers.
    # The body lines are just "I" on its own line.

    # Filter: keep only entries where the line is JUST the roman numeral (no trailing number)
    # and there's real body content after it
    if len(chapter_starts) > 12:
        # Too many - probably caught TOC entries. Keep only the later ones.
        # Find the first "Introduction" that is a section header (not in TOC)
        seen_intro = False
        filtered = []
        for start in chapter_starts:
            line_idx, label, title = start
            if label == "Introduction" and not seen_intro:
                seen_intro = True
                # Check if this is the body Introduction (has body text after it)
                if line_idx + 3 < len(lines) and len(lines[line_idx + 3].strip()) > 20:
                    filtered.append(start)
                continue
            if seen_intro:
                filtered.append(start)
        if filtered:
            chapter_starts = filtered

    seq = 1
    if chapter_starts:
        print(f"  Found {len(chapter_starts)} sections")
        for idx, (line_idx, label, title) in enumerate(chapter_starts):
            start_pos = sum(len(lines[k]) + 1 for k in range(line_idx))
            if idx + 1 < len(chapter_starts):
                next_line_idx = chapter_starts[idx + 1][0]
                end_pos = sum(len(lines[k]) + 1 for k in range(next_line_idx))
            else:
                end_pos = len(text)

            body = text[start_pos:end_pos]

            if label in ("Introduction", "Preface"):
                section = label
                slug = slugify(label)
            else:
                section = f"Chapter {label}: {title}"
                slug = slugify(title)[:40]

            filename = f"{seq:02d}-{slug}.txt"
            header = [
                "# The Pursuit of God, by A.W. Tozer",
                f"# Section: {section}",
                "# Source: Project Gutenberg #25141",
                "# Publisher: Christian Publications, Inc.",
            ]
            result = write_chapter(output_dir, filename, header, body)
            if result:
                files_created.append(filename)
                chapter_titles.append(section)
                seq += 1

    print(f"\n  Created {len(files_created)} files in PursuitOfGod/")
    for t in chapter_titles:
        print(f"    - {t}")
    return files_created, chapter_titles


# ============================================================
# Book 4: Grace Abounding to the Chief of Sinners
# ============================================================
def process_grace_abounding():
    print("\n=== Grace Abounding to the Chief of Sinners (PG #654) ===")
    text = download_text(654)
    text = strip_gutenberg_boilerplate(text)
    text = clean_text(text)

    output_dir = os.path.join(BASE_DIR, "GraceAbounding")
    files_created = []
    chapter_titles = []

    # Structure (from examining the text):
    # Line ~50: PREFATORY NOTE (body)
    # Line ~75: CONTENTS (table of contents - skip)
    # Line ~94: A PREFACE (body)
    # Line ~214: GRACE ABOUNDING TO THE CHIEF OF SINNERS (main body, paras 1-339)
    # Line ~3570: A BRIEF ACCOUNT OF THE AUTHOR'S IMPRISONMENT
    # Line ~3810: THE CONCLUSION
    # Line ~3867: A RELATION OF MY IMPRISONMENT IN THE MONTH OF NOVEMBER 1660
    # Line ~5003: _A Continuation of_ Mr BUNYAN'S LIFE (italic title)
    # Line ~5269: _A brief Character of Mr_ JOHN BUNYAN (italic title)
    # Line ~5300: POSTSCRIPT

    lines = text.split("\n")

    # Manually identify section boundaries by finding them in order,
    # skipping TOC entries (which have page numbers after them)
    section_defs = [
        (r"^PREFATORY NOTE\s*$", "Prefatory Note"),
        (r"^A PREFACE\s*$", "A Preface"),
        (r"^GRACE ABOUNDING TO THE CHIEF OF SINNERS\s*$", "Grace Abounding to the Chief of Sinners"),
        (r"^A BRIEF ACCOUNT OF THE AUTHOR.S IMPRISONMENT\s*$", "A Brief Account of the Author's Imprisonment"),
        (r"^THE CONCLUSION\s*$", "The Conclusion"),
        (r"^A RELATION OF MY IMPRISONMENT", "A Relation of the Author's Imprisonment"),
        (r"^_A Continuation", "A Continuation of the Author's Life"),
        (r"^_A brief Character", "A Brief Character of the Author"),
        (r"^POSTSCRIPT\s*$", "Postscript"),
    ]

    # Find positions - skip anything before line 50 (title block) and
    # anything in the CONTENTS section (lines ~75-92)
    found_sections = []
    # Convert line numbers to char positions
    line_to_pos = [0]
    for line in lines:
        line_to_pos.append(line_to_pos[-1] + len(line) + 1)

    # Find the CONTENTS block to skip
    contents_start = None
    contents_end = None
    for i, line in enumerate(lines):
        if line.strip() == "CONTENTS":
            contents_start = i
        if contents_start and i > contents_start + 2 and line.strip() == "" and i > contents_start:
            # Look for end of contents (blank line after last entry)
            next_nonempty = None
            for j in range(i+1, min(i+5, len(lines))):
                if lines[j].strip():
                    next_nonempty = j
                    break
            if next_nonempty and not any(lines[next_nonempty].strip().endswith(str(d)) for d in range(10)):
                contents_end = i
                break

    last_pos = 0
    for pattern, name in section_defs:
        for m in re.finditer(pattern, text, re.MULTILINE | re.IGNORECASE):
            pos = m.start()
            # Skip if in the CONTENTS or title block
            # Check line number
            approx_line = text[:pos].count("\n")
            if contents_start and contents_end and contents_start <= approx_line <= contents_end + 5:
                continue
            # Skip if before the actual content (title page area, ~first 45 lines)
            if approx_line < 45 and name != "Prefatory Note":
                continue
            # Must be after last found section
            if pos > last_pos:
                found_sections.append((pos, name))
                last_pos = pos
                break

    print(f"  Found {len(found_sections)} sections: {[s[1] for s in found_sections]}")

    seq = 1

    # The main "Grace Abounding" section has 339 numbered paragraphs.
    # Split it into sub-sections of ~40 paragraphs each.
    for sidx, (start_pos, section_name) in enumerate(found_sections):
        end_pos = found_sections[sidx + 1][0] if sidx + 1 < len(found_sections) else len(text)
        section_text = text[start_pos:end_pos]

        if section_name == "Grace Abounding to the Chief of Sinners":
            # Split the main body into paragraph groups
            para_pattern = re.compile(r"^(\d+)\.\s", re.MULTILINE)
            para_matches = list(para_pattern.finditer(section_text))

            if para_matches:
                # Build position map
                para_positions = {}
                for pm in para_matches:
                    num = int(pm.group(1))
                    if num not in para_positions:
                        para_positions[num] = pm.start()

                max_para = max(para_positions.keys())
                print(f"  Main body: {len(para_positions)} numbered paragraphs (1-{max_para})")

                # Content before paragraph 1 (the section header and intro)
                if para_matches:
                    intro = section_text[:para_matches[0].start()].strip()
                    if len(intro) > 200:
                        filename = f"{seq:02d}-{slugify('grace-abounding-introduction')}.txt"
                        header = [
                            "# Grace Abounding to the Chief of Sinners, by John Bunyan",
                            "# Section: Introduction",
                            "# Source: Project Gutenberg #654",
                            "# Date: 1666",
                        ]
                        result = write_chapter(output_dir, filename, header, intro)
                        if result:
                            files_created.append(filename)
                            chapter_titles.append("Introduction")
                            seq += 1

                # Split into groups of 40 paragraphs
                group_size = 40
                current = 1
                while current <= max_para:
                    end_para = min(current + group_size - 1, max_para)

                    start = para_positions.get(current)
                    if start is None:
                        for p in range(current, end_para + 1):
                            if p in para_positions:
                                start = para_positions[p]
                                current = p
                                break
                    if start is None:
                        current = end_para + 1
                        continue

                    # Find end
                    end = len(section_text)
                    for p in range(end_para + 1, max_para + 2):
                        if p in para_positions:
                            end = para_positions[p]
                            break

                    body = section_text[start:end]
                    sub_name = f"Paragraphs {current}-{min(end_para, max_para)}"
                    filename = f"{seq:02d}-{slugify(sub_name)}.txt"
                    header = [
                        "# Grace Abounding to the Chief of Sinners, by John Bunyan",
                        f"# Section: {sub_name}",
                        "# Source: Project Gutenberg #654",
                        "# Date: 1666",
                    ]
                    result = write_chapter(output_dir, filename, header, body)
                    if result:
                        files_created.append(filename)
                        chapter_titles.append(sub_name)
                        seq += 1

                    current = end_para + 1
            else:
                # No numbered paragraphs, write as one section
                filename = f"{seq:02d}-{slugify(section_name)}.txt"
                header = [
                    "# Grace Abounding to the Chief of Sinners, by John Bunyan",
                    f"# Section: {section_name}",
                    "# Source: Project Gutenberg #654",
                    "# Date: 1666",
                ]
                result = write_chapter(output_dir, filename, header, section_text)
                if result:
                    files_created.append(filename)
                    chapter_titles.append(section_name)
                    seq += 1
        else:
            # Regular section
            slug = slugify(section_name)
            filename = f"{seq:02d}-{slug}.txt"
            header = [
                "# Grace Abounding to the Chief of Sinners, by John Bunyan",
                f"# Section: {section_name}",
                "# Source: Project Gutenberg #654",
                "# Date: 1666",
            ]
            result = write_chapter(output_dir, filename, header, section_text)
            if result:
                files_created.append(filename)
                chapter_titles.append(section_name)
                seq += 1

    print(f"\n  Created {len(files_created)} files in GraceAbounding/")
    for t in chapter_titles:
        print(f"    - {t}")
    return files_created, chapter_titles


# ============================================================
# Book 5: Power Through Prayer
# ============================================================
def process_power_through_prayer():
    print("\n=== Power Through Prayer (PG #65115) ===")
    text = download_text(65115)
    text = strip_gutenberg_boilerplate(text)
    text = clean_text(text)

    output_dir = os.path.join(BASE_DIR, "PowerThroughPrayer")
    files_created = []
    chapter_titles = []

    # Structure:
    # - Title page, then "FOREWORDS" with sections I (by Dixon) and II (by Head)
    # - Then 20 actual chapters numbered I-XX
    # - Each chapter: Roman numeral on own line, then epigraph in _italics_, then body
    # - Foreword sections have "BY ..." after the roman numeral

    lines = text.split("\n")

    valid_romans = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
                    "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]

    # Find all Roman numeral markers
    all_markers = []
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped in valid_romans:
            # Check if preceded by blank line
            if i > 0 and lines[i-1].strip() == "":
                # Check if next line indicates foreword (starts with "BY") or chapter (starts with _ or blank)
                is_foreword = False
                if i + 1 < len(lines) and lines[i+1].strip().upper().startswith("BY "):
                    is_foreword = True
                all_markers.append((i, stripped, is_foreword))

    # Separate foreword markers from chapter markers
    foreword_markers = [m for m in all_markers if m[2]]
    chapter_markers = [m for m in all_markers if not m[2]]

    # Keep only the first 20 chapter markers (I-XX)
    # The foreword has I and II, then actual chapters restart at I
    print(f"  Found {len(foreword_markers)} foreword sections, {len(chapter_markers)} chapter markers")

    # Chapter titles (from the book - these chapters don't have explicit titles,
    # so we derive them from the content)
    chapter_title_map = {
        "I": "The Man Behind the Sermon",
        "II": "Preaching that Kills",
        "III": "The Letter Killeth",
        "IV": "Tendencies to be Avoided",
        "V": "Prayer the Great Essential",
        "VI": "A Praying Ministry Successful",
        "VII": "Much Time Should Be Given to Prayer",
        "VIII": "Examples of Praying Men",
        "IX": "Begin the Day with Prayer",
        "X": "Prayer and Devotion United",
        "XI": "An Example of Devotion",
        "XII": "Heart Preparation Necessary",
        "XIII": "Grace from the Heart Rather than the Head",
        "XIV": "Unction, the Mark of True Preaching",
        "XV": "Unction and the Word of God",
        "XVI": "Unction and the Holy Spirit",
        "XVII": "Prayer Marks Spiritual Leadership",
        "XVIII": "The Preacher's Cry: Pray for Us",
        "XIX": "Deliberation Necessary to Largest Results",
        "XX": "A Praying Pulpit Begets a Praying Pew",
    }

    seq = 1

    # Write foreword sections
    if foreword_markers:
        # Content before first foreword (title page etc.)
        first_fw_line = foreword_markers[0][0]
        # Find "FOREWORDS" header
        fw_header_pos = None
        for i, line in enumerate(lines):
            if line.strip().upper() == "FOREWORDS":
                fw_header_pos = i
                break

        for fidx, (line_idx, label, _) in enumerate(foreword_markers):
            start_pos = sum(len(lines[k]) + 1 for k in range(line_idx))
            if fidx + 1 < len(foreword_markers):
                next_idx = foreword_markers[fidx + 1][0]
                end_pos = sum(len(lines[k]) + 1 for k in range(next_idx))
            elif chapter_markers:
                next_idx = chapter_markers[0][0]
                end_pos = sum(len(lines[k]) + 1 for k in range(next_idx))
            else:
                end_pos = len(text)

            body = text[start_pos:end_pos]
            # Get the "BY" line for attribution
            by_line = lines[line_idx + 1].strip() if line_idx + 1 < len(lines) else ""
            author = by_line.replace("BY ", "").replace("BY", "").strip().rstrip(".")

            section = f"Foreword {label}: {author}" if author else f"Foreword {label}"
            slug = slugify(section)[:40]
            filename = f"{seq:02d}-{slug}.txt"
            header = [
                "# Power Through Prayer, by E.M. Bounds",
                f"# Section: {section}",
                "# Source: Project Gutenberg #65115",
                "# Date: 1907",
            ]
            result = write_chapter(output_dir, filename, header, body)
            if result:
                files_created.append(filename)
                chapter_titles.append(section)
                seq += 1

    # Write actual chapters
    for cidx, (line_idx, label, _) in enumerate(chapter_markers):
        start_pos = sum(len(lines[k]) + 1 for k in range(line_idx))
        if cidx + 1 < len(chapter_markers):
            next_idx = chapter_markers[cidx + 1][0]
            end_pos = sum(len(lines[k]) + 1 for k in range(next_idx))
        else:
            end_pos = len(text)

        body = text[start_pos:end_pos]
        title = chapter_title_map.get(label, f"Chapter {label}")
        section = f"Chapter {label}: {title}"
        slug = slugify(title)[:40]
        filename = f"{seq:02d}-{slug}.txt"
        header = [
            "# Power Through Prayer, by E.M. Bounds",
            f"# Section: {section}",
            "# Source: Project Gutenberg #65115",
            "# Date: 1907",
        ]
        result = write_chapter(output_dir, filename, header, body)
        if result:
            files_created.append(filename)
            chapter_titles.append(section)
            seq += 1

    print(f"\n  Created {len(files_created)} files in PowerThroughPrayer/")
    for t in chapter_titles:
        print(f"    - {t}")
    return files_created, chapter_titles


# ============================================================
# Book 6: Holy in Christ
# ============================================================
def process_holy_in_christ():
    print("\n=== Holy in Christ (PG #26990) ===")
    text = download_text(26990)
    text = strip_gutenberg_boilerplate(text)
    text = clean_text(text)

    output_dir = os.path.join(BASE_DIR, "HolyInChrist")
    files_created = []
    chapter_titles = []

    # Structure:
    # "First Day." on its own line
    # blank line
    # "HOLY IN CHRIST." on its own line
    # blank line
    # Actual subtitle like "God's Call to Holiness." on its own line
    # Then scripture quotes and body text

    ordinals = [
        "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh",
        "Eighth", "Ninth", "Tenth", "Eleventh", "Twelfth", "Thirteenth",
        "Fourteenth", "Fifteenth", "Sixteenth", "Seventeenth", "Eighteenth",
        "Nineteenth", "Twentieth", "Twenty-[Ff]irst", "Twenty-[Ss]econd",
        "Twenty-[Tt]hird", "Twenty-[Ff]ourth", "Twenty-[Ff]ifth",
        "Twenty-[Ss]ixth", "Twenty-[Ss]eventh", "Twenty-[Ee]ighth",
        "Twenty-[Nn]inth", "Thirtieth", "Thirty-[Ff]irst"
    ]
    ordinal_pattern = "|".join(ordinals)
    day_pattern = re.compile(
        rf"^({ordinal_pattern})\s+Day\.?\s*$",
        re.MULTILINE | re.IGNORECASE
    )
    matches = list(day_pattern.finditer(text))

    seq = 1

    if matches and len(matches) >= 10:
        # Check for preface/introduction
        pre_text = text[:matches[0].start()].strip()
        if len(pre_text) > 500:
            filename = f"{seq:02d}-preface.txt"
            header = [
                "# Holy in Christ, by Andrew Murray",
                "# Section: Preface",
                "# Source: Project Gutenberg #26990",
                "# Date: 1887",
            ]
            result = write_chapter(output_dir, filename, header, pre_text)
            if result:
                files_created.append(filename)
                chapter_titles.append("Preface")
                seq += 1

        print(f"  Found {len(matches)} day/meditation sections")
        for idx, m in enumerate(matches):
            start = m.start()
            end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
            body_text = text[start:end]

            day_label = m.group(1).strip().title()

            # Find the actual subtitle: it's after "HOLY IN CHRIST." line
            # Pattern: Day label -> blank -> "HOLY IN CHRIST." -> blank -> subtitle
            subtitle = ""
            after_match = text[m.end():end]
            subtitle_pattern = re.compile(
                r"HOLY IN CHRIST\.?\s*\n\n(.+?)(?:\n\n|$)",
                re.DOTALL
            )
            sm = subtitle_pattern.search(after_match)
            if sm:
                subtitle = sm.group(1).strip().split("\n")[0].strip().rstrip(".")
                # Clean up: remove italics markers
                subtitle = subtitle.replace("_", "").strip()

            section = f"{day_label} Day"
            if subtitle and subtitle.upper() != "HOLY IN CHRIST":
                section += f": {subtitle}"

            slug = slugify(f"day-{seq:02d}-{subtitle}" if subtitle else f"day-{seq:02d}")
            filename = f"{seq:02d}-{slug}.txt"
            header = [
                "# Holy in Christ, by Andrew Murray",
                f"# Section: {section}",
                "# Source: Project Gutenberg #26990",
                "# Date: 1887",
            ]
            result = write_chapter(output_dir, filename, header, body_text)
            if result:
                files_created.append(filename)
                chapter_titles.append(section)
                seq += 1

        # Check for notes/appendix after last day
        note_pattern = re.compile(r"^(?:NOTE|APPENDIX|Note\.)", re.MULTILINE | re.IGNORECASE)
        last_day_end = matches[-1].start()
        last_section = text[last_day_end:]
        note_match = note_pattern.search(last_section)
        if note_match:
            note_start_in_text = last_day_end + note_match.start()
            note_text = text[note_start_in_text:]
            if len(note_text.strip()) > 500:
                filename = f"{seq:02d}-notes.txt"
                header = [
                    "# Holy in Christ, by Andrew Murray",
                    "# Section: Notes",
                    "# Source: Project Gutenberg #26990",
                    "# Date: 1887",
                ]
                result = write_chapter(output_dir, filename, header, note_text)
                if result:
                    files_created.append(filename)
                    chapter_titles.append("Notes")
                    seq += 1

    print(f"\n  Created {len(files_created)} files in HolyInChrist/")
    for t in chapter_titles:
        print(f"    - {t}")
    return files_created, chapter_titles


# ============================================================
# Main
# ============================================================
def main():
    print("=" * 60)
    print("Downloading and splitting 6 Project Gutenberg books")
    print(f"Output base: {BASE_DIR}")
    print("=" * 60)

    all_results = {}

    all_results["ImitationOfChrist"] = process_imitation_of_christ()
    all_results["PracticePresenceOfGod"] = process_practice_presence()
    all_results["PursuitOfGod"] = process_pursuit_of_god()
    all_results["GraceAbounding"] = process_grace_abounding()
    all_results["PowerThroughPrayer"] = process_power_through_prayer()
    all_results["HolyInChrist"] = process_holy_in_christ()

    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    total = 0
    for book, (files, titles) in all_results.items():
        print(f"\n{book}/: {len(files)} files")
        total += len(files)
    print(f"\nTotal files created: {total}")


if __name__ == "__main__":
    main()
