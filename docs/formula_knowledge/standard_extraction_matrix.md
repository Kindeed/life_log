# Standard Extraction Matrix

This file turns the source registry into concrete extraction work. The intent is to avoid adding isolated formulas without knowing which standard table, field, or procedure they belong to.

## CCSDS Space Link Services

| Source | Extract | Output artifacts | Formula catalog targets | Notes |
| --- | --- | --- | --- | --- |
| CCSDS 401.0-B RF and Modulation Systems | modulation families, symbol-rate assumptions, spectral occupancy, frequency/Doppler constraints | modulation table, occupied-bandwidth notes, frequency guard procedure | BB-005, BB-006, TRK-007, TRK-010, TRK-011 | Start with public table of contents and active issue; avoid restricted/regulatory interpretation until checked. |
| CCSDS 131.0-B TM Synchronization and Channel Coding | randomizer behavior, attached sync marker, RS/convolutional/turbo/LDPC options, interleaving, coded-frame lengths | coding-mode table, sync overhead table, coded-rate procedure | BB-015, BB-016, BB-018 to BB-030, TM-010 to TM-013, TM-023 to TM-042 | First-pass extraction completed from public Issue 5; CCSDS lists Issue 6 in April 2026, so B-6 delta verification remains required. |
| CCSDS 131.2-B high-rate telemetry ACM | SCCC/high-rate coding modes and modulation options | ACM mode table, spectral efficiency table | BB-005, BB-006, BB-011, BB-012 | Treat MODCOD/performance tables as data, not prose. |
| CCSDS 131.3-B DVB-S2 mapping | DVB-S2 MODCODs usable by CCSDS links, PL frame overhead, supported services | MODCOD table, frame overhead table | BB-005, BB-006, PROTO-003, SYS-003 | Cross-check ETSI DVB-S2 source if needed. |
| CCSDS 231.0-B TC Synchronization and Channel Coding | CLTU structure, BCH/LDPC block parameters, fill/tail, repeated transfer frame rules | CLTU overhead table, BCH/LDPC rate table | TC-006 to TC-008, TC-017 to TC-025, PROTO-005 | BCH/LDPC codeword sizing, CLTU start/tail lengths, fill formulas, and managed parameters started in `standard_extracts.md`. |
| CCSDS 132.0-B TM Space Data Link Protocol | TM transfer-frame fields, optional fields, security extension interaction | TM frame field table and efficiency formula variants | TM-008, TM-009, TM-015 to TM-022, PROTO-001, PROTO-012 | Primary/secondary header fields, OCF/FECF, data-field capacity, and SDLS capacity started in `standard_extracts.md`. |
| CCSDS 232.0-B TC Space Data Link Protocol | TC transfer-frame fields, sequence control, segmentation/security fields | TC frame field table and command efficiency variants | TC-001 to TC-006, TC-011 to TC-016, PROTO-001, PROTO-006 | Frame length count, segment header, control command sizes, FECF, and SDLS capacity started in `standard_extracts.md`. |
| CCSDS 732.0-B AOS Space Data Link Protocol | AOS transfer-frame fields, insert zone, virtual-channel operation | AOS frame field table, VC throughput formulas | TM-008, TM-009, PROTO-012 | Useful for high-rate downlink and relay scenarios. |
| CCSDS 732.1-B USLP | USLP transfer-frame fields, VC/MAP services, truncated transfer frames | USLP field table, service-overhead table | TM-008, PROTO-001, PROTO-003, PROTO-012 | Current source registry notes Issue 3, June 2024. |
| CCSDS 414.1-B PN Ranging Systems | transparent/regenerative PN modes, chip-rate parameter values, modulation options | PN mode table, chip-rate table, ambiguity/resolution procedure | TRK-001 to TRK-006, TRK-017 to TRK-023 | Chip-rate equations, selector rules, acquisition scaling, delay limits, and jitter reference rows started in `standard_extracts.md`. |
| CCSDS 415.0-G CDMA/ranging support | spread-spectrum concepts, processing gain, CDMA relay examples | processing-gain notes, CDMA ranging scenario | BB-017, TRK-004, TRK-005 | Green Book support material, not a requirement source. |
| CCSDS 211.0/211.1/211.2 Proximity-1 | Proximity frame fields, physical data rates, coding/sync options | proximity mode table, net-rate formula | PROTO-011, PROTO-012, LINK formulas | Needed for orbiter-lander/relay calculators. |
| CCSDS 121/122/123 compression | compression parameters, packet insertion, rate-control fields, predictor/quantizer controls | compression parameter table, packet overhead table | COMP-001 to COMP-014, SYS-003, SYS-004 | Avoid implementing algorithm internals before extracting exact state machines/tables. |

## ITU-R Propagation

| Source | Extract | Output artifacts | Formula catalog targets | Notes |
| --- | --- | --- | --- | --- |
| ITU-R P.525 | FSPL equations, radar free-space loss, conversion formulas | free-space/radar formula variants | LINK-001, LINK-002, LINK-018 to LINK-026, TRK-014 to TRK-016, MEAS-009, MEAS-010 | P.525-5 equations 1-11 extracted in `standard_extracts.md`; next step is calculator test vectors. |
| ITU-R P.618 | Earth-space attenuation procedure, availability percentage, elevation/path geometry | P.618 procedure checklist and input schema | LINK-009, LINK-011, LINK-052 to LINK-065, SYS-010 | Rain attenuation and total attenuation formulas extracted; scintillation, depolarization, and full availability procedure remain. |
| ITU-R P.676 | gaseous attenuation model and required atmospheric inputs | gas attenuation procedure | LINK-012 | Likely table/procedure-heavy. |
| ITU-R P.838 | rain specific attenuation coefficients and polarization/elevation handling | `k`, `alpha` coefficient table schema | LINK-010, LINK-011, LINK-045 to LINK-049 | Formula and curve-fit structure extracted; coefficient tables need machine-readable assets. |
| ITU-R P.839 | rain height model | rain-height helper procedure | LINK-050, LINK-051 | Rain-height relation extracted; digital map interpolation needs data asset handling. |
| ITU-R P.840 | cloud/fog attenuation | cloud attenuation procedure | LINK-009 | Add after P.618/P.838. |

## NASA/JPL and Textbook Cross-Checks

| Source | Extract | Output artifacts | Formula catalog targets | Notes |
| --- | --- | --- | --- | --- |
| DSN 810-005 | DSN link, telemetry, command, ranging, frequency/timing modules | DSN scenario checklist, station-parameter fields | LINK, TC, TRK, ORB | Module 105E atmospheric attenuation/noise-temperature formulas extracted; station antenna modules 101/103/104 remain. |
| DESCANSO-DSTSE | antenna gain, effective aperture, system temperature, link derivation | derivation notes and variable definitions | RF-003, RF-004, RF-010, RF-021 to RF-030, LINK-003, LINK-027 to LINK-037 | Antenna aperture efficiency, pointing/polarization loss, received-power chain, noise density, and performance-margin formulas extracted. |
| Balanis | antenna parameters, Friis, radar equation, antenna temperature, arrays | antenna formula batch | RF, TRK-014, TRK-015 | Use published-book concepts; do not copy text. |
| Sklar / Proakis / Haykin | BER/PER, modulation, coding, synchronization, source coding | digital-comms formula batch | BB-001 to BB-062, COMP, PROTO | Baseband timing/energy, Shannon/Nyquist, pulse shaping, quantization, matched-filter, OFDM, phase-jitter, and MIMO seeds added; detailed BER tables and synchronization loop procedures remain. |
| Maral/Bousquet | satellite uplink/downlink/overall link, transponder, intersatellite links | satellite link scenarios | LINK, RF, SYS | Useful for scenario UI organization. |
| SMAD / Vallado / Bate | contact geometry, data budget, operations closure, orbital relationships | orbit/contact/system formulas | ORB, SYS, TRK | Needed because the requested scope includes overall system calculations. |

## Extraction Status

| Batch | Status | Completion evidence required |
| --- | --- | --- |
| Source registry | started | Every source has official/publisher URL and intended use. |
| Formula seed catalog | started | Each domain has formula entries and variable definitions. |
| CCSDS table extraction | started | Table entries captured with source section/page references and tests for selected examples; CCSDS 131 B-5, 231, 132, 232, and 414.1 have first-pass extracts. |
| ITU-R propagation procedures | not started | Procedure checklist, coefficient schema, validity ranges, and sample validation cases. |
| App integration | not started for new knowledge base | Data model, calculators, tests, and phone UI verification. |
