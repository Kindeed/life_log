# Variable Glossary

This glossary defines shared symbols for the formula knowledge base. App implementation should map these symbols to stable field IDs, default units, and validation constraints.

## Constants

| Symbol | Meaning | Default value | Unit | Notes |
| --- | --- | --- | --- | --- |
| `c` | speed of light in vacuum | `299792458` | m/s | Use exact SI value. |
| `k` | Boltzmann constant | `1.380649e-23` | J/K | In dB link budgets, `-10log10(k) ~= 228.6`. |
| `T0` | standard noise temperature | `290` | K | Used for noise figure to temperature conversion. |
| `h` | Planck constant | `6.62607015e-34` | J*s | Optical photon calculations. |
| `pi` | circle constant | math constant | unitless | Use Dart `math.pi`. |

## RF and Antenna

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `f` / `f_c` | `carrier_frequency` | carrier frequency | Hz, kHz, MHz, GHz |
| `lambda` | `wavelength` | wavelength | m |
| `D` | `antenna_diameter` | circular aperture diameter | m |
| `eta` | `aperture_efficiency` | aperture efficiency | ratio, percent |
| `A` | `physical_aperture` | physical aperture area | m^2 |
| `A_p` | `geometrical_aperture` | geometrical aperture area used in aperture-gain formulas | m^2 |
| `A_e` | `effective_aperture` | effective receiving aperture | m^2 |
| `G` | `antenna_gain_linear` | antenna gain linear | ratio |
| `G_m` | `boresight_gain` | nominal peak or boresight antenna gain | dBi |
| `G_dBi` | `antenna_gain` | antenna gain relative to isotropic | dBi |
| `G(theta,phi)` | `antenna_pattern_gain` | antenna gain pattern at off-boresight cone/clock angle | dBi |
| `G/T` | `g_over_t` | gain-to-noise-temperature ratio | dB/K |
| `P_tx` | `tx_power` | transmitter RF output power | W, dBW, dBm |
| `L_tx` | `tx_loss` | transmitter-side feed/network loss | dB |
| `EIRP` | `eirp` | effective isotropic radiated power | dBW, dBm |
| `ERP` | `erp` | effective radiated power relative to dipole | dBW, dBm |
| `VSWR` | `vswr` | voltage standing wave ratio | ratio |
| `Gamma` | `reflection_coefficient` | reflection coefficient magnitude | ratio |
| `theta_3dB` | `beamwidth_3db` | half-power beamwidth | deg, rad |
| `theta_error` | `pointing_error` | pointing offset from boresight | deg, rad |
| `theta` / `phi` | `pattern_cone_clock_angle` | antenna pattern cone and clock angles | deg, rad |
| `eta_ap` | `aperture_efficiency_total` | total aperture efficiency | ratio |
| `eta_rad` | `radiation_efficiency` | radiation/ohmic efficiency component | ratio |
| `eta_taper` | `aperture_taper_efficiency` | aperture illumination taper efficiency | ratio |
| `eta_spillover` | `spillover_efficiency` | feed spillover efficiency | ratio |
| `eta_surface` | `surface_error_efficiency` | reflector surface rms error efficiency | ratio |
| `eta_blockage` | `aperture_blockage_efficiency` | feed/subreflector blockage efficiency | ratio |
| `eta_strut` | `strut_blockage_efficiency` | support-strut blockage efficiency | ratio |
| `eta_squint` | `squint_efficiency` | lateral feed-displacement squint efficiency | ratio |
| `eta_astigmatism` | `astigmatism_efficiency` | axial feed-displacement astigmatism efficiency | ratio |
| `K_surf` | `surface_error_geometry_factor` | surface-error correction factor depending on reflector geometry | unitless |
| `sigma_surface` | `surface_rms_error` | reflector surface rms error | m, mm |
| `PointingLoss` | `pointing_loss` | gain degradation from off-boresight pointing | dB |
| `MeanPointingLoss` | `mean_pointing_loss` | expected pointing loss over pointing-error distribution | dB |
| `eta_pol` | `polarization_efficiency` | delivered power divided by polarization-matched available power | ratio |
| `AR` | `axial_ratio` | polarization ellipse axial ratio | ratio |
| `D_lambda` | `electrical_aperture_size` | antenna aperture diameter expressed in wavelengths | ratio |
| `phi_deg` | `off_axis_angle_deg` | off-axis antenna angle for reference pattern checks | deg |
| `phi_min` | `minimum_reference_pattern_angle` | lower off-axis-angle bound for ITU reference pattern branch | deg |
| `G_ref` | `reference_pattern_gain` | ITU reference radiation-pattern gain envelope | dBi |
| `G_sidelobe_objective` | `sidelobe_design_objective_gain` | ITU side-lobe design objective gain envelope | dBi |
| `D_e` | `equivalent_circular_diameter` | circular-equivalent diameter for asymmetric apertures | m |
| `A_aperture` | `asymmetric_aperture_area` | physical aperture area for non-circular antennas | m^2 |
| `U(theta,phi)` | `radiation_intensity` | radiated power per unit solid angle in a direction | W/sr |
| `U_max` | `maximum_radiation_intensity` | peak radiation intensity | W/sr |
| `P_rad` | `radiated_power` | total power radiated by antenna | W |
| `D_0` | `directivity` | maximum directivity relative to isotropic radiator | ratio, dBi |
| `Omega_A` | `beam_solid_angle` | antenna beam solid angle | sr |
| `P_n(theta,phi)` | `normalized_power_pattern` | normalized antenna power pattern | ratio |
| `theta_HP_deg` / `phi_HP_deg` | `orthogonal_half_power_beamwidths` | half-power beamwidths in two principal planes | deg |
| `theta_FNBW` | `first_null_beamwidth` | angular distance between first pattern nulls | deg, rad |
| `D_max` | `maximum_antenna_dimension` | largest physical dimension of an antenna or test article | m |
| `R_ff` | `far_field_distance` | minimum far-field measurement or link distance | m |
| `PLF` | `polarization_loss_factor` | polarization match as a linear power factor | ratio |
| `rho_wave` / `rho_ant` | `polarization_unit_vectors` | incident wave and antenna polarization unit vectors | unitless |
| `AF(theta)` | `array_factor` | array factor as a function of observation angle | complex ratio |
| `AF_norm` | `normalized_array_factor` | normalized array-factor magnitude | ratio |
| `w_n` | `array_element_weight` | complex excitation weight of element n | complex ratio |
| `N_elem` | `array_element_count` | number of antenna elements in an array | count |
| `k0` | `free_space_phase_constant` | phase constant `2*pi/lambda` | rad/m |
| `d_elem` | `array_element_spacing` | distance between adjacent elements | m |
| `beta_phase` | `array_progressive_phase` | progressive excitation phase between array elements | rad |
| `psi` | `array_phase_variable` | array phase variable combining angle, spacing, and progressive phase | rad |

## Noise and Receiver

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `T_sys` | `system_temp` | system noise temperature | K |
| `T_ant` | `antenna_noise_temp` | antenna noise temperature | K |
| `T_rx` | `receiver_noise_temp` | receiver equivalent noise temperature | K |
| `T_e` | `equivalent_noise_temp` | equivalent noise temperature | K |
| `NF` | `noise_figure` | noise figure | dB |
| `F` | `noise_factor` | linear noise factor | ratio |
| `N0` | `noise_density` | noise spectral density | dBW/Hz |
| `B` / `B_n` | `noise_bandwidth` | receiver noise bandwidth | Hz |

## Link Budget

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `R` / `d` | `range` / `distance` | link range | m, km |
| `L_fs` | `fspl` | free-space path loss | dB |
| `L_bf` | `free_space_basic_transmission_loss` | ITU-R free-space basic transmission loss | dB |
| `L_total` | `total_loss` | total path and implementation loss | dB |
| `A_rain` | `rain_attenuation` | rain attenuation | dB |
| `A_gas` | `gas_attenuation` | atmospheric gas attenuation | dB |
| `A_cloud` | `cloud_attenuation` | cloud/fog attenuation | dB |
| `A_scint` | `scintillation_loss` | scintillation fade allowance | dB |
| `A_R` | `rain_attenuation_probability` | rain attenuation exceeded for a fixed probability | dB |
| `A_G` | `gaseous_attenuation_probability` | gaseous attenuation for a fixed probability | dB |
| `A_C` | `cloud_attenuation_probability` | cloud attenuation for a fixed probability | dB |
| `A_S` | `scintillation_attenuation_probability` | tropospheric scintillation attenuation for a fixed probability | dB |
| `A_T` | `total_atmospheric_attenuation_probability` | total atmospheric attenuation combining simultaneous impairments | dB |
| `A_0_01` | `rain_attenuation_0_01_percent` | rain attenuation exceeded for 0.01% of an average year | dB |
| `A_rain_p` | `rain_attenuation_percent_p` | rain attenuation exceeded for `p_exceed` percent of an average year | dB |
| `A_zen` | `zenith_atmospheric_attenuation` | atmospheric attenuation at zenith | dB |
| `A_atm` | `atmospheric_attenuation` | atmosphere attenuation at an elevation angle | dB |
| `AM` | `air_mass_factor` | flat-Earth air mass scaling factor | unitless |
| `L_atm` | `atmospheric_loss_factor` | linear atmospheric loss factor | ratio |
| `gamma_R` | `rain_specific_attenuation` | rain specific attenuation | dB/km |
| `R_p` | `rain_rate_percent_p` | rain rate exceeded for p% of an average year | mm/h |
| `R_0_01` | `rain_rate_0_01_percent` | one-minute rain rate exceeded for 0.01% of an average year | mm/h |
| `k_rain` | `rain_specific_attenuation_k` | ITU-R P.838 rain coefficient adjusted for path and polarization | unitless |
| `alpha_rain` | `rain_specific_attenuation_alpha` | ITU-R P.838 rain exponent adjusted for path and polarization | unitless |
| `k_H` / `k_V` | `rain_k_horizontal_vertical` | ITU-R P.838 horizontal/vertical rain coefficients | unitless |
| `alpha_H` / `alpha_V` | `rain_alpha_horizontal_vertical` | ITU-R P.838 horizontal/vertical rain exponents | unitless |
| `tau` | `polarization_tilt_angle` | polarization tilt angle relative to horizontal; 45 deg for circular polarization | deg, rad |
| `theta_elev` | `path_elevation_angle` | Earth-space path elevation angle | deg, rad |
| `theta_elev_deg` | `path_elevation_angle_deg` | path elevation angle in degrees for ITU-R P.618 exponential terms | deg |
| `h_0` | `zero_c_isotherm_height` | annual mean 0 deg C isotherm height above mean sea level | km |
| `h_R` | `rain_height` | annual mean rain height above mean sea level | km |
| `h_s` | `station_height_amsl` | earth station height above mean sea level | km |
| `L_s` | `rain_slant_path_length` | slant path length below rain height | km |
| `L_G` | `rain_horizontal_projection` | horizontal projection of the rain slant path | km |
| `L_R` | `rain_adjusted_slant_path` | adjusted slant path used by vertical factor | km |
| `L_E` | `rain_effective_path_length` | effective rain path length | km |
| `r_0_01` | `rain_horizontal_reduction_factor` | P.618 horizontal reduction factor for 0.01% | ratio |
| `v_0_01` | `rain_vertical_adjustment_factor` | P.618 vertical adjustment factor for 0.01% | ratio |
| `zeta` | `rain_auxiliary_angle` | auxiliary angle for vertical adjustment branch | deg, rad |
| `chi` | `rain_latitude_adjustment` | P.618 latitude adjustment term | deg |
| `phi_lat` | `station_latitude` | earth station latitude | deg |
| `beta` | `rain_probability_extrapolation_beta` | P.618 probability extrapolation branch value | unitless |
| `p_exceed` | `exceedance_probability_percent` | percentage of average year that attenuation is exceeded | percent |
| `R_eff` | `effective_earth_radius` | effective Earth radius used by P.618 rain geometry, 8500 km | km |
| `gamma_o` | `oxygen_specific_attenuation` | oxygen/dry-air specific attenuation | dB/km |
| `gamma_w` | `water_vapour_specific_attenuation` | water-vapour specific attenuation | dB/km |
| `gamma_gas` | `gas_specific_attenuation` | total gaseous specific attenuation | dB/km |
| `Npp_oxygen` | `oxygen_imaginary_refractivity` | imaginary part of oxygen/dry-air complex refractivity | unitless |
| `Npp_water` | `water_vapour_imaginary_refractivity` | imaginary part of water-vapour complex refractivity | unitless |
| `Npp_D` | `dry_continuum_imaginary_refractivity` | dry continuum contribution in P.676 | unitless |
| `rho_wv` | `water_vapour_density` | water vapour density | g/m^3 |
| `rho_ws` | `surface_water_vapour_density` | surface water vapour density | g/m^3 |
| `e_wv` | `water_vapour_partial_pressure` | water vapour partial pressure | hPa |
| `p_dry` | `dry_air_pressure` | dry-air pressure | hPa |
| `P_s` | `surface_barometric_pressure` | surface total barometric pressure | hPa |
| `T_K` | `air_temperature_k` | air temperature | K |
| `T_surface` | `surface_temperature_k` | surface temperature | K |
| `theta_300` | `temperature_ratio_300_over_t` | P.676 temperature ratio, `300/T_K` | ratio |
| `S_i` | `spectral_line_strength` | oxygen or water-vapour line strength | varies |
| `F_i` | `spectral_line_shape_factor` | oxygen or water-vapour line-shape factor | 1/GHz |
| `f_i` | `spectral_line_frequency` | line centre frequency | GHz |
| `Delta_f` | `spectral_line_width` | pressure/Doppler broadened line width | GHz |
| `delta_i` | `oxygen_line_interference_factor` | line interference correction factor | unitless |
| `a_i` | `gas_layer_path_length` | path length through atmospheric layer i | km |
| `gamma_i` | `layer_specific_attenuation` | specific attenuation in atmospheric layer i | dB/km |
| `A_o` | `oxygen_slant_attenuation` | slant path gaseous attenuation attributable to oxygen | dB |
| `A_w` | `water_vapour_slant_attenuation` | slant path gaseous attenuation attributable to water vapour | dB |
| `h_o` | `oxygen_equivalent_height` | equivalent oxygen attenuation height | km |
| `h_w` | `water_vapour_equivalent_height` | equivalent water-vapour attenuation height | km |
| `a_o` / `b_o` / `c_o` / `d_o` | `oxygen_height_coefficients` | P.676 coefficient-table values for oxygen equivalent height | varies |
| `A_hw` / `B_hw` | `water_height_coefficients` | P.676 water-vapour equivalent-height constants | varies |
| `a_hw_i` / `b_hw_i` / `f_hw_i` | `water_height_line_coefficients` | P.676 water-vapour equivalent-height coefficients | varies |
| `gamma_c` | `cloud_specific_attenuation` | specific attenuation in cloud or fog | dB/km |
| `K_l` | `cloud_liquid_specific_attenuation_coefficient` | P.840 cloud liquid water specific attenuation coefficient | (dB/km)/(g/m^3) |
| `rho_l` | `cloud_liquid_water_density` | liquid water density in cloud or fog | g/m^3 |
| `epsilon_p` | `water_permittivity_real` | real part of water dielectric permittivity | unitless |
| `epsilon_pp` | `water_permittivity_imaginary` | imaginary part of water dielectric permittivity | unitless |
| `eta_cloud` | `cloud_permittivity_auxiliary_ratio` | P.840 auxiliary ratio `(2+epsilon_p)/epsilon_pp` | unitless |
| `epsilon_0` / `epsilon_1` / `epsilon_2` | `water_debye_permittivity_terms` | P.840 double-Debye permittivity constants | unitless |
| `f_p` | `water_principal_relaxation_frequency` | principal relaxation frequency of liquid water | GHz |
| `f_s_cloud` | `water_secondary_relaxation_frequency` | secondary relaxation frequency of liquid water | GHz |
| `K_L` | `cloud_liquid_mass_absorption_coefficient` | mass absorption coefficient for integrated cloud liquid water | dB/(kg/m^2), dB/mm |
| `L_cloud` | `integrated_cloud_liquid_water_content` | integrated cloud liquid water content | kg/m^2, mm |
| `L_cloud_p` | `integrated_cloud_liquid_water_percent_p` | integrated cloud liquid water content at exceedance probability | kg/m^2, mm |
| `P_L` | `cloud_probability` | probability of cloud at a location | percent |
| `m_L` | `cloud_lognormal_mean` | log-normal mean parameter for integrated cloud liquid water | unitless |
| `sigma_L` | `cloud_lognormal_stddev` | log-normal standard deviation parameter for integrated cloud liquid water | unitless |
| `Qinv` | `inverse_normal_ccdf` | inverse standard normal complementary cumulative distribution function | unitless |
| `N_wet` | `wet_refractivity_term` | wet term of surface radio refractivity | N-units |
| `sigma_ref` | `scintillation_reference_stddev` | reference standard deviation of signal amplitude | dB |
| `h_L` | `turbulent_layer_height` | height of turbulent layer used in scintillation prediction | m |
| `L_scint` | `scintillation_effective_path_length` | effective path length for scintillation prediction | m |
| `eta_ant` | `antenna_efficiency` | antenna efficiency used for scintillation antenna averaging | ratio |
| `D_eff` | `effective_antenna_diameter` | effective antenna diameter | m |
| `x_scint` | `scintillation_antenna_averaging_argument` | antenna averaging argument in P.618 | unitless |
| `g_x` | `scintillation_antenna_averaging_factor` | P.618 antenna averaging factor before square root | unitless |
| `sigma_scint` | `scintillation_signal_stddev` | standard deviation of scintillation amplitude | dB |
| `a_scint` | `scintillation_time_percentage_factor` | time percentage factor for scintillation fade depth | unitless |
| `A_atm_no_scint` | `atmospheric_attenuation_without_scintillation` | total atmospheric attenuation excluding scintillation | dB |
| `T_sky` | `sky_noise_temperature` | sky noise temperature at ground-station antenna | K |
| `T_mr` | `mean_radiating_temperature` | atmospheric mean radiating temperature | K |
| `e` | `field_strength_v_m` | RMS electric field strength | V/m |
| `E` | `field_strength_dbuv_m` | electric field strength in logarithmic units | dB(uV/m) |
| `s` / `S` | `power_flux_density` | power flux density | W/m^2, dBW/m^2 |
| `p` | `eirp_w` | equivalent isotropically radiated power | W |
| `Pt` | `isotropic_tx_power_dbw` | isotropically transmitted power | dBW |
| `Pr` | `isotropic_rx_power_dbw` | available received power through isotropic matched antenna | dBW |
| `C/N0` | `cn0` | carrier-to-noise-density ratio | dB-Hz |
| `Eb/N0` | `ebn0` | energy-per-bit to noise-density ratio | dB |
| `Es/N0` | `esn0` | energy-per-symbol to noise-density ratio | dB |
| `R_b` | `bit_rate` | bit rate | bps |
| `R_s` | `symbol_rate` | symbol rate | symbols/s |
| `Margin` | `link_margin` | available minus required performance | dB |
| `P_R` | `received_power` | received signal power at the chosen receiver reference point | W, dBW |
| `P_T` | `transmitted_power_at_antenna_terminals` | total transmitted power at antenna terminals | W, dBW |
| `L_T` | `transmit_circuit_loss` | transmitting circuit/feed loss | dB, ratio |
| `L_TP` | `tx_pointing_loss` | transmitting antenna pointing loss | dB, ratio |
| `L_s` | `space_loss` | free-space spreading loss | dB, ratio |
| `L_A` | `atmospheric_attenuation` | atmospheric attenuation term | dB, ratio |
| `L_P` | `polarization_loss` | polarization mismatch loss term | dB, ratio |
| `L_RP` | `rx_pointing_loss` | receiving antenna pointing loss | dB, ratio |
| `L_R` | `receive_circuit_loss` | receiving circuit/feed loss | dB, ratio |
| `S_data` | `data_sideband_power` | portion of received power in data modulation sidebands | W, dBW |
| `P_c` | `residual_carrier_power` | portion of received power in residual carrier | W, dBW |
| `B_LO` | `loop_noise_bandwidth` | one-sided carrier loop threshold noise bandwidth | Hz |
| `B_R` | `ranging_noise_bandwidth` | one-sided transponder ranging-channel noise bandwidth | Hz |
| `L_system` | `system_implementation_loss` | receiver/demodulation/system loss applied to `ST/N0` | dB |
| `Threshold_ST_N0` | `threshold_energy_per_bit_noise_density` | required energy-per-bit to noise-density threshold | dB |
| `RequiredSNR` | `required_ranging_snr` | required ranging signal-to-noise ratio | dB |
| `OutputSNR` | `output_ranging_snr` | ranging SNR after radio/system loss | dB |
| `CD` | `weather_cumulative_distribution` | cumulative distribution of weather effect | ratio |
| `T_M` | `atmosphere_mean_radiating_temp` | mean effective radiating temperature of atmosphere | K |
| `T_atm` | `atmospheric_noise_temp` | atmospheric noise-temperature contribution | K |
| `T_CMB` | `cosmic_background_temp` | cosmic microwave background temperature before attenuation | K |
| `T_CMB_eff` | `effective_cosmic_background_temp` | attenuated cosmic background contribution | K |
| `T_AMW` | `antenna_microwave_noise_temp` | antenna and microwave hardware noise-temperature component | K |
| `T_op` | `operating_system_noise_temp` | system operating noise temperature including sky terms | K |
| `T1`, `T2`, `a_noise` | `antenna_noise_model_coefficients` | coefficients for DSN antenna-microwave noise model | K, K, 1/deg |

## Modulation and Coding

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `M` | `modulation_order` | modulation constellation size | unit |
| `m` | `bits_per_symbol` | bits per symbol, `log2(M)` | bit/symbol |
| `T_s` | `symbol_period` | symbol period | s |
| `T_b` | `bit_period` | bit period | s |
| `R_c` | `coding_rate` | channel coding rate | ratio |
| `alpha` | `rolloff` | raised-cosine rolloff factor | ratio |
| `B_n` | `noise_bandwidth` | receiver noise bandwidth used for baseband SNR conversions | Hz |
| `B_RC_baseband` | `raised_cosine_baseband_bandwidth` | one-sided baseband raised-cosine bandwidth | Hz |
| `B_RC_passband` | `raised_cosine_passband_bandwidth` | occupied passband bandwidth estimate | Hz |
| `B_Nyquist_min` | `nyquist_min_bandwidth` | ideal zero-rolloff one-sided baseband bandwidth | Hz |
| `E_b` | `energy_per_bit` | energy per information bit | J, dBJ |
| `E_s` | `energy_per_symbol` | energy per modulation symbol | J, dBJ |
| `S_data` | `data_sideband_power` | power in the data modulation sidebands | W, dBW |
| `eta_capacity` | `capacity_spectral_efficiency` | Shannon-limit spectral efficiency | bit/s/Hz |
| `BER` | `bit_error_rate` | bit error probability | ratio |
| `SER` | `symbol_error_rate` | symbol error probability | ratio |
| `PER` | `packet_error_rate` | packet or frame error probability | ratio |
| `EVM` | `evm` | error vector magnitude | ratio, percent |
| `Q(x)` | `gaussian_q_function` | Gaussian tail probability function | unitless |
| `erfc(x)` | `complementary_error_function` | complementary error function | unitless |
| `Delta_q` | `quantizer_step` | uniform quantizer step size | input-unit |
| `V_FS` | `full_scale_range` | ADC or quantizer full-scale input range | V or source-unit |
| `N_bits` | `adc_bits` | ADC or quantizer bit depth | bit |
| `sigma_q` | `quantization_noise_rms` | RMS quantization noise | input-unit |
| `ENOB` | `effective_number_of_bits` | effective ADC resolution inferred from SNR | bit |
| `samples_per_symbol` | `samples_per_symbol` | digital oversampling ratio per symbol | sample/symbol |
| `PAPR` | `peak_to_average_power_ratio` | peak-to-average signal power ratio | ratio, dB |
| `r(t)` | `received_waveform` | received waveform entering matched filter/correlator | signal-unit |
| `s_k(t)` | `candidate_signal_waveform` | kth candidate transmitted signal waveform | signal-unit |
| `MatchedFilterOutput_k` | `matched_filter_decision_statistic` | correlation statistic for kth candidate signal | signal-unit |
| `Delta_f_subcarrier` | `ofdm_subcarrier_spacing` | OFDM subcarrier spacing | Hz |
| `T_u` | `ofdm_useful_symbol_duration` | OFDM useful symbol duration | s |
| `T_cp` | `ofdm_cyclic_prefix_duration` | cyclic prefix duration | s |
| `T_ofdm` | `ofdm_symbol_duration` | OFDM symbol duration including cyclic prefix | s |
| `CP_Overhead` | `cyclic_prefix_overhead` | cyclic prefix overhead fraction | ratio |
| `N_data_subcarriers` | `ofdm_data_subcarriers` | number of OFDM data-bearing subcarriers | unit |
| `bits_per_subcarrier` | `ofdm_bits_per_subcarrier` | modulation bits mapped per data subcarrier | bit/subcarrier |
| `sigma_t` | `timing_jitter_rms` | RMS timing jitter when used for phase-error calculations | s |
| `sigma_phase` | `phase_error_rms` | RMS phase error | rad |
| `Delta_f` | `frequency_offset` | carrier or oscillator frequency offset | Hz |
| `T_obs` | `observation_time` | observation/integration interval for phase rotation | s |
| `H` | `mimo_channel_matrix` | MIMO channel matrix | unitless |
| `N_t` | `mimo_tx_antennas` | number of transmit antennas | unit |
| `N_r` | `mimo_rx_antennas` | number of receive antennas | unit |
| `rho` | `mimo_snr_linear` | MIMO receive SNR in linear form | ratio |
| `depth` | `interleaver_depth` | interleaver depth | unit |
| `block_bits` | `codeblock_bits` | code block length | bit |
| `InfoBits` | `information_bits` | uncoded information length entering a channel encoder | bit |
| `b_i` | `serial_input_bit` | bit at index `i` in the serial coded-symbol input stream | bit |
| `QPSKPhase_deg` | `qpsk_phase_state_deg` | RF carrier phase state for a CCSDS QPSK I/Q bit pair | deg |
| `R_cs` | `coded_symbol_rate` | coded symbol rate delivered to modulation or physical layer | symbol/s |
| `R_chs` | `channel_symbol_rate` | channel symbol rate at the channel-symbol reference point | symbol/s |
| `R_source` | `source_data_rate` | source data rate before coding/modulation overhead | bit/s |
| `f_sc` | `subcarrier_frequency` | telemetry or telecommand subcarrier frequency | Hz |
| `SubcarrierRatio` | `subcarrier_to_symbol_ratio` | subcarrier frequency divided by coded symbol rate | ratio |
| `PhaseImbalance_deg` | `phase_imbalance_deg` | measured phase imbalance between modulator branches or constellation points | deg |
| `PhaseLimit_deg` | `phase_imbalance_limit_deg` | applicable CCSDS phase-imbalance limit for the selected modulation family | deg |
| `AmplitudeImbalance_dB` | `amplitude_imbalance_db` | measured amplitude imbalance between modulator branches or constellation points | dB |
| `AmpLimit_dB` | `amplitude_imbalance_limit_db` | applicable CCSDS amplitude-imbalance limit for the selected modulation family | dB |
| `R_cs_meas` | `measured_coded_symbol_rate` | measured coded symbol rate | symbol/s |
| `R_cs_nom` | `nominal_coded_symbol_rate` | nominal configured coded symbol rate | symbol/s |
| `Delta_R_cs` | `coded_symbol_rate_variation` | absolute coded-symbol-rate variation over a stability interval | symbol/s |
| `OffsetLimit_ppm` | `symbol_rate_offset_limit_ppm` | allowed coded-symbol-rate offset | ppm |
| `StabilityLimit` | `symbol_rate_stability_limit` | allowed fractional symbol-rate instability | ratio |
| `BTS` | `bandwidth_time_product` | GMSK or filtered-OQPSK one-sided 3-dB bandwidth-time product | ratio |
| `B_3dB` | `one_sided_3db_filter_bandwidth` | one-sided 3-dB bandwidth of the shaping filter | Hz |
| `tau_g_variation` | `group_delay_variation` | in-band group-delay variation | s |
| `AMPM_Slope_deg_per_dB` | `ampm_slope_deg_per_db` | amplifier AM/PM conversion slope | deg/dB |
| `Delta_f_sc` | `subcarrier_frequency_offset` | measured subcarrier frequency offset | Hz |
| `OffsetFractionLimit` | `subcarrier_offset_fraction_limit` | allowed subcarrier frequency offset as a fraction of `f_sc` | ratio |
| `R_chs_meas` | `measured_channel_symbol_rate` | measured channel symbol rate at transmitter output reference point | symbol/s |
| `R_chs_nom` | `nominal_channel_symbol_rate` | nominal configured channel symbol rate | symbol/s |
| `Delta_R_chs` | `channel_symbol_rate_variation` | short-term channel-symbol-rate variation | symbol/s |
| `R_cs_allowed_i` | `proximity_allowed_coded_symbol_rate` | one value in the Proximity-1 physical-layer coded-symbol-rate set | symbol/s |
| `ChannelSymbolRateOffset` | `channel_symbol_rate_offset` | fractional offset between measured and nominal channel symbol rates | ratio |
| `r_conv` | `convolutional_code_rate` | CCSDS convolutional code rate | ratio |
| `K_conv` | `constraint_length` | convolutional code constraint length; CCSDS text uses `K` | bit |
| `J` | `rs_symbol_bits` | Reed-Solomon symbol length | bit/symbol |
| `E` | `rs_error_correction_symbols` | Reed-Solomon symbol-error correction capability per codeword | symbol |
| `I` | `rs_interleaving_depth` | Reed-Solomon interleaving depth | unit |
| `RS_n` | `rs_codeword_symbols` | Reed-Solomon codeword length | symbol |
| `RS_k` | `rs_information_symbols` | Reed-Solomon information symbols per codeword before virtual fill | symbol |
| `q_rs` | `rs_virtual_fill_symbols_per_codeword` | virtual fill symbols per R-S codeword that are not transmitted | symbol |
| `r_turbo` | `turbo_nominal_code_rate` | CCSDS Turbo nominal code rate | ratio |
| `k_turbo` | `turbo_information_block_bits` | Turbo information block length | bit |
| `r_ldpc` | `ldpc_code_rate` | CCSDS LDPC code rate | ratio |
| `m_ldpc` | `ldpc_codewords_per_codeblock` | number of LDPC codewords aggregated in one stream-LDPC codeblock | unit |

## Telemetry and Frames

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `word_length` | `word_length` | PCM word length | bit |
| `words_per_minor` | `words_per_minor` | PCM words per minor frame | unit |
| `minor_frame_rate` | `minor_rate` | minor frames per second | Hz |
| `minor_frames_per_major` | `minor_per_major` | minor frames in major frame | unit |
| `sync_bits` | `sync_bits` | synchronization marker length | bit |
| `TransferFrameBits` | `transfer_frame_bits` | complete transfer frame length | bit |
| `coded_unit_bits` | `coded_unit_bits` | coded frame, codeblock, or codeword length immediately following an ASM | bit |
| `ASM_bits` | `attached_sync_marker_bits` | Attached Sync Marker length | bit |
| `CSM_bits` | `code_sync_marker_bits` | Code Synchronization Marker length for LDPC stream codeblocks | bit |
| `RandomizerPeriodBits` | `randomizer_period_bits` | pseudo-randomizer sequence period | bit |
| `SMTF_Bits` | `sync_marked_transfer_frame_bits` | Transfer Frame plus ASM before stream-LDPC slicing | bit |
| `TM_FrameOctets` | `tm_frame_octets` | complete TM transfer frame length | octet |
| `TC_FrameOctets` | `tc_frame_octets` | complete TC transfer frame length | octet |
| `FrameLengthCount` | `frame_length_count` | TC frame length count field equal to total octets minus one | octet-count |
| `DataFieldBits` | `data_field_bits` | payload data field length | bit |
| `SecondaryHeaderOctets` | `secondary_header_octets` | TM secondary header length when present | octet |
| `OCFOctets` | `ocf_octets` | Operational Control Field length, usually 4 octets when present | octet |
| `FECFOctets` | `fecf_octets` | Frame Error Control Field length, 2 octets when present | octet |
| `SecurityHeaderOctets` | `security_header_octets` | SDLS security header length | octet |
| `SecurityTrailerOctets` | `security_trailer_octets` | SDLS security trailer length | octet |
| `SegmentHeaderOctets` | `segment_header_octets` | TC segment header length, 1 octet when present | octet |
| `FrameCount` | `frame_count` | master, virtual, or TC frame sequence count | unit |
| `VC_share` | `virtual_channel_share` | assigned virtual-channel fraction | ratio |

## Telecommand

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `CommandBits` | `command_bits` | useful command payload | bit |
| `HeaderBits` | `header_bits` | TC header and control fields | bit |
| `CRCBits` | `crc_bits` | CRC or frame error-control field | bit |
| `SecurityBits` | `security_bits` | authentication/encryption overhead | bit |
| `N_repeat` | `repeat_count` | command repeat count | unit |
| `GuardTime` | `guard_time` | inter-frame guard time | s, ms |
| `UplinkRate` | `uplink_rate` | telecommand link bit rate | bps |
| `CLTU_Bits` | `cltu_bits` | complete Communications Link Transmission Unit length | bit |
| `BCH_Codewords` | `bch_codewords` | number of TC BCH codewords in a CLTU | unit |
| `LDPC_Codewords` | `ldpc_codewords` | number of TC LDPC codewords in a CLTU | unit |
| `k_ldpc` | `ldpc_information_bits` | LDPC information bits per codeword | bit |
| `n_ldpc` | `ldpc_codeword_bits` | LDPC transmitted codeword length | bit |
| `TailBits` | `tail_bits` | CLTU tail-sequence length | bit |
| `Repetitions` | `cltu_repetitions` | number of CLTU transfers requested by the repetitions parameter | unit |

## Tracking, Ranging, and Doppler

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `R_chip` | `chip_rate` | PN ranging chip rate | chips/s |
| `Fchip` | `pn_chip_rate` | CCSDS PN ranging chip rate | Mchip/s, chips/s |
| `Fclock` | `pn_ranging_clock` | PN ranging clock frequency; CCSDS table 3-1 uses `Fchip = 2 Fclock` | MHz |
| `l_pn` | `pn_chip_rate_l` | CCSDS PN chip-rate selector; implementation alias for the standard symbol `l` | unit |
| `k_pn` | `pn_chip_rate_k` | CCSDS PN chip-rate exponent selector; implementation alias for the standard symbol `k` to avoid conflict with Boltzmann constant | unit |
| `Tacq` | `pn_acquisition_time` | PN ranging code phase acquisition time | s |
| `PrN0` | `ranging_power_noise_density` | ranging power over noise spectral density | dB-Hz |
| `B_L` | `chip_tracking_loop_bandwidth` | chip tracking loop noise bandwidth | Hz |
| `N_code` | `code_length` | PN code length | chip |
| `sigma_t` | `timing_error` | timing uncertainty | s, ns |
| `sigma` | `radar_cross_section` | radar target cross-section | m^2 |
| `f_D` | `doppler_shift` | Doppler frequency shift | Hz |
| `v_r` | `relative_velocity` | radial relative velocity | m/s, km/s |
| `r_sc` | `spacecraft_position_vector` | spacecraft position vector in the selected frame | m, km |
| `r_site` | `station_position_vector` | ground station position vector in the selected frame | m, km |
| `v_sc` | `spacecraft_velocity_vector` | spacecraft velocity vector in the selected frame | m/s, km/s |
| `v_site` | `station_velocity_vector` | ground station velocity vector in the selected frame | m/s, km/s |
| `rho_vec` | `line_of_sight_vector` | station-to-spacecraft line-of-sight vector | m, km |
| `rho_dot` | `range_rate` | line-of-sight range rate | m/s, km/s |
| `f_T` | `transmitted_frequency` | transmitted carrier frequency | Hz |
| `f_R` | `received_frequency` | received carrier frequency | Hz |
| `f_ref` | `coherent_reference_frequency` | reference carrier frequency used for first-order two-way Doppler conversion | Hz |
| `beta` | `velocity_over_light_speed` | radial speed normalized by light speed | ratio |
| `sigma_f` | `doppler_frequency_uncertainty` | standard deviation of Doppler frequency estimate | Hz |
| `DeltaPhi` | `doppler_phase_increment` | phase increment accumulated during a Doppler count interval | rad |
| `N_start` | `doppler_counter_start` | Doppler counter value at the start of the sampling interval | cycles |
| `N_end` | `doppler_counter_end` | Doppler counter value at the end of the sampling interval | cycles |
| `n_start` | `resolver_count_start` | fractional resolver count at the start of the sampling interval | cycles |
| `n_end` | `resolver_count_end` | fractional resolver count at the end of the sampling interval | cycles |
| `T_i` | `doppler_sampling_interval` | Doppler count sampling interval | s |
| `f_B` | `doppler_bias_frequency` | bias frequency added before Doppler counting | Hz |
| `f_D_biased` | `biased_doppler_frequency` | biased Doppler frequency before bias removal | Hz |
| `f_D_biased_avg` | `average_biased_doppler_frequency` | average biased Doppler frequency over a sampling interval | Hz |
| `f_D_avg` | `average_unbiased_doppler_frequency` | average Doppler frequency after bias removal | Hz |
| `cycles_D` | `integrated_doppler_cycles` | integrated Doppler cycles over a count interval | cycles |
| `sigma_Ti` | `sampling_epoch_uncertainty` | timing uncertainty in Doppler sample epoch | s |
| `T_clock` | `resolver_clock_period` | Doppler resolver quantization clock period | s |
| `T_range` | `ranging_wave_period` | sine-wave or square-wave ranging-signal period | s |
| `T_corr` | `ranging_correlation_interval` | ranging correlation/integration interval | s |
| `P_ranging` | `received_ranging_power` | received ranging-signal power in the ranging channel | W |
| `sigma_tau` | `delay_uncertainty` | standard deviation of group-delay or timing estimate | s |
| `D_meas` | `measured_tracking_delay` | measured two-way group delay before hardware corrections | s |
| `BIAS_sc` | `spacecraft_turnaround_delay` | spacecraft ranging turnaround delay correction | s |
| `BIAS_dss` | `station_turnaround_delay` | station turnaround or tracking-system hardware delay correction | s |
| `Z_correction` | `station_reference_delay_correction` | station reference-location delay correction | s |
| `RTPT` | `round_trip_propagation_time` | corrected round-trip propagation time | s |
| `R_corrected` | `corrected_range` | corrected one-way range from round-trip propagation time | m, km |
| `RangeObserved` | `observed_range` | measured range observable | m, km |
| `RangeComputed` | `computed_range` | modeled range from orbit/observation model | m, km |
| `RangeResidual` | `range_residual` | observed range minus computed range | m, km |
| `DopplerObserved` | `observed_doppler` | measured Doppler observable | Hz |
| `DopplerComputed` | `computed_doppler` | modeled Doppler observable | Hz |
| `DopplerResidual` | `doppler_residual` | observed Doppler minus computed Doppler | Hz |
| `sigma_q` | `measurement_stddev` | standard deviation of a measured radiometric quantity | same as measured quantity |
| `dq_dxi` | `measurement_sensitivity` | partial derivative of measurement quantity with respect to an error source | varies |
| `sigma_xi` | `error_source_stddev` | standard deviation of an independent error source | varies |
| `rho_1` | `station_1_range` | range from station 1 to spacecraft/source | m, km |
| `rho_2` | `station_2_range` | range from station 2 to spacecraft/source | m, km |
| `DeltaRange12` | `differenced_range` | range from station 1 minus range from station 2 | m, km |
| `D_baseline` | `station_baseline_length` | station baseline length for differenced ranging or interferometry | m, km |
| `delta` | `declination_angle` | source declination or small angular offset in differenced-ranging context | rad, deg |
| `tau_g` | `geometric_delay` | VLBI/DOR geometric group delay | s |
| `s_sc` | `spacecraft_direction_unit_vector` | unit vector toward spacecraft | unitless |
| `s_qso` | `quasar_direction_unit_vector` | unit vector toward calibration quasar | unitless |
| `DeltaTau_DOR` | `delta_dor_delay` | spacecraft-minus-quasar differential one-way ranging delay | s |
| `B_span` | `spanned_bandwidth` | total spanned bandwidth between tones or recorded bands | Hz |
| `b_perp` | `projected_baseline` | baseline projected perpendicular to the line of sight | m, km |
| `sigma_DeltaTau` | `delta_dor_delay_uncertainty` | standard deviation of Delta-DOR differential delay | s |
| `S_min` | `minimum_detectable_signal` | minimum detectable radar echo power | W |
| `B_n` | `noise_bandwidth` | receiver noise bandwidth | Hz |
| `tau_p` | `pulse_width` | radar pulse duration | s |
| `B_waveform` | `waveform_bandwidth` | waveform or compressed-pulse bandwidth | Hz |
| `PRF` | `pulse_repetition_frequency` | radar pulse repetition frequency | Hz |
| `T_coh` | `coherent_integration_time` | coherent processing/integration time | s |
| `PCN0_DL` | `downlink_residual_carrier_power_noise_density` | downlink residual-carrier power-to-noise spectral density | Hz, dB-Hz |
| `PTN0_DL` | `downlink_total_power_noise_density` | downlink total carrier/signal power-to-noise spectral density | Hz, dB-Hz |
| `EsN0` | `symbol_energy_noise_density_linear` | symbol energy to one-sided noise spectral density in linear units | ratio |
| `S_L` | `costas_squaring_loss` | suppressed-carrier Costas-loop squaring loss | ratio |
| `rho_L_dB` | `carrier_loop_snr_db` | carrier-loop signal-to-noise ratio | dB |
| `rho_L_min_dB` | `carrier_loop_snr_threshold_db` | recommended minimum carrier-loop signal-to-noise ratio | dB |
| `sigma_V` | `range_rate_stddev` | standard deviation of Doppler-derived range rate | m/s |
| `sigma_VN` | `doppler_thermal_range_rate_stddev` | Doppler range-rate standard deviation from thermal noise | m/s |
| `sigma_VF` | `doppler_frequency_source_range_rate_stddev` | Doppler range-rate standard deviation from frequency-source instability | m/s |
| `sigma_VS` | `doppler_scintillation_range_rate_stddev` | Doppler range-rate standard deviation from solar phase scintillation | m/s |
| `sigma_VI` | `doppler_data_imbalance_range_rate_stddev` | Doppler range-rate standard deviation from telemetry data imbalance | m/s |
| `theta_t` | `telemetry_modulation_index` | telemetry modulation index used in data-imbalance Doppler model | rad |
| `Idata` | `telemetry_data_imbalance` | imbalance fraction between binary zero and one telemetry symbols | ratio |
| `n_zero` | `telemetry_zero_count` | number of logical zero telemetry symbols | count |
| `n_one` | `telemetry_one_count` | number of logical one telemetry symbols | count |
| `T_Doppler` | `doppler_integration_time` | Doppler measurement integration time | s |
| `sigma_y` | `allan_deviation` | Allan deviation of a frequency source over an averaging time | ratio |
| `sigma_phiN` | `carrier_phase_thermal_stddev` | carrier-loop phase error standard deviation from thermal noise | rad |
| `sigma_phiF` | `carrier_phase_source_stddev` | carrier-loop phase error standard deviation from phase/frequency source noise | rad |
| `sigma_phiS` | `carrier_phase_scintillation_stddev` | carrier-loop phase error standard deviation from solar phase scintillation | rad |
| `RU` | `range_unit` | DSN range unit, proportional to two-way phase delay | unitless |
| `f_S` | `s_band_uplink_frequency` | S-band uplink carrier frequency | Hz |
| `f_X` | `x_band_uplink_frequency` | X-band uplink carrier frequency | Hz |
| `f_K` | `k_band_uplink_frequency` | K-band uplink carrier frequency | Hz |
| `f_Ka` | `ka_band_uplink_frequency` | Ka-band uplink carrier frequency | Hz |
| `f_0` | `sequential_component_zero_frequency` | component-zero frequency for sequential ranging | Hz |
| `f_n` | `sequential_component_frequency` | frequency of sequential ranging component n | Hz |
| `n_RC` | `range_clock_component_number` | component number used as sequential-ranging range clock | unit |
| `n_L` | `last_ambiguity_component_number` | last ambiguity-resolving component number in sequential ranging | unit |
| `f_RC_seq` | `sequential_range_clock_frequency` | sequential-ranging range-clock frequency | Hz |
| `BandFactor` | `uplink_band_factor` | DSN band-dependent multiplier: 1, 221/749, 221/2407, or 221/3599 | ratio |
| `f_uplink` | `uplink_carrier_frequency` | selected uplink carrier frequency | Hz |
| `T1` | `range_clock_integration_time` | integration time for the range clock | s |
| `T2` | `ambiguity_component_integration_time` | integration time for each ambiguity-resolving component | s |
| `PRN0` | `ranging_power_noise_density_linear` | ranging signal power to noise spectral density in linear units | Hz |
| `sigma_rhoN_seq` | `sequential_thermal_range_error` | sequential-ranging thermal-noise range standard deviation | m |
| `sigma_rhoN_target` | `target_thermal_range_error` | target thermal-noise range standard deviation | m |
| `sigma_rhoTCT` | `time_code_translator_range_jitter` | range error from Time Code Translator timing jitter | m |
| `sigma_rho_seq` | `sequential_total_range_error` | sequential-ranging total range standard deviation | m |
| `N_C` | `ambiguity_component_count` | number of ambiguity-resolving components | count |
| `P_acq_seq` | `sequential_acquisition_probability` | probability of acquiring a sequential range measurement | ratio |
| `A_over_B` | `pn_chip_rate_rational_factor` | rational chip-rate factor used by DSN PN ranging | ratio |
| `l_CR` | `dsn_pn_chip_rate_l` | DSN module 214 PN chip-rate selector | unit |
| `k_CR` | `dsn_pn_chip_rate_k` | DSN module 214 PN chip-rate exponent selector | unit |
| `f_chip_DSN` | `dsn_pn_chip_rate` | DSN PN ranging chip rate | chips/s |
| `f_RC_PN` | `pn_range_clock_frequency` | PN range-clock frequency | Hz |
| `b_n` | `pn_component_code_bit` | binary bit of PN component code n | bit |
| `c_n` | `pn_component_code_chip` | bipolar chip of PN component code n | +1/-1 |
| `lambda_n` | `pn_component_code_length` | length of PN component code n | chips |
| `L_PN` | `pn_composite_code_period` | composite PN range-code period | chips |
| `R_1` | `range_clock_cross_correlation_factor` | cross-correlation factor against the range clock | ratio |
| `T_PN` | `pn_ranging_integration_time` | PN range measurement integration time | s |
| `sigma_rho_PN` | `pn_thermal_range_error` | PN-ranging thermal-noise range standard deviation | m |
| `sigma_RR` | `regenerative_ranging_range_error` | regenerative PN range standard deviation | m |
| `sigma_UL` | `uplink_regeneration_range_error` | range error from uplink range-clock regeneration jitter | m |
| `B_RL` | `uplink_range_clock_loop_bandwidth` | uplink code/range-clock tracking loop bandwidth | Hz |
| `PRPT_UL` | `uplink_ranging_power_fraction` | uplink ranging-signal to total-power ratio | ratio |
| `PTN0_UL` | `uplink_total_power_noise_density` | uplink total power to noise spectral density | Hz |
| `P_n` | `pn_component_acquisition_probability` | probability of acquiring PN component code n | ratio |
| `Delta_f_RC` | `range_clock_frequency_mismatch` | frequency mismatch between received range clock and local model | Hz |
| `SNR_CH` | `vlbi_channel_snr` | single-channel VLBI correlation SNR | ratio |
| `SNR_post` | `vlbi_post_correlation_snr` | post-correlation VLBI SNR | ratio |
| `BW_obs` | `vlbi_observation_bandwidth` | observation bandwidth used in VLBI delay error estimate | Hz |
| `f_CH` | `vlbi_channel_center_frequency` | center frequency of a VLBI synthesis channel | Hz |
| `f_AVG` | `vlbi_average_channel_frequency` | average center frequency across VLBI synthesis channels | Hz |
| `BW_RMS` | `vlbi_rms_synthesized_bandwidth` | RMS synthesized bandwidth | Hz |
| `n_channels` | `vlbi_channel_count` | number of comparable VLBI channels | count |
| `s_DOR` | `delta_dor_downlink_signal` | Delta-DOR downlink signal model | amplitude |
| `theta_d` | `telemetry_phase_modulation` | telemetry/data phase modulation process on the Delta-DOR carrier | rad |
| `theta_1` | `dor_tone_1_modulation_index` | modulation index for DOR tone 1 | rad |
| `theta_2` | `dor_tone_2_modulation_index` | modulation index for DOR tone 2 | rad |
| `f_1` | `dor_tone_1_frequency` | first DOR tone frequency | Hz |
| `f_2` | `dor_tone_2_frequency` | second DOR tone frequency | Hz |
| `f_DOR` | `dor_tone_frequency` | DOR tone frequency used for single-tone spanned bandwidth | Hz |
| `B_span_DOR` | `dor_spanned_bandwidth` | spanned bandwidth between DOR spectral components | Hz |
| `Delta_f_osc` | `oscillator_error` | oscillator frequency error | Hz |
| `GuardBand` | `protection_band` | allocated guard band | Hz |
| `b` | `baseline_vector` | Delta-DOR baseline vector | m |
| `s` | `source_unit_vector` | source direction unit vector | unitless |
| `Delta_tau` | `ddor_delay` | differential delay | s |

## System-Level Operations

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `DataVolume` | `data_volume` | data amount | bit, byte |
| `Duration` | `duration` | production or contact duration | s, min, h |
| `NetDownlinkRate` | `net_downlink_rate` | useful downlink payload rate | bps |
| `StorageCapacity` | `storage_capacity` | onboard storage capacity | bit, byte |
| `DutyCycle` | `duty_cycle` | active fraction of period | ratio |
| `AveragePower` | `average_power` | duty-cycle weighted power | W |

## Orbit, Coverage, and Contact

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `R_e` | `earth_radius` | Earth reference radius | m, km |
| `mu` | `gravitational_parameter` | central body gravitational parameter | m^3/s^2 |
| `h` | `altitude` | spacecraft altitude above reference radius | m, km |
| `a` | `semi_major_axis` | orbit semi-major axis | m, km |
| `r` | `orbital_radius` | spacecraft radius from central body center | m, km |
| `n` | `mean_motion` | mean angular motion | rad/s, deg/s |
| `T` | `orbit_period` | orbit period | s, min |
| `rho` | `slant_range` | ground-space slant range | m, km |
| `psi` | `central_angle` | central angle between station and subsatellite point | rad, deg |
| `E` | `elevation_angle` | station elevation angle | rad, deg |
| `az` | `azimuth` | station azimuth angle | rad, deg |
| `east` | `enu_east` | east component in topocentric frame | m, km |
| `north` | `enu_north` | north component in topocentric frame | m, km |
| `up` | `enu_up` | up component in topocentric frame | m, km |
| `range_rate` | `range_rate` | line-of-sight range rate | m/s, km/s |

## Compression and Source Coding

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `CR` | `compression_ratio` | uncompressed bits divided by compressed bits | ratio |
| `UncompressedBits` | `uncompressed_bits` | source data volume before compression | bit |
| `CompressedBits` | `compressed_bits` | data volume after compression | bit |
| `HeaderBits` | `compression_header_bits` | compression or packet header overhead | bit |
| `bpp` | `bits_per_pixel` | bits per image pixel | bit/pixel |
| `bpsample` | `bits_per_sample` | bits per instrument sample | bit/sample |
| `H` | `entropy` | source entropy | bit/symbol |
| `L_avg` | `average_code_length` | expected code length | bit/symbol |
| `q` | `quantization_step` | near-lossless quantization step | source-unit |

## Protocol and Measurement

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `HeaderBits` | `header_bits` | protocol header length | bit |
| `TrailerBits` | `trailer_bits` | protocol trailer length | bit |
| `PLTU_Bits` | `proximity_pltu_bits` | complete Proximity-1 Link Transmission Unit size | bit |
| `PLTU_OverheadBits` | `proximity_pltu_overhead_bits` | Proximity-1 ASM plus CRC-32 overhead per PLTU | bit |
| `ASM_Bits` | `proximity_attached_sync_marker_bits` | Proximity-1 PLTU Attached Synchronization Marker length, 24 bits | bit |
| `CRC32_Bits` | `proximity_crc32_bits` | Proximity-1 PLTU CRC length, 32 bits | bit |
| `ProxIdleBits` | `proximity_idle_bits` | total idle/acquisition/tail bits inserted around PLTUs | bit |
| `ProxIdleRepeats` | `proximity_idle_pn_repeats` | repetitions of the 32-bit Proximity-1 idle PN sequence | unit |
| `Acquisition_Idle_Duration` | `proximity_acquisition_idle_duration` | managed acquisition idle duration before Proximity-1 data | s |
| `Tail_Idle_Duration` | `proximity_tail_idle_duration` | managed tail idle duration after Proximity-1 data | s |
| `Rd` | `proximity_data_rate` | Proximity-1 input data rate selected before coding | bit/s |
| `Rd_allowed_i` | `proximity_allowed_data_rate` | one value in the Proximity-1 allowed data-rate table | bit/s |
| `InputBits` | `proximity_coding_input_bits` | PLTU plus idle bitstream length entering the selected Proximity-1 code | bit |
| `ProxLDPCBlocks` | `proximity_ldpc_blocks` | number of Proximity-1 1024-bit LDPC message blocks | unit |
| `ProxLDPCCodewordBits` | `proximity_ldpc_codeword_bits` | Proximity-1 LDPC codeword length, 2048 bits | bit |
| `ProxLDPCCodeRate` | `proximity_ldpc_code_rate` | Proximity-1 LDPC code rate, 1/2 | ratio |
| `CSM_Bits` | `proximity_codeword_sync_marker_bits` | Proximity-1 LDPC Codeword Sync Marker length, 64 bits | bit |
| `PN_Prox_Idle` | `proximity_idle_pn_sequence` | Proximity-1 idle PN sequence value `352EF853` | hex constant |
| `PN_i` | `proximity_randomizer_bit` | pseudo-randomizer bit at index `i`, periodic with length 255 for Proximity-1 LDPC | bit |
| `ProxV3HeaderBits` | `proximity_v3_header_bits` | Proximity-1 Version-3 Transfer Frame header length | bit |
| `ProxV3HeaderOctets` | `proximity_v3_header_octets` | Proximity-1 Version-3 Transfer Frame header length | octet |
| `ProxV3FrameOctets` | `proximity_v3_frame_octets` | complete Proximity-1 Version-3 Transfer Frame length | octet |
| `ProxV3DataFieldOctets` | `proximity_v3_data_field_octets` | Version-3 Transfer Frame data-field length | octet |
| `ProxV3MaxDataFieldOctets` | `proximity_v3_max_data_field_octets` | maximum Version-3 Transfer Frame data-field capacity | octet |
| `ProxV3FrameEfficiency` | `proximity_v3_frame_efficiency` | Version-3 data-field fraction before PLTU ASM/CRC overhead | ratio |
| `ProxV3NetFrameEfficiency` | `proximity_v3_net_frame_efficiency` | Version-3 data-field fraction after fixed PLTU ASM/CRC overhead | ratio |
| `ProxFrameSequenceModulus` | `proximity_frame_sequence_modulus` | wrap modulus for the 8-bit frame sequence number | unit |
| `ProxSCIDCount` | `proximity_spacecraft_id_count` | number of spacecraft identifiers representable by a 10-bit SCID field | unit |
| `ProxPortCount` | `proximity_port_count` | number of Port ID values representable by a 3-bit field | unit |
| `ProxPCIDCount` | `proximity_physical_channel_id_count` | number of Physical Channel ID values representable by a 1-bit field | unit |
| `PlaintextBits` | `plaintext_bits` | security payload bits before security overhead | bit |
| `IVBits` | `initialization_vector_bits` | security initialization vector length | bit |
| `AuthTagBits` | `auth_tag_bits` | authentication tag length | bit |
| `PER` | `packet_error_rate` | packet/frame error probability | ratio |
| `AckDelay` | `ack_delay` | acknowledgement delay | s, ms |
| `PFD` | `power_flux_density` | power flux density | W/m^2, dBW/m^2 |
| `PSD` | `power_spectral_density` | power spectral density | W/Hz, dBW/Hz |
| `V_rms` | `rms_voltage` | RMS voltage | V |
| `Z` | `impedance` | RF/load impedance when used in `P=V^2/Z` | ohm |
