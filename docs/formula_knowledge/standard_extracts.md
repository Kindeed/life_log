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
| CCSDS-231 | Listed as source; CLTU formulas partly seeded | BCH/LDPC codeword sizing, CLTU start/tail lengths, fill formulas, managed parameters extracted | Extract PLOP timing details and any mission-specific maximum CLTU constraints when implementing. |
| CCSDS-132 | Listed as source; generic TM frame formulas seeded | TM primary/secondary header fields, data-field capacity, OCF/FECF overhead, SDLS capacity extracted | Add machine-readable field schema and examples for packet/OID extraction. |
| CCSDS-232 | Listed as source; generic TC frame formulas seeded | TC frame length count, data-field capacity, segment header, control command sizes, FECF, SDLS capacity extracted | Add COP/FARM timing and sequence-control behavior in a later pass. |

## CCSDS 231.0-B-4 TC Synchronization and Channel Coding

Source: CCSDS 231.0-B-4, `TC Synchronization and Channel Coding`, July 2021.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| TCCH-001 | Section 3.2, figure 3-1 | BCH codeword has 56 information bits, 7 complemented parity bits, and 1 appended filler bit; transmitted length is 64 bits | Use `BCH_Codewords = ceil(TransferFrameBits/56)` for sizing. |
| TCCH-002 | Section 3.3 | BCH generator polynomial `g(x) = x^7 + x^6 + x^2 + 1` | Store as implementation metadata; parity generation is procedural. |
| TCCH-003 | Section 3.4 | `BCH_FillBits = (56 - (TransferFrameBits mod 56)) mod 56` | Fill pattern starts with zero and alternates ones and zeros. |
| TCCH-004 | Section 4.2 | LDPC options: `(n=128,k=64)` and `(n=512,k=256)`, both with code rate `1/2` | Use selectable `n_ldpc` and `k_ldpc` values; matrices remain table/procedure data. |
| TCCH-005 | Section 4.4 | `LDPC_FillBits = (k_ldpc - (TransferFrameBits mod k_ldpc)) mod k_ldpc` | LDPC fill is added before encoding and then encoded/randomized. |
| TCCH-006 | Section 5.2.1, figure 5-1 | BCH CLTU structure: 16-bit Start Sequence, 64-bit BCH codewords, 64-bit Tail Sequence | `BCH_CLTU_Bits = 16 + 64*BCH_Codewords + 64`. |
| TCCH-007 | Section 5.2.1, figure 5-2 | LDPC CLTU structure: 64-bit Start Sequence, 128- or 512-bit LDPC codewords, optional 128-bit tail for LDPC(128,64) | `LDPC_CLTU_Bits = 64 + n_ldpc*LDPC_Codewords + TailBits`. |
| TCCH-008 | Section 5.2.2 | Start sequence lengths: 16 bits for BCH; 64 bits for LDPC | Start bit patterns are standard constants; calculators normally only need lengths. |
| TCCH-009 | Section 5.2.4 | Tail sequence lengths: 64 bits for BCH; optional 128 bits for LDPC(128,64); no tail for LDPC(512,256) | Tail handling is a managed option for short LDPC. |
| TCCH-010 | Section 8.2 | Managed parameters include code type, maximum CLTU length, repetitions maximum, PLOP, BCH randomizer, BCH decoding mode, LDPC code length, LDPC tail usage | Convert to calculator validation/options before app implementation. |

## CCSDS 132.0-B-3 TM Space Data Link Protocol

Source: CCSDS 132.0-B-3, `TM Space Data Link Protocol`, October 2021.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| TMDL-001 | Section 4.1.1, figure 4-1 | TM frame fields: 6-octet primary header; optional secondary header up to 64 octets; variable data field; optional 4-octet OCF; optional 2-octet FECF | Frame length is constant within a mission phase for the relevant channel. |
| TMDL-002 | Section 4.1.2, figure 4-2 | Primary header fields: 2-bit TFVN, 10-bit SCID, 3-bit VCID, 1-bit OCF flag, 8-bit MC frame count, 8-bit VC frame count, 16-bit data field status | Use as a field-width table, not a standalone formula. |
| TMDL-003 | Section 4.1.2.7 | Data field status subfields: secondary-header flag 1 bit, sync flag 1 bit, packet-order flag 1 bit, segment length ID 2 bits, first header pointer 11 bits | Important for packet extraction and idle/OID cases. |
| TMDL-004 | Section 4.1.2.7.6 | First Header Pointer special values: `11111111111` no packet starts; `11111111110` only idle data | Encode as option constants for parser/calculator explanations. |
| TMDL-005 | Section 4.1.3 | Secondary header length: identification octet plus 1-63 octets of data; length field stores total secondary header octets minus one | `TM_SecondaryHeaderLengthField = TM_SecondaryHeaderOctets - 1`. |
| TMDL-006 | Section 4.1.4 | `TM_DataFieldOctets = TM_FrameOctets - 6 - SecondaryHeaderOctets - OCFOctets - FECFOctets` | Data field contains packets, one VCA_SDU, or idle data. |
| TMDL-007 | Section 4.1.6 | FECF is optional, 16 bits, computed with `G(X)=X^16+X^12+X^5+1` and all-ones preset polynomial | Same FECF formula family as TC. |
| TMDL-008 | Section 6.3 | TM with SDLS inserts security header before data and security trailer after data, reducing the data-field length | `TM_SDLS_DataFieldOctets = TM_FrameOctets - 6 - SecondaryHeaderOctets - SecurityHeaderOctets - SecurityTrailerOctets - OCFOctets - FECFOctets`. |

## CCSDS 232.0-B-4 TC Space Data Link Protocol

Source: CCSDS 232.0-B-4, `TC Space Data Link Protocol`, October 2021, with Corrigendum 1 dated October 2023.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| TCDL-001 | Section 4.1.1, figure 4-1 | TC frame fields: 5-octet primary header; variable data field up to 1019 or 1017 octets; optional 2-octet FECF | TC frame is variable length, unlike TM fixed-length frames. |
| TCDL-002 | Section 4.1.2, figure 4-2 | TC primary header fields: 2-bit TFVN, 1-bit bypass flag, 1-bit control command flag, 2-bit spare, 10-bit SCID, 6-bit VCID, 10-bit frame length count, 8-bit frame sequence number | Field widths drive parser and UI explanations. |
| TCDL-003 | Section 4.1.2.7 | `TC_FrameOctets = FrameLengthCount + 1` | Frame length count is one fewer than total octets in the transfer frame; maximum is 1024 octets. |
| TCDL-004 | Section 4.1.3.1 | `TC_DataFieldOctets = TC_FrameOctets - 5 - FECFOctets`; maximum data field is 1019 octets without FECF, 1017 with FECF | Base TC data capacity formula. |
| TCDL-005 | Section 4.1.3.2.2 | Segment Header is 1 octet: 2-bit sequence flags plus 6-bit MAP ID | `SegmentUserDataOctets = TC_DataFieldOctets - 1` when present. |
| TCDL-006 | Section 4.1.3.3 | Control command sizes: Unlock is 1 octet; Set V(R) is 3 octets | Useful for Type-BC command sizing. |
| TCDL-007 | Section 4.1.4 | FECF is optional, 16 bits, computed with `G(X)=X^16+X^12+X^5+1` and all-ones preset polynomial | Same CRC formula family as TM. |
| TCDL-008 | Section 6.3 | TC with SDLS uses security header/trailer only on Type-D frames; Type-C frames do not carry SDLS fields | Security overhead must depend on frame type. |
| TCDL-009 | Section 6.3.5 | `TC_SDLS_DataFieldOctets = TC_FrameOctets - 5 - SegmentHeaderOctets - SecurityHeaderOctets - SecurityTrailerOctets - FECFOctets`; maximum form replaces `TC_FrameOctets` with `1024` | The maximum data-field length with SDLS depends on segment and security field presence. |
