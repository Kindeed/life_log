# Space Telemetry, Telecommand, Tracking, and RF Formula Knowledge Base

This folder is the working knowledge base for expanding the LifeLog engineering calculator beyond the current compact telemetry workbench.

The goal is to build a source-backed formula library that can later drive:

- calculator definitions in `lib/modules/telemetry_calc/telemetry_calculators.dart`
- formula explanations in the UI
- variable glossaries and unit validation
- scenario calculators such as antenna sizing, link budget, channel coding, PCM/baseband, telecommand, ranging, Doppler, and system-level budget closure

## Current App Gap

The current app has 8 calculators and a small number of formula references:

- link budget
- rate and bandwidth
- PCM frame
- channel coding overhead
- telecommand throughput
- ranging and delay
- Doppler and guard margin
- custom local expression

That is useful as a first workbench, but it is not a complete engineering formula base. Current expansion has started antenna, receiver, propagation, CCSDS coding, TM/TC/AOS/USLP frame overhead, PN ranging, Delta-DOR, radar-style external tracking, optical link, and system-level mission budget coverage; it still needs exact table assets, validation cases, and production calculator integration.

## Knowledge Base Files

- `source_registry.md`: authoritative standards, handbooks, and textbooks to use as evidence.
- `formula_catalog.md`: formula entries with purpose, variables, units, source family, and implementation priority.
- `variable_glossary.md`: shared symbol and variable definitions.
- `coverage_matrix.md`: domain coverage map, current status, and remaining gaps.
- `standard_extraction_matrix.md`: concrete extraction tasks from standards/books to formulas, tables, and procedures.
- `standard_extracts.md`: extracted implementation-ready equations, parameter tables, and notes from specific standards.
- `implementation_backlog.md`: staged plan for converting the knowledge base into app calculators.

## Source Rules

1. Prefer public standards and official pages first: CCSDS, ITU-R, NASA/JPL/DSN, ECSS when available.
2. Use published textbooks for domain organization and well-known formulas, but do not copy copyrighted text.
3. Each formula entry must include:
   - formula expression
   - variable definitions
   - expected units
   - applicability and limits
   - source family
   - whether the current app already implements it
4. If an equation depends on a detailed standard procedure, such as ITU-R P.618 rain fade or CCSDS LDPC code tables, record the top-level formula and mark the table/procedure extraction separately.

## Completion Meaning

This initial folder is not the final complete knowledge base. It is the controlled seed that lets the work continue without losing traceability. Completion of the larger goal requires continued extraction from the listed standards and books, implementation-ready data models, tests, and UI integration.
