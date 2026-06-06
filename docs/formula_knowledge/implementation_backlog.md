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
   - CCSDS 131.0-B active issue; public B-5 first pass is extracted, and B-6 needs delta verification when the official PDF is accessible.
   - CCSDS 131.2-B and 131.3-B.
   - CCSDS 231.0-B-4.
   - Extract code families, code rates, sync marker sizes, randomizer behavior, CLTU/codeblock overhead, and MODCOD references.
   - Use `standard_extracts.md` CCSDS 231 rows to build BCH/LDPC CLTU sizing tests before adding telecommand UI controls.
   - Use `standard_extracts.md` CCSDS 131 rows to build R-S, Turbo, LDPC, ASM/CSM, and randomizer sizing tests before adding telemetry coding UI controls.

2. CCSDS data-link pass:
   - TM Space Data Link Protocol.
   - TC Space Data Link Protocol.
   - AOS Space Data Link Protocol.
   - USLP.
   - Extract frame field sizes, optional field switches, packet/transfer-frame efficiency formulas, virtual-channel throughput formulas.
   - Use `standard_extracts.md` CCSDS 132/232 rows to create TM/TC field-capacity schemas and SDLS overhead test cases.

3. Ranging/tracking pass:
   - CCSDS 414.1-B-3 PN Ranging.
   - DSN 810-005 ranging/frequency/timing modules.
   - Extract transparent/regenerative PN ranging modes, chip-rate table, ambiguity, timing, Doppler, Delta-DOR.
   - Current extraction includes CCSDS PN chip-rate/acquisition/delay limits plus DESCANSO and DSN 202/203/210/211/214 Doppler, carrier-loop SNR, Doppler error, Doppler counting, sequential ranging, PN/regenerative ranging, ranging variance, corrected round-trip delay, residuals, RSS uncertainty, VLBI/DOR, and radar-style external measurement formulas.
   - Use `standard_extracts.md` PN, DSTRK, DSN202, DSN203, DSN210, DSN211, and DSN214 rows to build chip-rate selector validation, annex B regression cases, Doppler-count examples, carrier-loop margin examples, range-correction examples, sequential/PN acquisition examples, and Delta-DOR geometry cases before app UI work.

4. RF/antenna/propagation pass:
   - CCSDS 401.0-B RF/modulation.
   - ITU-R P.525, P.618, P.676, P.838, P.839, P.840, S.465, and S.580.
   - Extract FSPL variants, rain/gas/cloud/scintillation procedures, earth-station reference antenna patterns, elevation/path geometry and applicability limits.
   - Use `standard_extracts.md` P.525 rows to build MHz/km, GHz/km, field-strength, PFD, isotropic received-power, and radar-loss regression cases.
   - Use `standard_extracts.md` DESCANSO/DSN rows to build antenna aperture, pointing/polarization, received-power, carrier/data/ranging margin, and atmospheric noise-temperature regression cases.
   - Use `standard_extracts.md` ITUANT/BOOKANT rows to build off-axis gain, side-lobe objective, beam solid angle, directivity, far-field distance, and array-factor examples before adding antenna UI controls.
   - Current first-pass extraction includes P.676 gas attenuation structure, P.840 cloud/fog attenuation, P.618 scintillation and sky-noise formulas, S.465/S.580 earth-station antenna pattern formulas, and CCSDS 401 QPSK/modulation-margin/symbol-rate/subcarrier checks; next work is coefficient/map assets, machine-readable modulation/limit tables, antenna temperature submodels, and validation examples.

5. Textbook cross-check pass:
   - Balanis for antenna formulas.
   - Sklar/Proakis/Haykin for modulation, coding, BER/PER, synchronization.
   - Maral/Bousquet and SMAD for satellite/system link budget organization.
   - Use `standard_extracts.md` digital-communications rows to build baseband timing, quantization, matched-filter, OFDM, phase-error, and MIMO calculator tests before UI work.

6. Compression and Proximity-1 pass:
   - CCSDS 121.0-B, 122.0-B, and 123.0-B.
   - CCSDS 211.0-B, 211.1-B, and 211.2-B.
   - Extract compression packetization overhead, Proximity-1 physical/coding/data-link mode tables, and relay-link net-rate formulas.
   - Current CCSDS 211.2-B-3 extraction covers PLTU size/efficiency, idle PN repeats, acquisition/tail bit budgets, allowed `Rd` validation, convolutional rate expansion, LDPC `(2048,1024)` plus 64-bit CSM overhead, and LDPC randomizer procedure.
   - Current ISO 22663 / CCSDS 211.0-B-5 extraction covers Version-3 Transfer Frame fixed header, maximum data-field capacity, field-width/cardinality outputs, and frame-plus-PLTU efficiency; CCSDS registry shows 211.0-B-6 as current and adds Version-4/USLP text, but the direct `211x0b6.pdf` guess returned 404, so B-6 exact deltas still need retrieval.
   - Current ISO 21460 / CCSDS 211.1-B-4 extraction covers `R_d/R_cs/R_chs` reference points, `R_chs=R_cs`, discrete physical-layer coded-symbol-rate validation, and channel-symbol-rate offset/stability margins; remaining physical-layer work is UHF channel/hailing/polarization table extraction.

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
   - directivity and beam solid angle
   - ITU off-axis reference-pattern and side-lobe objective checks
   - far-field distance and array-factor sanity checks
   - noise figure/noise temperature
   - cascaded noise
   - pointing and polarization loss
   - aperture efficiency decomposition and surface-error efficiency
   - DSN-style atmospheric noise and operating system temperature

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
   - P.676 gas attenuation line-by-line/approximate modes
   - P.840 cloud attenuation instantaneous/statistical/log-normal modes
   - P.839 rain height and P.618 slant-path rain geometry
   - P.618 scintillation and sky-noise temperature
   - P.618 total attenuation combiner for rain, gas, cloud, and scintillation

4. Baseband and channel workbench:
   - symbol rate
   - raised-cosine bandwidth
   - BER/PER approximations
   - coding overhead
   - interleaver latency
   - CCSDS QPSK I/Q phase mapping
   - modulator phase/amplitude imbalance margins
   - subcarrier frequency-to-coded-symbol-rate integer checks
   - coded-symbol-rate offset and stability margins
   - GMSK/filter `BTS` to bandwidth conversion
   - quantization and ENOB
   - matched-filter decision metrics
   - OFDM subcarrier, cyclic-prefix, and PAPR outputs
   - phase jitter/frequency-offset sanity checks
   - Proximity-1 `R_d/R_cs/R_chs` reference-point explanation
   - Proximity-1 coded/channel symbol-rate allowed-set, offset, and stability warnings

5. CCSDS frame/coding workbench:
   - TM/TC/AOS/USLP frame efficiency
   - CLTU overhead
   - sync marker overhead
   - selected code-rate tables
   - Proximity-1 Version-3 Transfer Frame header/data-field efficiency
   - Proximity-1 PLTU/CRC/ASM efficiency
   - Proximity-1 idle/acquisition/tail overhead
   - Proximity-1 convolutional and LDPC/CSM physical-stream efficiency

6. Tracking/ranging workbench:
   - PN ranging resolution/ambiguity
   - sequential ranging RU, component frequency, acquisition probability, and cycle time
   - Doppler and range-rate
   - Doppler carrier-loop SNR and lock margin
   - Doppler range-rate error budget
   - Doppler count interval and resolver quantization
   - corrected round-trip propagation time and range residual
   - radiometric RSS error budget
   - oscillator guard margin
   - Delta-DOR geometry estimates
   - VLBI synthesized bandwidth and delay/path error
   - radar/external-measurement range, resolution, PRF ambiguity, and velocity-resolution cards

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
