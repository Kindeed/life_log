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

Sources: NASA/JPL DESCANSO `Deep Space Telecommunications Systems Engineering`; DSN 810-005 modules 101I, 103F, 104P, and 105E.

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
| DS-STN-001 | DSN 810-005 101I appendix A.1; 103F appendix A.1; 104P appendix A.1 | `G(theta)=G0-G1*(theta-gamma)^2-Azen/sin(theta)` | Station gain curves are referenced to the feedhorn aperture. Select `G0`, `G1`, `gamma`, and `Azen` from the relevant station/band/configuration table. |
| DS-STN-002 | DSN 810-005 101I appendix A.2; 103F appendix A.2; 104P appendix A.2 | `Top(theta)=TAMW+Tsky`, `TAMW=T1+T2*exp(-a*theta)`, `Tsky=Tatm(theta)+TCMB/L(theta)` | This restates the DSN system-temperature closure at station-module level and points to modules 101/103/104 for `T1`, `T2`, `a`, and antenna/feed configuration tables. |
| DS-STN-003 | DSN 810-005 101I tables 2, 4, A-2, A-3; 103F tables 3, 5, A-2, A-3; 104P tables 5-9 and A-1 to A-5 | TAMW, Tsky, Top, Azen, gain-curve, and antenna-microwave noise-temperature parameter tables | Treat as machine-readable station data, not hand-entered constants. The UI should expose station, band, polarization, LNA/feed/dichroic path, weather CD, and elevation rather than a flat list of hidden coefficients. |

## ITU-R Earth-Station Antenna Patterns and Published Antenna Textbook Checks

Sources: ITU-R S.465-6 `Reference radiation pattern of earth station antennas in the fixed-satellite service`; ITU-R S.580-6 `Radiation diagrams for use as design objectives for antennas of earth stations operating with geostationary satellites`; Balanis `Antenna Theory: Analysis and Design`, 4th edition.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| ITUANT-001 | S.465-6 recommends 2 | `G=32-25log10(phi)` for `phi_min<=phi<48 deg`; `G=-10 dBi` for `48<=phi<=180 deg`; `phi_min=max(1 deg,100 lambda/D)` for `D/lambda>=50` | Use for fixed-satellite-service earth-station coordination/interference assessment when no measured antenna pattern is available. |
| ITUANT-002 | S.465-6 recommends 2 and notes 4-5 | Smaller-aperture and legacy branches use `phi_min=max(2 deg,114(D/lambda)^-1.09)` for `D/lambda<50`, plus the pre-1993 `52-10log10(D/lambda)-25log10(phi)` branch where applicable | Treat legacy branches as explicit scenario flags; do not silently apply them to new designs. |
| ITUANT-003 | S.580-6 recommends 1 and note 5 | GSO side-lobe design objective `G=29-25log10(phi)` and transition branch `G=-3.5 dBi` for `20 deg<phi<=26.3 deg` | This is a design objective for side-lobe peaks near the GSO zone, not a measured gain pattern. |
| ITUANT-004 | S.580-6 note 2 | Equivalent circular aperture diameter `D_e=sqrt(4A/pi)` for asymmetric aperture checks | Use with axis-orientation notes when validating asymmetric earth-station antenna layouts. |
| BOOKANT-001 | Balanis antenna-parameter chapters | `U=r^2 S_rad`, `D_0=4*pi U_max/P_rad`, `G=eta_rad D_0` | These definitions make gain/efficiency/directivity explicit instead of treating dBi as a free input. |
| BOOKANT-002 | Balanis beam solid angle and approximate directivity material | `Omega_A=integral(P_n dOmega)`, `D_0=4*pi/Omega_A`, and `D_0~=41253/(theta_HP phi_HP)` with beamwidths in degrees | Provides useful outputs for antenna sizing when only measured or specified HPBWs are available. |
| BOOKANT-003 | Balanis aperture and measurement-region material | Uniform circular-aperture estimates `theta_FNBW~=2.44lambda/D`, `theta_HPBW~=1.02lambda/D`, and far-field distance `R_ff>=2D_max^2/lambda` | Keeps reflector sizing, measurement setup, and inspection warnings in the same antenna workbench. |
| BOOKANT-004 | Balanis polarization and array chapters | `PLF=|rho_wave dot rho_ant|^2`; ULA `AF=sum(w_n exp(jn psi))`; equal-amplitude closed form `|sin(N_elem psi/2)/(N_elem sin(psi/2))|` | Seeds phased-array and polarization calculators without copying implementation-heavy array synthesis tables. |

## Digital Communications Textbook Cross-Checks

Sources: Sklar/Harris `Digital Communications: Fundamentals and Applications`, 3rd edition; Proakis/Salehi `Digital Communications`, 5th edition; Haykin/Moher `Communication Systems`, 5th edition; Goldsmith `Wireless Communications`; Rappaport `Wireless Communications: Principles and Practice`, 2nd edition; NASA/JPL DESCANSO chapter 5 for deep-space telemetry modulation examples.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| DIGCOM-001 | Sklar/Harris topics on signals, spectra, baseband transmission, link budgets; Proakis/Haykin digital communications basics | `T_s=1/R_s`, `T_b=1/R_b`, `E_b=S_data/R_b`, `E_s=S_data/R_s` | Basic baseband timing and energy terms. Must share reference point with link-budget power. |
| DIGCOM-002 | Sklar/Harris link budget and bandwidth-efficiency topics | `C=B log2(1+SNR)`, `SNR_required=2^eta_s-1` | Shannon capacity is a bound, not a guaranteed link closure. |
| DIGCOM-003 | Sklar/Harris and Proakis pulse-shaping/baseband topics | `B_Nyquist_min=R_s/2`, `B_RC_baseband=(1+alpha)R_s/2`, `B_RC_passband~=(1+alpha)R_s` | Keep baseband one-sided and passband occupied bandwidth as separate fields. |
| DIGCOM-004 | Sklar/Harris formatting/quantization topics | `Delta_q=V_FS/2^N`, `sigma_q^2=Delta_q^2/12`, `ENOB=(SNR_q_dB-1.76)/6.02` | Quantization assumptions require full-scale sine/high-resolution caveats in UI. |
| DIGCOM-005 | DESCANSO section 5.3.1 and Proakis optimum receiver material | Matched filter/correlation detector decision statistic; coherent antipodal error `P_e=Q(sqrt(2Eb/N0))=0.5 erfc(sqrt(Eb/N0))` | DESCANSO states DSN uses matched/correlation detection and models AWGN for deep-space telemetry. |
| DIGCOM-006 | DESCANSO section 5.2.2 and Sklar modulation topics | QPSK/SQPSK use two orthogonal BPSK components; QPSK/SQPSK have BPSK-like power efficiency and roughly half the bandwidth at same data rate and power | These are explanatory mode notes, not independent formulas beyond symbol-rate and bandwidth equations. |
| DIGCOM-007 | Sklar/Harris OFDM/MIMO/synchronization topics | OFDM `Delta_f=1/T_u`, `T_ofdm=T_u+T_cp`, `CP_Overhead=T_cp/T_ofdm`, MIMO `C=log2(det(I+rho/Nt HH^H))` | Mark OFDM/MIMO formulas as scenario seeds until detailed pilot, framing, channel-state, and implementation-loss models are extracted. |
| DIGCOM-008 | Goldsmith and Rappaport wireless-channel chapters; Proakis fading-channel material | Baseband channel `y=h*x+n`, tapped multipath impulse response, mean excess delay, RMS delay spread, coherence bandwidth/time, and maximum Doppler shift | Use these as a channel workbench group. The approximate coherence bandwidth/time constants are model-selection outputs, not universal requirements. |
| DIGCOM-009 | Goldsmith/Rappaport fading and path-loss material; Proakis fading-channel performance material | Log-distance shadowing, Rayleigh envelope PDF/CDF, Rician K factor, Rayleigh outage probability, Rayleigh BPSK average BER, and fading capacity definitions | Separate deterministic link budget from stochastic channel outputs: right-side UI should show average SNR, outage probability, and selected fading-model performance independently. |

## CCSDS 401.0-B-32 RF and Modulation Systems

Source: CCSDS 401.0-B-32, `Radio Frequency and Modulation Systems, Part 1: Earth Stations and Spacecraft`, October 2021.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| CCSDS401-001 | Section 2.4.10 | QPSK serial input is split so even bits `b_(2i)` go to I and odd bits `b_(2i+1)` go to Q; phase states are 45 deg for `00`, 135 deg for `10`, 225 deg for `11`, and 315 deg for `01` | Implement as a mapping/check table, not as a user-editable formula. |
| CCSDS401-002 | Sections 2.4.12A, 2.4.12B, 2.4.13B, 2.4.17A, 2.4.18, 2.4.20B/21A | Phase/amplitude imbalance limits vary by modulation family: common suppressed-carrier RF modulator rows use 5 deg and 0.5 dB; high-order APSK rows can use 3 deg phase; subcarrier modulators use 2 deg and 0.2 dB | Use `PhaseImbalanceMargin_deg` and `AmplitudeImbalanceMargin_dB` with a source-selected limit row. |
| CCSDS401-003 | Sections 2.4.14A and 2.4.14B | `SubcarrierRatio=f_sc/R_cs`; recommended ratios are integer values. Category A text selects 4 above 60 kHz unless spectral overlap requires a higher integer; Category B summary lists 5 above 60 kHz | Store category-specific defaults separately from the integer-ratio validator. |
| CCSDS401-004 | Sections 2.2.5 and 2.4.6 | Subcarrier frequency offset/stability limits include telecommand `2e-4*f_sc`, `1e-5` short-term, `5e-5` long-term and telemetry summary values of 200 ppm, `1e-6`, `2e-5` | Use one generic offset/stability margin formula with the applicable source row selected by link direction and section. |
| CCSDS401-005 | Section 2.4.19 | Suppressed-carrier telemetry coded-symbol-rate offset shall be within 100 ppm, with short-term stability better than `1e-6` and long-term stability better than `1e-5` | Supports right-side UI result groups for symbol-rate offset and stability margin. |
| CCSDS401-006 | Sections 2.4.18, 2.4.20B, and 2.4.21A | High-rate modulation rows include SRRC-QPSK/OQPSK/8PSK/APSK, 4D 8PSK TCM, GMSK, and filtered OQPSK; footnotes define SRRC alpha options and `BTS`, where `B` is one-sided 3-dB filter bandwidth | Use `B_3dB=BTS*R_cs` and table-driven modulation-family options; do not infer spectral-mask compliance without the SFCG mask data. |
| CCSDS401-007 | Section 2.4.18 and related high-rate rows | Signaling efficiency is the ratio of source data rate to channel symbol rate; in-band group-delay variation up to 10 percent of signal duration and AM/PM slope under 5 deg/dB are cited as acceptable engineering constraints in relevant high-rate rows | Add as advanced quality margins rather than primary link-budget outputs. |

## CCSDS 211.2-B-3 Proximity-1 Coding and Synchronization

Source: CCSDS 211.2-B-3, `Proximity-1 Space Link Protocol--Coding and Synchronization Sublayer`, October 2019.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| PROXCS-001 | Section 3.2, figure 3-1 | PLTU structure is 24-bit ASM `FAF320`, Transfer Frame, and 32-bit CRC-32: `PLTU_Bits=24+TransferFrameBits+32` | ASM is used for PLTU detection; CRC is calculated over the Transfer Frame, not the ASM. |
| PROXCS-002 | Section 3.3 | Idle data uses repeated 32-bit PN sequence `352EF853`; acquisition and tail sequences are idle data with managed durations | Use `ceil(Duration*Rd)` and `ceil(bits/32)` for acquisition/tail/idle planning. |
| PROXCS-003 | Section 3.4.2 | Input data rate `Rd` is selected from 1000, 2000, 4000, 8000, 16000, 32000, 64000, 128000, 256000, 512000, 1024000, and 2048000 bit/s; coding options are no coding, convolutional, or LDPC | The standard notes LDPC true `Rd` values are approximated here and require the data-link annex table for exact values. |
| PROXCS-004 | Section 3.4.3 | Convolutional coding is rate 1/2, constraint length 7, and non-punctured; all PLTUs and idle data are encoded | `R_cs_conv=2*Rd` and `ProxConvSymbols=2*InputBits`. |
| PROXCS-005 | Section 3.4.4 | LDPC message blocks are fixed 1024 bits; each is encoded using CCSDS LDPC `(n=2048,k=1024)`, rate 1/2 | `ProxLDPCBlocks=ceil(InputBits/1024)` and `ProxLDPCCodeRate=1024/2048`. |
| PROXCS-006 | Section 3.4.4 | LDPC Codeword Sync Marker is 64 bits, pattern `034776C7272895B0`, and immediately precedes each LDPC codeword with no intervening bits | `ProxLDPCOutputBits=ProxLDPCBlocks*(64+2048)`. |
| PROXCS-007 | Section 3.4.5 | LDPC codewords are randomized by XOR with a pseudo-random sequence that starts at the first codeword bit, repeats after 255 bits, and resets to all-ones at each codeword; the CSM is not randomized | Keep randomization as a procedure; it has no bit overhead but affects receiver synchronization and implementation tests. |

## CCSDS 211.0 / ISO 22663 Proximity-1 Data Link Layer

Sources: CCSDS publication registry for current `211.0-B-6`, July 2020; ISO 22663:2015 / CCSDS 211.0-B-5 public preview for field-level Version-3 Transfer Frame extracts. The public CCSDS `211x0b6.pdf` direct URL returned 404 in this pass, so B-6 USLP deltas remain to verify against an exact PDF.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| PROXDL-001 | CCSDS current-publication registry | CCSDS 211.0-B-6 is the active Data Link Layer issue and adds text related to CCSDS Version-4 / USLP Transfer Frame use | Do not infer Version-4 field formulas until B-6 text is directly retrieved. |
| PROXDL-002 | ISO 22663 / CCSDS 211.0-B-5 section 3.2 and figure 3-2 | Version-3 Transfer Frame has a 5-octet header and up to 2043-octet data field, for a maximum frame size of 2048 octets | `ProxV3DataFieldOctets=ProxV3FrameOctets-5`; max data field is 2043 octets. |
| PROXDL-003 | ISO 22663 / CCSDS 211.0-B-5 section 3.2.2 and figure 3-3 | Mandatory header fields: TFVN 2 bits, QoS 1, PDU Type 1, DFC ID 2, SCID 10, PCID 1, Port ID 3, Source/Destination 1, Frame Length 11, Frame Sequence Number 8 | The field-width sum is 40 bits, matching the 5-octet fixed header. |
| PROXDL-004 | ISO 22663 / CCSDS 211.0-B-5 field widths | `ProxFrameSequenceModulus=2^8`; `ProxSCIDCount=2^10`; `ProxPortCount=2^3`; `ProxPCIDCount=2` | These outputs are useful for validation messages and for explaining multiplexing capacity. |
| PROXDL-005 | ISO 22663 overview and contents | Data Link Layer covers Framing, MAC, Data Services, and I/O sublayers; key tables include U-frame construction rules, segment-header sequence flags, fixed/variable SPDU formats, and state tables | Treat these as extraction backlog items, not formulas, until exact row values are captured. |
| PROXDL-006 | CCSDS 211.0 plus CCSDS 211.2 relationship | Version-3 Transfer Frame overhead combines with PLTU ASM/CRC overhead as `8*ProxV3FrameOctets + 56` bits before optional coding and idle data | Provides a better right-side output than PLTU efficiency alone: frame efficiency after both link-layer and C&S fixed overhead. |

## CCSDS 211.1 / ISO 21460 Proximity-1 Physical Layer

Sources: CCSDS publication registry for `211.1-B-4`, December 2013; ISO 21460:2015 / CCSDS 211.1-B-4 public preview for field-level rate and scope extracts.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| PROXPHY-001 | ISO 21460 / CCSDS 211.1-B-4 section 1.5.3 and figure 1-1 | Proximity-1 distinguishes `R_d`, `R_cs`, and `R_chs`: encoder-input data rate, C&S-to-Physical coded symbol rate, and transmitter-output channel symbol rate | Keep these as separate UI fields/reference points even when a mode makes two rates numerically equal. |
| PROXPHY-002 | ISO 21460 / CCSDS 211.1-B-4 section 1.5.3 | For the specified modulation scheme, `R_chs=R_cs` | This is a physical-layer relationship and should not be applied blindly to unrelated CCSDS 401 high-rate modulations. |
| PROXPHY-003 | CCSDS 211.1-B-4 PICS evidence | Forward and return coded symbol rates use the discrete set `1000..4096000` symbols/s by powers of two; support for at least one value is mandatory | `ProxRcsError=min(abs(R_cs-R_cs_allowed_i))` supports mode validation and UI warnings. |
| PROXPHY-004 | CCSDS 211.1-B-4 PICS evidence | Short-term channel-symbol-rate stability value is `<=1%`; channel-symbol-rate offset value is `<0.1%` | Add physical-layer compliance margins `ProxShortTermStabilityMargin` and `ProxChannelOffsetMargin`. |
| PROXPHY-005 | ISO 21460 scope and overview | Physical Layer covers channel connection, UHF frequency/channel assignments for Mars, hailing channel, polarization, modulation, data rates, and performance requirements | Frequency/channel tables and hailing channel options remain table assets to extract, not scalar formulas. |

## ITU-R Rain and Earth-Space Propagation Extracts

Sources: ITU-R P.838-3 `Specific attenuation model for rain for use in prediction methods`; ITU-R P.839-4 `Rain height model for prediction methods`; ITU-R P.618-14 `Propagation data and prediction methods required for the design of Earth-space telecommunication systems`.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| ITURAIN-001 | P.838-3, equation 1 | `gamma_R = k*R^alpha` | Specific attenuation from rain rate. P.618 uses `R0.01` as the rain-rate input for its long-term rain attenuation procedure. |
| ITURAIN-002 | P.838-3, equations 2 and 3, tables 1 to 4 | Curve fits for `k_H`, `k_V`, `alpha_H`, and `alpha_V` as functions of `f_GHz`, using tabulated constants | Keep coefficient constants as table data; do not hard-code prose-only approximations. |
| ITURAIN-003 | P.838-3, equations 4 and 5 | `k=(k_H+k_V+(k_H-k_V)cos(theta)^2 cos(2*tau))/2`; `alpha=(k_H alpha_H+k_V alpha_V+(k_H alpha_H-k_V alpha_V)cos(theta)^2 cos(2*tau))/(2k)` | Converts horizontal/vertical coefficients to path elevation and polarization tilt. |
| ITURAIN-004 | P.839-4, recommendation 2 | `h_R = h_0 + 0.36 km` | `h_0` comes from the P.839 digital 0 deg C isotherm map; use bilinear interpolation between grid points. |
| ITURAIN-005 | P.618-14 section 2.2.1.1, equations 1 to 3 | `L_s=(h_R-h_s)/sin(theta)` for `theta>=5 deg`; low-elevation `L_s` uses effective Earth radius; `L_G=L_s cos(theta)` | Start of the slant-path rain geometry. If `h_R-h_s<=0`, predicted rain attenuation is zero. |
| ITURAIN-006 | P.618-14 section 2.2.1.1, equations 4 to 7 | `gamma_R=k(R0.01)^alpha`; compute `r0.01`, `v0.01`, `L_E=L_R v0.01`, and `A0.01=gamma_R L_E` | This is the implementation core for annual 0.01% rain fade. |
| ITURAIN-007 | P.618-14 section 2.2.1.1, equation 8 | `A_p=A0.01*(p/0.01)^(-(0.655+0.033ln(p)-0.045ln(A0.01)-beta(1-p)sin(theta)))` | Probability extrapolation for `0.001% <= p <= 5%`; beta is branch-dependent on p, latitude, and elevation. |
| ITURAIN-008 | P.618-14 section 2.5, equations 65 to 68 | `A_T=A_G+sqrt((A_R+A_C)^2+A_S^2)` for `0.001%<=p<=5%`; `A_T=A_G+sqrt(A_C^2+A_S^2)` for `5%<p<=50%`; use `A_C(5%)` and `A_G(5%)` below 5% | Total attenuation combines rain, gas, cloud, and scintillation. Gas/cloud/scintillation subprocedures now have first-pass extracts; coefficient maps/tables remain data assets. |
| ITUGAS-001 | P.676-13 Annex 1, equations 1 to 4 | `gamma=gamma_o+gamma_w=0.1820 f(N''_oxygen+N''_water)`, refractivity sums over spectral lines, and `e=rho*T/216.7` | Line-by-line gas model is table/procedure-heavy; catalog records the computational structure and required variables. |
| ITUGAS-002 | P.676-13 Annex 1, equations 5 to 13 | Line-shape factor, line strengths, dry continuum, path integral, and layer summation `A_gas=sum(a_i gamma_i)` | Exact spectroscopic tables should become data assets, not hand-coded markdown constants. |
| ITUGAS-003 | P.676-13 Annex 2, equations 29 to 37 | Approximate oxygen and water-vapour slant attenuation: `A_o=gamma_o h_o/sin(theta)`, `A_w=gamma_w h_w/sin(theta)`, with coefficient-file equivalent heights | Use for quick Earth-space gas attenuation when surface meteorology or P.2145 map values are available. |
| ITUCLOUD-001 | P.840-9 sections 1 and 2, equations 1 to 10 | `gamma_c=K_l rho_l`; double-Debye liquid-water model for `K_l`; temperature-dependent permittivity and relaxation frequencies | Valid for clouds/fog with small droplets under the P.840 frequency range. |
| ITUCLOUD-002 | P.840-9 section 3, equations 11 to 16 | `A_C=K_L L/sin(theta)` instantaneous/statistical forms and log-normal approximation using `Q^-1(p/P_L)` | Digital cloud-liquid-water maps remain data assets; formulas now identify the calculator inputs and outputs. |
| ITUSCINT-001 | P.618-14 section 2.4.1, equations 42 to 49 | `sigma_ref`, effective path length, effective antenna diameter, antenna averaging factor, time-percentage factor, and `A_S=a(p)*sigma` | Covers tropospheric scintillation at elevation angles >= 5 deg and `0.01% < p <= 50%`. Low-elevation deep/shallow fading remains to extract. |
| ITUSKY-001 | P.618-14 section 3, equations 69 and 70 | `T_sky=T_mr(1-10^(-A/10))+2.7*10^(-A/10)` and `T_mr=37.34+0.81*T_surface` | Adds channel/noise-temperature outputs that can be shown next to attenuation. |

## DESCANSO Tracking, Ranging, and External Measurement Extracts

Source: NASA/JPL DESCANSO `Deep Space Telecommunications Systems Engineering`, chapter 4, with radar cross-checks from ITU-R P.525-5 and Balanis.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| DSTRK-001 | DESCANSO section 4.2.1.1, equations 4.2-2 to 4.2-4 | Received frequency depends on line-of-sight velocity; low-speed one-way Doppler reduces to `f_D ~= -f_T*rho_dot/c` | Keep sign convention explicit. Two-way and three-way practical observables need spacecraft turnaround ratio and media/hardware corrections. |
| DSTRK-002 | DESCANSO section 4.2.1.2, equations 4.2-5 to 4.2-8 | Two-station differenced range, round-trip ranging modulation delay, and cross-correlation estimate | Supports range, differenced range, code ambiguity, and range-residual calculators. |
| DSTRK-003 | DESCANSO section 4.2.1.3, equations 4.2-9 and surrounding VLBI/DOR text | VLBI group delay is driven by baseline projection and source direction; DOR alternates spacecraft and quasar observations to reduce clock/media effects | Add Delta-DOR delay, spanned-bandwidth delay resolution, and angular-error estimates as a separate external-measurement group. |
| DSTRK-004 | DESCANSO sections 4.3.1 to 4.3.3, equations 4.3-1 to 4.3-4 | Biased Doppler counting/resolver phase increment gives average biased frequency; subtract bias to recover average Doppler | Needs counter start/end, resolver fractions, sampling interval, and bias-frequency variables. |
| DSTRK-005 | DESCANSO section 4.4.1.3.2, equations 4.4-23 and 4.4-24 | Ranging delay-estimate variance depends on ranging period, correlation interval, received ranging power, and noise spectral density | Current catalog includes the sine-wave/1-MHz-filtered strong-signal case; square-wave case remains to be extracted after equation-image verification. |
| DSTRK-006 | DESCANSO section 4.4.1.4.1 to 4.4.1.4.2 | Doppler sampling-time and resolver quantization errors convert timing uncertainty to phase uncertainty | Formula entries use uniform-quantization RMS `T_clock/sqrt(12)` and sample epoch phase propagation. |
| DSTRK-007 | DESCANSO section 4.4.1.4.5, equation 4.4-26 | `RTPT = D - BIAS_sc - BIAS_DSS - ZCORRECTION` | Turns measured two-way group delay into corrected round-trip propagation time before range conversion. |
| DSTRK-008 | DESCANSO section 4.4.1 radiometric DCT discussion, equation 4.4-27 | Independent measurement-error terms combine by root-sum-square through sensitivities `dq/dxi` | Use for range/Doppler/angle uncertainty cards, not as a mission-specific covariance estimator. |
| DSTRK-009 | ITU-R P.525-5 section 3 and Balanis radar-equation chapters | Radar free-space loss, monostatic/bistatic echo power, maximum range, range/Doppler resolution, and PRF ambiguity relations | These formulas support external-measurement and radar-like ground test scenarios separate from CCSDS PN ranging. |
| DSN202-001 | DSN 810-005 module 202E, section 2.1, equations 1 to 11 | Residual-carrier, suppressed-carrier BPSK, and QPSK/OQPSK carrier-loop SNR; recommended minimum `rho_L` thresholds | Catalog includes residual, direct-NRZ, BPSK squaring-loss, and loop-margin formulas. QPSK/OQPSK full squaring-loss branch should become a managed expression or lookup helper. |
| DSN202-002 | DSN 810-005 module 202E, section 2.2, equations 12 to 18 | Doppler frequency/range-rate error conversion, total Doppler error RSS, data-imbalance error, one-way thermal-noise variance, Allan-deviation approximation | Adds Doppler error cards that are more useful than raw Doppler shift alone. Solar scintillation equations remain table/model-heavy and are not fully extracted. |
| DSN202-003 | DSN 810-005 module 202E, section 2.3.4, equations 33 to 34 | Carrier phase-error variance is an RSS of thermal, frequency-source, and scintillation terms, with mode-specific recommended limits | Keep carrier phase-error as a separate output from Doppler measurement error. |
| DSN203-001 | DSN 810-005 module 203E, section 2.1 to 2.2, equations 1 to 5 | RU-to-two-way-delay conversion for S/X/K/Ka uplinks; sequential component frequency `f_n=2^-n f_0`; ambiguity tolerance `c/(2 f_n)`; cycle time | Provides direct calculator outputs for range-unit conversion and measurement cadence. |
| DSN203-002 | DSN 810-005 module 203E, section 2.6, equations 46 to 52 | Sequential-ranging thermal-noise range error, required `T1`, TCT jitter RSS, two-way delay sigma, component count, and acquisition probability | Use linear `Pr/N0` internally; dB-Hz inputs need conversion before applying these equations. |
| DSN214-001 | DSN 810-005 module 214C, section 2.2, equations 1 to 11 | PN RU conversion, chip rate, rational `A/B`, range-clock frequency, component-code bipolar conversion, periodic extension, composite period, and ambiguity resolution | Complements CCSDS 414.1 chip-rate rows with DSN operational PN range-code construction details. |
| DSN214-002 | DSN 810-005 module 214C, section 2.5.4 to 2.5.5, equations 85 to 91 | PN thermal range error, delay sigma, regenerative RSS, uplink loop jitter term, and component-code acquisition product | Regenerative and turn-around PN ranging should be separate scenario modes in the eventual UI. |
| DSN214-003 | DSN 810-005 module 214C, section 2.5.8, equations 95 to 96 | Non-coherent PN ranging correlation amplitude loss from range-clock frequency mismatch and direct range error from mismatch | Catalog currently includes amplitude loss; direct range-error term remains queued because equation extraction needs visual verification. |
| DSN211-001 | DSN 810-005 module 211G, section 2.2, equations 1 to 4 | VLBI channel SNR, multi-channel post-correlation SNR, delay/path error, and RMS synthesized bandwidth | Catalog includes the unambiguous multi-channel SNR, path-error, and RMS-bandwidth forms. Single-channel SNR normalization should be implemented only after unit tests against examples. |
| DSN210-001 | DSN 810-005 module 210E, section 2.2 to 2.4, equation 1 and DOR tone ambiguity discussion | Delta-DOR downlink signal model, DOR tone spanned bandwidth, and reciprocal-spanned-bandwidth group-delay ambiguity spacing | Supports UI controls for one-tone/two-tone DOR planning and ambiguity checks. |

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

## CCSDS 121.0-B-3 Lossless Data Compression

Source: CCSDS 121.0-B-3, `Lossless Data Compression`, August 2020.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| COMP121-001 | Sections 3.1.5 to 3.1.6 | Variables required by Rice adaptive coding include block size `J`, sample resolution `n`, and selected code-option ID; `J in {8,16,32,64}`, `n <= 32` | These are managed parameters, not free-form UI fields. |
| COMP121-002 | Section 2.1 and section 2.2 change notes | If input length is not a multiple of `J`, append padding samples; zero-valued preprocessed padding minimizes compressed data | Catalog adds `InputBlocks` and `PaddingSamples` for payload volume estimation. |
| COMP121-003 | Sections 4.2.6 and 4.3 | Reference samples are the first sample of a `J`-sample block and are inserted every `r` blocks when predictive preprocessing needs prior samples; `r <= 4096` | Expose reference-sample overhead only when a predictor mode requires it. |
| COMP121-004 | Sections 4.2.5 and 4.4 | Unit-delay prediction uses the previous sample except at the first sample in a reference interval; `Delta_i=x_i-xhat_i`; `theta_i=min(xhat_i-x_min,x_max-xhat_i)`; mapper produces nonnegative `delta_i` | Use signed/unsigned sample-range helpers before applying the mapper. |
| COMP121-005 | Sections 3.2 and 3.3 | FS codeword for value `v` has `v` zeros followed by one `1`; split-sample option FS-codes `floor(delta_i/2^k)` and appends `k` uncoded LSBs per encoded sample | `k=0` is the FS option; CDS ordering sends all FS codewords before all split bits. |
| COMP121-006 | Section 3.4 | `gamma_j=(delta_(2*j-1)+delta_(2*j))*(delta_(2*j-1)+delta_(2*j)+1)/2 + delta_(2*j)`, `j=1..J/2`; use `delta_1=0` if the first block sample is a reference sample | Second-extension should be a selectable procedure output with estimated encoded length. |
| COMP121-007 | Section 3.5 | Zero-block option always encodes consecutive all-zero blocks; each `r`-block reference interval is partitioned into segments of 64 blocks except possibly the last | Catalog adds zero-block segment sizing; exact zero-run FS/ROS mapping should become table data. |
| COMP121-008 | Section 3.6 | No-compression attaches an identification field and otherwise leaves the entire `J`-sample preprocessed block unchanged | Catalog adds `NoCompressionCDSBits=IDBits+J*n`. |
| COMP121-009 | Sections 3.7 and 5.2.1 | Code selection minimizes encoded bits including ID bits; zero-block has priority; ties prefer no-compression, then second-extension, then smallest `k` | Implement as a deterministic tie-break procedure; table 5-1 provides ID bit sequences. |

## CCSDS 120.2-G-2 / CCSDS 123.0-B-2 Multispectral and Hyperspectral Compression

Sources: CCSDS 120.2-G-2, `Low-Complexity Lossless and Near-Lossless Multispectral and Hyperspectral Image Compression`, December 2022; CCSDS 123.0-B-2 technical corrigendum 3, February 2021. CCSDS lists 123.0-B-2 Issue 2, February 2019, with updates through corrigendum 3.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| COMP123G-001 | Sections 2.1 and 3.3.3 | The standard supports BSQ, BIP, and BIL scan orders for three-dimensional instrument data | Store scan order as a mode field; raw image sizing uses `N_x*N_y*N_z*D` independent of order. |
| COMP123G-002 | Section 3.2.3, equation 13 | `s_hat_z(t)=floor(s_tilde_z(t)/2)`; predicted sample is `D` bits and scaled predicted sample is `(D+1)` bits | Useful for explaining predictor precision and for later exact predictor implementation. |
| COMP123G-003 | Section 3.2.3 | Scaled prediction error is effectively `2*s_z(t)-s_tilde_z(t)` | Keep as predictor metadata until the full closed-loop predictor is implemented. |
| COMP123G-004 | Section 3.2.4.1 | Near-lossless residual quantizer has step size `2*m_z(t)+1`, guaranteeing reconstruction error no larger than `m_z(t)` | This becomes a primary output in a compression trade workbench. |
| COMP123G-005 | Section 3.2.4.1 | Lossless compression sets `m_z(t)=0`; absolute-error-only mode sets `m_z(t)=a_z` | Relative-error formulas in the extracted PDF text were not sufficiently legible; keep them pending until verified from the Blue Book or a cleaner source. |
| COMP123G-006 | Section 3.2.4.1 | Periodic error-limit updates encode new error limits every `2^u` frames | Rate-control UI should show update cadence and header/bitstream impact when exact header fields are extracted. |
| COMP123G-007 | Corrigendum 3, tables B-20 and B-25 updates | Corrigendum 3 changes hybrid entropy-coder table entries, including a flush-word row and one input-codeword range | Treat as table/procedure data, not standalone scalar formulas. |

## Orbit, Contact Geometry, and System Operations Cross-Checks

Sources: Vallado, `Fundamentals of Astrodynamics and Applications`; Bate, Mueller, and White, `Fundamentals of Astrodynamics`; Wertz et al., `Space Mission Engineering: The New SMAD`; NASA/JPL `Basics of Space Flight`; NASA SmallSat State of the Art communications chapter; CelesTrak coordinate references; ESA Navipedia coordinate transformation pages; IERS Conventions.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| ORBSYS-001 | Vallado/Bate two-body orbit chapters | Specific energy, vis-viva, specific angular momentum, eccentricity vector, semilatus rectum, conic radius, and periapsis/apoapsis relations | Catalog adds ORB-017 to ORB-023; keep perturbation handling separate from two-body seed formulas. |
| ORBSYS-002 | Navipedia geodetic/ECEF transform; IERS terrestrial reference conventions | Prime vertical radius and geodetic station ECEF coordinate equations | Catalog adds ORB-024 and ORB-025; use WGS-84 constants as scenario defaults rather than hard-coded formula constants. |
| ORBSYS-003 | Navipedia ECEF/ENU transform; Vallado topocentric look-angle treatment | ECEF relative vector rotated to ENU, with azimuth, elevation, and slant range derived from ENU components | Catalog adds ORB-026 to ORB-028; ensure azimuth quadrant handling uses `atan2(east,north)`. |
| ORBSYS-004 | IERS/CelesTrak Earth-orientation references | Simple `R3(theta_GMST)` ECI-to-ECEF rotation is only a first-order transform | Production-quality orbit/contact calculators need time scale, precession, nutation, polar motion, and EOP inputs. |
| ORBSYS-005 | SMAD/Vallado spherical visibility geometry | Minimum-elevation access half-angle, boundary slant range, footprint radius, access flag, and first-order pass duration | Catalog adds ORB-030 to ORB-034 for quick design trades; precise AOS/LOS requires propagated states. |
| ORBSYS-006 | Vallado/SMAD ground-track context | Ground-track shift per orbit and circular-orbit subsatellite latitude/longitude estimates | Catalog adds ORB-035 to ORB-037; J2 nodal regression and longitude normalization remain later work. |
| ORBSYS-007 | SMAD/NASA SmallSat communications operations context | Generated data, usable contact time, per-pass capacity, aggregate downlink capacity, storage balance, and contact efficiency | Catalog adds SYS-011 to SYS-018 as system closure formulas that connect orbit access to link budget outputs. |
| ORBSYS-008 | SMAD operations budget context | Required net/line rate, target downlink bits, required compression ratio, queue drain time, energy use, battery depth of discharge, recorder turnover, contact utilization, science return, and light-time | Catalog adds SYS-019 to SYS-030; later app UI should present these as a schedule/workflow summary rather than isolated calculators. |

## Extraction Status Delta

| Source | Previous status | Current status | Remaining work |
| --- | --- | --- | --- |
| ITU-P525 | Listed as source; formulas partly seeded | Equations 1-11 extracted into catalog and variables | Add unit-test examples for all practical-unit conversions when calculators are implemented. |
| DESCANSO/DSN/ITU antenna patterns/Balanis | Listed as source; antenna/link formulas partly seeded | Received-power chain, aperture efficiency, pointing/polarization loss, noise density, link margins, ranging SNR, DSN atmospheric noise-temperature, ITU earth-station reference patterns, and Balanis antenna definitions/array seeds extracted | Extract DSN 101/103/104 antenna station tables, antenna-temperature submodels, reflector-specific constants, and deterministic examples for each workbench. |
| Digital comm books | Listed as source; BER/PER/modulation formulas partly seeded | Baseband timing, energy metrics, Shannon/Nyquist, pulse shaping, quantization, matched-filter detection, OFDM, phase jitter, and MIMO formulas added | Extract exact CCSDS modulation families and add test vectors for BER, quantization, OFDM, and phase-noise calculators. |
| CCSDS-401 | Listed as RF/modulation source; generic symbol-rate formulas seeded | QPSK bit/phase mapping, modulator imbalance margins, subcarrier-ratio checks, symbol-rate offset/stability margins, GMSK/filter bandwidth relationship, and high-rate modulation quality margins extracted | Add machine-readable modulation-family and limit tables before app implementation. |
| CCSDS-211.2 | Listed as Proximity-1 coding/sync source; only generic net-rate formula seeded | PLTU size/efficiency, idle PN sizing, allowed `Rd` validation, convolutional expansion, LDPC `(2048,1024)` plus 64-bit CSM overhead, and randomizer procedure extracted | Exact examples and test vectors remain to add. |
| CCSDS-211.0/ISO-22663 | Listed as Proximity-1 data-link source; only generic net-rate formula seeded | Version-3 Transfer Frame fixed header, maximum frame/data-field capacity, header field-width sum, sequence-number/addressing cardinalities, and frame-plus-PLTU efficiency formulas extracted | Verify B-6 USLP/Version-4 deltas against exact current PDF before implementing Version-4 UI. |
| CCSDS-211.1/ISO-21460 | Listed as Proximity-1 physical-layer source; no scalar formulas seeded | `R_d/R_cs/R_chs` reference points, `R_chs=R_cs`, discrete coded-symbol-rate validation, channel-symbol-rate offset margin, and short-term stability margin extracted | Extract UHF channel/hailing/polarization tables from exact standard text or public table assets. |
| CCSDS-121 | Listed as compression source; only generic compression ratios seeded | Block sizing, padding, reference-sample overhead, unit-delay prediction, prediction-error mapper, FS/split/second-extension/zero-block/no-compression sizing, and code-option selection extracted | Convert ID table 5-1 and zero-run ROS table into machine-readable table assets before app implementation. |
| CCSDS-120.2/123 | Listed as compression source; only generic compression ratios seeded | Three-dimensional image sizing, scaled predictor relation, near-lossless quantizer step, lossless/absolute-error modes, and periodic error-limit update cadence extracted from the CCSDS 123 Green Book and corrigendum | Retrieve the full 123.0-B-2 Blue Book PDF and verify relative-error formula, header fields, predictor tables, and hybrid entropy coder tables. |
| Orbit/contact/system books and public coordinate references | Listed as future system source; only seed formulas existed | Two-body orbit relations, geodetic/ECEF/ENU transforms, first-order ECI/ECEF warning, minimum-elevation contact geometry, ground-track shift, subsatellite point estimates, contact capacity, storage closure, compression requirement, energy, and science-return formulas added | Add numerical validation examples, Earth-orientation data handling, J2 nodal regression, repeat-ground-track checks, and propagated AOS/LOS event solving. |
| ITU-P618/P676/P838/P839/P840 | Listed as source; rain and total attenuation top-level formulas seeded | P.838 rain specific attenuation, P.839 rain height, P.618 slant-path rain attenuation/total attenuation/scintillation/sky-noise, P.676 gaseous attenuation, and P.840 cloud/fog attenuation formulas extracted | Continue low-elevation multipath, depolarization, coefficient map/table assets, and implementation-ready coefficient packaging. |
| CCSDS-414.1 | Listed as source; PN formulas partly seeded | Chip-rate equations, selector rules, cross-support examples, acquisition scaling, delay limits, and jitter reference rows extracted | Extract full transparent/regenerative mode field matrices and station/on-board performance tables. |
| CCSDS-131 | Listed as source; generic coding formulas seeded | Public B-5 convolutional, R-S, Turbo, LDPC, ASM, CSM, randomizer, and frame-length extracts added | Verify deltas against Issue 6 when the official B-6 PDF is accessible. |
| CCSDS-231 | Listed as source; CLTU formulas partly seeded | BCH/LDPC codeword sizing, CLTU start/tail lengths, fill formulas, managed parameters extracted | Extract PLOP timing details and any mission-specific maximum CLTU constraints when implementing. |
| CCSDS-132 | Listed as source; generic TM frame formulas seeded | TM primary/secondary header fields, data-field capacity, OCF/FECF overhead, SDLS capacity extracted | Add machine-readable field schema and examples for packet/OID extraction. |
| CCSDS-133 | Referenced by seeded packet overhead formulas; no extracted rows | Space Packet primary-header field widths, packet length count, APID/idle packet, sequence modulus, secondary-header/user-data capacity, and packet efficiency extracted | Add packet extraction examples across TM/AOS/USLP frames and optional secondary-header schemas. |
| CCSDS-232 | Listed as source; generic TC frame formulas seeded | TC frame length count, data-field capacity, segment header, control command sizes, FECF, SDLS capacity extracted | Add cross-standard TC/COP examples when implementing. |
| CCSDS-232.1 | Listed as future COP/FARM source; only generic ARQ formulas existed | COP-1 FOP/FARM variables, go-back-N retransmission, 8-bit sequence modulus, `T1_Initial` delay budget, Transmission_Limit/Count, FOP/FARM windows, CLCW reporting period, and BD one-shot behavior extracted | Convert FOP/FARM state-table events into machine-readable procedure tests before app implementation. |
| CCSDS-732.1 | Listed as source; generic USLP overhead formulas seeded | USLP identifier widths, primary-header length, Frame Length count, VCF Count options, truncated header, TFDF/TFDZ capacity, OCF/FECF, OID constants, and SDLS TFDF capacity extracted | Add AOS cross-check, exact packet extraction examples, SDLS managed-parameter options, and machine-readable TFDZ construction-rule table. |

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

## CCSDS 232.1-B-2 Communications Operation Procedure-1

Source: CCSDS 232.1-B-2, `Communications Operation Procedure-1`, September 2010, including Technical Corrigendum 1 dated April 2019.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| COP1-001 | Sections 2.1 and 2.2 | COP-1 uses go-back-N ARQ; FOP-1 retransmits all unacknowledged Type-A Transfer Frames on the VC when a CLCW Retransmit flag or timeout requires recovery | Catalog adds `COP1_GoBackN_RetransmitFrames = SentQueueLength`. |
| COP1-002 | Section 5.1.1 | FOP-1 maintains per-VC variables including `V(S)`, Wait_Queue, Sent_Queue, `NN(R)`, `T1_Initial`, Transmission_Limit, Transmission_Count, `K`, Timeout_Type, and Suspend_State | Variable glossary adds COP-1 field IDs for calculator state display and validation. |
| COP1-003 | Sections 5.1.3 and 5.2.4 | `V(S)` supplies the next Type-AD `N(S)` and is incremented after insertion into the frame | Catalog adds modulo-256 next-sequence formula. |
| COP1-004 | Section 5.1.8 | `NN(R)` is the sequence number of the oldest unacknowledged AD frame on the Sent_Queue | Catalog adds outstanding-frame distance between `V(S)` and `NN(R)`. |
| COP1-005 | Section 5.1.9.2 | Normal `T1_Initial` lower bound is the sum of sending lower-layer delay, maximum-frame serial transmit time, forward light time, receiving lower-layer delay, CLCW sample/encode time, return CLCW transmit time, return light time, and CLCW extraction/delivery time | Catalog adds `COP1_T1_Min` and the maximum-frame transmit-time subformula. |
| COP1-006 | Sections 5.1.10.2 and 5.1.10.4 | Transmission_Limit applies to the first frame on the Sent_Queue; Transmission_Count increments on retransmission and resets to 1 after acknowledgements or when a new queue starts | Catalog adds attempts remaining, retransmission-allowed, and first-frame max-transmission formulas. |
| COP1-007 | Section 5.1.4 | Wait_Queue maximum capacity is one Type-AD FDU | Catalog adds `COP1_WaitQueueCapacityFDUs = 1`. |
| COP1-008 | Section 5.2.10 | A new Type-AD FDU can be transmitted when `V(S) < NN(R) + K` and an FDU is waiting, with modulo arithmetic for the 8-bit sequence space | Catalog adds FOP window-open test using modulo distance. |
| COP1-009 | Section 6.1.8 and table 7-2 | With Type-AD retransmission allowed, FARM window `W` is an even integer from 2 to 254; `PW=NW=W/2` | Catalog adds FARM window range and split formulas. |
| COP1-010 | Section 6.1.8.3.1 | Positive-window condition covers expected and ahead-of-expected `N(S)` values; `N(S)=V(R)` is accepted, larger positive offsets are discarded and set Retransmit | Catalog adds positive-window offset and condition formulas. |
| COP1-011 | Section 6.1.8.3.1 | Negative-window frames are discarded without additional action; outside the FARM window causes lockout | Catalog adds negative-window and lockout-area condition formulas. |
| COP1-012 | Section 6.2 note | COP-1 Frame Sequence Number is an 8-bit field; FARM arithmetic for `V(R)`, `N(S)`, `PW`, and `NW` is modulo 256 | Catalog adds `COP1_FrameSequenceModulus = 256`. |
| COP1-013 | Tables 7-1 and 7-2 | Managed parameters include `K` in 1..255 with `K <= PW`, `Timeout_Type` in {0,1}, FARM `W/PW/NW`, and CLCW reporting period | Catalog adds K constraint and CLCW report-rate formula. |
| COP1-014 | Sections 5.1.9 and 5.1.10.4 | Type-BD expedited frames do not use the Timer or Transmission_Count and are transmitted once | Catalog adds `COP1_BD_MaxTransmissions = 1`. |

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

## CCSDS 133.0-B-2 Space Packet Protocol

Source: CCSDS 133.0-B-2, `Space Packet Protocol`, June 2020 with Corrigendum 2. Public PDF extracted from the CCSDS publications site.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| SPP-001 | Sections 4.1 and 4.1.2 | Space Packet consists of a mandatory 6-octet Packet Primary Header plus a Packet Data Field of 1 to 65536 octets | Catalog adds TM-043 to TM-049 for packet length and bounds. |
| SPP-002 | Section 4.1.2 | Packet Primary Header fields total 48 bits: 3-bit version, 1-bit type, 1-bit secondary-header flag, 11-bit APID, 2-bit sequence flags, 14-bit sequence count/name, and 16-bit Packet Data Length | Use as a field-width schema for packet cards and validation. |
| SPP-003 | Section 4.1.5 | Packet Data Length field stores one fewer than the total octets in the Packet Data Field | `SpacePacketDataFieldOctets = PacketDataLength + 1`. |
| SPP-004 | Section 4.1.3 | Idle Packet APID is the 11-bit all-ones value, decimal 2047 | Catalog adds the APID cardinality and idle APID constant. |
| SPP-005 | Section 4.1.4 | Packet Sequence Count is a 14-bit continuous sequence count, independent per APID | Catalog adds the 16384-count wrap modulus and next-count formula. |
| SPP-006 | Section 4.1.6 | Packet Data Field may contain an optional variable-length Packet Secondary Header and a User Data Field; at least one data-field octet is required | Use `SpacePacketUserDataOctets = SpacePacketDataFieldOctets - PacketSecondaryHeaderOctets` for capacity and efficiency. |

## CCSDS 732.1-B-3 Unified Space Data Link Protocol

Source: CCSDS 732.1-B-3, `Unified Space Data Link Protocol`, June 2024. Public PDF extracted from the CCSDS publications site.

| Extract ID | Standard location | Equation or table | Implementation note |
| --- | --- | --- | --- |
| USLP-001 | Sections 3.4.2 and 4.1.2 | Identifier concatenations: `MCID=TFVN+SCID`, `GVCID=MCID+VCID`, `GMAP ID=GVCID+MAP ID` | Catalog adds TM-056 to TM-058 for field-width outputs. |
| USLP-002 | Section 4.1.2.1 and figure 4-2 | Non-truncated Transfer Frame Primary Header has 13 fields: 4-bit TFVN, 16-bit SCID, 1-bit source/destination, 6-bit VCID, 4-bit MAP ID, 1-bit end-of-header flag, 16-bit Frame Length, two 1-bit control flags, 2 spare bits, 1-bit OCF flag, 3-bit VCF Count Length, and 0-56-bit VCF Count | Base fixed header before VCF Count is 56 bits; catalog adds TM-064 to TM-066. |
| USLP-003 | Section 4.1.2.2 | TFVN is set to binary `1100`; SCID has 16 bits | Store TFVN as an option constant and use SCID count for validation. |
| USLP-004 | Sections 4.1.2.4 and 4.1.4.1 | VCID has 6 bits; VCID 63 is reserved for Only Idle Data Transfer Frames; OID MAP ID is 0 | Catalog adds TM-060, TM-082, and TM-083. |
| USLP-005 | Section 4.1.2.7 | Frame Length field is a 16-bit length count equal to one fewer than the total transfer-frame octets, limiting frames to 65536 octets | Catalog adds TM-062 and TM-063. |
| USLP-006 | Sections 4.1.2.11 and 4.1.2.12, table 4-2 | VCF Count Length selects 0 to 7 octets; when present, the VCF Count is a sequential binary count modulo maximum count plus one | Catalog adds VCF Count bit, header-length, modulus, and next-count formulas. |
| USLP-007 | Section 4.1.2.6 and annex D | Truncated Transfer Frame Primary Header contains only the first six contiguous fields, totaling 32 bits | Catalog adds TM-069 and TM-070; truncated frame length comes from the VC managed parameter, not the normal Frame Length field. |
| USLP-008 | Sections 4.1.4.1, 4.1.5, and 4.1.6 | TFDF is variable length; OCF is optional 4 octets; FECF is optional 2 octets | Catalog adds TM-071 to TM-073 and overhead fractions. |
| USLP-009 | Section 4.1.4.2 and figure 4-4 | TFDF Header has mandatory 3-bit TFDZ Construction Rule and 5-bit UPID, plus optional 16-bit First Header/Last Valid Octet Pointer | Catalog adds `USLP_TFDFHeaderOctets = 1 or 3` and TFDZ capacity. |
| USLP-010 | Section 4.1.4.2.4 | FHP/LVOP offset is measured from the first octet in the TFDZ; all-ones pointer is used for standard-defined no-start/no-completion cases | Catalog adds TM-081 and keeps pointer interpretation as parser/procedure data. |
| USLP-011 | Section 6.3.5 | With SDLS, TFDF length is reduced by Security Header and Security Trailer in addition to primary header, Insert Zone, OCF, and FECF | Catalog adds `USLP_SDLS_TFDFOctets` for secured-link capacity. |

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
