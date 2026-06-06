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
   - Use `standard_extracts.md` DVB-S2 rows to build BBFRAME/FECFRAME/PLFRAME overhead, pilot-overhead, occupied-bandwidth, spectral-efficiency, frame-duration, and net-rate regression cases before adding high-rate telemetry UI controls.

2. CCSDS data-link pass:
   - TM Space Data Link Protocol.
   - Space Packet Protocol.
   - TC Space Data Link Protocol.
   - AOS Space Data Link Protocol.
   - USLP.
   - Extract frame field sizes, optional field switches, packet/transfer-frame efficiency formulas, virtual-channel throughput formulas.
   - Use `standard_extracts.md` CCSDS 132/133/232/732.1 rows to create TM/Space Packet/TC/USLP field-capacity schemas, packet-efficiency outputs, VCF Count/OID validation, and SDLS overhead test cases.
   - Current CCSDS 133.0-B-2 extraction covers Space Packet primary-header width, data-field length count, min/max packet length, APID/idle packet constants, sequence-count modulus, secondary-header/user-data capacity, and packet efficiency.
   - Current CCSDS 732.1-B-3 extraction covers USLP identifier widths, non-truncated and truncated primary-header sizes, Frame Length count, VCF Count length/modulus, TFDF/TFDZ capacity, OCF/FECF overhead, OID constants, fixed-TFDZ idle fill, SDLS capacity, and first-order segmentation count.
   - Current CCSDS 732.0-B AOS extraction covers stable primary-header, GVCID, VC frame count, signaling, optional OCF/FECF, data-field, M_PDU packet-zone, VCA_SDU, SDLS capacity, and frame-efficiency formulas from the current B-5 registry plus public older-issue cross-checks.
   - Remaining data-link work is exact AOS B-5 direct PDF extraction, packet extraction examples across TM/AOS/USLP, and machine-readable construction-rule tables.
   - Current CCSDS 232.1-B-2 extraction covers COP-1 FOP/FARM variables, 8-bit sequence arithmetic, `T1_Initial` delay budget, Transmission_Limit/Count, Sent_Queue, FOP/FARM sliding windows, CLCW reporting period, and Type-BD one-shot behavior.
   - Remaining COP work is state-table event test extraction, PLOP timing, and systematic retransmission examples.

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
   - Use `standard_extracts.md` DESCANSO/DSN rows to build antenna aperture, pointing/polarization, received-power, carrier/data/ranging margin, atmospheric noise-temperature, receiver reference-plane, and Y-factor calibration regression cases.
   - Use `standard_extracts.md` ITUANT/BOOKANT rows to build off-axis gain, side-lobe objective, beam solid angle, directivity, far-field distance, array-factor, scan-steering, grating-lobe, scan-loss, phase-quantization, beam-squint, aperture taper, measured-pattern integration, active VSWR, coupling-efficiency, taper-synthesis, and antenna-gain-measurement examples before adding antenna UI controls.
   - Current first-pass extraction includes P.676 gas attenuation structure, P.840 cloud/fog attenuation, P.618 scintillation and sky-noise formulas, S.465/S.580 earth-station antenna pattern formulas, receiver/passive-loss/Y-factor formulas, receiver/link uncertainty propagation formulas, DSN 101/103/104 station gain/noise-temperature model rows, Balanis/Mailloux aperture-field, measured-pattern, taper, coupling, and gain-measurement formulas, and CCSDS 401 QPSK/modulation-margin/symbol-rate/subcarrier checks; next work is coefficient/map assets, DSN station coefficient tables, machine-readable modulation/limit tables, measured-pattern import examples, active-array validation cases, antenna temperature validation examples, and receiver-chain uncertainty UI scenarios.

5. Textbook cross-check pass:
   - Balanis for antenna formulas.
   - Sklar/Proakis/Haykin plus Gardner/Mengali for modulation, coding, BER/PER, synchronization, EVM/MER, soft decisions, pulse shaping, and receiver loops.
   - Goldsmith/Rappaport for wireless channel, fading, delay spread, Doppler, coherence, outage, and shadowing formulas.
   - Maral/Bousquet and SMAD for satellite/system link budget organization.
   - Use `standard_extracts.md` digital-communications and measurement-confidence rows to build baseband timing, quantization, matched-filter, EVM/MER, LLR demapper, raised-cosine/RRC, synchronization-loop, timing-error detector, OFDM, phase-error, MIMO, AWGN modulation BER/SER, BER/FER confidence, zero-error demonstration, allowed-error pass probability, fading-channel BER/outage, diversity-combining, coding-gain, minimum-distance, and log-distance path-loss calculator tests before UI work.

6. Compression and Proximity-1 pass:
   - CCSDS 121.0-B, 122.0-B, and 123.0-B.
   - CCSDS 211.0-B, 211.1-B, and 211.2-B.
   - Extract compression packetization overhead, Proximity-1 physical/coding/data-link mode tables, and relay-link net-rate formulas.
   - Current CCSDS 121.0-B-3 extraction covers block sizing, padding, reference-sample overhead, unit-delay prediction, prediction-error mapper, FS/split/second-extension/zero-block/no-compression sizing, and code-option selection.
   - Current CCSDS 120.2-G-2 / 123 extraction covers 3-D image sizing, scaled predictor relationship, scaled prediction-error explanation, near-lossless quantizer step, lossless and absolute-error modes, periodic error-limit updates, and corrigendum-tracked table changes.
   - Remaining compression work is exact CCSDS 122.0-B-2 image-compression tables, full CCSDS 123.0-B-2 Blue Book header/predictor/hybrid-entropy tables, relative-error-limit formula verification from a cleaner source, CCSDS 121 ID/zero-run table assets, and textbook examples from Sayood/Salomon.
   - Current CCSDS 211.2-B-3 extraction covers PLTU size/efficiency, idle PN repeats, acquisition/tail bit budgets, allowed `Rd` validation, convolutional rate expansion, LDPC `(2048,1024)` plus 64-bit CSM overhead, and LDPC randomizer procedure.
   - Current ISO 22663 / CCSDS 211.0-B-5 extraction covers Version-3 Transfer Frame fixed header, maximum data-field capacity, field-width/cardinality outputs, and frame-plus-PLTU efficiency; CCSDS registry shows 211.0-B-6 as current and adds Version-4/USLP text, but the direct `211x0b6.pdf` guess returned 404, so B-6 exact deltas still need retrieval.
   - Current ISO 21460 / CCSDS 211.1-B-4 extraction covers `R_d/R_cs/R_chs` reference points, `R_chs=R_cs`, discrete physical-layer coded-symbol-rate validation, and channel-symbol-rate offset/stability margins; remaining physical-layer work is UHF channel/hailing/polarization table extraction.

7. Orbit/contact and RF measurement pass:
   - SMAD, Vallado, Bate, DSN 810-005, and ITU-R P.525.
   - Extract slant range, elevation, pass/contact estimates, range-rate, antenna slew rate, PFD, PSD, and lab power/voltage conversion formulas.
   - Current measurement uncertainty extraction covers JCGM/NIST combined standard uncertainty, independent RSS, expanded uncertainty, Type-A repeatability, small-signal dB uncertainty conversion, Y-factor calibration uncertainty, `G/T`, `N0`, `C/N0`, `Eb/N0`, margin uncertainty, BER/FER point estimates, binomial standard uncertainty, Clopper-Pearson and Wilson confidence intervals, zero-error/allowed-error pass probabilities, test-duration sizing, and measured `Eb/N0`/implementation-loss references.
   - Current orbit/contact extraction covers two-body energy/vis-viva/angular-momentum/eccentricity/conic relations, station geodetic-to-ECEF, ECEF-to-ENU, local az/el/range, first-order ECI/ECEF warning, minimum-elevation access geometry, coverage radius, access flag, approximate pass duration, ground-track shift, circular-orbit subsatellite point estimates, J2 secular RAAN/perigee/mean-anomaly rates, sun-synchronous inclination estimate, repeat-ground-track closure, Kepler propagation, AOS/LOS/max-elevation event definitions, Hohmann transfer, plane-change, and combined maneuver formulas.
   - Current system operations extraction covers generated data, usable contact time, per-pass and aggregate downlink capacity, storage end/peak margin, contact efficiency, passes required, required net/line rate, contact bit budget, required compression ratio, queue drain time, energy, battery depth of discharge, recorder turnover, contact utilization, science return, and command round-trip light time.
   - Remaining orbit/system/measurement work is numerical validation examples, high-precision Earth-orientation/EOP handling, SGP4/TLE integration, propagated AOS/LOS root-bracketing tests, repeat-ground-track integer-search examples, maneuver edge-case handling, exact binomial interval helper tests, calibration-report examples, BER/FER acceptance card UI examples, schedule import/export, and timeline consistency checks.

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
   - ULA and rectangular planar-array steering phase
   - grating-lobe visibility and element-spacing checks
   - broadside array FNBW/HPBW and uniform sidelobe reference
   - scan-loss, phase-quantization efficiency, RMS phase-error loss, and beam-squint warnings

2. Full link budget workbench:
   - EIRP
   - FSPL
   - received power
   - C/N0, Eb/N0, Es/N0
   - required EIRP / required G/T
   - margin and bottleneck explanation
   - satellite incident PFD, saturation flux density, IBO, OBO, and transponder gain
   - per-carrier satellite EIRP and output back-off for multi-carrier loading
   - cascaded uplink/downlink C/N0 and reciprocal impairment summation
   - C/I, C/IM, interference aggregation, and interference margin
   - HPA DC power, dissipated heat, and efficiency derating
   - transponder bandwidth/power utilization with power-limited versus bandwidth-limited bottleneck output

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
   - EVM/MER constellation quality and RSS EVM contributor breakdown
   - nearest-neighbor hard decisions and soft-bit LLR/max-log demapping
   - Nyquist zero-ISI, raised-cosine, and root-raised-cosine response cards
   - OFDM subcarrier, cyclic-prefix, and PAPR outputs
   - phase jitter/frequency-offset sanity checks
   - second-order loop bandwidth, damping, settling, overshoot, and normalized loop bandwidth
   - Gardner, Mueller-Muller, early-late, Costas, and Mth-power synchronization detector outputs
   - Proximity-1 `R_d/R_cs/R_chs` reference-point explanation
   - Proximity-1 coded/channel symbol-rate allowed-set, offset, and stability warnings

5. CCSDS frame/coding workbench:
   - TM/TC/AOS/USLP frame efficiency
   - Space Packet primary-header, APID, sequence-count, packet length, and packet efficiency
   - CLTU overhead
   - sync marker overhead
   - selected code-rate tables
   - COP-1 FOP/FARM sequence state, T1 timer budget, FOP/FARM window checks, retransmission limit, Sent_Queue, and CLCW reporting cadence
   - USLP MCID/GVCID/GMAP ID widths, VCF Count options, truncated frames, TFDF/TFDZ, OID, and SDLS overhead
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

7. Optical communications workbench:
   - diffraction-limited telescope gain and beam divergence
   - optical link factor and received optical power
   - detected signal photons, background photons, and dark counts per slot
   - M-PPM bit rate, slot width, peak-to-average power ratio, and photon efficiency
   - Poisson OOK/PPM BER/SER seeds and background-sensitive warnings
   - uplink beacon acquisition power for tracking photoelectron requirements
   - diffuse sky, point-source, and solar-background power cards
   - diffraction-limited FOV, seeing-limited FOV, Fried parameter, focal-plane spot-size cards
   - detector-array selected-set signal/background combining and PPM error objective
   - ITU-R P.1814 terrestrial FSO link-margin, geometric spreading, visibility attenuation, weak-turbulence scintillation, and ambient-light cards
   - remaining source work: coded SCPPM/PPM performance tables, Hufnagel-Valley/CLEAR turbulence profile datasets, P.1814 mid/far-IR coefficient tables, rain/fog CCDF procedure, optical validation examples, and production-ready detector-array optimization tests

8. System closure workbench:
   - mission data volume
   - required contact time
   - net downlink rate
   - storage margin
   - power/duty-cycle closure

## Stage 5: UI Implication

The UI should not show all parameters in one two-column form. The formula library implies a new UI structure:

- domain landing page: Antenna, Link, Propagation, Baseband, Coding, Frames, Command, Ranging, Optical, System.
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
