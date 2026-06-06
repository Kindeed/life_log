# Implementation Backlog for Formula Knowledge Base

The full goal is larger than a single app change. This backlog keeps the expansion aligned with source-backed engineering coverage.

## Stage 1: Knowledge Base Foundation

Status: started.

- Create source registry.
- Create formula catalog with source family and implementation status.
- Create variable glossary with stable field-ID suggestions.
- Record current app coverage and missing groups.
- Keep formulas out of cloud/photo sync paths.

Done in this seed pass:

- RF, antenna, receiver, link budget, baseband, telemetry frame, telecommand, ranging, tracking, system, and optical extension categories.
- Initial catalog contains 80+ implementation candidates.

## Stage 2: Source Extraction Passes

Each pass should produce a reviewed delta to `formula_catalog.md` and, where needed, machine-readable data later.

1. CCSDS coding and synchronization pass:
   - CCSDS 131.0-B active issue.
   - CCSDS 131.2-B and 131.3-B.
   - CCSDS 231.0-B-4.
   - Extract code families, code rates, sync marker sizes, randomizer behavior, CLTU/codeblock overhead, and MODCOD references.

2. CCSDS data-link pass:
   - TM Space Data Link Protocol.
   - TC Space Data Link Protocol.
   - AOS Space Data Link Protocol.
   - USLP.
   - Extract frame field sizes, optional field switches, packet/transfer-frame efficiency formulas, virtual-channel throughput formulas.

3. Ranging/tracking pass:
   - CCSDS 414.1-B-3 PN Ranging.
   - DSN 810-005 ranging/frequency/timing modules.
   - Extract transparent/regenerative PN ranging modes, chip-rate table, ambiguity, timing, Doppler, Delta-DOR.
   - Use `standard_extracts.md` PN rows to build chip-rate selector validation and annex B regression cases before app UI work.

4. RF/propagation pass:
   - CCSDS 401.0-B RF/modulation.
   - ITU-R P.525, P.618, P.676, P.838, P.839, P.840.
   - Extract FSPL variants, rain/gas/cloud/scintillation procedures, elevation/path geometry and applicability limits.
   - Use `standard_extracts.md` P.525 rows to build MHz/km, GHz/km, field-strength, PFD, isotropic received-power, and radar-loss regression cases.

5. Textbook cross-check pass:
   - Balanis for antenna formulas.
   - Sklar/Proakis/Haykin for modulation, coding, BER/PER, synchronization.
   - Maral/Bousquet and SMAD for satellite/system link budget organization.

6. Compression and Proximity-1 pass:
   - CCSDS 121.0-B, 122.0-B, and 123.0-B.
   - CCSDS 211.0-B, 211.1-B, and 211.2-B.
   - Extract compression packetization overhead, Proximity-1 physical/coding/data-link mode tables, and relay-link net-rate formulas.

7. Orbit/contact and RF measurement pass:
   - SMAD, Vallado, Bate, DSN 810-005, and ITU-R P.525.
   - Extract slant range, elevation, pass/contact estimates, range-rate, antenna slew rate, PFD, PSD, and lab power/voltage conversion formulas.

## Stage 3: App Data Model

Design a formula-library data model separate from current calculator definitions.

Candidate entities:

- `FormulaSource`: standard/book/source metadata.
- `FormulaEntry`: formula expression, title, category, explanation, source IDs.
- `FormulaVariable`: symbol, name, unit dimension, description.
- `FormulaScenario`: a practical calculator assembled from multiple formula entries.
- `FormulaProcedure`: multi-step standards algorithm requiring tables or conditional branches.

The current `TelemetryCalculatorDefinition` can remain for UI execution, but scenarios should eventually be generated from the formula library or reference it directly.

## Stage 4: Calculator Expansion

Recommended implementation order:

1. Antenna and receiver workbench:
   - parabolic gain
   - effective aperture
   - G/T
   - noise figure/noise temperature
   - cascaded noise
   - pointing and polarization loss

2. Full link budget workbench:
   - EIRP
   - FSPL
   - received power
   - C/N0, Eb/N0, Es/N0
   - required EIRP / required G/T
   - margin and bottleneck explanation

3. Propagation workbench:
   - ITU-R P.525 FSPL
   - P.838 rain specific attenuation
   - P.618 Earth-space rain fade skeleton
   - P.676 gas attenuation skeleton

4. Baseband and channel workbench:
   - symbol rate
   - raised-cosine bandwidth
   - BER/PER approximations
   - coding overhead
   - interleaver latency

5. CCSDS frame/coding workbench:
   - TM/TC/AOS/USLP frame efficiency
   - CLTU overhead
   - sync marker overhead
   - selected code-rate tables

6. Tracking/ranging workbench:
   - PN ranging resolution/ambiguity
   - Doppler and range-rate
   - oscillator guard margin
   - Delta-DOR geometry estimates

7. System closure workbench:
   - mission data volume
   - required contact time
   - net downlink rate
   - storage margin
   - power/duty-cycle closure

## Stage 5: UI Implication

The UI should not show all parameters in one two-column form. The formula library implies a new UI structure:

- domain landing page: Antenna, Link, Propagation, Baseband, Coding, Frames, Command, Ranging, System.
- scenario page: concise primary inputs, derived variables, key outputs.
- formula drawer: expanded derivation, variables, source references.
- advanced parameter groups: collapsed by default.
- validation: unit-compatible inputs only, with warnings for formulas outside their applicability range.

## Verification Gates

For each batch:

- source URL or bibliographic reference recorded
- formula variables defined in `variable_glossary.md`
- unit dimensions mapped
- app implementation, if any, has engine tests
- UI implementation, if any, has narrow-screen widget tests
- phone test for any changed calculator screen
