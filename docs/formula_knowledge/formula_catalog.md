# Formula Catalog v0.1

This is the first source-backed seed catalog for a larger formula knowledge base. It intentionally separates `formula availability` from `app implementation`: many formulas are known and documented here but not yet implemented in LifeLog.

Notation:

- `Implemented`: already represented in the current app.
- `Seeded`: documented here; implementation not yet done.
- `Procedure`: top-level relationship is known, but a standard table or multi-step procedure must still be extracted.

## RF, Antenna, and Receiver Front End

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| RF-001 | `lambda = c / f` | `lambda`: wavelength m; `c`: speed of light m/s; `f`: frequency Hz | Converts RF frequency to wavelength. Used by antenna gain, aperture, and FSPL. | ITU-P525, BOOK-BALANIS | Seeded |
| RF-002 | `A = pi D^2 / 4` | `A`: circular aperture area m^2; `D`: antenna diameter m | Physical area of a circular dish aperture. | BOOK-BALANIS | Seeded |
| RF-003 | `G = eta (pi D / lambda)^2` | `G`: linear antenna gain; `eta`: aperture efficiency; `D`: diameter; `lambda`: wavelength | Parabolic aperture gain. Convert to dBi with `10 log10(G)`. | BOOK-BALANIS, DESCANSO-DSTSE | Seeded |
| RF-004 | `A_e = G lambda^2 / (4 pi)` | `A_e`: effective aperture m^2; `G`: linear gain | Relates antenna gain to receiving effective aperture. | BOOK-BALANIS, DESCANSO-DSTSE | Seeded |
| RF-005 | `G_dBi = 10 log10(G)` | `G`: linear gain | Converts linear gain to dBi. | General RF engineering | Seeded |
| RF-006 | `G = 10^(G_dBi/10)` | `G_dBi`: antenna gain in dBi | Converts dBi gain to linear gain. | General RF engineering | Seeded |
| RF-007 | `theta_3dB ~= K lambda / D` | `theta_3dB`: beamwidth rad; `K`: aperture-dependent constant | Approximate half-power beamwidth. Use source-specific constants for reflector/taper type. | BOOK-BALANIS | Procedure |
| RF-008 | `EIRP_dBW = P_tx_dBW - L_tx_dB + G_tx_dBi` | `P_tx`: transmitter output; `L_tx`: feed/network loss; `G_tx`: antenna gain | Effective isotropic radiated power. | DSN-810-005, BOOK-MARAL | Implemented |
| RF-009 | `ERP_dBW = EIRP_dBW - 2.15` | `ERP`: referenced to half-wave dipole | Converts EIRP to ERP. | General RF engineering | Seeded |
| RF-010 | `G/T_dB/K = G_rx_dBi - 10 log10(T_sys_K)` | `T_sys`: system noise temperature | Receiver merit figure used directly in link budgets. | DSN-810-005, DESCANSO-DSTSE | Implemented |
| RF-011 | `T_e = T0 (10^(NF_dB/10) - 1)` | `T_e`: equivalent noise temperature; `T0`: 290 K; `NF`: noise figure | Converts receiver noise figure to equivalent temperature. | BOOK-MARAL, BOOK-SKLAR | Seeded |
| RF-012 | `T_cascade = T1 + T2/G1 + T3/(G1 G2) + ...` | `Tn`: stage equivalent noise temp; `Gn`: linear stage gain | Friis noise cascade in temperature form. | BOOK-MARAL, BOOK-SKLAR | Seeded |
| RF-013 | `F = F1 + (F2-1)/G1 + (F3-1)/(G1 G2) + ...` | `F`: noise factor; `G`: linear gain | Friis noise cascade in noise-factor form. | BOOK-SKLAR | Seeded |
| RF-014 | `T_sys = T_ant + T_feed + T_rx + T_sky + T_misc` | component temperatures K | System noise temperature budget. Terms depend on reference plane. | DSN-810-005, DESCANSO-DSTSE | Seeded |
| RF-015 | `L_point_dB ~= 12 (theta_error/theta_3dB)^2` | `theta_error`: pointing error; `theta_3dB`: HPBW | Common small-error pointing loss approximation. Must be validated for antenna pattern. | BOOK-MARAL, BOOK-BALANIS | Seeded |
| RF-016 | `Gamma = (VSWR - 1)/(VSWR + 1)` | `Gamma`: reflection coefficient | VSWR to reflection coefficient. | General RF engineering | Seeded |
| RF-017 | `L_mismatch_dB = -10 log10(1 - |Gamma|^2)` | `Gamma`: reflection coefficient magnitude | Mismatch loss from input reflection. | General RF engineering | Seeded |
| RF-018 | `L_pol_dB = -20 log10(|e_tx dot e_rx|)` | `e_tx`, `e_rx`: unit polarization vectors | Polarization mismatch loss. | BOOK-BALANIS | Seeded |
| RF-019 | `P_rx_dBW = EIRP + G_rx - L_path - L_misc` | `L_path`: propagation losses; `L_misc`: implementation losses | Received carrier power at receiver reference plane. | DSN-810-005, BOOK-MARAL | Implemented |
| RF-020 | `N0_dBW/Hz = 10 log10(k T_sys)` | `k`: Boltzmann constant; `T_sys`: K | Noise spectral density. Equivalent dB form uses `-228.6 + 10log10(T)`. | BOOK-SKLAR, DSN-810-005 | Seeded |

## Propagation and Link Budget

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| LINK-001 | `L_fs = 20 log10(4 pi R / lambda)` | `R`: range m; `lambda`: wavelength m | Free-space path loss. | ITU-P525, BOOK-BALANIS | Implemented |
| LINK-002 | `L_fs_dB = 92.45 + 20log10(d_km) + 20log10(f_GHz)` | `d_km`: distance km; `f_GHz`: frequency GHz | Convenient FSPL form. | ITU-P525 | Implemented |
| LINK-003 | `C/N0 = EIRP + G/T - L_total + 228.6` | dB units | Carrier-to-noise-density ratio. `228.6` is `-10log10(k)` in dB. | DSN-810-005, BOOK-MARAL | Implemented |
| LINK-004 | `Eb/N0 = C/N0 - 10log10(R_b)` | `R_b`: bit rate bps | Converts carrier density to energy-per-bit density. | BOOK-SKLAR | Implemented |
| LINK-005 | `Es/N0 = Eb/N0 + 10log10(log2(M) R_c)` | `M`: modulation order; `R_c`: code rate | Converts bit metric to symbol metric for M-ary modulation with coding. | BOOK-SKLAR | Seeded |
| LINK-006 | `C/N = C/N0 - 10log10(B_n)` | `B_n`: receiver noise bandwidth Hz | Carrier-to-noise ratio in a finite bandwidth. | BOOK-SKLAR | Seeded |
| LINK-007 | `N_dBW = -228.6 + 10log10(T_sys) + 10log10(B)` | `B`: Hz | Thermal noise power in bandwidth. | BOOK-SKLAR | Seeded |
| LINK-008 | `Margin = Available Eb/N0 - Required Eb/N0` | dB | Link closure margin. | DSN-810-005, BOOK-MARAL | Implemented |
| LINK-009 | `A_total = A_fs + A_gas + A_rain + A_cloud + A_scint + A_pol + A_misc` | loss terms dB | Full propagation/implementation loss budget. | ITU-P618, ITU-P676, ITU-P838 | Seeded |
| LINK-010 | `gamma_R = k R^alpha` | `gamma_R`: dB/km; `R`: rain rate mm/h; `k`, `alpha`: frequency/polarization coefficients | Rain specific attenuation. | ITU-P838 | Seeded |
| LINK-011 | `A_rain = gamma_R L_eff` | `L_eff`: effective path length km | Rain attenuation once effective path is known. | ITU-P618, ITU-P838 | Procedure |
| LINK-012 | `A_gas = integral(gamma_gas(s) ds)` | `gamma_gas`: dB/km | Atmospheric oxygen/water-vapor attenuation along path. | ITU-P676 | Procedure |
| LINK-013 | `S = P_tx G_tx / (4 pi R^2)` | `S`: power flux density W/m^2 | Free-space power flux at range. | BOOK-BALANIS | Seeded |
| LINK-014 | `P_rx = S A_e` | `A_e`: effective aperture | Received power from incident flux and effective aperture. | BOOK-BALANIS | Seeded |
| LINK-015 | `C = B log2(1 + S/N)` | `C`: channel capacity bps; `B`: bandwidth Hz | Shannon capacity upper bound. | BOOK-SKLAR | Seeded |
| LINK-016 | `Required EIRP = Required C/N0 - G/T + L_total - 228.6` | dB units | Inverts link equation for transmitter sizing. | DSN-810-005, BOOK-MARAL | Seeded |
| LINK-017 | `Required G/T = Required C/N0 - EIRP + L_total - 228.6` | dB/K | Inverts link equation for ground-station sizing. | DSN-810-005, BOOK-MARAL | Seeded |
| LINK-018 | `e = sqrt(30 p) / d` | `e`: RMS field strength V/m; `p`: EIRP W; `d`: distance m | ITU-R P.525 point-to-area field strength. | ITU-P525 | Seeded |
| LINK-019 | `e_mV_m = 173 sqrt(p_kW) / d_km` | practical units | ITU-R P.525 field-strength expression in mV/m, kW, and km. | ITU-P525 | Seeded |
| LINK-020 | `s = e^2 / (120 pi) = p / (4 pi d^2)` | `s`: power flux density W/m^2 | Plane-wave PFD relation from ITU-R P.525. | ITU-P525 | Seeded |
| LINK-021 | `p_r = p lambda^2 / ((4 pi d)^2)` | isotropic receiving antenna | Received power at isotropic receive antenna in free space. | ITU-P525 | Seeded |
| LINK-022 | `L_bf = 20 log10(4 pi d / lambda)` | same units for `d` and `lambda` | ITU-R free-space basic transmission loss. | ITU-P525 | Seeded |
| LINK-023 | `L_bf = 32.4 + 20 log10(f_MHz) + 20 log10(d_km)` | `f_MHz`, `d_km` | ITU-R P.525 practical FSPL form. | ITU-P525 | Seeded |
| LINK-024 | `E = Pt - 20 log10(d_km) + 74.8` | `E`: dB(uV/m); `Pt`: dBW isotropic power | Field strength from isotropically transmitted power. | ITU-P525 | Seeded |
| LINK-025 | `Pr = E - 20 log10(f_GHz) - 167.2` | `Pr`: dBW received by isotropic matched antenna | Available isotropic receive power from field strength. | ITU-P525 | Seeded |
| LINK-026 | `S_dBW_m2 = E - 145.8` | `S`: dBW/m^2; `E`: dB(uV/m) | Power flux density from electric field strength. | ITU-P525 | Seeded |

## Modulation, Baseband, and Digital Communication

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| BB-001 | `f_s >= 2 B` | `f_s`: sampling frequency; `B`: signal bandwidth | Nyquist sampling condition. | BOOK-SKLAR | Seeded |
| BB-002 | `SNR_q_dB ~= 6.02 N + 1.76` | `N`: ADC bits | Ideal full-scale uniform quantization SNR for a sine wave. | BOOK-SKLAR | Seeded |
| BB-003 | `R_pcm = f_s N n_ch` | `n_ch`: channel count | PCM source bit rate before framing/compression. | BOOK-SKLAR, IRIG/PCM practice | Seeded |
| BB-004 | `M = 2^m` | `m`: bits per symbol | Modulation order relationship. | BOOK-SKLAR | Seeded |
| BB-005 | `R_s = R_b / (m R_c)` | `R_s`: symbol rate; `R_b`: information bit rate; `R_c`: code rate | Symbol rate after coding and modulation. | BOOK-SKLAR, CCSDS-401 | Implemented |
| BB-006 | `B_occ ~= (1 + alpha) R_s` | `alpha`: raised-cosine rolloff | Occupied bandwidth estimate for raised-cosine shaped signal. | BOOK-SKLAR, CCSDS-401 | Implemented |
| BB-007 | `eta_s = R_info / B_occ` | `eta_s`: spectral efficiency bps/Hz | Measures useful information rate per Hz. | BOOK-SKLAR | Implemented |
| BB-008 | `EVM_rms ~= 1/sqrt(SNR_linear)` | EVM as ratio | Approximate EVM-to-SNR relation for AWGN-dominated links. | BOOK-SKLAR | Seeded |
| BB-009 | `BER_BPSK = Q(sqrt(2 Eb/N0))` | `Q`: Gaussian Q-function | Coherent BPSK BER in AWGN. | BOOK-SKLAR | Seeded |
| BB-010 | `BER_QPSK ~= Q(sqrt(2 Eb/N0))` | Gray-coded QPSK | Coherent QPSK bit error approximation in AWGN. | BOOK-SKLAR | Seeded |
| BB-011 | `SER_MPSK ~= 2 Q(sqrt(2 Es/N0) sin(pi/M))` | `M`: PSK order | M-PSK symbol error approximation. | BOOK-SKLAR | Seeded |
| BB-012 | `BER_MQAM ~= 4/log2(M) (1-1/sqrt(M)) Q(sqrt(3 log2(M)/(M-1) Eb/N0))` | square M-QAM | Common high-SNR AWGN approximation. | BOOK-SKLAR | Seeded |
| BB-013 | `PER = 1 - (1 - BER)^N` | `N`: packet/frame bits | Converts independent bit error probability to packet error probability. | BOOK-SKLAR | Seeded |
| BB-014 | `BER ~= 1 - (1 - PER)^(1/N)` | `PER`: packet error rate | Inverts PER to average BER under independence assumption. | BOOK-SKLAR | Seeded |
| BB-015 | `R_coded = R_info / R_c` | `R_c`: code rate | Encoded bit stream rate. | CCSDS-131, CCSDS-231 | Implemented |
| BB-016 | `Latency_interleaver ~= depth * block_bits / R_info` | `depth`: interleaver depth | First-order interleaver latency estimate. | CCSDS-131, BOOK-SKLAR | Implemented |
| BB-017 | `Processing gain = 10log10(R_chip / R_data)` | spread-spectrum rates | Direct-sequence spread-spectrum processing gain. | CCSDS-415, BOOK-SKLAR | Seeded |

## Telemetry, PCM, Space Packet, and Transfer Frames

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| TM-001 | `MinorFrameBits = word_length * words_per_minor + sync_bits` | PCM frame terms | Minor-frame size including sync. | IRIG 106 Ch. 4, PCM practice | Implemented |
| TM-002 | `R_bit = MinorFrameBits * minor_frame_rate` | `minor_frame_rate`: Hz | PCM stream bit rate. | IRIG 106 Ch. 4, PCM practice | Implemented |
| TM-003 | `T_major = minor_frames_per_major / minor_frame_rate` | frame counts and rate | Major-frame period. | IRIG 106 Ch. 4, PCM practice | Implemented |
| TM-004 | `FrameEfficiency = PayloadBits / TotalFrameBits` | payload and frame bits | PCM or transfer-frame useful fraction. | IRIG/CCSDS practice | Implemented |
| TM-005 | `ParameterSampleRate = samples_per_major / T_major` | samples per major frame | Effective sample rate for a parameter. | IRIG 106 Ch. 4 | Implemented |
| TM-006 | `PacketOverhead = HeaderBits + SecondaryHeaderBits + ErrorControlBits` | packet fields | Space packet overhead budget. | CCSDS-133 | Seeded |
| TM-007 | `PacketEfficiency = UserDataBits / (UserDataBits + PacketOverhead)` | packet bits | Space packet efficiency. | CCSDS-133 | Seeded |
| TM-008 | `TransferFrameEfficiency = DataFieldBits / TransferFrameBits` | frame field sizes | TM/AOS/USLP frame useful fraction. | CCSDS-132, CCSDS-732, CCSDS-732.1 | Procedure |
| TM-009 | `VC_Throughput = LineRate * TransferFrameEfficiency * VC_share` | `VC_share`: virtual-channel allocation | Virtual channel payload throughput. | CCSDS-132, CCSDS-732 | Seeded |
| TM-010 | `CADU_or_SMTF_Rate = TransferFrameRate * coded_frame_bits` | frame rate and coded length | Stream rate for coded/sync-marked frames. | CCSDS-131 | Procedure |
| TM-011 | `RS_rate = k / n` | Reed-Solomon message/codeword symbols | Code rate for RS coding. Exact values come from selected CCSDS mode. | CCSDS-131 | Procedure |
| TM-012 | `SyncOverhead = ASM_bits / (ASM_bits + frame_bits)` | attached sync marker bits | Attached sync marker overhead. | CCSDS-131 | Procedure |
| TM-013 | `RandomizerOverhead = 0` | no added bits | CCSDS randomization changes bit pattern, not stream length. | CCSDS-131 | Seeded |
| TM-014 | `StorageFillTime = StorageCapacityBits / GeneratedDataRate` | storage bits, data rate | On-board data storage fill time. | BOOK-SMAD | Seeded |

## Telecommand and Uplink Commanding

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| TC-001 | `FrameBits = CommandBits + HeaderBits + CRCBits + SecurityBits` | TC frame fields | Simplified TC frame length budget. | CCSDS-232 | Implemented |
| TC-002 | `FrameTime = FrameBits / UplinkRate` | uplink rate bps | Time to radiate one command frame. | CCSDS-232 | Implemented |
| TC-003 | `TotalCommandTime = N_repeat * FrameTime + max(0,N_repeat-1) * GuardTime` | repeat count and guard time | Command transmission duration with repeats. | CCSDS-231, CCSDS-232 | Implemented |
| TC-004 | `EffectiveCommandThroughput = CommandBits / TotalCommandTime` | useful bits and total time | Useful command throughput. | CCSDS-232 | Implemented |
| TC-005 | `CommandOverhead = 1 - CommandBits / FrameBits` | useful/total bits | TC frame overhead fraction. | CCSDS-232 | Implemented |
| TC-006 | `CLTUOverhead = (CLTU_bits - TransferFrameBits) / CLTU_bits` | CLTU bits | CLTU overhead from start/tail/fill/coding. Exact composition is mode-dependent. | CCSDS-231 | Procedure |
| TC-007 | `BCH_rate = k / n` | BCH block parameters | TC BCH code rate. Exact selected block parameters must come from CCSDS table. | CCSDS-231 | Procedure |
| TC-008 | `LDPC_rate = k / n` | LDPC block parameters | Short TC LDPC code rate. Exact selected code parameters from standard. | CCSDS-231 | Procedure |
| TC-009 | `AuthenticationOverhead = AuthTagBits / (FrameBits + AuthTagBits)` | security tag length | Data-link or application security overhead. | CCSDS-355, mission security design | Seeded |
| TC-010 | `RequiredUplinkRate = CommandBits / RequiredDeliveryTime / efficiency` | delivery target | Inverts command throughput for uplink planning. | CCSDS-232, BOOK-SMAD | Seeded |

## Ranging, Doppler, Tracking, and External Measurement

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| TRK-001 | `t_oneway = R / c` | `R`: range m | One-way propagation delay. | CCSDS-414.1, DSN-810-005 | Implemented |
| TRK-002 | `t_roundtrip = 2R / c` | range m | Two-way light time. | CCSDS-414.1, DSN-810-005 | Implemented |
| TRK-003 | `R = c t_roundtrip / 2` | measured two-way time | Converts round-trip delay to range. | CCSDS-414.1 | Seeded |
| TRK-004 | `RangeResolution ~= c / (2 R_chip)` | `R_chip`: chip rate Hz | PN ranging resolution estimate. | CCSDS-414.1 | Implemented |
| TRK-005 | `UnambiguousRange ~= c N_code / (2 R_chip)` | `N_code`: PN code length | PN code unambiguous range. | CCSDS-414.1 | Implemented |
| TRK-006 | `RangeError ~= c sigma_t / 2` | `sigma_t`: timing error s | Timing error converted to two-way range error. | CCSDS-414.1 | Implemented |
| TRK-007 | `f_D = -f_c v_r / c` | `v_r`: radial relative velocity | One-way Doppler shift. Sign convention must be explicit. | CCSDS-401, DSN-810-005 | Implemented |
| TRK-008 | `v_r = -c f_D / f_c` | measured Doppler | Radial velocity estimate from Doppler. | DSN-810-005 | Seeded |
| TRK-009 | `Delta_f_osc = f_c * ppm * 1e-6` | oscillator tolerance ppm | Frequency-source error. | CCSDS-401, DSN-810-005 | Implemented |
| TRK-010 | `Delta_f_total = |f_D| + |Delta_f_osc| + Delta_f_misc` | error terms Hz | Guard-band sizing total frequency uncertainty. | CCSDS-401 | Implemented |
| TRK-011 | `GuardMargin = GuardBand - Delta_f_total` | Hz | Frequency guard margin. | CCSDS-401 | Implemented |
| TRK-012 | `Delta_tau = (b dot s) / c` | `b`: baseline vector; `s`: source unit vector | Delta-DOR geometric delay core relationship. | DSN-810-005 | Seeded |
| TRK-013 | `sigma_theta ~= c sigma_tau / |b_perp|` | delay error and projected baseline | Approximate angular error from delay error. | DSN-810-005 | Seeded |
| TRK-014 | `P_r = P_t G_t G_r lambda^2 sigma / ((4pi)^3 R^4 L)` | radar cross-section `sigma` | Monostatic radar range equation. | BOOK-BALANIS | Seeded |
| TRK-015 | `P_r = P_t G_t G_r lambda^2 sigma / ((4pi)^3 R_t^2 R_r^2 L)` | bistatic ranges | Bistatic radar-style external measurement power. | BOOK-BALANIS | Seeded |
| TRK-016 | `L_br = 103.4 + 20 log10(f_MHz) + 40 log10(d_km) - 10 log10(sigma)` | `sigma`: radar cross-section m^2 | ITU-R P.525 radar free-space basic transmission loss for common-antenna radar. | ITU-P525 | Seeded |
| TRK-017 | `Fchip_S = l_pn * f_S_MHz / (128 * 2^k_pn)` | S-band uplink, CCSDS 414.1 table 3-1 | PN ranging uplink chip rate for S-band. `Fchip` is in Mchip/s; `k_pn`/`l_pn` are implementation aliases for the standard's `k`/`l` selectors. | CCSDS-414.1 | Seeded |
| TRK-018 | `Fchip_X = l_pn * (221/749) * f_X_MHz / (128 * 2^k_pn)` | X-band uplink, table 3-1 | PN ranging uplink chip rate for X-band. | CCSDS-414.1 | Seeded |
| TRK-019 | `Fchip_Ka = l_pn * (221/3599) * f_Ka_MHz / (128 * 2^k_pn)` | Ka-band uplink, table 3-1 | PN ranging uplink chip rate for Ka-band. | CCSDS-414.1 | Seeded |
| TRK-020 | `Tacq = Tacq_ref / 10^((PrN0_dBHz - PrN0_ref_dBHz)/10)` | acquisition reference table | PN ranging acquisition-time scaling. Regenerative tables use 30 dB-Hz references; transparent station table uses 10 dB-Hz. | CCSDS-414.1 | Procedure |
| TRK-021 | `DelayStabilityLimit = max(1/(30 Fchip), 20 ns)` | `Fchip`: chip/s | On-board or transparent ranging-delay stability bound. | CCSDS-414.1 | Seeded |
| TRK-022 | `DelayCalibrationLimit = max(1/(500 Fchip), 1 ns)` | `Fchip`: chip/s | Transponder delay calibration accuracy bound. | CCSDS-414.1 | Seeded |
| TRK-023 | `JitterTotal_RSS = sqrt(sum(jitter_i^2))` | independent jitter components | End-to-end ranging jitter combination by root-sum-square. | CCSDS-414.1 | Seeded |

## System-Level Mission and Operations Budgets

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| SYS-001 | `DataVolume = DataRate * Duration` | bits and seconds | Data produced or downlinked during a period. | BOOK-SMAD | Seeded |
| SYS-002 | `RequiredContactTime = DataVolume / NetDownlinkRate` | bits, bps | Contact time needed to empty data volume. | BOOK-SMAD | Seeded |
| SYS-003 | `NetDownlinkRate = LineRate * coding_eff * frame_eff * protocol_eff` | efficiency factors | System-level net payload rate. | CCSDS-131, CCSDS-132, CCSDS-732 | Seeded |
| SYS-004 | `StorageMargin = StorageCapacity - DataGenerated + DataDownlinked` | bits | Storage closure over an operations period. | BOOK-SMAD | Seeded |
| SYS-005 | `EnergyPerBit = P_tx / R_b` | W and bps | Transmit energy per bit at hardware level. | BOOK-SKLAR, BOOK-SMAD | Seeded |
| SYS-006 | `DutyCycle = OnTime / Period` | seconds | RF or payload duty cycle. | BOOK-SMAD | Seeded |
| SYS-007 | `AveragePower = Sum(P_i * duty_i)` | power states | Power budget average over a period. | BOOK-SMAD | Seeded |
| SYS-008 | `RequiredAntennaDiameter = lambda/pi * sqrt(G/eta)` | target gain and efficiency | Inverts parabolic gain for antenna sizing. | BOOK-BALANIS | Seeded |
| SYS-009 | `RequiredDataRate = DataVolume / AvailableContactTime` | bits and seconds | Downlink rate needed for operations plan. | BOOK-SMAD | Seeded |
| SYS-010 | `AvailabilityMargin = FadeMargin - FadeDepth(p)` | percentile fade depth | Availability-driven fade closure. | ITU-P618 | Procedure |

## Optical / Laser Communication Extensions

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| OPT-001 | `theta_div ~= K lambda / D_t` | optical aperture and wavelength | Diffraction-limited beam divergence approximation. | DESCANSO optical references, BOOK-BALANIS | Seeded |
| OPT-002 | `E_photon = h f = h c / lambda` | Planck constant, optical frequency | Photon energy for photon-counting link budgets. | General physics, optical comm references | Seeded |
| OPT-003 | `N_photons = P_r / E_photon` | received optical power | Photon arrival rate. | Optical communication engineering | Seeded |
| OPT-004 | `L_point_opt ~= 4.343 * (theta_error/sigma_beam)^2` | Gaussian beam approximation | Optical pointing loss under Gaussian-beam assumptions. | DESCANSO optical references | Procedure |

## Orbit, Geometry, Coverage, and Contact

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| ORB-001 | `r = R_e + h` | `r`: orbital radius; `R_e`: Earth radius; `h`: altitude | Circular-orbit radius from altitude. | BOOK-SMAD, BOOK-VALLADO | Seeded |
| ORB-002 | `n = sqrt(mu / a^3)` | `n`: mean motion rad/s; `mu`: gravitational parameter; `a`: semi-major axis | Keplerian mean motion. | BOOK-VALLADO, BOOK-BATE | Seeded |
| ORB-003 | `T = 2 pi sqrt(a^3 / mu)` | `T`: orbital period | Keplerian orbital period. | BOOK-VALLADO, BOOK-BATE | Seeded |
| ORB-004 | `v_c = sqrt(mu / r)` | `v_c`: circular velocity | Circular-orbit speed. | BOOK-VALLADO, BOOK-BATE | Seeded |
| ORB-005 | `rho = sqrt(r^2 + R_e^2 - 2 r R_e cos(psi))` | `rho`: slant range; `psi`: geocentric angle | Ground-station to spacecraft slant range for spherical Earth geometry. | BOOK-SMAD, BOOK-VALLADO | Seeded |
| ORB-006 | `sin(E) = (r cos(psi) - R_e) / rho` | `E`: elevation angle | Elevation angle from central angle and slant range. | BOOK-SMAD, BOOK-VALLADO | Seeded |
| ORB-007 | `cos(psi_h) = R_e / r` | `psi_h`: horizon central angle | Geometric horizon for zero elevation. Add minimum elevation by modified geometry. | BOOK-SMAD, BOOK-VALLADO | Seeded |
| ORB-008 | `ground_range = R_e psi` | `psi`: central angle rad | Surface ground range from central angle. | BOOK-SMAD | Seeded |
| ORB-009 | `visible_fraction ~= psi_h / pi` | circular orbit approximation | Rough single-station visibility fraction for equatorial simplification. | BOOK-SMAD | Seeded |
| ORB-010 | `contact_time ~= visible_fraction * T` | visibility fraction and period | First-cut pass duration estimate. Replace with propagated AOS/LOS for production. | BOOK-SMAD | Seeded |
| ORB-011 | `range_rate = dot(rho_vector, v_rel) / |rho_vector|` | relative position and velocity | Line-of-sight range-rate for Doppler/ranging. | BOOK-VALLADO, DSN-810-005 | Seeded |
| ORB-012 | `az = atan2(east, north)` | topocentric ENU components | Azimuth from topocentric vector. | BOOK-VALLADO | Seeded |
| ORB-013 | `el = asin(up / rho)` | topocentric up component | Elevation from topocentric vector. | BOOK-VALLADO | Seeded |
| ORB-014 | `rho = sqrt(east^2 + north^2 + up^2)` | topocentric vector | Slant range from ENU components. | BOOK-VALLADO | Seeded |
| ORB-015 | `Doppler_rate = -f_c / c * d(v_r)/dt` | radial acceleration | Doppler rate from range acceleration. | DSN-810-005, BOOK-VALLADO | Seeded |
| ORB-016 | `Antenna_slew_rate ~= sqrt((daz/dt)^2 + (del/dt)^2)` | az/el angular rates | Ground antenna tracking-rate sizing approximation. | DSN-810-005, BOOK-SMAD | Seeded |

## Data Compression and Source Coding

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| COMP-001 | `CR = UncompressedBits / CompressedBits` | `CR`: compression ratio | Measures achieved compression. | CCSDS-121, CCSDS-122, CCSDS-123 | Seeded |
| COMP-002 | `CompressedBits = UncompressedBits / CR + HeaderBits` | compressed payload and headers | Data-volume reduction including packet/header overhead. | CCSDS-121, CCSDS-122, CCSDS-123 | Seeded |
| COMP-003 | `CompressedRate = SourceRate / CR` | rates in bps | First-order compressed bit rate. | CCSDS-121, BOOK-SMAD | Seeded |
| COMP-004 | `NetCompressedRate = (SourceBits / CR + HeaderBits) / Duration` | source data and duration | Net downlink/storage rate after compression overhead. | CCSDS-121, CCSDS-122 | Seeded |
| COMP-005 | `bpp = Bits / PixelCount` | image bits and pixels | Bits per pixel for image compression. | CCSDS-122, CCSDS-123 | Seeded |
| COMP-006 | `bpsample = Bits / SampleCount` | sample count | Bits per sample for instrument compression. | CCSDS-121, CCSDS-123 | Seeded |
| COMP-007 | `H = -sum(p_i log2(p_i))` | `p_i`: symbol probabilities | Entropy lower bound for lossless coding. | BOOK-SKLAR | Seeded |
| COMP-008 | `L_avg = sum(p_i l_i)` | codeword lengths | Average code length. | BOOK-SKLAR | Seeded |
| COMP-009 | `CodingEfficiency = H / L_avg` | entropy and average length | Source-code efficiency. | BOOK-SKLAR | Seeded |
| COMP-010 | `Residual = Sample - Predictor(SampleHistory)` | predictor output | Predictive coding residual. CCSDS predictor details are procedure/table dependent. | CCSDS-121, CCSDS-123 | Procedure |
| COMP-011 | `QuantizedResidual = round(Residual / q)` | quantization step `q` | Near-lossless residual quantization skeleton. | CCSDS-123 | Procedure |
| COMP-012 | `PacketizedCompressedBits = CompressedDataBits + PacketOverheadBits` | source packet overhead | Compressed stream inserted into source packets. | CCSDS-121, CCSDS-122, CCSDS-123 | Procedure |
| COMP-013 | `StorageGain = 1 - CompressedBits / UncompressedBits` | storage reduction | Fractional storage saving. | CCSDS-121, BOOK-SMAD | Seeded |
| COMP-014 | `DownlinkTimeSaved = DataVolume/Rate - CompressedBits/Rate` | volume and downlink rate | Contact-time saving from compression. | BOOK-SMAD, CCSDS-121 | Seeded |

## Protocol, Security, and Space Link Overhead Extensions

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| PROTO-001 | `ProtocolEfficiency = UserDataBits / (UserDataBits + HeaderBits + TrailerBits)` | protocol field bits | Generic protocol-layer efficiency. | CCSDS-132, CCSDS-232, CCSDS-732, CCSDS-732.1 | Seeded |
| PROTO-002 | `LayeredEfficiency = prod(eta_i)` | per-layer efficiencies | Combined efficiency across packet, frame, coding, and security layers. | CCSDS SLS, BOOK-SMAD | Seeded |
| PROTO-003 | `NetUserRate = PhysicalRate * LayeredEfficiency` | physical line rate and efficiency | User payload rate after protocol/coding overhead. | CCSDS SLS | Seeded |
| PROTO-004 | `IdleFraction = IdleBits / TotalFrameBits` | idle/fill data bits | Idle insertion cost in scheduled links. | CCSDS-132, CCSDS-732, CCSDS-732.1 | Seeded |
| PROTO-005 | `FillOverhead = FillBits / (PayloadBits + FillBits)` | fill bits | Fill overhead when transfer data does not align to frame/codeblock boundaries. | CCSDS-131, CCSDS-231 | Procedure |
| PROTO-006 | `SecurityEfficiency = PlaintextBits / (PlaintextBits + IVBits + AuthTagBits + PaddingBits)` | security overhead fields | Security overhead for authenticated/encrypted data links. | CCSDS-355, CCSDS-232, CCSDS-732.1 | Seeded |
| PROTO-007 | `ReplayWindowMemory = WindowSize * SequenceNumberBytes` | replay protection fields | Ground/space memory sizing for anti-replay tracking. | CCSDS-355 | Seeded |
| PROTO-008 | `ARQGoodput = PayloadBits * (1-PER) / TransactionTime` | packet/frame error rate | First-order goodput with retransmissions omitted. | CCSDS COP, BOOK-SKLAR | Seeded |
| PROTO-009 | `ExpectedTransmissions = 1 / (1 - PER)` | frame error probability | Expected attempts for independent retransmission trials. | BOOK-SKLAR, CCSDS COP | Seeded |
| PROTO-010 | `ARQGoodput ~= PayloadBits / (FrameTime * ExpectedTransmissions + AckDelay)` | ARQ timing | Stop-and-wait style goodput estimate. | CCSDS COP, BOOK-SKLAR | Seeded |
| PROTO-011 | `ProxNetRate = ProxPhysicalRate * ProxCodingEfficiency * ProxFrameEfficiency` | Proximity-1 factors | Relay/lander proximity link net rate. | CCSDS-211.0, CCSDS-211.1, CCSDS-211.2 | Seeded |
| PROTO-012 | `MultiplexedRate_i = NetRate * Allocation_i` | allocation fraction | Virtual-channel or service allocation rate. | CCSDS-132, CCSDS-732, CCSDS-732.1 | Seeded |

## Measurement, Unit, and RF Lab Conversions

| ID | Formula | Variables | Explanation | Source family | Status |
| --- | --- | --- | --- | --- | --- |
| MEAS-001 | `P_dBW = 10 log10(P_W)` | `P_W`: power in watts | Watt to dBW. | General RF engineering | Seeded |
| MEAS-002 | `P_dBm = 10 log10(P_mW)` | `P_mW`: power in milliwatts | Milliwatt to dBm. | General RF engineering | Seeded |
| MEAS-003 | `P_dBm = P_dBW + 30` | dB powers | dBW/dBm conversion. | General RF engineering | Seeded |
| MEAS-004 | `P_W = 10^(P_dBW/10)` | dBW | dBW to watts. | General RF engineering | Seeded |
| MEAS-005 | `ratio_dB = 10 log10(P2/P1)` | power ratio | Power ratio in dB. | General RF engineering | Seeded |
| MEAS-006 | `voltage_dB = 20 log10(V2/V1)` | equal impedances assumed | Voltage ratio in dB. | General RF engineering | Seeded |
| MEAS-007 | `P = V_rms^2 / Z` | `V_rms`: RMS voltage; `Z`: RF/load impedance | RF power from RMS voltage. | General RF engineering | Seeded |
| MEAS-008 | `V_rms = sqrt(P Z)` | power and RF/load impedance | RMS voltage from RF power. | General RF engineering | Seeded |
| MEAS-009 | `PFD = EIRP / (4 pi R^2)` | power flux density W/m^2 | Power flux density at range. | ITU-P525, BOOK-MARAL | Seeded |
| MEAS-010 | `PFD_dBW_m2 = EIRP_dBW - 10log10(4 pi R^2)` | dB form | PFD in dBW/m^2. | ITU-P525, BOOK-MARAL | Seeded |
| MEAS-011 | `PSD_dBW_Hz = P_dBW - 10log10(B)` | bandwidth `B` | Power spectral density. | General RF engineering | Seeded |
| MEAS-012 | `CN0_from_CNR = C/N + 10log10(B_n)` | measured C/N and bandwidth | Converts measured carrier-to-noise ratio to C/N0. | BOOK-SKLAR, DSN-810-005 | Seeded |

## Current App Coverage Summary

Implemented formulas are concentrated in:

- RF-008, RF-010, RF-019
- LINK-001 to LINK-004 and LINK-008
- BB-005 to BB-007, BB-015, BB-016
- TM-001 to TM-005
- TC-001 to TC-005
- TRK-001, TRK-002, TRK-004 to TRK-011

High-value missing groups:

1. Antenna sizing and receiver noise cascade.
2. ITU-R propagation and availability.
3. TM/TC/AOS/USLP frame overhead from CCSDS tables.
4. CCSDS coding modes and MODCOD tables.
5. External measurement: Delta-DOR, radar-style range equation, angular error.
6. System-level mission data/contact/storage closure.
7. Compression, Proximity-1 relay links, contact geometry, and RF measurement conversions.
