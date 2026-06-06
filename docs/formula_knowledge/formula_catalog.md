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
| RF-021 | `eta_ap = eta_rad * eta_taper * eta_spillover * eta_surface * eta_blockage * eta_strut * eta_squint * eta_astigmatism` | aperture efficiency factors | Aperture efficiency budget for reflector antennas. Terms can be omitted when unavailable but must not be double-counted. | DESCANSO-DSTSE, BOOK-BALANIS | Seeded |
| RF-022 | `eta_surface = exp(-(4*pi*K_surf*sigma_surface/lambda)^2)` | `sigma_surface`: reflector surface rms error | Ruze-style surface-error efficiency term as given in DESCANSO reflector discussion. `K_surf` depends on reflector geometry such as f/D. | DESCANSO-DSTSE, BOOK-BALANIS | Seeded |
| RF-023 | `G_ap_dBi = 10log10(eta_ap * 4*pi*A_p/lambda^2)` | aperture area and total aperture efficiency | Aperture antenna gain in dBi; equivalent to `eta_ap*(pi*D/lambda)^2` for a circular aperture. | DESCANSO-DSTSE, BOOK-BALANIS | Seeded |
| RF-024 | `A_p = pi*D^2/4` | circular reflector diameter | Geometrical aperture area for circular dish antennas; kept as an explicit antenna-design output even though RF-002 already covers area. | DESCANSO-DSTSE, BOOK-BALANIS | Seeded |
| RF-025 | `PointingLoss_dB(theta,phi) = G_m_dBi - G(theta,phi)_dBi` | antenna gain pattern and boresight gain | Pattern-based pointing loss from off-boresight target location. | DESCANSO-DSTSE | Procedure |
| RF-026 | `MeanPointingLoss = integral(PointingLoss(theta,phi) * p_e(theta,phi) dtheta dphi)` | pointing-error probability density | Statistical pointing loss for design-control tables. | DESCANSO-DSTSE | Procedure |
| RF-027 | `VarPointingLoss = integral((PointingLoss-MeanPointingLoss)^2 * p_e(theta,phi) dtheta dphi)` | pointing-loss distribution | Variance of pointing loss for tolerance/statistical link budgets. | DESCANSO-DSTSE | Procedure |
| RF-028 | `eta_pol = P_delivered / P_available` | delivered and polarization-matched available power | Polarization efficiency definition. | DESCANSO-DSTSE, BOOK-BALANIS | Seeded |
| RF-029 | `L_pol_dB = -10log10(eta_pol)` | polarization efficiency | Polarization mismatch loss from efficiency; complements RF-018 vector form. | DESCANSO-DSTSE, BOOK-BALANIS | Seeded |
| RF-030 | `Ellipticity_dB = 20log10(AR)` | `AR`: polarization axial ratio | Ellipticity from polarization axial ratio. | DESCANSO-DSTSE, BOOK-BALANIS | Seeded |
| RF-031 | `D_lambda = D/lambda` | antenna diameter and wavelength | Electrical aperture size used by ITU reference-pattern validity and beamwidth checks. | ITU-S465, ITU-S580, BOOK-BALANIS | Seeded |
| RF-032 | `phi_min = max(1 deg, 100/D_lambda deg)` for `D_lambda>=50` | electrical aperture size | Minimum off-axis angle for the main ITU-R S.465 reference pattern branch. | ITU-S465 | Procedure |
| RF-033 | `G_ref(phi) = 32 - 25log10(phi_deg)` for `phi_min<=phi<48 deg`; `G_ref=-10 dBi` for `48<=phi<=180 deg` | off-axis angle in degrees | ITU-R S.465 fixed-satellite earth-station reference radiation pattern for coordination/interference assessment. | ITU-S465 | Procedure |
| RF-034 | `phi_min_small = max(2 deg, 114*D_lambda^-1.09 deg)` for `D_lambda<50` | electrical aperture size | ITU-R S.465 minimum off-axis angle branch for smaller earth-station antennas. | ITU-S465 | Procedure |
| RF-035 | `G_ref_legacy(phi) = 52 - 10log10(D_lambda) - 25log10(phi_deg)`; far sidelobe `=10 - 10log10(D_lambda)` | legacy network condition | ITU-R S.465 note branch for certain pre-1993 coordinated earth-station networks. | ITU-S465 | Procedure |
| RF-036 | `G_sidelobe_objective(phi) = 29 - 25log10(phi_deg)` | off-axis angle toward the GSO region | ITU-R S.580 design objective for GSO earth-station side-lobe peaks. | ITU-S580 | Procedure |
| RF-037 | `G_s580_transition = -3.5 dBi` for `20 deg < phi <= 26.3 deg` | off-axis angle | ITU-R S.580 transition note when the design objective and S.465 reference pattern are discontinuous. | ITU-S580 | Procedure |
| RF-038 | `D_e = sqrt(4*A_aperture/pi)` | asymmetric aperture area | Circular-equivalent diameter for asymmetric apertures used by S.580 side-lobe checks. | ITU-S580, BOOK-BALANIS | Seeded |
| RF-039 | `U(theta,phi) = r^2*S_rad(theta,phi)` | radiation power density | Radiation intensity from far-field power density. | BOOK-BALANIS | Seeded |
| RF-040 | `D_0 = 4*pi*U_max/P_rad` | maximum radiation intensity and radiated power | Antenna directivity definition. | BOOK-BALANIS | Seeded |
| RF-041 | `G = eta_rad*D_0` | radiation efficiency and directivity | Realized antenna gain as efficiency times directivity. | BOOK-BALANIS | Seeded |
| RF-042 | `Omega_A = integral_0^(2pi) integral_0^pi P_n(theta,phi)*sin(theta)dtheta dphi` | normalized power pattern | Antenna beam solid angle. | BOOK-BALANIS | Procedure |
| RF-043 | `D_0 = 4*pi/Omega_A` | beam solid angle | Directivity from beam solid angle. | BOOK-BALANIS | Seeded |
| RF-044 | `D_0 ~= 41253/(theta_HP_deg*phi_HP_deg)` | half-power beamwidths in degrees | Common pencil-beam directivity estimate from orthogonal HPBWs. | BOOK-BALANIS | Seeded |
| RF-045 | `theta_FNBW_uniform_circular ~= 2.44*lambda/D` | circular aperture diameter | First-null beamwidth approximation for a uniformly illuminated circular aperture. | BOOK-BALANIS | Seeded |
| RF-046 | `theta_HPBW_uniform_circular ~= 1.02*lambda/D` | circular aperture diameter | Half-power beamwidth approximation for a uniformly illuminated circular aperture. | BOOK-BALANIS | Seeded |
| RF-047 | `R_ff >= 2*D_max^2/lambda` | largest antenna dimension | Fraunhofer far-field distance criterion for antenna pattern/link measurements. | BOOK-BALANIS | Seeded |
| RF-048 | `PLF = |rho_wave dot rho_ant|^2` | wave and antenna polarization unit vectors | Polarization loss factor in linear power ratio. | BOOK-BALANIS | Seeded |
| RF-049 | `AF(theta) = sum_{n=0}^{N_elem-1} w_n*exp(j*n*(k0*d_elem*cos(theta)+beta_phase))` | element weights, spacing, phase progression | Uniform-line array-factor structure before normalization. | BOOK-BALANIS | Procedure |
| RF-050 | `AF_norm = |sin(N_elem*psi/2)/(N_elem*sin(psi/2))|`, `psi=k0*d_elem*cos(theta)+beta_phase` | array size and phase variable | Closed-form normalized array factor for equal-amplitude linear arrays. | BOOK-BALANIS | Seeded |
| RF-051 | `F = 1 + T_e/T0` | equivalent noise temperature and standard temperature | Converts equivalent noise temperature back to linear noise factor. Complements RF-011. | BOOK-MARAL, BOOK-SKLAR | Seeded |
| RF-052 | `NF_dB = 10log10(F)` | linear noise factor | Converts noise factor to noise figure in dB. | BOOK-MARAL, BOOK-SKLAR | Seeded |
| RF-053 | `T_passive = (L_linear - 1)*T_phys` | passive loss factor and physical temperature | Equivalent input noise temperature of a passive lossy element at physical temperature. | BOOK-MARAL, BOOK-SKLAR | Seeded |
| RF-054 | `T_referred_before_loss = (L_linear - 1)*T_phys + L_linear*T_downstream` | passive loss before a receiver/noise stage | Refers downstream receiver noise through a lossy feed, radome, diplexer, waveguide, or switch placed before the LNA. | BOOK-MARAL, BOOK-SKLAR, DSN-810-005 | Seeded |
| RF-055 | `T_sys_ant_ref = T_ant + (L_feed - 1)*T_feed_phys + L_feed*T_rx + T_misc` | antenna temperature, feed loss, receiver temperature | System temperature referred to the antenna/feed reference plane when a lossy feed precedes the receiver. | DESCANSO-DSTSE, BOOK-MARAL, DSN-810-005 | Seeded |
| RF-056 | `T_out_lossy = T_in/L_linear + (1 - 1/L_linear)*T_phys` | input brightness/noise temperature and passive loss | Output noise temperature after a lossy passive path, useful for atmosphere/feed attenuation and emission. | BOOK-MARAL, DSN-810-005 | Seeded |
| RF-057 | `Y = P_hot/P_cold` | measured hot/cold output powers | Y-factor definition for receiver noise-temperature measurement. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| RF-058 | `T_e_yfactor = (T_hot - Y*T_cold)/(Y - 1)` | hot and cold source temperatures, Y factor | Receiver equivalent noise temperature from a hot/cold Y-factor measurement. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| RF-059 | `Y_dB = 10log10(Y)` | Y factor | dB representation of a power-ratio Y-factor measurement. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| RF-060 | `ENR_linear = (T_hot - T0)/T0` | hot-source temperature and standard temperature | Excess noise ratio for a calibrated noise source. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| RF-061 | `T_hot = T0*(ENR_linear + 1)` | excess noise ratio | Hot-source equivalent temperature from ENR. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| RF-062 | `T_ant = integral_4pi(T_b(theta,phi)*P_n(theta,phi)dOmega) / integral_4pi(P_n(theta,phi)dOmega)` | scene brightness temperature and antenna power pattern | Antenna noise temperature from scene brightness weighted by the normalized antenna pattern. | BOOK-BALANIS, DESCANSO-DSTSE | Procedure |
| RF-063 | `T_ant_ohmic = eta_rad*T_scene + (1 - eta_rad)*T_phys` | radiation efficiency, scene and physical temperature | First-order antenna temperature with ohmic/radiation-efficiency loss. | BOOK-BALANIS, BOOK-MARAL | Seeded |
| RF-064 | `G_DSN(theta) = G0 - G1*(theta - gamma)^2 - A_zen/sin(theta)` | DSN gain parameters and zenith attenuation | DSN station antenna gain versus elevation angle, referenced to the feedhorn aperture in modules 101/103/104. | DSN-810-005-101, DSN-810-005-103, DSN-810-005-104 | Procedure |

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
| LINK-027 | `P_R_dBW = P_T_dBW - L_T_dB + G_T_dBi - L_TP_dB - L_s_dB - L_A_dB - L_P_dB - L_RP_dB + G_R_dBi - L_R_dB` | transmit power, antenna gains, circuit/pointing/space/atmosphere/polarization losses | Full received-power accounting form for ground-space links. | DESCANSO-DSTSE, DSN-810-005 | Seeded |
| LINK-028 | `L_s_ratio = (lambda/(4*pi*r))^2` | wavelength and range | Linear space-loss ratio between two antennas. | DESCANSO-DSTSE, ITU-P525 | Seeded |
| LINK-029 | `L_s_dB = 20log10(4*pi*r/lambda)` | range and wavelength | Positive dB space loss corresponding to LINK-028. | DESCANSO-DSTSE, ITU-P525 | Seeded |
| LINK-030 | `N0_W_Hz = k*T_sys` | system equivalent noise temperature | One-sided thermal noise spectral density. | DESCANSO-DSTSE, DSN-810-005 | Seeded |
| LINK-031 | `P_to_N0_dBHz = P_R_dBW - N0_dBW_Hz` | received power and noise spectral density | Received total power-to-noise-density ratio. | DESCANSO-DSTSE, DSN-810-005 | Seeded |
| LINK-032 | `ST_N0_receiver_dB = S_data_dBW - N0_dBW_Hz - 10log10(R_b)` | data-sideband power, bit rate, noise density | Telemetry/command energy-per-bit to noise-density ratio at receiver input. | DESCANSO-DSTSE | Seeded |
| LINK-033 | `ST_N0_output_dB = ST_N0_receiver_dB - L_system_dB` | receiver/demodulation implementation loss | Output `ST/N0` after system losses. | DESCANSO-DSTSE | Seeded |
| LINK-034 | `PerformanceMargin_dB = ST_N0_output_dB - Threshold_ST_N0_dB` | output and threshold bit-energy metric | Telemetry or command performance margin. | DESCANSO-DSTSE, DSN-810-005 | Seeded |
| LINK-035 | `CarrierMargin_dB = P_c_dBW - N0_dBW_Hz - 10log10(2*B_LO)` | residual carrier power and loop bandwidth | Carrier margin relative to phase-lock threshold. | DESCANSO-DSTSE | Seeded |
| LINK-036 | `RangingInputSNR = P_R_ul / (B_R * N0_ul)` | uplink ranging sideband power, transponder ranging bandwidth, uplink noise density | Ranging channel input SNR at the spacecraft receiver. | DESCANSO-DSTSE | Seeded |
| LINK-037 | `RangingMargin_dB = OutputSNR_dB - RequiredSNR_dB` | returned ranging SNR and required SNR | Ranging performance margin. | DESCANSO-DSTSE | Seeded |
| LINK-038 | `T_M = 255 + 25*CD` | weather cumulative distribution `CD` | DSN 105E atmosphere mean effective radiating temperature model. | DSN-810-005-105E | Seeded |
| LINK-039 | `A_atm(theta_elev) = A_zen / sin(theta_elev)` | zenith attenuation and elevation angle | Flat-Earth elevation scaling for atmospheric attenuation. | DSN-810-005-105E | Procedure |
| LINK-040 | `L_atm = 10^(A_atm(theta_elev)/10)` | atmospheric attenuation in dB | Converts atmospheric attenuation to linear loss factor. | DSN-810-005-105E | Seeded |
| LINK-041 | `T_atm(theta_elev) = T_M * (1 - 1/L_atm)` | atmosphere mean radiating temperature and loss factor | Atmospheric noise-temperature contribution. | DSN-810-005-105E | Seeded |
| LINK-042 | `T_CMB_eff(theta_elev) = T_CMB / L_atm` | cosmic microwave background and atmosphere loss | Effective cosmic background noise contribution after atmospheric attenuation. | DSN-810-005-105E | Seeded |
| LINK-043 | `T_AMW(theta_elev) = T1 + T2*exp(-a_noise*theta_elev)` | antenna module coefficients | DSN antenna-microwave noise-temperature component used by station modules. | DSN-810-005-105E | Procedure |
| LINK-044 | `T_op(theta_elev) = T_AMW(theta_elev) + T_atm(theta_elev) + T_CMB_eff(theta_elev)` | antenna-microwave, atmosphere, cosmic terms | System operating noise temperature with atmosphere and attenuated cosmic background. | DSN-810-005-105E | Seeded |
| LINK-045 | `gamma_R = k_rain * R_p^alpha_rain` | `R_p`: rain rate mm/h exceeded for probability p | ITU-R rain specific attenuation power-law model. P.618 uses `R_0_01` for the 0.01% annual statistic. | ITU-P838, ITU-P618 | Seeded |
| LINK-046 | `log10(k_pol) = sum(a_j * exp(-((log10(f_GHz)-b_j)/c_j)^2)) + m_k*log10(f_GHz) + c_k` | P.838 coefficient table constants | Curve fit for horizontal or vertical rain coefficient `k_H`/`k_V` over 1 to 1000 GHz. | ITU-P838 | Procedure |
| LINK-047 | `alpha_pol = sum(a_j * exp(-((log10(f_GHz)-b_j)/c_j)^2)) + m_alpha*log10(f_GHz) + c_alpha` | P.838 coefficient table constants | Curve fit for horizontal or vertical rain exponent `alpha_H`/`alpha_V`. | ITU-P838 | Procedure |
| LINK-048 | `k_rain = (k_H + k_V + (k_H-k_V)*cos(theta_elev)^2*cos(2*tau))/2` | elevation and polarization tilt | Path/polarization-adjusted rain coefficient. `tau=45 deg` for circular polarization. | ITU-P838 | Seeded |
| LINK-049 | `alpha_rain = (k_H*alpha_H + k_V*alpha_V + (k_H*alpha_H-k_V*alpha_V)*cos(theta_elev)^2*cos(2*tau))/(2*k_rain)` | horizontal/vertical coefficients | Path/polarization-adjusted rain exponent. | ITU-P838 | Seeded |
| LINK-050 | `h_R = h_0 + 0.36 km` | `h_0`: annual mean 0 deg C isotherm height | ITU-R rain height above mean sea level when no local rain-height data are available. | ITU-P839 | Seeded |
| LINK-051 | `h_0 = bilinear(lat, lon, h0_grid)` | P.839 digital map grid | Interpolates 0 deg C isotherm height from four nearest P.839 map grid points. | ITU-P839 | Procedure |
| LINK-052 | `L_s = (h_R - h_s)/sin(theta_elev)` | rain height, station height, elevation | Slant path length below rain height for elevation angles at least 5 degrees. | ITU-P618 | Seeded |
| LINK-053 | `L_s = 2*(h_R-h_s)/(sqrt(sin(theta_elev)^2 + 2*(h_R-h_s)/R_eff) + sin(theta_elev))` | low elevation geometry | Slant path length below rain height for elevation angles below 5 degrees. | ITU-P618 | Seeded |
| LINK-054 | `L_G = L_s*cos(theta_elev)` | slant path length and elevation | Horizontal projection of the slant rain path. | ITU-P618 | Seeded |
| LINK-055 | `r_0_01 = 1/(1 + 0.78*sqrt(L_G*gamma_R/f_GHz) - 0.38*(1-exp(-2*L_G)))` | horizontal path projection and rain specific attenuation | Horizontal reduction factor for 0.01% of an average year. | ITU-P618 | Seeded |
| LINK-056 | `zeta = atan((h_R-h_s)/(L_G*r_0_01))` | rain height and reduced horizontal path | Auxiliary angle for vertical adjustment factor. | ITU-P618 | Seeded |
| LINK-057 | `L_R = if zeta>theta_elev then L_G*r_0_01/cos(theta_elev) else (h_R-h_s)/sin(theta_elev)` | reduced slant path | Adjusted slant-path term used by P.618 vertical factor. | ITU-P618 | Procedure |
| LINK-058 | `chi = max(0, 36 - abs(phi_lat))` | station latitude in degrees | Latitude adjustment term used in P.618 rain vertical factor. | ITU-P618 | Seeded |
| LINK-059 | `v_0_01 = 1/(1 + sqrt(sin(theta_elev))*(31*(1-exp(-theta_elev_deg/(1+chi)))*sqrt(L_R*gamma_R)/f_GHz^2 - 0.45))` | elevation, latitude term, path, rain, frequency | Vertical adjustment factor for 0.01% of an average year; P.618 uses elevation in degrees in the exponential term. | ITU-P618 | Seeded |
| LINK-060 | `L_E = L_R*v_0_01` | adjusted path and vertical factor | Effective rain path length. | ITU-P618 | Seeded |
| LINK-061 | `A_0_01 = gamma_R*L_E` | rain specific attenuation and effective path | Rain attenuation exceeded for 0.01% of an average year. | ITU-P618 | Seeded |
| LINK-062 | `beta = 0` or `-0.005*(abs(phi_lat)-36)` or `-0.005*(abs(phi_lat)-36)+1.8-4.25*sin(theta_elev)` | probability, latitude, elevation branch | P.618 beta branch used for annual probability extrapolation from `A_0_01`. | ITU-P618 | Procedure |
| LINK-063 | `A_rain_p = A_0_01*(p_exceed/0.01)^(-(0.655 + 0.033*ln(p_exceed) - 0.045*ln(A_0_01) - beta*(1-p_exceed)*sin(theta_elev)))` | target exceedance probability | Rain attenuation exceeded for `p_exceed` percent of an average year, valid over the P.618 probability range. | ITU-P618 | Seeded |
| LINK-064 | `A_T(p_exceed) = A_G(p_exceed) + sqrt((A_R(p_exceed)+A_C(p_exceed))^2 + A_S(p_exceed)^2)` | gas, rain, cloud, scintillation | Total attenuation for `0.001% <= p_exceed <= 5%`, combining simultaneous effects. | ITU-P618 | Procedure |
| LINK-065 | `A_T(p_exceed) = A_G(p_exceed) + sqrt(A_C(p_exceed)^2 + A_S(p_exceed)^2)` | gas, cloud, scintillation | Total attenuation for `5% < p_exceed <= 50%`; P.618 holds cloud and gas terms at 5% for p below 5%. | ITU-P618 | Procedure |
| LINK-066 | `gamma_gas = gamma_o + gamma_w = 0.1820*f_GHz*(Npp_oxygen + Npp_water)` | complex refractivity imaginary parts | ITU-R P.676 line-by-line specific gaseous attenuation from oxygen/dry air and water vapour. | ITU-P676 | Procedure |
| LINK-067 | `e_wv = rho_wv*T_K/216.7` | water vapour density and temperature | Converts water vapour density to water vapour partial pressure for P.676. | ITU-P676 | Seeded |
| LINK-068 | `Npp_oxygen = sum(S_i*F_i for oxygen lines) + Npp_D` | spectroscopic line table | Imaginary oxygen/dry-air refractivity including dry continuum. | ITU-P676 | Procedure |
| LINK-069 | `Npp_water = sum(S_i*F_i for water-vapour lines)` | spectroscopic line table | Imaginary water-vapour refractivity from water-vapour spectral lines. | ITU-P676 | Procedure |
| LINK-070 | `S_i_oxygen = a1*1e-7*p_dry*theta_300^3*exp(a2*(1-theta_300))` | oxygen line coefficients | Oxygen line strength for P.676 line-by-line calculation. | ITU-P676 | Procedure |
| LINK-071 | `S_i_water = b1*1e-1*e_wv*theta_300^3.5*exp(b2*(1-theta_300))` | water-vapour line coefficients | Water-vapour line strength for P.676 line-by-line calculation. | ITU-P676 | Procedure |
| LINK-072 | `F_i = f_GHz/f_i*((Delta_f-delta_i*(f_i-f_GHz))/((f_i-f_GHz)^2+Delta_f^2) + (Delta_f-delta_i*(f_i+f_GHz))/((f_i+f_GHz)^2+Delta_f^2))` | line frequency, width, and interference factor | P.676 spectral line-shape factor. | ITU-P676 | Procedure |
| LINK-073 | `A_gas_profile = sum(path_length_i*gamma_i)` | layer path length and layer specific attenuation | P.676 slant-path gaseous attenuation by summing atmospheric layers. | ITU-P676 | Procedure |
| LINK-074 | `A_o_inst = gamma_o*h_o/sin(theta_elev)` | oxygen specific attenuation and equivalent height | P.676 approximate instantaneous slant oxygen attenuation. | ITU-P676 | Procedure |
| LINK-075 | `h_o = a_o(f)+b_o(f)*T_surface+c_o(f)*P_s+d_o(f)*rho_ws` | coefficient data file | Oxygen equivalent height in the P.676 approximate method. | ITU-P676 | Procedure |
| LINK-076 | `A_w_inst = gamma_w*h_w/sin(theta_elev)` | water-vapour specific attenuation and equivalent height | P.676 approximate instantaneous water-vapour attenuation method 1. | ITU-P676 | Procedure |
| LINK-077 | `h_w = A_hw*f_GHz + B_hw + sum(a_hw_i/((f_GHz-f_hw_i)^2+b_hw_i))` | water-vapour equivalent-height coefficients | Water-vapour equivalent height approximation for P.676 method 1. | ITU-P676 | Procedure |
| LINK-078 | `A_G = A_o + A_w` | oxygen and water-vapour attenuation | Total gaseous attenuation term for P.618 total-attenuation combination. | ITU-P676, ITU-P618 | Seeded |
| LINK-079 | `gamma_c = K_l*rho_l` | cloud liquid coefficient and liquid density | Specific attenuation inside cloud/fog under P.840 Rayleigh approximation. | ITU-P840 | Seeded |
| LINK-080 | `K_l = 0.819*f_GHz/(epsilon_pp*(1+eta_cloud^2))` | dielectric permittivity model | Cloud liquid water specific attenuation coefficient. | ITU-P840 | Procedure |
| LINK-081 | `eta_cloud = (2 + epsilon_p)/epsilon_pp` | real and imaginary permittivity | P.840 auxiliary ratio for liquid-water attenuation. | ITU-P840 | Seeded |
| LINK-082 | `epsilon_0 = 77.66 + 103.3*(300/T_cloud - 1)` | liquid water temperature | Static dielectric constant term in the P.840 double-Debye model. | ITU-P840 | Seeded |
| LINK-083 | `epsilon_1 = 0.0671*epsilon_0`; `epsilon_2 = 3.52` | liquid water dielectric constants | Secondary dielectric constants in the P.840 model. | ITU-P840 | Seeded |
| LINK-084 | `f_p = 20.20 - 146*(300/T_cloud - 1) + 316*(300/T_cloud - 1)^2`; `f_s = 39.8*f_p` | relaxation frequencies | Principal and secondary relaxation frequencies for liquid water. | ITU-P840 | Seeded |
| LINK-085 | `K_L = K_l(f_GHz,273.75K)*(A1*exp(-((f_GHz-f1_cloud)^2)/sigma1_cloud)+A2*exp(-((f_GHz-f2_cloud)^2)/sigma2_cloud)+A3)` | P.840 fitted coefficients | Cloud liquid mass absorption coefficient used with integrated liquid water. | ITU-P840 | Procedure |
| LINK-086 | `A_C_inst = K_L*L_cloud/sin(theta_elev)` | integrated cloud liquid water | Instantaneous slant cloud attenuation. | ITU-P840 | Seeded |
| LINK-087 | `A_C_stat = K_L*L_cloud_p/sin(theta_elev)` | cloud liquid water at exceedance probability | Statistical slant cloud attenuation. | ITU-P840 | Procedure |
| LINK-088 | `A_C_logn = if p_exceed<P_L then K_L*exp(m_L + sigma_L*Qinv(p_exceed/P_L))/sin(theta_elev) else 0` | cloud probability and log-normal parameters | P.840 log-normal cloud attenuation approximation. | ITU-P840 | Procedure |
| LINK-089 | `sigma_ref = 3.6e-3 + 1e-4*N_wet` | wet refractivity term | P.618 reference standard deviation for tropospheric scintillation amplitude. | ITU-P618 | Seeded |
| LINK-090 | `L_scint = 2*h_L/(sqrt(sin(theta_elev)^2 + 2.35e-4) + sin(theta_elev))` | turbulent-layer height and elevation | Effective path length for scintillation prediction. | ITU-P618 | Seeded |
| LINK-091 | `D_eff = sqrt(eta_ant)*D` | antenna efficiency and diameter | Effective antenna diameter for scintillation antenna averaging. | ITU-P618 | Seeded |
| LINK-092 | `x_scint = 1.22*D_eff^2*f_GHz/L_scint` | effective antenna diameter, frequency, path length | P.618 antenna-averaging argument. | ITU-P618 | Seeded |
| LINK-093 | `g_x = 3.86*(x_scint^2+1)^(11/12)*sin((11/6)*atan(1/x_scint)) - 7.08*x_scint^(5/6)` | antenna-averaging argument | P.618 antenna averaging helper. If `g_x < 0`, scintillation fade depth is set to zero. | ITU-P618 | Seeded |
| LINK-094 | `sigma_scint = sigma_ref*f_GHz^(7/12)*sqrt(g_x)/sin(theta_elev)^1.2` | reference sigma and antenna averaging | Standard deviation of tropospheric scintillation amplitude for elevation at least 5 degrees. | ITU-P618 | Seeded |
| LINK-095 | `a_scint(p) = -0.061*(log10(p_exceed))^3 + 0.072*(log10(p_exceed))^2 - 1.71*log10(p_exceed) + 3.0` | exceedance probability | P.618 time-percentage factor for scintillation, valid over the stated probability range. | ITU-P618 | Seeded |
| LINK-096 | `A_S = a_scint(p_exceed)*sigma_scint` | time-percentage factor and sigma | Tropospheric scintillation fade depth exceeded for `p_exceed` percent of time. | ITU-P618 | Seeded |
| LINK-097 | `T_sky = T_mr*(1 - 10^(-A_atm_no_scint/10)) + 2.7*10^(-A_atm_no_scint/10)` | atmospheric attenuation and mean radiating temperature | P.618 sky noise temperature at a ground-station antenna. | ITU-P618 | Seeded |
| LINK-098 | `T_mr = 37.34 + 0.81*T_surface` | surface temperature | P.618 mean radiating temperature estimate for clear/cloudy weather when surface temperature is known. | ITU-P618 | Seeded |

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
| BB-018 | `ConvOutSymbols = InfoBits / r_conv` | `r_conv`: 1/2, 2/3, 3/4, 5/6, or 7/8 | CCSDS TM convolutional encoder output symbols for the selected managed rate. | CCSDS-131 | Seeded |
| BB-019 | `ConvExpansion = 1 / r_conv` | convolutional coding rate | Physical symbol expansion before modulation. Basic CCSDS convolutional coding is rate 1/2, K=7; punctured rates are higher. | CCSDS-131 | Seeded |
| BB-020 | `RS_n = 2^J - 1` | `J=8` bits per R-S symbol | CCSDS TM Reed-Solomon codeword length in symbols; with J=8, `RS_n=255`. | CCSDS-131 | Seeded |
| BB-021 | `RS_k = RS_n - 2E` | `E`: 8 or 16 symbols | CCSDS TM Reed-Solomon information symbols per codeword. Gives (255,239) for E=8 and (255,223) for E=16. | CCSDS-131 | Seeded |
| BB-022 | `RS_CheckBits = 2 * E * I * J` | `I`: interleaving depth | Reed-Solomon check-symbol length for an interleaved codeblock. | CCSDS-131 | Seeded |
| BB-023 | `RS_CodeblockBits = RS_n * I * J` | R-S codeword length and interleaving depth | Maximum interleaved Reed-Solomon codeblock length. | CCSDS-131 | Seeded |
| BB-024 | `RS_InfoBits = (RS_k - q_rs) * I * J` | `q_rs`: virtual fill symbols per R-S codeword | Transmitted information-space bits after shortening by virtual fill. | CCSDS-131 | Seeded |
| BB-025 | `RS_Efficiency = RS_InfoBits / RS_CodeblockBits` | R-S information and full codeblock bits | Coding efficiency including interleaving and virtual fill. | CCSDS-131 | Seeded |
| BB-026 | `TurboCodewordBits = (k_turbo + 4) / r_turbo` | `r_turbo`: 1/2, 1/3, 1/4, or 1/6 | CCSDS TM Turbo codeword length including four trellis-termination bit times. | CCSDS-131 | Seeded |
| BB-027 | `TurboTrueRate = k_turbo / TurboCodewordBits` | information bits and transmitted codeword bits | True rate is slightly below nominal rate because of trellis termination. | CCSDS-131 | Seeded |
| BB-028 | `LDPC_EffectiveRate = k_ldpc / n_ldpc` | selected LDPC table row | Effective LDPC rate from the exact CCSDS table values. Nominal labels such as 7/8 should not be used to derive `n_ldpc` by algebra alone. | CCSDS-131 | Procedure |
| BB-029 | `LDPC_StreamCodeblockBits = m_ldpc * n_ldpc` | `m_ldpc`: codewords per LDPC codeblock | Codeblock length for LDPC coding of a stream of Sync-Marked Transfer Frames. | CCSDS-131 | Seeded |
| BB-030 | `LDPC_StreamInfoBits = m_ldpc * k_ldpc` | slice length and codeblock size | Information bits consumed by one stream-LDPC codeblock. | CCSDS-131 | Seeded |
| BB-031 | `T_s = 1 / R_s` | symbol rate | Symbol period. | BOOK-SKLAR, BOOK-PROAKIS, DESCANSO-DSTSE | Seeded |
| BB-032 | `T_b = 1 / R_b` | bit rate | Bit period. | BOOK-SKLAR, BOOK-PROAKIS | Seeded |
| BB-033 | `E_b = S_data / R_b` | data-sideband power and bit rate | Received or transmitted energy per information bit, depending on the selected reference point. | BOOK-SKLAR, DESCANSO-DSTSE | Seeded |
| BB-034 | `E_s = S_data / R_s` | data-sideband power and symbol rate | Energy per modulation symbol. | BOOK-SKLAR, BOOK-PROAKIS | Seeded |
| BB-035 | `E_s/N0_dB = E_b/N0_dB + 10log10(m * R_c)` | bits per symbol and coding rate | Converts information-bit energy metric to coded modulation symbol metric. | BOOK-SKLAR, BOOK-PROAKIS | Seeded |
| BB-036 | `E_b/N0_dB = C/N0_dBHz - 10log10(R_b)` | carrier-to-noise density and bit rate | Same relationship used by link-budget calculators, kept here as a baseband performance metric. | BOOK-SKLAR, DESCANSO-DSTSE | Seeded |
| BB-037 | `C/N_dB = C/N0_dBHz - 10log10(B_n)` | receiver noise bandwidth | Carrier-to-noise ratio in a finite noise bandwidth. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| BB-038 | `SNR_linear = (E_b/N0) * (R_b / B_n)` | bit-energy metric and noise bandwidth | Relates bit-energy metric to measured SNR in bandwidth. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| BB-039 | `C = B * log2(1 + SNR_linear)` | bandwidth and SNR | Shannon-Hartley capacity upper bound. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| BB-040 | `eta_capacity = log2(1 + SNR_linear)` | SNR | Ideal spectral efficiency upper bound in bit/s/Hz. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| BB-041 | `SNR_required = 2^eta_s - 1` | target spectral efficiency | Shannon-limit SNR needed for a target spectral efficiency. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| BB-042 | `B_Nyquist_min = R_s / 2` | ideal zero-rolloff baseband signaling | Minimum one-sided baseband bandwidth for ideal Nyquist pulses. | BOOK-SKLAR, BOOK-PROAKIS | Seeded |
| BB-043 | `B_RC_baseband = (1 + alpha) * R_s / 2` | raised-cosine rolloff | One-sided baseband raised-cosine bandwidth. | BOOK-SKLAR, BOOK-PROAKIS | Seeded |
| BB-044 | `B_RC_passband ~= (1 + alpha) * R_s` | passband raised-cosine signal | Approximate occupied passband bandwidth for raised-cosine shaped digital modulation. | BOOK-SKLAR, CCSDS-401 | Seeded |
| BB-045 | `samples_per_symbol = f_s / R_s` | sampling and symbol rates | Digital receiver/transmitter oversampling ratio. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| BB-046 | `Delta_q = V_FS / 2^N_bits` | full-scale quantizer range and ADC bits | Uniform quantizer step size. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| BB-047 | `sigma_q^2 = Delta_q^2 / 12` | quantizer step size | Uniform quantization-noise variance under high-resolution assumptions. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| BB-048 | `ENOB = (SNR_q_dB - 1.76) / 6.02` | quantization SNR | Effective number of bits from measured or target SNR. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| BB-049 | `PAPR_dB = 10log10(P_peak / P_avg)` | peak and average signal power | Peak-to-average power ratio, important for OFDM and saturated transmit chains. | BOOK-SKLAR | Seeded |
| BB-050 | `MatchedFilterOutput_k = integral(r(t) * s_k(t) dt)` | received waveform and candidate signal | Correlation or matched-filter decision statistic for symbol detection. | BOOK-PROAKIS, DESCANSO-DSTSE | Procedure |
| BB-051 | `P_e_binary = Q(sqrt(2*E_b/N0)) = 0.5*erfc(sqrt(E_b/N0))` | coherent antipodal binary signaling | Coherent BPSK/antipodal bit error probability in AWGN. | BOOK-PROAKIS, DESCANSO-DSTSE | Seeded |
| BB-052 | `Q(x) = 0.5*erfc(x/sqrt(2))` | Gaussian Q-function | Relation between Gaussian Q-function and complementary error function. | BOOK-SKLAR, BOOK-PROAKIS | Seeded |
| BB-053 | `P_b_DPSK = 0.5*exp(-E_b/N0)` | differential binary PSK | Noncoherent/differential binary PSK bit error probability in AWGN. | BOOK-SKLAR, BOOK-PROAKIS | Seeded |
| BB-054 | `P_b_MFSK_noncoh ~= 0.5*exp(-E_b/(2*N0))` | binary orthogonal FSK approximation | First-cut noncoherent orthogonal binary FSK error approximation; exact M-ary expressions are table/procedure candidates. | BOOK-SKLAR, BOOK-PROAKIS | Procedure |
| BB-055 | `Delta_f_subcarrier = 1 / T_u` | useful OFDM symbol duration | Orthogonal OFDM subcarrier spacing. | BOOK-SKLAR | Seeded |
| BB-056 | `T_ofdm = T_u + T_cp` | useful symbol and cyclic prefix | Total OFDM symbol duration including cyclic prefix. | BOOK-SKLAR | Seeded |
| BB-057 | `CP_Overhead = T_cp / (T_u + T_cp)` | cyclic prefix duration | OFDM cyclic-prefix overhead fraction. | BOOK-SKLAR | Seeded |
| BB-058 | `OFDM_NetRate = N_data_subcarriers * bits_per_subcarrier * code_rate / T_ofdm` | OFDM subcarriers and coding | Net coded payload rate before pilots, framing, and higher-layer overhead. | BOOK-SKLAR | Seeded |
| BB-059 | `PhaseError_rms = 2*pi*f_c*sigma_t` | carrier frequency and timing jitter | RMS phase error induced by timing jitter. | BOOK-SKLAR, BOOK-HAYKIN | Seeded |
| BB-060 | `SNR_phase_limit ~= 1 / sigma_phase^2` | small phase jitter in radians | Approximate SNR limit from RMS phase noise/jitter. | BOOK-SKLAR, BOOK-HAYKIN | Procedure |
| BB-061 | `FreqOffsetPhase = 2*pi*Delta_f*T_obs` | frequency offset and observation time | Phase rotation accumulated from carrier frequency offset. | BOOK-SKLAR, DESCANSO-DSTSE | Seeded |
| BB-062 | `MIMO_C = log2(det(I_Nr + rho/Nt * H*H^H))` | channel matrix, SNR, antennas | Flat-fading MIMO capacity model with equal power allocation. | BOOK-SKLAR, BOOK-PROAKIS | Procedure |
| BB-063 | `QPSK_I_bit_i = b_(2i); QPSK_Q_bit_i = b_(2i+1)` | serial bit stream and symbol index | CCSDS QPSK input splitting: even bits feed the I channel and odd bits feed the Q channel. | CCSDS-401 | Seeded |
| BB-064 | `QPSKPhase_deg(I,Q) = {45,135,225,315} for IQ={00,10,11,01}` | I/Q bit pair | CCSDS QPSK phase-state convention with Gray-adjacent 90-degree phase errors. | CCSDS-401 | Seeded |
| BB-065 | `PhaseImbalanceMargin_deg = PhaseLimit_deg - abs(PhaseImbalance_deg)` | modulator phase imbalance and selected limit | Compliance margin for RF or subcarrier modulator phase imbalance. Typical CCSDS 401 limits are 5 deg, 3 deg, or 2 deg depending on modulation family and section. | CCSDS-401 | Seeded |
| BB-066 | `AmplitudeImbalanceMargin_dB = AmpLimit_dB - abs(AmplitudeImbalance_dB)` | modulator amplitude imbalance and selected limit | Compliance margin for RF or subcarrier modulator amplitude imbalance. CCSDS 401 gives 0.5 dB for many suppressed-carrier modulators and 0.2 dB for spacecraft subcarrier modulators. | CCSDS-401 | Seeded |
| BB-067 | `SubcarrierRatio = f_sc / R_cs` | subcarrier frequency and coded symbol rate | Telemetry subcarrier frequency-to-coded-symbol-rate ratio for PCM/PSK/PM residual-carrier checks. | CCSDS-401 | Seeded |
| BB-068 | `SubcarrierRatioError = abs(SubcarrierRatio - round(SubcarrierRatio))` | subcarrier ratio | Deviation from the integer subcarrier-ratio condition recommended by CCSDS 401. | CCSDS-401 | Seeded |
| BB-069 | `CodedSymbolRateOffset_ppm = 1e6*(R_cs_meas - R_cs_nom)/R_cs_nom` | measured and nominal coded symbol rates | Converts coded-symbol-rate offset to ppm for suppressed-carrier telemetry stability checks. | CCSDS-401 | Seeded |
| BB-070 | `SymbolRateOffsetMargin_ppm = OffsetLimit_ppm - abs(CodedSymbolRateOffset_ppm)` | ppm offset and CCSDS limit | Margin to the CCSDS 401 maximum coded-symbol-rate offset limit; the common suppressed-carrier telemetry limit is 100 ppm. | CCSDS-401 | Seeded |
| BB-071 | `SymbolRateStabilityMargin = StabilityLimit - abs(Delta_R_cs/R_cs)` | fractional coded symbol rate variation | Short-term or long-term coded-symbol-rate stability margin. CCSDS 401 lists `1e-6` and `1e-5` reference limits for suppressed-carrier telemetry. | CCSDS-401 | Seeded |
| BB-072 | `B_3dB = BTS * R_cs` | GMSK bandwidth-time product and coded symbol rate | Converts a GMSK or filtered-OQPSK `BTS` value to one-sided 3-dB filter bandwidth because `T_s=1/R_cs`. | CCSDS-401 | Seeded |
| BB-073 | `SignalingEfficiency = R_source / R_chs` | source bit rate and channel symbol rate | CCSDS 401 high-rate telemetry signaling efficiency, useful for comparing bandwidth-efficient modulation options. | CCSDS-401 | Seeded |
| BB-074 | `GroupDelayVariationFraction = tau_g_variation / T_s` | in-band group-delay variation and signal duration | Expresses channel group-delay variation as a fraction of symbol duration; CCSDS 401 high-rate EES text uses 10 percent as an acceptable reference value. | CCSDS-401 | Seeded |
| BB-075 | `AMPMMargin_deg_per_dB = AMPM_Limit_deg_per_dB - AMPM_Slope_deg_per_dB` | amplifier AM/PM conversion slope | Margin to the CCSDS 401 high-rate modulation AM/PM slope limit, commonly 5 deg/dB unless receiver equalization is applied. | CCSDS-401 | Seeded |
| BB-076 | `SubcarrierFrequencyOffsetMargin_Hz = OffsetFractionLimit*f_sc - abs(Delta_f_sc)` | subcarrier frequency and measured offset | Margin to telecommand or telemetry subcarrier frequency-offset limits such as `2e-4*f_sc` or 200 ppm. | CCSDS-401 | Seeded |
| BB-077 | `R_chs = R_cs` | Proximity-1 channel and coded symbol rates | Proximity-1 Physical Layer relationship for the specified Bi-Phase-L or bypass modulation scheme. | CCSDS-211.1, ISO-21460 | Seeded |
| BB-078 | `ProxRcsError = min(abs(R_cs - R_cs_allowed_i))` | selected coded symbol rate and allowed-rate table | Validation distance to the Proximity-1 Physical Layer discrete coded-symbol-rate set, 1000 through 4096000 symbols/s by powers of two. | CCSDS-211.1, ISO-21460 | Seeded |
| BB-079 | `ChannelSymbolRateOffset = abs(R_chs_meas - R_chs_nom) / R_chs_nom` | measured and nominal channel symbol rates | Fractional channel-symbol-rate offset for Proximity-1 physical-layer acquisition/compliance checks. | CCSDS-211.1, ISO-21460 | Seeded |
| BB-080 | `ProxChannelOffsetMargin = 0.001 - ChannelSymbolRateOffset` | channel-symbol-rate offset | Margin to the Proximity-1 physical-layer channel-symbol-rate offset limit of less than 0.1 percent. | CCSDS-211.1 | Seeded |
| BB-081 | `ProxShortTermStabilityMargin = 0.01 - abs(Delta_R_chs/R_chs)` | short-term channel-symbol-rate variation | Margin to the Proximity-1 short-term channel-symbol-rate stability value of 1 percent. | CCSDS-211.1 | Seeded |

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
| TM-015 | `TM_DataFieldOctets = TM_FrameOctets - 6 - SecondaryHeaderOctets - OCFOctets - FECFOctets` | TM transfer frame field lengths | TM data field length without SDLS. Secondary header, OCF, and FECF terms are zero when absent. | CCSDS-132 | Seeded |
| TM-016 | `TM_SecondaryHeaderOctets = 1 + SecondaryHeaderDataOctets` | secondary header ID plus data field | TM secondary header length. The header is optional and up to 64 octets. | CCSDS-132 | Seeded |
| TM-017 | `TM_SecondaryHeaderLengthField = TM_SecondaryHeaderOctets - 1` | 6-bit length field | Value encoded in the TM secondary header length subfield. | CCSDS-132 | Seeded |
| TM-018 | `TM_OCFOverhead = 4 / TM_FrameOctets` | OCF present | Operational Control Field overhead for TM frames. | CCSDS-132 | Seeded |
| TM-019 | `TM_FECFOverhead = 2 / TM_FrameOctets` | FECF present | Frame Error Control Field overhead for TM frames. | CCSDS-132 | Seeded |
| TM-020 | `TM_SDLS_DataFieldOctets = TM_FrameOctets - 6 - SecondaryHeaderOctets - SecurityHeaderOctets - SecurityTrailerOctets - OCFOctets - FECFOctets` | SDLS security fields | TM data-field capacity when SDLS is used. | CCSDS-132, CCSDS-355 | Seeded |
| TM-021 | `TM_FrameEfficiency = TM_DataFieldOctets / TM_FrameOctets` | useful data capacity | TM frame data-field efficiency before packet/idle effects. | CCSDS-132 | Seeded |
| TM-022 | `FrameCountNext = (FrameCount + 1) mod 256` | master or virtual channel frame count | TM master-channel and virtual-channel frame counters are 8-bit modulo counters. | CCSDS-132 | Seeded |
| TM-023 | `ASM_bits = 32 / r_turbo` | Turbo nominal code rate | CCSDS TM Turbo ASM length: 64, 96, 128, or 192 bits for rates 1/2, 1/3, 1/4, or 1/6. | CCSDS-131 | Seeded |
| TM-024 | `ASM_bits = 32` | uncoded, convolutional, RS, concatenated, rate-7/8 TF-LDPC, or stream-LDPC | Common 32-bit Attached Sync Marker length. | CCSDS-131 | Seeded |
| TM-025 | `ASM_bits = 64` | rate 1/2, 2/3, or 4/5 Transfer-Frame LDPC | Attached Sync Marker length for the lower-rate transfer-frame LDPC modes. | CCSDS-131 | Seeded |
| TM-026 | `ASMOverhead = ASM_bits / (ASM_bits + coded_unit_bits)` | codeblock, codeword, or frame unit bits | Sync-marker overhead for the unit that ASM immediately precedes. | CCSDS-131 | Seeded |
| TM-027 | `CADU_Bits_RS = ASM_bits + RS_CodeblockBits` | R-S codeblock plus ASM | Channel Access Data Unit size for a full R-S codeblock without virtual-fill shortening. | CCSDS-131 | Seeded |
| TM-028 | `CADU_Bits_RS_Short = ASM_bits + (RS_n - q_rs) * I * J` | shortened R-S codeblock | CADU size when R-S virtual fill is not transmitted. | CCSDS-131 | Seeded |
| TM-029 | `RS_TransferFrameOctets = (255 - 2E - q_rs) * I` | `E`, `q_rs`, `I` | Allowable transfer-frame length for R-S coding with octet compatibility. | CCSDS-131 | Seeded |
| TM-030 | `RS_CodeblockOctets = (255 - q_rs) * I` | R-S virtual fill and interleaving | 32-bit compatibility requires this codeblock length to be a multiple of 4 octets. | CCSDS-131 | Procedure |
| TM-031 | `TurboTransferFrameOctets in {223,446,892,1115}` | selected Turbo block size | CCSDS-validated transfer-frame lengths for Turbo coding. | CCSDS-131 | Seeded |
| TM-032 | `TurboCADUBits = ASM_bits + TurboCodewordBits` | Turbo ASM plus codeword | Total transmitted synchronized Turbo unit length before modulation. | CCSDS-131 | Seeded |
| TM-033 | `LDPC_TF_Octets in {128,512,892,2048}` | selected LDPC transfer-frame mode | Transfer-frame LDPC allows 892 octets for rate 7/8, and 128/512/2048 octets for rates 1/2, 2/3, and 4/5. | CCSDS-131 | Seeded |
| TM-034 | `CSM_bits = 32` | stream-LDPC rate 7/8 | Code Synchronization Marker length for stream LDPC rate 7/8. | CCSDS-131 | Seeded |
| TM-035 | `CSM_bits = 64` | stream-LDPC rates 1/2, 2/3, 4/5 | Code Synchronization Marker length for stream LDPC lower-rate modes. | CCSDS-131 | Seeded |
| TM-036 | `StreamLDPC_UnitBits = CSM_bits + m_ldpc * n_ldpc` | stream-LDPC codeblock and CSM | Physical synchronized unit length for LDPC coding of an SMTF stream. | CCSDS-131 | Seeded |
| TM-037 | `SMTF_Bits = ASM_bits + TransferFrameBits` | stream-LDPC Transfer Frame plus ASM | Sync-Marked Transfer Frame size before stream slicing. | CCSDS-131 | Seeded |
| TM-038 | `RandomizerPeriodBits = 2^17 - 1 = 131071` | long pseudo-randomizer | CCSDS preferred TM pseudo-randomizer period. Randomization adds no bits. | CCSDS-131 | Seeded |
| TM-039 | `LegacyRandomizerPeriodBits = 2^8 - 1 = 255` | short pseudo-randomizer | Backward-compatible randomizer period; standard warns about possible spectral lines. | CCSDS-131 | Seeded |
| TM-040 | `RandomizedBit_i = DataBit_i xor PRN_i` | pseudo-random sequence | Randomizer operation for codeblock, codeword, or Transfer Frame bits after the ASM. | CCSDS-131 | Procedure |
| TM-041 | `TM_MaxFrameOctets_StreamLDPC = 2048` | TM/AOS stream-LDPC | Maximum TM or AOS Transfer Frame length when LDPC is applied to a stream of SMTFs. | CCSDS-131 | Seeded |
| TM-042 | `USLP_MaxFrameOctets_StreamLDPC = 65536` | USLP stream-LDPC | Maximum USLP Transfer Frame length when LDPC is applied to a stream of SMTFs. | CCSDS-131 | Seeded |
| TM-043 | `SpacePacketPrimaryHeaderBits = 3+1+1+11+2+14+16 = 48` | Space Packet primary header fields | Sum of Packet Version Number, Packet Type, Secondary Header Flag, APID, Sequence Flags, Sequence Count, and Packet Data Length. | CCSDS-133 | Seeded |
| TM-044 | `SpacePacketPrimaryHeaderOctets = 6` | primary header bits | Mandatory CCSDS Space Packet primary header size. | CCSDS-133 | Seeded |
| TM-045 | `SpacePacketDataFieldOctets = PacketDataLength + 1` | Packet Data Length field | Packet Data Length stores one fewer than the Packet Data Field octet count. | CCSDS-133 | Seeded |
| TM-046 | `SpacePacketOctets = SpacePacketPrimaryHeaderOctets + SpacePacketDataFieldOctets` | primary header and data field | Complete Space Packet length. | CCSDS-133 | Seeded |
| TM-047 | `SpacePacketMinOctets = 7` | minimum data-field length | Minimum Space Packet size: 6-octet primary header plus at least 1 data-field octet. | CCSDS-133 | Seeded |
| TM-048 | `SpacePacketMaxDataFieldOctets = 2^16 = 65536` | Packet Data Length field width | Maximum Packet Data Field size implied by the 16-bit length field. | CCSDS-133 | Seeded |
| TM-049 | `SpacePacketMaxOctets = 6 + 65536 = 65542` | maximum data field and header | Maximum complete CCSDS Space Packet size. | CCSDS-133 | Seeded |
| TM-050 | `SpacePacketUserDataOctets = SpacePacketDataFieldOctets - PacketSecondaryHeaderOctets` | packet data field and optional secondary header | Space Packet user-data capacity when a secondary header is present. | CCSDS-133 | Seeded |
| TM-051 | `SpacePacketEfficiency = SpacePacketUserDataOctets / SpacePacketOctets` | packet user data and complete packet | User-data fraction of a Space Packet before transfer-frame overhead. | CCSDS-133 | Seeded |
| TM-052 | `APIDCount = 2^11; IdleAPID = 2^11 - 1 = 2047` | APID field width | Application Process ID cardinality and the all-ones idle-packet APID. | CCSDS-133 | Seeded |
| TM-053 | `PacketSequenceModulus = 2^14 = 16384` | Packet Sequence Count field width | Wrap modulus for the 14-bit Packet Sequence Count. | CCSDS-133 | Seeded |
| TM-054 | `PacketSequenceNext = (PacketSequenceCount + 1) mod PacketSequenceModulus` | current packet sequence count | Per-APID packet sequence counter update. | CCSDS-133 | Seeded |
| TM-055 | `PacketSegmentsNeeded = ceil(UserDataOctets / MaxUserDataPerPacketOctets)` | user data and selected packet capacity | First-order count of packets needed when a user data unit is split into Space Packets. | CCSDS-133 | Seeded |
| TM-056 | `USLP_MCIDBits = 4 + 16 = 20` | TFVN and SCID | USLP Master Channel Identifier field width. | CCSDS-732.1 | Seeded |
| TM-057 | `USLP_GVCIDBits = USLP_MCIDBits + 6 = 26` | MCID and VCID | USLP Global Virtual Channel Identifier field width. | CCSDS-732.1 | Seeded |
| TM-058 | `USLP_GMAPIDBits = USLP_GVCIDBits + 4 = 30` | GVCID and MAP ID | USLP Global MAP Identifier field width. | CCSDS-732.1 | Seeded |
| TM-059 | `USLP_SCIDCount = 2^16 = 65536` | SCID field width | Number of spacecraft identifiers representable in the USLP primary header. | CCSDS-732.1 | Seeded |
| TM-060 | `USLP_VCIDCount = 2^6; USLP_UserVCIDCount = 63` | VCID field width | USLP has 64 VCID values; VCID 63 is reserved for Only Idle Data frames. | CCSDS-732.1 | Seeded |
| TM-061 | `USLP_MAPIDCount = 2^4 = 16` | MAP ID field width | Number of MAP identifiers representable within a USLP virtual channel. | CCSDS-732.1 | Seeded |
| TM-062 | `USLP_FrameOctets = USLP_FrameLengthCount + 1` | Frame Length field | USLP Frame Length count is one fewer than the total transfer-frame octets. | CCSDS-732.1 | Seeded |
| TM-063 | `USLP_MaxFrameOctets = 2^16 = 65536` | Frame Length field width | Maximum USLP transfer-frame size before physical/coding constraints. | CCSDS-732.1 | Seeded |
| TM-064 | `USLP_PrimaryHeaderBaseBits = 4+16+1+6+4+1+16+1+1+2+1+3 = 56` | non-truncated primary header fields before VCF Count | Fixed part of the non-truncated USLP Transfer Frame Primary Header. | CCSDS-732.1 | Seeded |
| TM-065 | `USLP_VCFCountBits = 8 * USLP_VCFCountOctets` | selected VCF Count length code | VCF Count field length for the table-defined 0-to-7-octet count options. | CCSDS-732.1 | Seeded |
| TM-066 | `USLP_PrimaryHeaderOctets = 7 + USLP_VCFCountOctets` | fixed header and VCF Count | Non-truncated USLP primary-header length. | CCSDS-732.1 | Seeded |
| TM-067 | `USLP_VCFCountModulus = 2^(8*USLP_VCFCountOctets)` | VCF Count octets | Wrap modulus when a VCF Count is present. | CCSDS-732.1 | Seeded |
| TM-068 | `USLP_VCFCountNext = (USLP_VCFCount + 1) mod USLP_VCFCountModulus` | VCF Count | Per-VC sequence-controlled or expedited frame counter update. | CCSDS-732.1 | Seeded |
| TM-069 | `USLP_TruncatedPrimaryHeaderBits = 4+16+1+6+4+1 = 32` | first six primary-header fields | USLP truncated primary header contains only fields through the End of Frame Primary Header Flag. | CCSDS-732.1 | Seeded |
| TM-070 | `USLP_TruncatedPrimaryHeaderOctets = 4` | truncated primary header bits | Length of the truncated USLP Transfer Frame Primary Header. | CCSDS-732.1 | Seeded |
| TM-071 | `USLP_OCFOctets = 4 if OCF_Flag else 0` | OCF presence flag | Optional USLP Operational Control Field length. | CCSDS-732.1 | Seeded |
| TM-072 | `USLP_FECFOctets = 2 if FECF_Present else 0` | managed FECF presence | Optional USLP Frame Error Control Field length. | CCSDS-732.1 | Seeded |
| TM-073 | `USLP_TFDFOctets = USLP_FrameOctets - USLP_PrimaryHeaderOctets - InsertZoneOctets - USLP_OCFOctets - USLP_FECFOctets` | frame, primary header, insert zone, OCF, FECF | USLP Transfer Frame Data Field capacity without SDLS security fields. | CCSDS-732.1 | Seeded |
| TM-074 | `USLP_SDLS_TFDFOctets = USLP_FrameOctets - USLP_PrimaryHeaderOctets - SecurityHeaderOctets - InsertZoneOctets - SecurityTrailerOctets - USLP_OCFOctets - USLP_FECFOctets` | SDLS security fields and optional frame fields | USLP Transfer Frame Data Field capacity when SDLS is used. | CCSDS-732.1, CCSDS-355 | Seeded |
| TM-075 | `USLP_TFDFHeaderOctets = 1 + (2 if FHP_LVOP_Present else 0)` | TFDZ construction rule, UPID, optional pointer | USLP TFDF Header length: mandatory 3-bit rule plus 5-bit UPID, with optional 16-bit FHP/LVOP. | CCSDS-732.1 | Seeded |
| TM-076 | `USLP_TFDZOctets = USLP_TFDFOctets - USLP_TFDFHeaderOctets` | TFDF and TFDF Header | Data-zone capacity for user data, packets, SDUs, protocol commands, or idle data. | CCSDS-732.1 | Seeded |
| TM-077 | `USLP_FrameEfficiency = USLP_TFDZOctets / USLP_FrameOctets` | TFDZ and complete frame | USLP data-zone fraction after primary header, optional fields, and TFDF Header. | CCSDS-732.1 | Seeded |
| TM-078 | `USLP_TFDFHeaderOverhead = USLP_TFDFHeaderOctets / USLP_FrameOctets` | TFDF Header and frame | TFDF Header overhead fraction. | CCSDS-732.1 | Seeded |
| TM-079 | `USLP_OCFOverhead = 4 / USLP_FrameOctets` | OCF present | OCF overhead fraction when present. | CCSDS-732.1 | Seeded |
| TM-080 | `USLP_FECFOverhead = 2 / USLP_FrameOctets` | FECF present | FECF overhead fraction when present. | CCSDS-732.1 | Seeded |
| TM-081 | `USLP_PointerAllOnes = 2^16 - 1 = 65535` | First Header / Last Valid Octet Pointer width | All-ones FHP/LVOP value used for the standard's special pointer cases. | CCSDS-732.1 | Seeded |
| TM-082 | `USLP_OID_VCID = 2^6 - 1 = 63` | VCID field width | Reserved VCID for Only Idle Data Transfer Frames. | CCSDS-732.1 | Seeded |
| TM-083 | `USLP_OID_MAPID = 0` | MAP ID field | MAP ID required for OID Transfer Frames. | CCSDS-732.1 | Seeded |
| TM-084 | `USLP_FixedTFDZIdleOctets = USLP_TFDZOctets - ValidDataOctets` | fixed TFDZ and valid data | Idle octets needed to complete a partially filled fixed-length TFDZ. | CCSDS-732.1 | Seeded |
| TM-085 | `USLP_SegmentsNeeded = ceil(SDUOctets / USLP_MaxTFDZOctetsForSAP)` | SDU size and selected SAP TFDZ capacity | First-order number of USLP frames required to transport a segmented SDU. | CCSDS-732.1 | Seeded |

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
| TC-011 | `TC_FrameOctets = FrameLengthCount + 1` | 10-bit TC frame length count | TC primary header length count conversion. | CCSDS-232 | Seeded |
| TC-012 | `TC_DataFieldOctets = TC_FrameOctets - 5 - FECFOctets` | TC primary header and optional FECF | TC transfer-frame data-field capacity without SDLS. | CCSDS-232 | Seeded |
| TC-013 | `TC_MaxDataFieldOctets = 1019 - FECFOctets` | `FECFOctets`: 0 or 2 | TC data field maximum: 1019 octets without FECF, 1017 octets with FECF. | CCSDS-232 | Seeded |
| TC-014 | `SegmentUserDataOctets = TC_DataFieldOctets - 1` | segment header present | User data capacity when the 1-octet TC Segment Header is used. | CCSDS-232 | Seeded |
| TC-015 | `TC_SDLS_DataFieldOctets = TC_FrameOctets - 5 - SegmentHeaderOctets - SecurityHeaderOctets - SecurityTrailerOctets - FECFOctets` | Type-D frame with SDLS | TC data-field capacity when SDLS is used. Type-C frames do not carry SDLS fields. | CCSDS-232, CCSDS-355 | Seeded |
| TC-016 | `FECF = [(X^16 M(X)) + (X^(n-16) L(X))] mod G(X)` | `G(X)=X^16+X^12+X^5+1`; `L(X)=sum(X^i,i=0..15)` | 16-bit FECF CRC used by TM and TC transfer frames when FECF is present. | CCSDS-132, CCSDS-232 | Procedure |
| TC-017 | `BCH_Codewords = ceil(TransferFrameBits / 56)` | 56 information bits per BCH codeword | Number of TC BCH codewords required for transfer frames plus fill. | CCSDS-231 | Seeded |
| TC-018 | `BCH_FillBits = (56 - (TransferFrameBits mod 56)) mod 56` | fill pattern is alternating 0/1 | BCH fill needed to complete an integral number of 56-bit information groups. | CCSDS-231 | Seeded |
| TC-019 | `BCH_CLTU_Bits = 16 + 64 * BCH_Codewords + 64` | start sequence, BCH codewords, tail sequence | Total CLTU size when BCH coding is used. | CCSDS-231 | Seeded |
| TC-020 | `BCH_TransmittedRate = 56 / 64` | information bits per transmitted BCH codeword | Effective transmitted BCH codeword payload fraction including the appended filler bit. | CCSDS-231 | Seeded |
| TC-021 | `LDPC_Codewords = ceil(TransferFrameBits / k_ldpc)` | `k_ldpc`: 64 or 256 | Number of LDPC codewords required for transfer frames plus fill. | CCSDS-231 | Seeded |
| TC-022 | `LDPC_FillBits = (k_ldpc - (TransferFrameBits mod k_ldpc)) mod k_ldpc` | fill before encoding | LDPC fill needed to complete an integral number of information blocks. | CCSDS-231 | Seeded |
| TC-023 | `LDPC_CLTU_Bits = 64 + n_ldpc * LDPC_Codewords + TailBits` | start sequence, LDPC codewords, optional tail | Total CLTU size when LDPC coding is used. `TailBits` is 0 or 128 for LDPC(128,64), and 0 for LDPC(512,256). | CCSDS-231 | Seeded |
| TC-024 | `RepeatedCLTUBits = Repetitions * CLTU_Bits` | repetitions parameter | Radiated CLTU bit count for repeated transfer. | CCSDS-231 | Seeded |
| TC-025 | `CLTU_Duration = CLTU_Bits / ChannelSymbolRate` | channel symbol/bit rate after coding | First-order CLTU transmission duration. | CCSDS-231 | Seeded |
| TC-026 | `COP1_FrameSequenceModulus = 2^8 = 256` | COP-1 Frame Sequence Number width | Wrap modulus for COP-1 `N(S)`, `V(S)`, `V(R)`, `N(R)`, and `NN(R)` arithmetic. | CCSDS-232.1 | Seeded |
| TC-027 | `COP1_NextVS = (V_S + 1) mod 256` | transmitter frame sequence number | FOP-1 increments `V(S)` after inserting it into the `N(S)` field of a Type-AD Transfer Frame. | CCSDS-232.1 | Seeded |
| TC-028 | `COP1_OutstandingADFrames = (V_S - NN_R) mod 256` | `V(S)` and oldest unacknowledged frame | Count of Type-AD frames transmitted ahead of the oldest unacknowledged frame. | CCSDS-232.1 | Seeded |
| TC-029 | `COP1_FOPWindowOpen = COP1_OutstandingADFrames < K` | FOP sliding-window width | FOP-1 may transmit a new Type-AD FDU only while the outstanding sequence distance is within the FOP sliding window. | CCSDS-232.1 | Procedure |
| TC-030 | `1 <= K <= min(PW,255)` | FOP and FARM positive-window widths | Managed-parameter constraint for `FOP_Sliding_Window_Width`; `K` may never exceed 255. | CCSDS-232.1 | Seeded |
| TC-031 | `COP1_T1_Min = t_send_lower + T_max_frame_tx + tau_forward + t_farm_lower + t_clcw_sample + T_clcw_tx + tau_return + t_clcw_extract` | COP-1 timer-delay components | Minimum normal-operation `T1_Initial` budget for one VC, following the standard's listed delay components. | CCSDS-232.1 | Seeded |
| TC-032 | `T_max_frame_tx = MaxCLTUBits / UplinkBitRate` | maximum-length transfer frame with CLTU/coding bits | Serial transmission time term used inside the `T1_Initial` budget. | CCSDS-232.1, CCSDS-231 | Seeded |
| TC-033 | `COP1_RoundTripLightTime = tau_forward + tau_return` | forward and return one-way light times | Propagation part of the COP-1 acknowledgement loop, including relay paths when present. | CCSDS-232.1, BOOK-SMAD | Seeded |
| TC-034 | `COP1_AttemptsRemaining = Transmission_Limit - Transmission_Count` | FOP-1 transmission counters | Remaining transmissions before the first frame on the Sent_Queue reaches the managed transmission limit. | CCSDS-232.1 | Seeded |
| TC-035 | `COP1_RetransmissionAllowed = Transmission_Count < Transmission_Limit` | transmission count and limit | Condition for timer-triggered recovery before an Alert or Suspend action. | CCSDS-232.1 | Procedure |
| TC-036 | `COP1_FirstFrameMaxTransmissions = Transmission_Limit` | managed transmission limit | Maximum number of transmissions of the first frame on the Sent_Queue, including the first transmission. | CCSDS-232.1 | Seeded |
| TC-037 | `COP1_WaitQueueCapacityFDUs = 1` | FOP-1 Wait_Queue | Maximum number of Type-AD FDUs held in the FOP-1 Wait_Queue. | CCSDS-232.1 | Seeded |
| TC-038 | `COP1_GoBackN_RetransmitFrames = SentQueueLength` | unacknowledged Sent_Queue frames | Go-back-N retransmission resends all unacknowledged Type-A Transfer Frames on the VC. | CCSDS-232.1 | Seeded |
| TC-039 | `COP1_FARM_W_Range = even W, 2 <= W <= 254` | retransmission-allowed FARM window | FARM sliding-window total width constraint when Type-AD retransmission is allowed. | CCSDS-232.1 | Seeded |
| TC-040 | `COP1_FARM_PW = COP1_FARM_NW = W/2` | FARM total, positive, and negative windows | Positive and negative FARM window widths for normal retransmission-allowed COP-1 operation. | CCSDS-232.1 | Seeded |
| TC-041 | `COP1_FARM_LockoutSpan = 256 - W` | frame sequence modulus and FARM window | Sequence-number span outside the FARM sliding window. | CCSDS-232.1 | Seeded |
| TC-042 | `COP1_PositiveWindowOffset = (N_S - V_R) mod 256` | received frame sequence and receiver expected sequence | Sequence distance from expected frame into the positive side of the FARM window. | CCSDS-232.1 | Seeded |
| TC-043 | `COP1_InPositiveWindow = 0 <= COP1_PositiveWindowOffset <= PW - 1` | positive-window offset and width | FARM positive-window test; `N(S)=V(R)` is the accept case, larger positive offsets are discarded and set Retransmit. | CCSDS-232.1 | Procedure |
| TC-044 | `COP1_NegativeWindowOffset = (V_R - N_S) mod 256` | receiver expected sequence and received frame sequence | Sequence distance from expected frame into the negative side of the FARM window. | CCSDS-232.1 | Seeded |
| TC-045 | `COP1_InNegativeWindow = 1 <= COP1_NegativeWindowOffset <= NW` | negative-window offset and width | FARM negative-window test for duplicate or late retransmitted Type-AD frames that are discarded without additional action. | CCSDS-232.1 | Procedure |
| TC-046 | `COP1_InLockoutArea = not (COP1_InPositiveWindow or COP1_InNegativeWindow)` | FARM window tests | FARM lockout-area condition; lockout frames are discarded and set the Lockout Flag. | CCSDS-232.1 | Procedure |
| TC-047 | `CLCW_ReportRate = 1 / CLCW_ReportingPeriod` | FARM managed reporting period | CLCW status reporting cadence for COP-1 acknowledgement and flow-control visibility. | CCSDS-232.1 | Seeded |
| TC-048 | `COP1_BD_MaxTransmissions = 1` | Type-BD expedited service | Type-BD frames do not use the COP-1 timer or Transmission_Count and are transmitted once. | CCSDS-232.1 | Seeded |

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
| TRK-024 | `rho_vec = r_sc - r_site` | spacecraft and station position vectors | Topocentric line-of-sight vector from station to spacecraft. | DESCANSO-DSTSE, BOOK-VALLADO | Seeded |
| TRK-025 | `rho = norm(rho_vec)` | `rho_vec` | Geometric station-to-spacecraft range before media/equipment corrections. | DESCANSO-DSTSE, BOOK-VALLADO | Seeded |
| TRK-026 | `rho_dot = dot(rho_vec, v_sc - v_site) / rho` | relative state vectors | Line-of-sight range rate used by Doppler observables. | DESCANSO-DSTSE, BOOK-VALLADO | Seeded |
| TRK-027 | `f_R = f_T * sqrt((1 - beta)/(1 + beta))` | `beta = v_r/c` | Relativistic one-way received frequency for pure line-of-sight motion. | DESCANSO-DSTSE | Seeded |
| TRK-028 | `f_D_oneway ~= -f_T * rho_dot / c` | low-speed line-of-sight motion | First-order one-way Doppler observable. | DESCANSO-DSTSE | Seeded |
| TRK-029 | `f_D_twoway ~= -2 * f_ref * rho_dot / c` | coherent round-trip approximation | First-order two-way Doppler shift for a coherent turnaround when uplink/downlink ratios are collapsed into a reference frequency. | DESCANSO-DSTSE, DSN-810-005 | Seeded |
| TRK-030 | `rho_dot_oneway ~= -c * f_D / f_T` | one-way Doppler | Converts one-way Doppler frequency to line-of-sight velocity. | DESCANSO-DSTSE | Seeded |
| TRK-031 | `rho_dot_twoway ~= -c * f_D / (2 f_ref)` | two-way Doppler | Converts coherent two-way Doppler to line-of-sight velocity under the same first-order approximation. | DESCANSO-DSTSE, DSN-810-005 | Seeded |
| TRK-032 | `sigma_rhodot_oneway = c * sigma_f / f_T` | Doppler frequency standard deviation | Velocity uncertainty propagated from one-way Doppler frequency uncertainty. | DESCANSO-DSTSE | Seeded |
| TRK-033 | `sigma_rhodot_twoway = c * sigma_f / (2 f_ref)` | Doppler frequency standard deviation | Velocity uncertainty propagated from coherent two-way Doppler uncertainty. | DESCANSO-DSTSE | Seeded |
| TRK-034 | `DeltaPhi = 2*pi*(N_end - N_start + n_end - n_start)` | Doppler counter and resolver counts | Phase increment over a Doppler sampling interval. | DESCANSO-DSTSE | Seeded |
| TRK-035 | `f_D_biased_avg = DeltaPhi / (2*pi*T_i)` | sampling interval `T_i` | Average biased Doppler frequency from accumulated phase count. | DESCANSO-DSTSE | Seeded |
| TRK-036 | `f_D_avg = f_D_biased_avg - f_B` | bias frequency `f_B` | Unbiased average Doppler frequency after removing the MDA bias oscillator. | DESCANSO-DSTSE | Seeded |
| TRK-037 | `cycles_D = f_D_avg * T_i` | Doppler average and count time | Integrated Doppler cycle count over the sampling interval. | DESCANSO-DSTSE | Seeded |
| TRK-038 | `sigma_phase_sample = 2*pi*f_D_biased*sigma_Ti` | sample-time error | Phase error from Doppler sampling-epoch uncertainty. | DESCANSO-DSTSE | Seeded |
| TRK-039 | `sigma_phase_quant = 2*pi*f_D_biased*T_clock/sqrt(12)` | resolver clock period | RMS phase quantization error for a uniform resolver time quantization. | DESCANSO-DSTSE | Seeded |
| TRK-040 | `sigma_tau_sine^2 = T_range^2 * N0 / (64 * T_corr * P_ranging)` | sine-wave/filtered ranging | Strong-signal delay-estimate variance for the DSN filtered ranging case. | DESCANSO-DSTSE | Seeded |
| TRK-041 | `sigma_R_oneway = c * sigma_tau` | one-way delay standard deviation | Converts one-way group-delay uncertainty to distance uncertainty. | DESCANSO-DSTSE | Seeded |
| TRK-042 | `sigma_R_twoway = c * sigma_tau / 2` | two-way group-delay standard deviation | Converts round-trip group-delay uncertainty to one-way range uncertainty. | DESCANSO-DSTSE | Seeded |
| TRK-043 | `RTPT = D_meas - BIAS_sc - BIAS_dss - Z_correction` | measured delay and hardware corrections | DSN round-trip propagation time after spacecraft and station delay corrections. | DESCANSO-DSTSE, DSN-810-005 | Seeded |
| TRK-044 | `R_corrected = c * RTPT / 2` | corrected round-trip propagation time | Corrected one-way geometric range from DSN round-trip group delay. | DESCANSO-DSTSE | Seeded |
| TRK-045 | `RangeResidual = RangeObserved - RangeComputed` | observed and modeled range | Orbit-determination residual for range measurements. | DESCANSO-DSTSE, BOOK-VALLADO | Seeded |
| TRK-046 | `DopplerResidual = DopplerObserved - DopplerComputed` | observed and modeled Doppler | Orbit-determination residual for Doppler measurements. | DESCANSO-DSTSE, BOOK-VALLADO | Seeded |
| TRK-047 | `sigma_q = sqrt(sum((dq_dxi * sigma_xi)^2))` | independent error sources | Radiometric design-control-table RSS uncertainty propagation. | DESCANSO-DSTSE | Seeded |
| TRK-048 | `DeltaRange12 = rho_1 - rho_2` | simultaneous station ranges | Differenced range from two tracking stations. | DESCANSO-DSTSE | Seeded |
| TRK-049 | `sin(delta) ~= DeltaRange12 / D_baseline` | small-angle geometry | Declination-like estimate from north-south differenced ranging geometry. | DESCANSO-DSTSE | Seeded |
| TRK-050 | `tau_g = dot(b, s) / c` | baseline and source unit vector | VLBI/DOR geometric group delay. | DESCANSO-DSTSE | Seeded |
| TRK-051 | `DeltaTau_DOR = dot(b, s_sc - s_qso) / c` | spacecraft and quasar directions | Delta-DOR differential delay after alternating spacecraft and quasar observations. | DESCANSO-DSTSE | Seeded |
| TRK-052 | `DelayResolution_VLBI ~= 1 / (2 * B_span)` | spanned bandwidth | First-null scale for wideband group-delay resolution. | DESCANSO-DSTSE | Seeded |
| TRK-053 | `sigma_theta_DDOR ~= c * sigma_DeltaTau / norm(b_perp)` | differential delay uncertainty | Angular uncertainty estimate from projected VLBI baseline. | DESCANSO-DSTSE | Seeded |
| TRK-054 | `Rmax_mono = (P_t*G_t*G_r*lambda^2*sigma / ((4*pi)^3*S_min*L))^(1/4)` | radar link terms | Monostatic radar maximum range for a minimum detectable received power. | BOOK-BALANIS, ITU-P525 | Seeded |
| TRK-055 | `SNR_radar = P_r / (k*T_sys*B_n)` | received radar echo and receiver noise | Radar echo signal-to-noise ratio. | BOOK-BALANIS | Seeded |
| TRK-056 | `RangeResolution_pulse = c*tau_p/2` | pulse width | Basic pulse radar range resolution. | BOOK-BALANIS | Seeded |
| TRK-057 | `RangeResolution_bw = c/(2*B_waveform)` | waveform bandwidth | Bandwidth-limited range resolution for compressed or wideband ranging waveforms. | BOOK-BALANIS, DESCANSO-DSTSE | Seeded |
| TRK-058 | `R_unamb = c/(2*PRF)` | pulse repetition frequency | Monostatic pulsed-radar unambiguous range. | BOOK-BALANIS | Seeded |
| TRK-059 | `DopplerResolution = 1/T_coh` | coherent integration time | Doppler-bin resolution for coherent processing. | BOOK-BALANIS, BOOK-SKLAR | Seeded |
| TRK-060 | `VelocityResolution_mono = lambda/(2*T_coh)` | monostatic radar wavelength | Radial-velocity resolution from Doppler resolution. | BOOK-BALANIS | Seeded |
| TRK-061 | `VelocityUnamb_mono = lambda*PRF/4` | pulse repetition frequency | First-order unambiguous radial velocity for pulsed monostatic radar. | BOOK-BALANIS | Seeded |
| TRK-062 | `rho_L_residual = PCN0_DL / B_L` | residual carrier `P_C/N0`, loop bandwidth | DSN residual-carrier loop signal-to-noise ratio. | DSN-810-005-202 | Seeded |
| TRK-063 | `rho_L_residual_nrz = PCN0_DL / (B_L * (1 + 2*EsN0))` | direct NRZ telemetry on residual carrier | Residual-carrier loop SNR including direct-modulation telemetry sideband loss. | DSN-810-005-202 | Seeded |
| TRK-064 | `rho_L_bpsk = PTN0_DL * S_L / B_L` | total downlink power-to-noise density and squaring loss | Suppressed-carrier BPSK Costas-loop signal-to-noise ratio. | DSN-810-005-202 | Seeded |
| TRK-065 | `S_L = EsN0^2 / (1 + 2*EsN0)` | symbol energy-to-noise density | Suppressed-carrier BPSK Costas-loop squaring loss. | DSN-810-005-202 | Seeded |
| TRK-066 | `rho_L_margin_dB = rho_L_dB - rho_L_min_dB` | `rho_L_min_dB`: mode threshold | Carrier-loop lock margin against DSN recommended minima. | DSN-810-005-202 | Seeded |
| TRK-067 | `sigma_f_oneway = f_C * sigma_V / c` | range-rate standard deviation | Converts one-way Doppler range-rate error to frequency error. | DSN-810-005-202 | Seeded |
| TRK-068 | `sigma_f_twoway = 2*f_C * sigma_V / c` | two-way or three-way range-rate error | Converts coherent two-way/three-way range-rate error to Doppler frequency error. | DSN-810-005-202 | Seeded |
| TRK-069 | `sigma_V_total = sqrt(sigma_VN^2 + sigma_VF^2 + sigma_VS^2)` | thermal, frequency-source, scintillation terms | DSN Doppler range-rate error root-sum-square model. | DSN-810-005-202 | Seeded |
| TRK-070 | `Idata = abs(n_zero - n_one) / (n_zero + n_one)` | telemetry symbol counts | Direct-modulation data imbalance. | DSN-810-005-202 | Seeded |
| TRK-071 | `sigma_VI_oneway ~= c*theta_t*Idata*B_L / (sqrt(24)*pi*f_C)` | direct BPSK imbalance | One-way Doppler error from data imbalance. | DSN-810-005-202 | Seeded |
| TRK-072 | `sigma_VI_twoway ~= c*theta_t*Idata*B_L / (2*sqrt(24)*pi*f_C)` | direct BPSK imbalance | Two-way/three-way Doppler error from data imbalance. | DSN-810-005-202 | Seeded |
| TRK-073 | `sigma_VN_oneway^2 = 2*(c/(2*pi*f_C*T_Doppler))^2 / rho_L` | thermal noise and count time | One-way Doppler range-rate variance from downlink thermal noise. | DSN-810-005-202 | Seeded |
| TRK-074 | `sigma_VF_oneway ~= c*sigma_y(T_Doppler)` | Allan deviation | One-way Doppler range-rate error from frequency-source instability when the loop passes the source phase noise. | DSN-810-005-202 | Seeded |
| TRK-075 | `sigma_phi_total = sqrt(sigma_phiN^2 + sigma_phiF^2 + sigma_phiS^2)` | carrier-loop phase-error terms | Carrier phase-error RSS model; separate from Doppler measurement error. | DSN-810-005-202 | Seeded |
| TRK-076 | `TwoWayDelay_S = 2*RU/f_S` | S-band uplink carrier | DSN range-unit conversion to two-way time delay for S-band uplink. | DSN-810-005-203, DSN-810-005-214 | Seeded |
| TRK-077 | `TwoWayDelay_X = (749/221) * 2*RU/f_X` | X-band uplink carrier | DSN range-unit conversion to two-way time delay for X-band uplink. | DSN-810-005-203, DSN-810-005-214 | Seeded |
| TRK-078 | `TwoWayDelay_K = (2407/221) * 2*RU/f_K` | K-band uplink carrier | DSN range-unit conversion to two-way time delay for K-band uplink. | DSN-810-005-203, DSN-810-005-214 | Seeded |
| TRK-079 | `TwoWayDelay_Ka = (3599/221) * 2*RU/f_Ka` | Ka-band uplink carrier | DSN range-unit conversion to two-way time delay for Ka-band uplink. | DSN-810-005-203, DSN-810-005-214 | Seeded |
| TRK-080 | `f_n = 2^(-n) * f_0` | sequential ranging component number | Sequential-ranging component frequency. | DSN-810-005-203 | Seeded |
| TRK-081 | `AmbiguityRange_n = c / (2*f_n)` | component frequency | A-priori one-way range ambiguity tolerance for a periodic range component. | DSN-810-005-203 | Seeded |
| TRK-082 | `f_RC_seq = 2^(-7-n_RC) * BandFactor * f_uplink` | uplink band and range-clock component | Sequential-ranging range-clock frequency. `BandFactor` is 1, 221/749, 221/2407, or 221/3599 for S/X/K/Ka uplink. | DSN-810-005-203 | Seeded |
| TRK-083 | `SeqCycleTime = T1 + 3 + (n_L - n_RC)*(T2 + 1)` | sequential-ranging timing choices | Cycle time for one sequential-ranging measurement. | DSN-810-005-203 | Seeded |
| TRK-084 | `sigma_rhoN_seq = c / (sqrt(32)*pi*f_RC_seq*sqrt(T1*PRN0))` | range-clock integration and ranging `Pr/N0` | Sequential-ranging thermal-noise range error for sinewave range clock. | DSN-810-005-203 | Seeded |
| TRK-085 | `T1_required_seq = c^2 / (32*pi^2*f_RC_seq^2*PRN0*sigma_rhoN_target^2)` | target thermal range error | Required range-clock integration time for sequential-ranging thermal-noise target. | DSN-810-005-203 | Seeded |
| TRK-086 | `sigma_rho_seq = sqrt(sigma_rhoN_seq^2 + sigma_rhoTCT^2)` | thermal and TCT jitter terms | Sequential-ranging range error including Time Code Translator jitter. | DSN-810-005-203 | Seeded |
| TRK-087 | `sigma_tau_seq = 2*sigma_rho_seq / c` | one-way range error | Sequential-ranging two-way delay standard deviation. | DSN-810-005-203 | Seeded |
| TRK-088 | `N_C = n_L - n_RC` | last and range-clock component numbers | Number of ambiguity-resolving components in sequential ranging. | DSN-810-005-203 | Seeded |
| TRK-089 | `P_acq_seq = (0.5 + 0.5*erf(sqrt(T2*PRN0)))^N_C` | ambiguity component integration | Sequential-ranging probability of acquisition. | DSN-810-005-203 | Seeded |
| TRK-090 | `f_chip_DSN = BandFactor * (A_over_B) * f_uplink` | PN ranging chip-rate factor | DSN PN chip rate for S/X/K/Ka uplinks using the module 214 band factor. | DSN-810-005-214, CCSDS-414.1 | Seeded |
| TRK-091 | `A_over_B = l_CR / (128 * 2^k_CR)` | PN chip-rate selectors | Rational chip-rate factor used by DSN module 214. | DSN-810-005-214, CCSDS-414.1 | Seeded |
| TRK-092 | `f_RC_PN = f_chip_DSN / 2` | PN chip rate | PN range-clock frequency. | DSN-810-005-214, CCSDS-414.1 | Seeded |
| TRK-093 | `c_n(i) = 2*b_n(i) - 1` | binary component code bit | Converts PN component-code bits to bipolar chips. | DSN-810-005-214 | Seeded |
| TRK-094 | `b_n_periodic(i) = b_n(i mod lambda_n)` | finite PN component code | Periodic extension of a component code. | DSN-810-005-214 | Seeded |
| TRK-095 | `L_PN = product(lambda_n) = 1009470` | six DSN/CCSDS component-code lengths | Composite PN range-code period. | DSN-810-005-214, CCSDS-414.1 | Seeded |
| TRK-096 | `PN_AmbiguityResolution = c*L_PN/(4*f_RC_PN)` | PN code period and range clock | One-way ambiguity resolution of the DSN/T4B/T2B PN range code family. | DSN-810-005-214 | Seeded |
| TRK-097 | `sigma_rho_PN = c / (f_RC_PN*A_c*R_1*sqrt(32*pi^2*T_PN*PRN0))` | PN code, correlation loss, integration | PN-ranging thermal-noise range error. | DSN-810-005-214 | Seeded |
| TRK-098 | `sigma_RR = sqrt(sigma_rho_PN^2 + sigma_UL^2)` | downlink and uplink-regeneration terms | Regenerative PN ranging total range error. | DSN-810-005-214 | Seeded |
| TRK-099 | `sigma_UL = c/(4*pi*R_1*f_RC_PN) * sqrt(B_RL/(PRPT_UL*PTN0_UL))` | uplink range-clock tracking loop | Uplink thermal-noise range error term for regenerative PN ranging. | DSN-810-005-214 | Seeded |
| TRK-100 | `P_acq_PN = product(P_n for n=2..6)` | component-code acquisition probabilities | PN range-code probability of acquisition. | DSN-810-005-214 | Seeded |
| TRK-101 | `A_c = abs(sinc(2*Delta_f_RC*T_PN))` | non-coherent range-clock frequency mismatch | PN non-coherent correlation amplitude loss. | DSN-810-005-214 | Seeded |
| TRK-102 | `SNR_post = n_channels * SNR_CH` | comparable VLBI channels | Post-correlation SNR from multiple similar VLBI channels. | DSN-810-005-211 | Seeded |
| TRK-103 | `sigma_path_VLBI = c/(2*pi*SNR_post*BW_obs)` | post-correlation SNR and observation bandwidth | VLBI path-length error from correlation delay measurement. | DSN-810-005-211 | Seeded |
| TRK-104 | `BW_RMS = sqrt(sum((f_CH - f_AVG)^2)/n_channels)` | channel center frequencies | RMS synthesized bandwidth for wideband VLBI. | DSN-810-005-211 | Seeded |
| TRK-105 | `s_DOR(t) = sqrt(2*P_T)*sin(2*pi*f_c*t + theta_d(t) + theta_1*sin(2*pi*f_1*t) + theta_2*sin(2*pi*f_2*t))` | carrier, telemetry, and DOR tones | Delta-DOR downlink signal model with one or two sinusoidal DOR tones. | DSN-810-005-210 | Seeded |
| TRK-106 | `B_span_DOR_single = 2*f_DOR` | one sinusoidal DOR tone | Spanned bandwidth between the lower and upper fundamental harmonics of one DOR tone. | DSN-810-005-210 | Seeded |
| TRK-107 | `DelayAmbiguity_DOR = 1/B_span_DOR` | spanned bandwidth | Differential group-delay ambiguity spacing for DOR tone geometry. | DSN-810-005-210 | Seeded |

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
| SYS-011 | `GeneratedBits = sum_i(SourceRate_i * DutyCycle_i * PlanningPeriod)` | payload/source rates and duty cycles | Data generated over an operations planning period by multiple sources. | BOOK-SMAD, NASA-SST-COMM | Seeded |
| SYS-012 | `UsableContactTime = max(0, ScheduledContactTime - AcquisitionTime - PointingSettleTime - ProtocolSetupTime)` | scheduled window and overhead times | Contact time remaining for useful data transfer after setup overheads. | BOOK-SMAD, NASA-SST-COMM | Seeded |
| SYS-013 | `PassCapacityBits = NetDownlinkRate * UsableContactTime` | net rate and usable pass duration | Useful payload capacity of one contact opportunity. | BOOK-SMAD, NASA-SST-COMM | Seeded |
| SYS-014 | `DownlinkCapacityBits = sum_j(NetDownlinkRate_j * UsableContactTime_j * LinkAvailability_j)` | per-contact rate, duration, and availability | Aggregate downlink capacity across scheduled contacts. | BOOK-SMAD, NASA-SST-COMM | Seeded |
| SYS-015 | `StorageEndBits = StorageStartBits + GeneratedBits - DownlinkedBits` | storage state and data flows | Recorder balance at the end of a planning interval. | BOOK-SMAD | Seeded |
| SYS-016 | `StoragePeakMarginBits = StorageCapacityBits - max_t(StorageUsedBits(t))` | storage capacity and time history | Worst-case recorder margin over a schedule. | BOOK-SMAD | Procedure |
| SYS-017 | `ContactEfficiency = UsableContactTime / ScheduledContactTime` | contact duration and overhead | Fraction of a scheduled contact used for payload transfer. | BOOK-SMAD | Seeded |
| SYS-018 | `PassesRequired = ceil(DataVolume / PassCapacityBits)` | data volume and per-pass capacity | Minimum number of similar contacts needed to downlink a data volume. | BOOK-SMAD | Seeded |
| SYS-019 | `RequiredNetRate = DataVolume / sum_j(UsableContactTime_j)` | data volume and total usable contact time | Net user rate needed over known contact windows. | BOOK-SMAD | Seeded |
| SYS-020 | `RequiredLineRate = RequiredNetRate / LayeredEfficiency` | net rate and protocol/coding efficiency | Physical line rate needed after frame, coding, protocol, and security overhead. | CCSDS SLS, BOOK-SMAD | Seeded |
| SYS-021 | `TargetDownlinkBits = NetDownlinkRate * AvailableContactTime - HeaderBits` | net rate, time, and overhead | Payload bit budget available inside a contact after fixed overhead. | BOOK-SMAD, CCSDS SLS | Seeded |
| SYS-022 | `RequiredCompressionRatio = UncompressedBits / TargetDownlinkBits` | raw volume and contact bit budget | Compression ratio required to fit a data set into an available downlink opportunity. | BOOK-SMAD, CCSDS-121, CCSDS-122, CCSDS-123 | Seeded |
| SYS-023 | `QueueDrainTime = QueueBits / NetDownlinkRate` | queued data and net downlink rate | Time to empty an onboard downlink queue at a fixed useful rate. | BOOK-SMAD | Seeded |
| SYS-024 | `EnergyUsed = sum_i(Power_i * Duration_i)` | power states and durations | Energy consumed by scheduled spacecraft states. | BOOK-SMAD | Seeded |
| SYS-025 | `BatteryDepthOfDischarge = EnergyUsed / BatteryCapacityEnergy` | consumed energy and battery capacity | First-order depth-of-discharge estimate for a schedule segment. | BOOK-SMAD | Seeded |
| SYS-026 | `AverageGeneratedRate = GeneratedBits / PlanningPeriod` | generated volume and period | Average data-production rate over a planning interval. | BOOK-SMAD | Seeded |
| SYS-027 | `RecorderTurnoverTime = StorageCapacityBits / AverageGeneratedRate` | storage capacity and generation rate | Time to fill the recorder if no downlink occurs. | BOOK-SMAD | Seeded |
| SYS-028 | `ContactUtilization = DataVolume / DownlinkCapacityBits` | demanded volume and scheduled capacity | Fraction of scheduled downlink capacity consumed by a demand set. | BOOK-SMAD | Seeded |
| SYS-029 | `ScienceReturnFraction = DownlinkedScienceBits / GeneratedScienceBits` | science data generated and returned | System-level science return metric for operations trade studies. | BOOK-SMAD, NASA-SST-COMM | Seeded |
| SYS-030 | `CommandRoundTripLightTime = 2*Range/c` | range and speed of light | First-order two-way light-time relevant to command-response operations. | DSN-810-005, BOOK-SMAD | Seeded |

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
| ORB-017 | `epsilon = v^2/2 - mu/r = -mu/(2*a)` | speed, radius, gravitational parameter | Specific orbital energy for a two-body conic orbit. | BOOK-VALLADO, BOOK-BATE | Seeded |
| ORB-018 | `v = sqrt(mu*(2/r - 1/a))` | radius and semi-major axis | Vis-viva speed for elliptic, parabolic, or hyperbolic conic motion. | BOOK-VALLADO, BOOK-BATE | Seeded |
| ORB-019 | `h_vec = r_vec x v_vec; h = norm(h_vec)` | inertial position and velocity | Specific angular momentum vector and magnitude. | BOOK-VALLADO, BOOK-BATE | Seeded |
| ORB-020 | `e_vec = (v_vec x h_vec)/mu - r_vec/r` | state vector and angular momentum | Eccentricity vector from Cartesian state. | BOOK-VALLADO, BOOK-BATE | Seeded |
| ORB-021 | `p = h^2/mu = a*(1-e^2)` | angular momentum, semi-major axis, eccentricity | Semilatus rectum relation for a Keplerian conic. | BOOK-VALLADO, BOOK-BATE | Seeded |
| ORB-022 | `r_orbit = p/(1 + e*cos(nu))` | semilatus rectum, eccentricity, true anomaly | Radius as a function of true anomaly. | BOOK-VALLADO, BOOK-BATE | Seeded |
| ORB-023 | `r_p = a*(1-e); r_a = a*(1+e)` | semi-major axis and eccentricity | Perigee/periapsis and apogee/apoapsis radii for an ellipse. | BOOK-VALLADO, BOOK-BATE | Seeded |
| ORB-024 | `N_phi = a_E / sqrt(1 - e_E^2*sin(phi)^2)` | ellipsoid semi-major axis, eccentricity, latitude | Prime vertical radius of curvature for WGS-84-style geodetic coordinates. | IERS, NAVIPEDIA | Seeded |
| ORB-025 | `x_site=(N_phi+h_site)*cos(phi)*cos(lon); y_site=(N_phi+h_site)*cos(phi)*sin(lon); z_site=(N_phi*(1-e_E^2)+h_site)*sin(phi)` | geodetic latitude, longitude, height | Convert a ground station from geodetic coordinates to Earth-fixed Cartesian coordinates. | IERS, NAVIPEDIA | Seeded |
| ORB-026 | `rho_ecef = r_sat_ecef - r_site_ecef` | satellite and station ECEF positions | Earth-fixed topocentric relative-position vector before ENU rotation. | BOOK-VALLADO, NAVIPEDIA | Seeded |
| ORB-027 | `east=-sin(lon)*dx+cos(lon)*dy; north=-sin(phi)*cos(lon)*dx-sin(phi)*sin(lon)*dy+cos(phi)*dz; up=cos(phi)*cos(lon)*dx+cos(phi)*sin(lon)*dy+sin(phi)*dz` | ECEF relative vector and station geodetic coordinates | Transform a station-centered ECEF relative vector into local ENU components. | NAVIPEDIA, IERS | Seeded |
| ORB-028 | `el = atan2(up, sqrt(east^2+north^2)); az = atan2(east,north); rho = sqrt(east^2+north^2+up^2)` | local ENU vector | Horizon coordinates used by antenna pointing and access checks. | BOOK-VALLADO, NAVIPEDIA | Seeded |
| ORB-029 | `r_ecef ~= R3(theta_GMST) * r_eci` | inertial vector and Earth rotation angle | First-order ECI-to-ECEF rotation; high-precision products require IERS precession, nutation, polar motion, and Earth-orientation parameters. | IERS, CELESTRAK | Procedure |
| ORB-030 | `cos(psi_Emin) = (R_e/r)*cos(E_min)^2 + sin(E_min)*sqrt(1 - (R_e/r)^2*cos(E_min)^2)` | orbit radius and minimum elevation | Spherical-Earth central angle to the access boundary for a minimum elevation mask. | BOOK-SMAD, BOOK-VALLADO | Seeded |
| ORB-031 | `rho_Emin = sqrt(r^2 - R_e^2*cos(E_min)^2) - R_e*sin(E_min)` | orbit radius and minimum elevation | Slant range at the minimum-elevation access boundary. | BOOK-SMAD, BOOK-VALLADO | Seeded |
| ORB-032 | `coverage_radius = R_e * psi_Emin` | Earth radius and access half-angle | Ground footprint radius for a circular-orbit spherical-Earth approximation. | BOOK-SMAD | Seeded |
| ORB-033 | `AccessFlag = (el >= E_min) and (rho <= RangeMax)` | elevation mask and range limit | Binary visibility/access condition for schedule filtering. | BOOK-SMAD, BOOK-VALLADO | Procedure |
| ORB-034 | `PassDurationApprox = 2*psi_Emin / abs(omega_rel)` | access half-angle and apparent angular rate | First-order pass-duration estimate before full orbit propagation. | BOOK-SMAD | Procedure |
| ORB-035 | `GroundTrackShiftPerOrbit = omega_E * T` | Earth rotation rate and orbital period | Longitude shift of Earth under the orbit between consecutive revolutions, before nodal regression corrections. | BOOK-VALLADO, BOOK-SMAD | Seeded |
| ORB-036 | `lat_ss = asin(sin(i)*sin(u))` | inclination and argument of latitude | Subsatellite latitude for a circular orbit in a simple inertial-to-rotating geometry. | BOOK-VALLADO | Seeded |
| ORB-037 | `lon_ss = atan2(cos(i)*sin(u), cos(u)) - theta_GMST` | inclination, argument of latitude, Earth rotation | Subsatellite longitude for a circular orbit before longitude normalization and perturbation corrections. | BOOK-VALLADO | Procedure |

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
| COMP-015 | `InputBlocks = ceil(InputSamples / J)` | input sample count and CCSDS 121 block size | Number of `J`-sample input blocks; padding is used when the input sequence is not an integer number of blocks. | CCSDS-121 | Seeded |
| COMP-016 | `PaddingSamples = (J - (InputSamples mod J)) mod J` | input sample count and block size | Samples appended to align a CCSDS 121 input sequence to full blocks; zero-valued preprocessed padding minimizes coded output. | CCSDS-121 | Seeded |
| COMP-017 | `ReferenceSampleCount = ceil(InputBlocks / r)` | input blocks and reference interval | Count of uncoded reference samples when predictive preprocessing requires one reference at the first block of each `r`-block interval. | CCSDS-121 | Seeded |
| COMP-018 | `ReferenceSampleBits = ReferenceSampleCount * n` | reference samples and sample resolution | Output bit budget for uncoded CCSDS 121 reference samples placed in the corresponding CDS. | CCSDS-121 | Seeded |
| COMP-019 | `xhat_i = x_i if reference sample else x_(i-1)` | unit-delay predictor state | CCSDS 121 unit-delay predictor; the first sample in a reference interval predicts itself. | CCSDS-121 | Procedure |
| COMP-020 | `Delta_i = x_i - xhat_i` | sample and predicted sample | Prediction error entering the CCSDS 121 prediction-error mapper. | CCSDS-121 | Seeded |
| COMP-021 | `theta_i = min(xhat_i - x_min, x_max - xhat_i)` | predictor value and sample range | CCSDS 121 mapper threshold for the allowed prediction-error range. | CCSDS-121 | Seeded |
| COMP-022 | `delta_i = 2*Delta_i if 0 <= Delta_i <= theta_i; -2*Delta_i - 1 if -theta_i <= Delta_i < 0; theta_i + abs(Delta_i) otherwise` | prediction error and mapper threshold | Nonnegative mapped prediction error for CCSDS 121 entropy coding. | CCSDS-121 | Procedure |
| COMP-023 | `x_min = 0; x_max = 2^n - 1` | unsigned sample resolution | Unsigned CCSDS 121 `n`-bit sample range. | CCSDS-121 | Seeded |
| COMP-024 | `x_min = -2^(n-1); x_max = 2^(n-1) - 1` | signed sample resolution | Signed CCSDS 121 `n`-bit sample range. | CCSDS-121 | Seeded |
| COMP-025 | `FSCodewordBits(v) = v + 1` | fundamental-sequence value | Fundamental Sequence codeword length: `v` zeros followed by one `1`. | CCSDS-121 | Seeded |
| COMP-026 | `SplitMSB_i = floor(delta_i / 2^k); SplitLSB_i = delta_i mod 2^k` | mapped sample and split parameter | CCSDS 121 split-sample decomposition; the MSB value is FS-coded and the `k` LSBs are sent uncoded. | CCSDS-121 | Seeded |
| COMP-027 | `SplitUncodedBits = k * EncodedSamplesInBlock` | split parameter and coded sample count | Uncoded LSB field length for a split-sample CDS; use `J-1` when a reference sample occupies the first sample. | CCSDS-121 | Seeded |
| COMP-028 | `gamma_j = (delta_(2*j-1)+delta_(2*j))*(delta_(2*j-1)+delta_(2*j)+1)/2 + delta_(2*j)` | paired mapped samples | CCSDS 121 second-extension transform for each pair of preprocessed samples; use `delta_1=0` when the first block sample is a reference sample. | CCSDS-121 | Seeded |
| COMP-029 | `ZeroBlockSegments = ceil(BlocksInReferenceInterval / 64)` | blocks in a reference interval | CCSDS 121 zero-block option partitions each reference interval into 64-block segments, except possibly the last segment. | CCSDS-121 | Seeded |
| COMP-030 | `NoCompressionCDSBits = IDBits + J*n` | ID field, block size, sample resolution | Coded Data Set size when CCSDS 121 no-compression is selected for a whole preprocessed block. | CCSDS-121 | Seeded |
| COMP-031 | `SelectedCodeOption = argmin_option(EncodedBits_option + IDBits_option)` | candidate option bit lengths | CCSDS 121 single-block code-option selection; zero-block has priority for all-zero runs and tie-breaking prefers no-compression, then second-extension, then smallest `k`. | CCSDS-121 | Procedure |
| COMP-032 | `ImageSamples3D = N_x * N_y * N_z` | cross-track, frame/line, and spectral-band counts | Sample count for a multispectral or hyperspectral image cube. | CCSDS-123, CCSDS-120.2 | Seeded |
| COMP-033 | `ImageRawBits3D = N_x * N_y * N_z * D` | image dimensions and bit depth | Raw data volume for a `D`-bit multispectral/hyperspectral image cube. | CCSDS-123, CCSDS-120.2 | Seeded |
| COMP-034 | `s_hat_z(t) = floor(s_tilde_z(t) / 2)` | scaled predicted sample | CCSDS 123 predicted sample derived from the integer scaled predicted sample; `s_tilde` has one extra bit of resolution. | CCSDS-123, CCSDS-120.2 | Seeded |
| COMP-035 | `PredictionErrorScaled_z(t) = 2*s_z(t) - s_tilde_z(t)` | current sample and scaled predictor | Scaled prediction error used by the CCSDS 123 predictor explanation. | CCSDS-123, CCSDS-120.2 | Seeded |
| COMP-036 | `QuantizerStep_z(t) = 2*m_z(t) + 1` | per-sample maximum error value | Uniform near-lossless quantizer step size that guarantees reconstruction error no larger than `m_z(t)`. | CCSDS-123, CCSDS-120.2 | Seeded |
| COMP-037 | `m_z(t) = a_z` | band-specific absolute error limit | CCSDS 123 absolute-error-limit mode for near-lossless compression. | CCSDS-123, CCSDS-120.2 | Seeded |
| COMP-038 | `m_z(t) = 0` | lossless mode | Lossless CCSDS 123 setting for every band and sample. | CCSDS-123, CCSDS-120.2 | Seeded |
| COMP-039 | `ErrorLimitUpdatePeriodFrames = 2^u` | error-limit update exponent | Periodic error-limit update interval for CCSDS 123 near-lossless compression. | CCSDS-123, CCSDS-120.2 | Seeded |
| COMP-040 | `CompressedImageRate = CompressedImageBits / AcquisitionDuration` | compressed image size and acquisition time | Payload image data rate after compression for storage/downlink sizing. | CCSDS-122, CCSDS-123, BOOK-SMAD | Seeded |

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
| PROTO-013 | `PLTU_Bits = 24 + TransferFrameBits + 32` | Proximity ASM, Transfer Frame, CRC-32 | Proximity-1 Link Transmission Unit size. The 24-bit ASM pattern is `FAF320`; the trailer is a 32-bit CRC. | CCSDS-211.2 | Seeded |
| PROTO-014 | `PLTU_OverheadBits = ASM_Bits + CRC32_Bits = 56` | Proximity ASM and CRC-32 fields | Fixed PLTU synchronization and CRC overhead before channel coding. | CCSDS-211.2 | Seeded |
| PROTO-015 | `PLTU_Efficiency = TransferFrameBits / PLTU_Bits` | transfer-frame and PLTU sizes | Transfer-frame fraction of a Proximity-1 PLTU. | CCSDS-211.2 | Seeded |
| PROTO-016 | `ProxIdleRepeats = ceil(ProxIdleBits / 32)` | idle/acquisition/tail idle bits | Repetitions of the Proximity-1 idle PN sequence `352EF853`, which is 32 bits long. | CCSDS-211.2 | Seeded |
| PROTO-017 | `ProxAcquisitionBits = ceil(Acquisition_Idle_Duration * Rd)` | acquisition-idle duration and data rate | Acquisition sequence bit budget before the first PLTU. | CCSDS-211.2 | Seeded |
| PROTO-018 | `ProxTailBits = ceil(Tail_Idle_Duration * Rd)` | tail-idle duration and data rate | Tail sequence bit budget after the last PLTU. | CCSDS-211.2 | Seeded |
| PROTO-019 | `ProxRdError = min(abs(Rd - Rd_allowed_i))` | selected data rate and allowed-rate table | Validation distance to the Proximity-1 discrete `Rd` set: 1000 through 2048000 bit/s by powers of two. LDPC true rates require the data-link annex table. | CCSDS-211.2 | Seeded |
| PROTO-020 | `R_cs_uncoded = Rd` | Proximity-1 uncoded option | Coded-symbol stream rate for the no-coding option. | CCSDS-211.2 | Seeded |
| PROTO-021 | `R_cs_conv = 2*Rd; ProxConvSymbols = 2*InputBits` | Proximity-1 rate-1/2 convolutional code | Coded-symbol rate and symbol expansion for the non-punctured constraint-length-7 convolutional code. | CCSDS-211.2 | Seeded |
| PROTO-022 | `ProxLDPCBlocks = ceil(InputBits / 1024)` | PLTU plus idle bitstream | Number of fixed-length Proximity-1 LDPC message blocks after PLTU construction and idle insertion. | CCSDS-211.2 | Seeded |
| PROTO-023 | `ProxLDPCCodewordBits = 2048; ProxLDPCCodeRate = 1024/2048` | LDPC message block and codeword size | Proximity-1 LDPC uses the CCSDS rate-1/2 `(n=2048,k=1024)` code. | CCSDS-211.2 | Seeded |
| PROTO-024 | `ProxLDPCOutputBits = ProxLDPCBlocks * (64 + 2048)` | CSM plus LDPC codeword | Coded stream size when a 64-bit Codeword Sync Marker immediately precedes each LDPC codeword. CSM pattern is `034776C7272895B0`. | CCSDS-211.2 | Seeded |
| PROTO-025 | `ProxLDPCEfficiency = 1024 / (2048 + 64)` | LDPC message, codeword, and CSM bits | Physical stream efficiency of Proximity-1 LDPC before PLTU/idle/frame-layer overhead. | CCSDS-211.2 | Seeded |
| PROTO-026 | `RandomizedCodewordBit_i = LDPCCodewordBit_i xor PN_(i mod 255)` | LDPC codeword and pseudo-random sequence | Proximity-1 LDPC codeword randomization; the CSM itself is not randomized and the all-ones generator resets each codeword. | CCSDS-211.2 | Procedure |
| PROTO-027 | `ProxV3HeaderBits = 2+1+1+2+10+1+3+1+11+8 = 40` | Version-3 transfer-frame header fields | Sum of the mandatory Proximity-1 Version-3 Transfer Frame header fields: TFVN, QoS, PDU type, DFC ID, SCID, PCID, Port ID, source/destination, frame length, and frame sequence number. | CCSDS-211.0, ISO-22663 | Seeded |
| PROTO-028 | `ProxV3HeaderOctets = ProxV3HeaderBits / 8 = 5` | Version-3 transfer-frame header bits | Fixed Version-3 Transfer Frame header length. | CCSDS-211.0, ISO-22663 | Seeded |
| PROTO-029 | `ProxV3DataFieldOctets = ProxV3FrameOctets - 5` | complete frame and fixed header | Proximity-1 Version-3 Transfer Frame data-field capacity for a selected frame size. | CCSDS-211.0, ISO-22663 | Seeded |
| PROTO-030 | `ProxV3MaxDataFieldOctets = 2048 - 5 = 2043` | maximum Version-3 frame length | Maximum Version-3 Transfer Frame data-field capacity before PLTU ASM/CRC and channel-coding overhead. | CCSDS-211.0, ISO-22663 | Seeded |
| PROTO-031 | `ProxV3FrameEfficiency = ProxV3DataFieldOctets / ProxV3FrameOctets` | data field and complete transfer frame | Data-field fraction of a Proximity-1 Version-3 Transfer Frame. | CCSDS-211.0, ISO-22663 | Seeded |
| PROTO-032 | `ProxV3TotalWithPLTUOverheadBits = 8*ProxV3FrameOctets + 56` | Version-3 frame and PLTU overhead | Transfer frame plus Proximity-1 ASM and CRC-32 overhead before optional channel coding. | CCSDS-211.0, CCSDS-211.2 | Seeded |
| PROTO-033 | `ProxV3NetFrameEfficiency = 8*ProxV3DataFieldOctets / ProxV3TotalWithPLTUOverheadBits` | data field, transfer frame, ASM, CRC | Useful data-field fraction after fixed Version-3 header plus PLTU ASM/CRC overhead, before idle and coding. | CCSDS-211.0, CCSDS-211.2 | Seeded |
| PROTO-034 | `ProxFrameSequenceModulus = 2^8 = 256` | frame sequence number width | Wrap modulus for the 8-bit Proximity-1 frame sequence number. | CCSDS-211.0, ISO-22663 | Seeded |
| PROTO-035 | `ProxSCIDCount = 2^10; ProxPortCount = 2^3; ProxPCIDCount = 2` | SCID, Port ID, PCID field widths | Addressing/multiplexing cardinalities implied by the Version-3 header field widths. | CCSDS-211.0, ISO-22663 | Seeded |

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
