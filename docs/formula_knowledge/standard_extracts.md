# Standard Extracts

This file records implementation-ready extracts from individual standards. It is separate from `formula_catalog.md` so the catalog can stay concise while still preserving the exact standard context needed for calculators, validation, and UI explanations.

## ITU-R P.525-5 Free-Space Attenuation

Source: ITU-R P.525-5, `Calculation of free-space attenuation`, approved 2024-11.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| P525-001 | Annex 2.1, equation 1 | `e = sqrt(30 p) / d` | Field strength from EIRP in free space. Use SI units: `e` in V/m, `p` in W, `d` in m. |
| P525-002 | Annex 2.1, equation 2 | `e_mV_m = 173 sqrt(p_kW) / d_km` | Practical field-strength form. Keep field ID distinct from dB field strength `E`. |
| P525-003 | Annex 2.2, equation 3 | `s = e^2/(120 pi) = p/(4 pi d^2)` | Plane-wave PFD relation. Connects field-strength and PFD calculators. |
| P525-004 | Annex 2.3, equation 4 | `p_r = p lambda^2 / ((4 pi d)^2)` | Available power at an isotropic receiving antenna. |
| P525-005 | Annex 2.3, equation 5 | `L_bf = 20 log10(4 pi d / lambda)` | Free-space basic transmission loss with `d` and `lambda` in the same unit. |
| P525-006 | Annex 2.3, equation 6 | `L_bf = 32.4 + 20 log10(f_MHz) + 20 log10(d_km)` | Practical FSPL form in MHz and km. Existing app GHz/km form is equivalent after constant conversion. |
| P525-007 | Annex 3, equation 7 | `L_br = 103.4 + 20 log10(f_MHz) + 40 log10(d_km) - 10 log10(sigma)` | Radar free-space basic transmission loss for a common-antenna radar. |
| P525-008 | Annex 4, equations 8-11 | `E = Pt - 20log10(d_km) + 74.8`; `Pr = E - 20log10(f_GHz) - 167.2`; `L_bf = Pt - E + 20log10(f_GHz) + 167.2`; `S = E - 145.8` | dB conversions among isotropic transmitted power, field strength, received power, free-space loss, and PFD. |

## CCSDS 414.1-B-3 PN Ranging

Source: CCSDS 414.1-B-3, `Pseudo-Noise (PN) Ranging Systems`, January 2022. The document control notes an October 2024 editorial page-size change.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| PN-001 | Section 3.3.3, table 3-1 | `Fchip_S = l_pn * f_S_MHz / (128 * 2^k_pn)` | Regenerative PN ranging S-band uplink chip rate. `Fchip = 2 Fclock`, `Fchip` in Mchip/s. `k_pn`/`l_pn` are implementation aliases for standard symbols `k`/`l`. |
| PN-002 | Section 3.3.3, table 3-1 | `Fchip_X = l_pn * (221/749) * f_X_MHz / (128 * 2^k_pn)` | X-band uplink chip-rate relation. |
| PN-003 | Section 3.3.3, table 3-1 | `Fchip_Ka = l_pn * (221/3599) * f_Ka_MHz / (128 * 2^k_pn)` | Ka-band uplink chip-rate relation. The document notes the Ka-band uplink range for this table. |
| PN-004 | Section 3.3.3 | `k_pn=6` with `l_pn in {1..12,16,32,64,94}` or `l_pn=2` with `k_pn in {8,9,10}` | Selector validation rule. `l_pn=94` is only for Ka-band uplinks. |
| PN-005 | Section 3.3.3 | Cross-support rates: approximately 2 Mchip/s with `l_pn=8,k_pn=6`; approximately 1 Mchip/s with `l_pn=4,k_pn=6` | Earth stations should support both values for interoperability. |
| PN-006 | Annex B, table B-1 | For `f_X = 7179.000 MHz`: `l_pn=4,k_pn=6 -> 1034.295 kchips/s`; `l_pn=8,k_pn=6 -> 2068.590 kchips/s` | Useful regression examples for chip-rate calculators. |
| PN-007 | Section 3.4.3.3 | `Tacq = Tacq_ref / 10^((PrN0_dBHz - 30)/10)` | Regenerative on-board acquisition-time scaling from table 3-2 values. |
| PN-008 | Section 3.4.3.3, table 3-2 | `Tacq_ref = 85.7 s` for balanced weighted-voting Tausworthe `nu=4`; `5.2 s` for `nu=2`, at `Pr/N0=30 dB-Hz` | Table values become selectable reference rows. |
| PN-009 | Section 3.4.4 | `average_delay_stability <= max(1/(30 Fchip), 20 ns)` | Applies across nominal frequency, input level, modulation index, power, temperature, and lifetime. |
| PN-010 | Section 3.4.4 | `delay_calibration_accuracy <= max(1/(500 Fchip), 1 ns)` | Uses engineering telemetry such as uplink frequency, power level, voltage, and temperature. |
| PN-011 | Section 3.4.5, table 3-3 | On-board one-way jitter references at `Pr/N0=30 dB-Hz`, `B_L=1 Hz`, `Fchip=2.068 Mchip/s`: `0.87 m` for `nu=4`; `1.29 m` for `nu=2` | Store as table data, not a universal formula. |
| PN-012 | Section 3.5 and section 4 | Downlink chip rate is coherent with uplink chip rate; transparent station acquisition uses a 10 dB-Hz reference table | Transparent and regenerative modes need separate UI mode paths. |

## Extraction Status Delta

| Source | Previous status | Current status | Remaining work |
| --- | --- | --- | --- |
| ITU-P525 | Listed as source; formulas partly seeded | Equations 1-11 extracted into catalog and variables | Add unit-test examples for all practical-unit conversions when calculators are implemented. |
| CCSDS-414.1 | Listed as source; PN formulas partly seeded | Chip-rate equations, selector rules, cross-support examples, acquisition scaling, delay limits, and jitter reference rows extracted | Extract full transparent/regenerative mode field matrices and station/on-board performance tables. |
