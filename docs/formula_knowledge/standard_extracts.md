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

## DESCANSO and DSN Antenna/Link Engineering Extracts

Sources: NASA/JPL DESCANSO `Deep Space Telecommunications Systems Engineering`; DSN 810-005 module 105E, `Atmospheric and Environmental Effects`.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| DS-LINK-001 | DESCANSO section 1.2.1, equations 1.2-1 to 1.2-2 | Received power is a product of transmit power, circuit losses, antenna gains, pointing losses, space loss, atmosphere attenuation, polarization loss, and receive circuit loss; `L_s=(lambda/(4*pi*r))^2` | Store both linear and dB forms. UI should show a decomposed link budget, not one opaque input list. |
| DS-LINK-002 | DESCANSO section 1.2.1, equations 1.2-3 to 1.2-4 | `G = 4*pi*A_e/lambda^2`, `A_e=eta_ap*A_p` | Connects physical aperture, efficiency, effective aperture, and gain. |
| DS-LINK-003 | DESCANSO section 1.2.2, equation 1.2-5 | `N0=k*T_sys` | Noise temperature must be referenced to the same receiver point as received power. |
| DS-LINK-004 | DESCANSO section 1.2.3, equations 1.2-6 to 1.2-7 | Carrier margin is based on residual carrier power relative to `2*B_LO*N0` | Useful for carrier-loop acquisition/lock scenarios separate from data BER. |
| DS-LINK-005 | DESCANSO section 1.2.4, equations 1.2-8 to 1.2-10 | `ST/N0_receiver = S_data/(R_b*N0)`, output metric applies system loss, margin is output minus threshold | Defines the telemetry/command performance-margin chain. |
| DS-LINK-006 | DESCANSO section 1.2.5, equations 1.2-11 to 1.2-14 | Ranging input SNR uses uplink ranging sideband power over `B_R*N0`; ranging margin is output SNR minus required SNR | Keeps radiometric/ranging calculations distinct from telemetry data-link calculations. |
| DS-ANT-001 | DESCANSO section 8.2, equations 8.2-14 to 8.2-16 | `G=eta_ap*4*pi*A_p/lambda^2`; aperture efficiency is a product of radiation, taper, spillover, surface, blockage, strut, squint, and astigmatism terms; `eta_surface=exp(-(4*pi*K_surf*sigma_surface/lambda)^2)` | Use as an antenna workbench group with expandable efficiency factors. |
| DS-ANT-002 | DESCANSO section 8.4, equations 8.4-1 to 8.4-3 | Pointing loss is boresight gain minus off-axis pattern gain; mean and variance are expectations over the pointing-error density | Calculator needs both simple deterministic pointing loss and statistical design-control mode. |
| DS-ANT-003 | DESCANSO section 8.5, equations 8.5-1 to 8.5-2 | `eta_pol=P_delivered/P_available`; `Ellipticity_dB=20log10(AR)` | Complements vector polarization loss in the catalog. |
| DS-ATM-001 | DSN 810-005 105E section 2.1.1, equation 1 | `T_M=255+25*CD`, with `0<=CD<=0.99` | Weather cumulative distribution drives mean atmospheric radiating temperature. |
| DS-ATM-002 | DSN 810-005 105E section 2.1.2, equation 2 | `A(theta)=A_zen/sin(theta)` | Flat-Earth elevation-angle attenuation model; DSN text warns not to double-count atmosphere in effective antenna gain. |
| DS-ATM-003 | DSN 810-005 105E section 2.1.3, equation 3 | `T_atm(theta)=T_M*(1-1/L(theta))`, `L(theta)=10^(A(theta)/10)` | Converts atmospheric attenuation into noise-temperature contribution. |
| DS-ATM-004 | DSN 810-005 105E section 2.1.4, equations 4 to 6 | `T_CMB=2.725 K`; `T_CMB_eff=T_CMB/L(theta)`; `T_op=T_AMW+T_atm+T_CMB_eff` with `T_AMW=T1+T2*exp(-a_noise*theta)` | Adds sky-noise closure for receiver G/T and `N0` calculations. |

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

## CCSDS 131.0-B-5 TM Synchronization and Channel Coding

Source: CCSDS 131.0-B-5, `TM Synchronization and Channel Coding`, September 2023. CCSDS active-publication listings show Issue 6 dated April 2026; this extraction uses the public B-5 PDF until the B-6 PDF is publicly retrievable and checked.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| TMCH-001 | Section 3.3 and 3.4 | Basic convolutional code is rate `r=1/2`, constraint length `K=7`; punctured rates are `2/3`, `3/4`, `5/6`, `7/8` | `ConvOutSymbols = InfoBits/r_conv`; expose rate as a managed option and keep K/G vectors as metadata. |
| TMCH-002 | Section 4.3.1 and 4.3.2 | R-S symbol size `J=8`; correction capability `E in {8,16}`; `n=2^J-1=255`; `k=n-2E` | Gives standard (255,239) and (255,223) options. |
| TMCH-003 | Section 4.3.5 to 4.3.8 | Interleaving depth `I in {1,2,3,4,5,8}`; maximum codeblock length `Lmax=nI=255I`; check symbols are `2EI` symbols or `2EIJ` bits | Implement `RS_CheckBits`, `RS_CodeblockBits`, and interleaver validation from these managed options. |
| TMCH-004 | Section 4.3.7 and 11.5 | Shortened R-S transfer-frame length in octets: `L=(255-2E-q_rs)I`; codeblock octets after virtual fill shortening: `(255-q_rs)I` | `q_rs` is virtual fill per R-S codeword. 32-bit compatibility additionally requires `(255-q_rs)I` to be a multiple of 4 octets. |
| TMCH-005 | Section 6.3, tables 6-1 and 6-2 | Turbo nominal rates `r in {1/2,1/3,1/4,1/6}`; information lengths `k in {1784,3568,7136,8920}` bits; codeword length `n=(k+4)/r` | Use exact table values as selectable validation rows. True rate is `k/n`, slightly below nominal rate. |
| TMCH-006 | Section 7.4.3 and table 7-5 | Transfer-frame LDPC lengths for rates `1/2`, `2/3`, `4/5`: `k in {1024,4096,16384}` bits and table codeword lengths `n={2048,8192,32768}`, `{1536,6144,24576}`, `{1280,5120,20480}` respectively | Treat as table-backed choices, not a free algebraic formula in UI validation. |
| TMCH-007 | Section 8.1 and 8.2 | Stream-LDPC slices a stream of Sync-Marked Transfer Frames into `k`-bit sections, encodes to `n`-bit LDPC codewords, aggregates `m` codewords, and prepends a CSM | `LDPC_StreamInfoBits=m_ldpc*k_ldpc`; `StreamLDPC_UnitBits=CSM_bits+m_ldpc*n_ldpc`. |
| TMCH-008 | Section 8.2.2 | CSM is 32 bits for rate `7136/8160 (~7/8)` and 64 bits for rates `1/2`, `2/3`, `4/5` | CSM is not input to the LDPC encoder/decoder and immediately precedes each randomized codeblock. |
| TMCH-009 | Section 9.3 | ASM patterns: 32-bit `1ACFFC1D` for uncoded/convolutional/R-S/concatenated/rate-7/8 TF-LDPC/all stream-LDPC; 64-bit `034776C7272895B0` for rate-1/2 Turbo and lower-rate TF-LDPC; 96/128/192 bits for Turbo rates 1/3, 1/4, 1/6 | Calculators normally need length and mode; parser/test fixtures may also store the hex constants. |
| TMCH-010 | Section 9.4 and 9.5 | ASM immediately precedes the R-S codeblock, Turbo/TF-LDPC codeword, or Transfer Frame depending on coding mode; ASM is not part of R-S/Turbo/LDPC encoded data | Use `ASMOverhead=ASM_bits/(ASM_bits+coded_unit_bits)` and keep mode-specific placement text in UI explanations. |
| TMCH-011 | Section 10.2 to 10.4 | Randomization XORs each data bit after ASM with the pseudo-random sequence; long sequence length is `131071=2^17-1`, generated by `h(x)=x^17+x^14+1`; legacy sequence is `255=2^8-1` | Randomization has zero bit overhead. Long-randomizer seed is `11000111000111000`; short legacy seed is all ones. |
| TMCH-012 | Section 11.7 to 11.9 | Turbo transfer-frame octets: `{223,446,892,1115}`; TF-LDPC octets: `892` for rate 7/8, `{128,512,2048}` for rates 1/2, 2/3, 4/5; stream-LDPC max transfer-frame octets: 2048 for TM/AOS and 65536 for USLP | Implement as mode-dependent validation rows before exposing generalized frame-length inputs. |
| TMCH-013 | Section 12.1 to 12.8 | Managed parameters include randomizer choice, coding method, convolutional rate, R-S `E/I/Q`, Turbo `r/k`, LDPC `r/k`, and stream-LDPC `m=1..8` | These should become scenario configuration fields, mostly hidden in advanced groups. |

## Extraction Status Delta

| Source | Previous status | Current status | Remaining work |
| --- | --- | --- | --- |
| ITU-P525 | Listed as source; formulas partly seeded | Equations 1-11 extracted into catalog and variables | Add unit-test examples for all practical-unit conversions when calculators are implemented. |
| DESCANSO/DSN | Listed as source; antenna/link formulas partly seeded | Received-power chain, aperture efficiency, pointing/polarization loss, noise density, link margins, ranging SNR, and DSN atmospheric noise-temperature formulas extracted | Extract DSN 101/103/104 antenna station tables and build deterministic examples for each workbench. |
| CCSDS-414.1 | Listed as source; PN formulas partly seeded | Chip-rate equations, selector rules, cross-support examples, acquisition scaling, delay limits, and jitter reference rows extracted | Extract full transparent/regenerative mode field matrices and station/on-board performance tables. |
| CCSDS-131 | Listed as source; generic coding formulas seeded | Public B-5 convolutional, R-S, Turbo, LDPC, ASM, CSM, randomizer, and frame-length extracts added | Verify deltas against Issue 6 when the official B-6 PDF is accessible. |
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
