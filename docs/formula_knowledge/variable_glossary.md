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
| `theta_broadside` | `array_broadside_angle` | scan or observation angle measured from array broadside | rad, deg |
| `theta_scan` | `array_scan_angle` | commanded scan angle | rad, deg |
| `u_dir` / `v_dir` | `array_direction_cosines` | direction-cosine coordinates for linear or planar arrays | unitless |
| `u_scan` / `v_scan` | `array_scan_direction_cosines` | commanded scan point in direction-cosine coordinates | unitless |
| `u_scan_max` / `v_scan_max` | `array_scan_sector_bounds` | maximum absolute direction-cosine bounds for a scan sector | unitless |
| `u_grating_m` / `v_grating_n` | `grating_lobe_direction_cosines` | direction-cosine coordinates of grating-lobe order | unitless |
| `m` / `n` | `array_lattice_indices` | element or grating-lobe integer indices | integer |
| `d_x` / `d_y` | `planar_array_spacing` | rectangular planar-array lattice spacing | m |
| `beta_x` / `beta_y` | `planar_array_progressive_phase` | progressive phase commands along the x and y array axes | rad |
| `w_mn` | `planar_array_element_weight` | complex excitation weight for planar-array element `(m,n)` | complex ratio |
| `AF_u` | `linear_array_factor_direction_cosine` | linear-array factor written in direction-cosine form | complex ratio |
| `AF_planar` | `planar_array_factor` | rectangular planar-array factor | complex ratio |
| `theta_FNBW_ULA_broadside` | `ula_broadside_first_null_beamwidth` | broadside first-null beamwidth for a uniform linear array | rad, deg |
| `theta_HPBW_ULA_broadside` | `ula_broadside_half_power_beamwidth` | broadside half-power beamwidth for a uniform linear array | rad, deg |
| `SLL_uniform_ULA` | `uniform_array_first_sidelobe_level` | first sidelobe level for uniform amplitude weighting | dB |
| `G_elem` | `array_element_gain` | gain of one array element including element pattern at the relevant direction | ratio, dBi |
| `eta_array` | `array_efficiency` | aggregate array efficiency for feed, combining, mutual-coupling, taper, and implementation losses | ratio |
| `G_array_max` | `maximum_array_gain` | approximate coherent maximum array gain | ratio, dBi |
| `G_broadside_dBi` | `array_broadside_gain` | planar-array broadside gain | dBi |
| `G_scan_dBi` | `array_scanned_gain` | gain at commanded scan angle after scan-loss approximation | dBi |
| `B_phase` | `phase_shifter_bits` | phase-shifter quantization bit depth | bit |
| `eta_phase_quant` | `phase_quantization_efficiency` | coherent gain efficiency due to finite phase-shifter resolution | ratio |
| `sigma_phase_quant` | `phase_quantization_rms` | RMS quantization phase error | rad |
| `sigma_phase_rms` | `phase_error_rms` | RMS random phase error per element or channel | rad |
| `eta_phase_rms` | `rms_phase_error_efficiency` | coherent array gain efficiency due to random phase errors | ratio |
| `f0` | `array_design_frequency` | phase-shifter steering design frequency | Hz |
| `theta_scan_f0` | `design_frequency_scan_angle` | commanded scan angle at the design frequency | rad, deg |
| `theta_squint_f` | `beam_squint_angle` | shifted beam angle at another frequency | rad, deg |

## Noise and Receiver

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `T_sys` | `system_temp` | system noise temperature | K |
| `T_ant` | `antenna_noise_temp` | antenna noise temperature | K |
| `T_rx` | `receiver_noise_temp` | receiver equivalent noise temperature | K |
| `T_e` | `equivalent_noise_temp` | equivalent noise temperature | K |
| `T_phys` | `physical_temp` | physical temperature of a passive lossy element | K |
| `T_feed_phys` | `feed_physical_temp` | physical temperature of the feed/waveguide/diplexer loss element | K |
| `T_downstream` | `downstream_equivalent_noise_temp` | equivalent noise temperature of receiver stages after a preceding loss | K |
| `T_misc` | `misc_noise_temp` | miscellaneous additive noise-temperature allowance at the chosen reference plane | K |
| `T_b(theta,phi)` | `scene_brightness_temp` | directional scene brightness temperature | K |
| `T_in` | `input_noise_temp` | input noise or brightness temperature before a lossy passive path | K |
| `T_scene` | `scene_noise_temp` | effective incident scene noise temperature before antenna ohmic loss | K |
| `T_hot` | `hot_source_temp` | hot-source equivalent noise temperature for calibration | K |
| `T_cold` | `cold_source_temp` | cold-source equivalent noise temperature for calibration | K |
| `NF` | `noise_figure` | noise figure | dB |
| `F` | `noise_factor` | linear noise factor | ratio |
| `L_linear` | `passive_loss_factor` | passive attenuation/loss factor, greater than or equal to 1 | ratio |
| `L_feed` | `feed_loss_factor` | feed, waveguide, diplexer, or switch loss before the receiver | ratio |
| `Y` | `y_factor` | hot/cold output power ratio | ratio |
| `ENR` | `excess_noise_ratio` | calibrated noise-source excess noise ratio | ratio, dB |
| `N0` | `noise_density` | noise spectral density | dBW/Hz |
| `B` / `B_n` | `noise_bandwidth` | receiver noise bandwidth | Hz |
| `G0`, `G1`, `gamma` | `dsn_gain_curve_parameters` | DSN station gain-versus-elevation parameters | dBi, dBi/deg^2, deg |

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
| `PFD_sat_dBW_m2` | `satellite_incident_pfd` | power flux density incident at the satellite receive antenna reference plane | dBW/m^2 |
| `EIRP_uplink_dBW` | `uplink_eirp` | earth-station or relay uplink EIRP toward the satellite | dBW |
| `L_uplink_path_dB` | `uplink_additional_loss` | uplink attenuation, polarization, pointing, and implementation losses excluding the `10log10(4*pi*R_uplink^2)` spreading term | dB |
| `R_uplink` | `uplink_range` | uplink slant range used in incident PFD calculation | m |
| `SFD_dBW_m2` | `satellite_saturation_flux_density` | satellite input saturation flux density reference | dBW/m^2 |
| `IBO_dB` | `input_backoff` | transponder input back-off relative to saturation | dB |
| `P_in_sat_dBW` | `satellite_transponder_input_power` | carrier power at the satellite receiver/transponder input reference point | dBW |
| `G_rx_sat_dBi` | `satellite_receive_antenna_gain` | satellite receive antenna gain toward the uplink station | dBi |
| `lambda_u` | `uplink_wavelength` | uplink wavelength used for receive aperture conversion | m |
| `L_rx_sat_dB` | `satellite_receive_chain_loss` | satellite receive feed, pointing, polarization, and input chain losses | dB |
| `G_transponder_dB` | `transponder_gain` | effective bent-pipe transponder gain at the selected operating point | dB |
| `P_out_sat_dBW` | `satellite_transponder_output_power` | operating RF output carrier power from the satellite transponder or HPA | dBW |
| `P_out_sat_dBW_sat` | `satellite_transponder_saturated_output_power` | saturated RF output power reference for transponder or HPA back-off | dBW |
| `OBO_dB` | `output_backoff` | output back-off relative to saturated transponder or HPA output | dB |
| `EIRP_sat_oper_dBW` | `satellite_operating_eirp` | satellite downlink EIRP after output back-off | dBW |
| `EIRP_sat_sat_dBW` | `satellite_saturated_eirp` | saturated satellite downlink EIRP reference | dBW |
| `P_carrier_share_dB` | `equal_carrier_power_share` | per-carrier power share for equal-power carriers | dB |
| `N_carriers` | `carrier_count` | number of equal-power carriers sharing a transponder | count |
| `OBO_total_dB` | `aggregate_output_backoff` | total transponder output back-off for the aggregate carrier loading | dB |
| `EIRP_sat_per_carrier_dBW` | `satellite_per_carrier_eirp` | per-carrier satellite EIRP in multi-carrier operation | dBW |
| `OBO_per_carrier_dB` | `per_carrier_output_backoff` | per-carrier output back-off relative to saturated single-carrier EIRP | dB |
| `(C/N0)_uplink_linear` | `uplink_cn0_linear` | uplink carrier-to-noise-density ratio in linear Hz units | Hz |
| `(C/N0)_downlink_linear` | `downlink_cn0_linear` | downlink carrier-to-noise-density ratio in linear Hz units | Hz |
| `(C/N0)_total_linear` | `total_cn0_linear` | cascaded carrier-to-noise-density ratio in linear Hz units | Hz |
| `(C/N)_i_linear` | `cn_section_linear` | carrier-to-noise ratio contribution for a selected independent section | ratio |
| `(C/I)_linear` | `carrier_to_interference_linear` | carrier-to-interference ratio in linear form | ratio |
| `(C/IM)_linear` | `carrier_to_intermod_linear` | carrier-to-intermodulation ratio in linear form | ratio |
| `C_I_margin_dB` | `carrier_interference_margin` | available minus required carrier-to-interference ratio | dB |
| `C_I_available_dB` | `available_carrier_interference_ratio` | available carrier-to-interference ratio | dB |
| `C_I_required_dB` | `required_carrier_interference_ratio` | required carrier-to-interference ratio | dB |
| `I_i_linear` | `interference_power_linear` | individual interference power at a common reference point | W, ratio |
| `I_total_linear` | `total_interference_power_linear` | sum of independent interference powers at a common reference point | W, ratio |
| `I_total_linear_W` | `total_interference_power_w` | total interference power in watts | W |
| `C_I_total_dB` | `total_carrier_interference_ratio` | carrier-to-interference ratio after aggregating interference powers | dB |
| `C_dBW` | `carrier_power` | carrier power at the selected receiver or transponder reference point | dBW |
| `C_IM_dB` | `carrier_intermod_ratio` | carrier-to-intermodulation ratio | dB |
| `IM_dBW` | `intermodulation_power` | intermodulation distortion power at the selected reference point | dBW |
| `eta_hpa_oper` | `hpa_operating_efficiency` | HPA efficiency at the selected output back-off | ratio |
| `eta_hpa_sat` | `hpa_saturated_efficiency` | HPA efficiency at saturated output | ratio |
| `P_rf_out` | `hpa_rf_output_power` | RF output power from the HPA | W |
| `P_dc_hpa` | `hpa_dc_input_power` | DC input power required by the HPA | W |
| `P_diss_hpa` | `hpa_dissipated_power` | HPA heat dissipation for thermal sizing | W |
| `B_carrier_i` | `carrier_occupied_bandwidth` | occupied bandwidth for carrier i | Hz |
| `B_transponder` | `transponder_bandwidth` | usable transponder bandwidth | Hz |
| `TransponderUtilization` | `transponder_bandwidth_utilization` | fraction of transponder bandwidth occupied by assigned carriers | ratio |
| `P_carrier_i_linear` | `carrier_power_linear` | assigned RF power for carrier i in linear units | W |
| `P_transponder_oper_linear` | `transponder_operating_power_linear` | available operating transponder RF output power in linear units | W |
| `PowerUtilization` | `transponder_power_utilization` | fraction of operating transponder RF power allocated to active carriers | ratio |

## Wireless Channel and Fading

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `x(t)` | `transmitted_baseband_signal` | transmitted baseband waveform | signal-unit |
| `y(t)` | `received_baseband_signal` | received baseband waveform after channel and noise | signal-unit |
| `h(t)` / `h(tau,t)` | `channel_impulse_response` | baseband channel impulse response, optionally time varying | unitless or path-gain |
| `n(t)` | `additive_noise_waveform` | additive receiver/channel noise waveform | signal-unit |
| `a_i(t)` | `multipath_complex_gain` | complex gain of multipath component i | complex ratio |
| `tau_i` | `multipath_delay` | excess delay of multipath component i | s |
| `P_i` | `power_delay_profile_tap_power` | power in delay tap i | W, relative power, dB |
| `tau_bar` | `mean_excess_delay` | power-weighted mean excess delay | s |
| `sigma_tau` | `rms_delay_spread` | root-mean-square delay spread | s |
| `B_c_50` / `B_c_90` | `coherence_bandwidth` | approximate coherence bandwidth for selected correlation criterion | Hz |
| `v_rel` | `relative_speed` | relative speed causing Doppler spread | m/s |
| `f_Dmax` | `maximum_doppler_shift` | maximum Doppler shift | Hz |
| `T_c` | `coherence_time` | approximate time over which fading is highly correlated | s |
| `PL_logdist` | `log_distance_path_loss` | path loss from log-distance/shadowing model | dB |
| `PL_d0` | `reference_distance_path_loss` | path loss at reference distance `d0` | dB |
| `d0` | `reference_distance` | reference distance for log-distance path loss | m |
| `n_path` | `path_loss_exponent` | environment-specific path-loss exponent | unitless |
| `X_sigma` | `shadowing_random_variable` | zero-mean Gaussian shadowing term in dB | dB |
| `gamma_bar` | `average_snr` | average SNR before instantaneous fading realization | ratio |
| `gamma_inst` | `instantaneous_snr` | instantaneous SNR after fading realization | ratio |
| `gamma_th` | `outage_snr_threshold` | SNR threshold defining outage | ratio |
| `P_out` | `outage_probability` | probability that instantaneous SNR is below threshold | ratio |
| `r` | `fading_envelope` | fading envelope magnitude | ratio |
| `sigma_h` | `rayleigh_scale` | Rayleigh diffuse-component scale parameter | ratio |
| `K_Rice` | `rician_k_factor` | specular-to-diffuse power ratio | ratio, dB |
| `s_LOS` | `los_component_amplitude` | deterministic/specular component amplitude in a Rician channel | ratio |
| `C_inst` | `instantaneous_channel_capacity` | instantaneous flat-fading capacity | bit/s |
| `C_ergodic` | `ergodic_channel_capacity` | channel capacity averaged over fading states | bit/s |

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
| `ErrorVector_i` | `constellation_error_vector` | measured symbol minus ideal reference symbol | complex signal-unit |
| `r_i` | `measured_constellation_symbol` | measured received constellation symbol | complex signal-unit |
| `s_ref_i` | `reference_constellation_symbol` | ideal reference symbol corresponding to `r_i` | complex signal-unit |
| `s_k` | `candidate_constellation_symbol` | kth ideal constellation point | complex signal-unit |
| `EVM_rms` | `evm_rms` | root-mean-square error vector magnitude | ratio, percent |
| `EVM_total` | `total_evm` | root-sum-square EVM from independent impairments | ratio, percent |
| `EVM_noise` / `EVM_phase` / `EVM_iq` / `EVM_nonlinear` | `evm_contributors` | EVM contribution from noise, phase error, I/Q imbalance, and nonlinear distortion | ratio, percent |
| `MER_dB` | `modulation_error_ratio` | modulation error ratio derived from RMS EVM | dB |
| `Decision(r_i)` | `hard_symbol_decision` | nearest-neighbor hard decision for a received symbol | constellation symbol |
| `d_min` | `minimum_constellation_distance` | minimum Euclidean distance among constellation points | signal-unit |
| `LLR_b` | `soft_bit_log_likelihood_ratio` | log-likelihood ratio for one coded bit position | log ratio |
| `S_b0` / `S_b1` | `constellation_bit_partitions` | subsets of symbols whose selected bit equals zero or one | set |
| `LLR_maxlog_b` | `maxlog_soft_bit_llr` | max-log approximation to the soft-bit LLR | log ratio |
| `p_Nyquist` | `nyquist_pulse_response` | pulse response satisfying zero-ISI samples at symbol times | signal-unit |
| `H_RC(f)` | `raised_cosine_response` | raised-cosine frequency response | response-unit |
| `H_RRC(f)` | `root_raised_cosine_response` | root-raised-cosine frequency response | response-unit |
| `f1` / `f2` | `raised_cosine_band_edges` | lower and upper transition-band edges in raised-cosine response | Hz |
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
| `B_loop_Hz` | `sync_loop_noise_bandwidth` | synchronization loop noise bandwidth | Hz |
| `BT_loop` | `normalized_loop_bandwidth` | loop bandwidth normalized by symbol period | cycles/symbol |
| `omega_n` | `loop_natural_frequency` | second-order loop natural radian frequency | rad/s |
| `zeta` | `loop_damping_factor` | second-order loop damping factor | unitless |
| `T_settle_2pct` | `loop_settling_time_2pct` | approximate two-percent settling time | s |
| `M_overshoot` | `loop_step_overshoot` | underdamped second-order step-response overshoot | ratio |
| `e_Gardner` | `gardner_timing_error` | Gardner timing-error detector output | detector-unit |
| `e_MM` | `mueller_muller_timing_error` | Mueller-Muller timing-error detector output | detector-unit |
| `e_EL` | `early_late_timing_error` | early-late timing-error detector output | detector-unit |
| `y_k` / `y_{k-1/2}` / `y_{k+1/2}` | `timing_recovery_samples` | matched-filter samples used by timing-error detectors | complex signal-unit |
| `a_hat_k` | `detected_symbol_decision` | detected or sliced symbol used in decision-directed timing recovery | complex signal-unit |
| `Delta_EL` | `early_late_sample_offset` | early/late sample offset around a symbol timing hypothesis | s |
| `e_Costas_BPSK` | `costas_bpsk_phase_error` | BPSK Costas-loop phase detector output | detector-unit |
| `I_k` / `Q_k` | `costas_iq_outputs` | in-phase and quadrature matched-filter outputs | signal-unit |
| `theta_hat_MPSK` | `mpsk_carrier_phase_estimate` | carrier phase estimate from Mth-power PSK method | rad, deg |
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
| `DFL` | `dvb_data_field_length` | DVB-S2 baseband data-field length before padding | bit |
| `DFL_Max` | `dvb_max_data_field_length` | maximum DVB-S2 data-field length for selected MODCOD/FECFRAME row | bit |
| `K_bch` | `dvb_bch_information_bits` | BCH information length and BBFRAME target length for selected DVB-S2 MODCOD row | bit |
| `N_bch` | `dvb_bch_codeword_bits` | BCH codeword length before LDPC encoding | bit |
| `N_ldpc` | `dvb_ldpc_frame_bits` | LDPC FECFRAME length, typically normal or short frame length from DVB-S2 tables | bit |
| `BBPaddingBits` | `dvb_bbframe_padding_bits` | zero padding bits inserted after the data field before BCH encoding | bit |
| `BBFrameBits` | `dvb_bbframe_bits` | DVB-S2 baseband frame bits delivered to BCH encoder | bit |
| `BCHParityBits` | `dvb_bch_parity_bits` | parity bits added by the DVB-S2 BCH outer code | bit |
| `LDPCParityBits` | `dvb_ldpc_parity_bits` | parity bits added by the DVB-S2 LDPC inner code | bit |
| `DVB_FECFrameEfficiency` | `dvb_fecframe_efficiency` | BCH information length divided by LDPC frame length | ratio |
| `DVB_FECFrameOverhead` | `dvb_fecframe_overhead` | FEC overhead relative to BCH information length | ratio |
| `DVB_ModulatedSymbols` | `dvb_modulated_symbols` | modulation symbols carrying one FECFRAME | symbol |
| `DVB_PLSLOTS` | `dvb_plslot_count` | DVB-S2 physical-layer slot count, 90 modulation symbols per slot | slot |
| `PilotEnabled` | `dvb_pilots_enabled` | whether DVB-S2 pilot blocks are inserted | boolean |
| `DVB_PilotBlocks` | `dvb_pilot_block_count` | count of 36-symbol DVB-S2 pilot blocks in one PLFRAME | block |
| `DVB_PLFrameSymbols` | `dvb_plframe_symbols` | total modulation symbols in one DVB-S2 PLFRAME including header and pilots | symbol |
| `R_sym` | `dvb_symbol_rate` | transmitted DVB-S2 modulation symbol rate | symbol/s |
| `DVB_FrameDuration` | `dvb_plframe_duration` | duration of one DVB-S2 PLFRAME | s |
| `DVB_PHYEfficiency_bpsym` | `dvb_physical_efficiency_bits_per_symbol` | net data-field bits per transmitted modulation symbol | bit/symbol |
| `DVB_OccupiedBandwidth` | `dvb_occupied_bandwidth` | first-order occupied RF bandwidth for rolloff-shaped DVB-S2 signal | Hz |
| `DVB_SpectralEfficiency_bpsHz` | `dvb_spectral_efficiency` | net data spectral efficiency after frame, pilot, and rolloff overhead | bit/s/Hz |
| `DVB_NetBitRate` | `dvb_net_bit_rate` | net data-field bit rate after physical-layer overhead | bit/s |
| `DVB_PLHeaderFraction` | `dvb_plheader_fraction` | fraction of PLFRAME symbols occupied by the 90-symbol PLHEADER | ratio |
| `DVB_PilotOverhead` | `dvb_pilot_overhead` | fraction of PLFRAME symbols occupied by pilot blocks | ratio |

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
| `COP1_FrameSequenceModulus` | `cop1_frame_sequence_modulus` | modulo base for COP-1 8-bit frame sequence arithmetic | unit |
| `V_S` | `cop1_transmitter_frame_sequence_number` | FOP-1 Transmitter_Frame_Sequence_Number, the next Type-AD `N(S)` to transmit | integer |
| `V_R` | `cop1_receiver_frame_sequence_number` | FARM-1 Receiver_Frame_Sequence_Number, the next expected Type-AD `N(S)` | integer |
| `N_S` | `cop1_frame_sequence_number` | Frame Sequence Number in a Type-AD Transfer Frame primary header | integer |
| `N_R` | `cop1_next_expected_frame_sequence_number` | Next Expected Frame Sequence Number reported in a CLCW | integer |
| `NN_R` | `cop1_expected_acknowledgement_frame_sequence_number` | oldest unacknowledged Type-AD frame sequence number on the Sent_Queue | integer |
| `K` | `cop1_fop_sliding_window_width` | FOP_Sliding_Window_Width managed parameter | frame |
| `W` | `cop1_farm_sliding_window_width` | FARM_Sliding_Window_Width managed parameter | frame |
| `PW` | `cop1_farm_positive_window_width` | positive part of the FARM sliding window | frame |
| `NW` | `cop1_farm_negative_window_width` | negative part of the FARM sliding window | frame |
| `COP1_OutstandingADFrames` | `cop1_outstanding_ad_frames` | Type-AD sequence distance between `V(S)` and `NN(R)` | frame |
| `COP1_FOPWindowOpen` | `cop1_fop_window_open` | whether FOP-1 may accept/transmit another Type-AD FDU under window control | boolean |
| `T1_Initial` | `cop1_t1_initial` | FOP-1 timer initial value | s |
| `t_send_lower` | `cop1_sending_lower_processing_time` | processing delay below FOP-1 at the sending end | s |
| `T_max_frame_tx` | `cop1_max_frame_transmission_time` | time to radiate a maximum-length transfer frame including CLTU and coding bits | s |
| `MaxCLTUBits` | `max_cltu_bits` | maximum CLTU/coded bit count for the selected TC path | bit |
| `tau_forward` | `forward_one_way_light_time` | one-way propagation time from sender to receiver | s |
| `tau_return` | `return_one_way_light_time` | one-way propagation time for the return CLCW path | s |
| `t_farm_lower` | `cop1_receiving_lower_processing_time` | processing delay below FARM-1 at the receiving end | s |
| `t_clcw_sample` | `clcw_status_sample_encode_time` | worst-case time to sample and encode FARM-1 status as a CLCW | s |
| `T_clcw_tx` | `clcw_return_transmission_time` | worst-case time to transmit the CLCW in the return-link data structure | s |
| `t_clcw_extract` | `clcw_extract_delivery_time` | time to extract the CLCW and deliver it to FOP-1 | s |
| `Transmission_Limit` | `cop1_transmission_limit` | maximum transmissions of the first frame on the Sent_Queue, including first transmission | unit |
| `Transmission_Count` | `cop1_transmission_count` | count of transmissions for the first frame on the Sent_Queue | unit |
| `COP1_AttemptsRemaining` | `cop1_attempts_remaining` | remaining transmissions before reaching Transmission_Limit | unit |
| `SentQueueLength` | `cop1_sent_queue_length` | number of Type-AD or Type-BC frames held in the Sent_Queue | frame |
| `COP1_PositiveWindowOffset` | `cop1_positive_window_offset` | modulo-256 distance from `V(R)` to received `N(S)` | frame |
| `COP1_NegativeWindowOffset` | `cop1_negative_window_offset` | modulo-256 distance from received `N(S)` back to `V(R)` | frame |
| `CLCW_ReportingPeriod` | `clcw_reporting_period` | managed CLCW status reporting period | s |
| `CLCW_ReportRate` | `clcw_report_rate` | CLCW status reports per second | Hz |
| `Timeout_Type` | `cop1_timeout_type` | FOP-1 timeout action selector, 0 or 1 | enum |

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
| `GeneratedBits` | `generated_bits` | data produced during a planning interval | bit |
| `SourceRate_i` | `source_rate` | source or payload data rate for item `i` | bps |
| `PlanningPeriod` | `planning_period` | schedule or analysis interval | s, h, day |
| `ScheduledContactTime` | `scheduled_contact_time` | gross contact window duration | s |
| `AcquisitionTime` | `acquisition_time` | time spent acquiring the link or target | s |
| `PointingSettleTime` | `pointing_settle_time` | time reserved for antenna or spacecraft pointing settle | s |
| `ProtocolSetupTime` | `protocol_setup_time` | protocol, ranging, synchronization, or session setup time | s |
| `UsableContactTime` | `usable_contact_time` | contact duration available for useful payload transfer | s |
| `PassCapacityBits` | `pass_capacity_bits` | payload bits transferable in one contact | bit |
| `DownlinkCapacityBits` | `downlink_capacity_bits` | aggregate payload bits transferable across contacts | bit |
| `LinkAvailability_j` | `contact_link_availability` | probability or fraction of a contact usable after fade/weather constraints | ratio |
| `StorageStartBits` | `storage_start_bits` | recorder occupancy at start of interval | bit |
| `StorageEndBits` | `storage_end_bits` | recorder occupancy at end of interval | bit |
| `StorageUsedBits(t)` | `storage_used_bits_time_history` | time-varying recorder occupancy | bit |
| `ContactEfficiency` | `contact_efficiency` | usable contact time divided by scheduled contact time | ratio |
| `PassesRequired` | `passes_required` | count of similar contacts needed | count |
| `LayeredEfficiency` | `layered_efficiency` | product of frame, coding, protocol, and security efficiencies | ratio |
| `TargetDownlinkBits` | `target_downlink_bits` | useful payload bit budget available in a contact | bit |
| `QueueBits` | `queue_bits` | queued onboard data awaiting downlink | bit |
| `QueueDrainTime` | `queue_drain_time` | time required to empty queued data at a fixed rate | s |
| `Power_i` | `power_state_value` | power consumed in state `i` | W |
| `Duration_i` | `power_state_duration` | duration spent in state `i` | s |
| `EnergyUsed` | `energy_used` | energy consumed by scheduled states | J, Wh |
| `BatteryCapacityEnergy` | `battery_capacity_energy` | usable battery energy capacity | J, Wh |
| `BatteryDepthOfDischarge` | `battery_depth_of_discharge` | consumed fraction of battery energy | ratio |
| `AverageGeneratedRate` | `average_generated_rate` | average generated data rate over the planning period | bps |
| `RecorderTurnoverTime` | `recorder_turnover_time` | fill time at average data generation rate without downlink | s |
| `ContactUtilization` | `contact_utilization` | demanded data volume divided by scheduled downlink capacity | ratio |
| `GeneratedScienceBits` | `generated_science_bits` | science data produced | bit |
| `DownlinkedScienceBits` | `downlinked_science_bits` | science data returned to ground | bit |
| `ScienceReturnFraction` | `science_return_fraction` | returned science fraction | ratio |
| `Range` | `operations_range` | one-way distance for light-time planning | m, km |

## Optical Communications

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `D_t` / `D_r` | `optical_tx_rx_aperture` | optical transmit or receive telescope aperture diameter | m |
| `eta_opt` | `optical_aperture_efficiency` | optical aperture efficiency | ratio |
| `G_t_opt` / `G_r_opt` | `optical_telescope_gain` | optical transmit or receive telescope gain | ratio, dB |
| `theta_div` | `optical_beam_divergence` | optical beam divergence angle | rad, urad |
| `sigma_beam` | `optical_gaussian_beam_sigma` | Gaussian beam angular standard deviation for pointing-loss approximation | rad, urad |
| `P_t_opt` | `optical_tx_power` | transmitted optical power | W, dBW, dBm |
| `P_r_opt` | `optical_rx_power` | received optical power | W, dBW, dBm |
| `L_opt_ratio` | `optical_link_transmission_factor` | linear optical link transfer factor from transmit power to received optical power | ratio |
| `eta_tx` / `eta_rx` | `optical_tx_rx_efficiency` | transmitter and receiver optical throughput efficiencies | ratio |
| `eta_atmos` | `optical_atmospheric_transmission` | optical atmospheric transmission factor | ratio |
| `eta_point` | `optical_pointing_efficiency` | pointing loss represented as a power efficiency | ratio |
| `eta_QE` | `detector_quantum_efficiency` | detector quantum efficiency or photon detection efficiency | ratio |
| `eta_ATP` | `acquisition_tracking_optical_efficiency` | acquisition/tracking optical train transmission | ratio |
| `eta_trans` | `beacon_transmitter_efficiency` | uplink beacon transmitter optical efficiency | ratio |
| `E_photon` | `photon_energy` | energy per photon | J |
| `N_photons` | `photon_arrival_rate` | photon arrival rate from received optical power | photon/s |
| `K_s` | `signal_photons_per_slot` | mean signal photon/photoelectron count in a signal slot or pulse | photon, photoelectron |
| `K_b` | `background_photons_per_slot` | mean background plus dark-count photon/photoelectron count per slot | photon, photoelectron |
| `P_bg` | `background_optical_power` | background optical power entering the detector channel | W |
| `DCR` | `dark_count_rate` | detector dark count rate | count/s |
| `M_PPM` | `ppm_order` | pulse-position modulation order | unit |
| `T_slot` | `ppm_slot_width` | PPM slot duration | s |
| `Pav_photons_per_slot` | `ppm_average_photons_per_slot` | average signal photons per PPM slot | photon/slot |
| `PPM_PAPR` | `ppm_peak_to_average_power_ratio` | PPM optical peak-to-average power ratio | ratio, dB |
| `rho_photon` | `photon_efficiency` | information bits per detected signal photon | bit/photon |
| `Ps_PPM` | `ppm_symbol_error_probability` | PPM symbol error probability | ratio |
| `N_pe_frame` | `tracking_photoelectrons_per_frame` | target signal photoelectrons per acquisition/tracking frame | photoelectron/frame |
| `F_frame` | `tracking_frame_rate` | acquisition/tracking sensor frame rate | frame/s |
| `L_lambda` | `sky_spectral_radiance` | sky spectral radiance at the receive wavelength and solar geometry | W/m^2/sr/um |
| `H_lambda` | `point_source_spectral_irradiance` | stellar or planetary point-source spectral irradiance at receiver | W/m^2/um |
| `A_R_opt` | `optical_receiver_effective_area` | effective optical receiver collection area | m^2 |
| `Omega_FOV` | `optical_receiver_fov_solid_angle` | detector or field-stop solid angle | sr |
| `theta_FOV` | `optical_receiver_fov_angle` | receiver full-angle field of view | rad, urad |
| `theta_FOV_diff` | `diffraction_limited_fov` | diffraction-limited full-angle FOV scale | rad, urad |
| `Delta_lambda` | `optical_filter_bandwidth` | receiver optical bandpass | um, nm |
| `eta_R` | `optical_receiver_system_efficiency` | receive optical system efficiency for background/light collection | ratio |
| `P_sky` | `sky_background_power` | diffuse sky-background optical power in receiver FOV | W |
| `P_point` | `point_source_background_power` | point-source optical background power | W |
| `r_sep` | `turbulence_separation` | spatial separation used in refractive-index structure function | m |
| `D_n` | `refractive_index_structure_function` | refractive-index structure function value | unitless |
| `C_n2` | `refractive_index_structure_parameter` | refractive-index structure parameter for optical turbulence | m^(-2/3) |
| `k_opt` | `optical_wave_number` | optical wave number | 1/m |
| `zeta_zenith` | `optical_zenith_angle` | zenith angle for optical atmospheric path | rad, deg |
| `h_path` | `optical_turbulence_path_height` | path-height coordinate for integrating `C_n2` | m |
| `r0` | `fried_parameter` | atmospheric coherence diameter | m, cm |
| `theta_seeing` | `atmospheric_seeing_angle` | angular broadening caused by turbulence | rad, urad |
| `f_opt` | `optical_receiver_focal_length` | receive telescope focal length | m |
| `spot_diff_diameter` | `diffraction_limited_spot_diameter` | focal-plane diffraction-limited spot diameter | m, um |
| `spot_seeing_diameter` | `seeing_limited_spot_diameter` | focal-plane spot diameter broadened by atmospheric seeing | m, um |
| `S` | `selected_detector_set` | selected detector-array element subset | set |
| `K_s_i` / `K_b_i` | `detector_element_signal_background_counts` | per-element signal and background counts | photon, photoelectron |
| `K_s_array` / `K_b_array` | `detector_array_signal_background_counts` | selected-array signal and background count totals | photon, photoelectron |
| `P_SE` | `ppm_symbol_error_probability_array` | symbol error probability for a detector-array selection | ratio |
| `M_link_FSO_dB` | `fso_link_margin` | terrestrial free-space optical link margin | dB |
| `P_e_dBm` | `fso_emitter_power` | emitted optical power in P.1814 link margin | dBm |
| `S_r_dBm` | `fso_receiver_sensitivity` | receiver sensitivity at selected data rate/bandwidth | dBm |
| `A_geo_dB` | `fso_geometrical_attenuation` | attenuation from beam spreading and receiver capture area | dB |
| `A_atmo_dB` | `fso_atmospheric_attenuation` | total atmospheric attenuation for FSO link budget | dB |
| `A_scint_dB` | `fso_scintillation_attenuation` | scintillation fade allowance | dB |
| `A_system_dB` | `fso_system_loss` | pointing, optics, beam-wander, and other system losses | dB |
| `S_d` | `fso_beam_surface_at_receiver` | beam footprint surface area at receiver range | m^2 |
| `Scapture` | `fso_receiver_capture_surface` | receiver capture surface area | m^2 |
| `d_km` | `fso_link_distance` | terrestrial FSO emitter-receiver distance | km |
| `theta_mrad` | `fso_beam_divergence_mrad` | beam divergence used in P.1814 geometric attenuation | mrad |
| `gamma_atmo` | `fso_specific_atmospheric_attenuation` | total specific atmospheric attenuation | dB/km |
| `gamma_clear_air` | `fso_specific_clear_air_attenuation` | specific attenuation under clear-air conditions | dB/km |
| `gamma_excess` | `fso_specific_excess_attenuation` | specific attenuation from aerosol, haze, fog, rain, snow, hail, or similar particles | dB/km |
| `gamma_sp` | `fso_specific_suspended_particle_attenuation` | specific attenuation due to suspended particles | dB/km |
| `K_VIS` | `visibility_conversion_coefficient` | coefficient selected by visibility measurement method | dB |
| `V_km` | `visibility_distance` | meteorological visibility or MOR-derived visibility | km |
| `V_T2` / `V_T5` | `visibility_threshold_distance` | visibility referenced to 2 percent or 5 percent irradiance threshold | km |
| `lambda_um` / `lambda_nm` | `optical_wavelength_um_nm` | optical wavelength for attenuation or solar polynomial models | um, nm |
| `q_VIS` | `visibility_wavelength_exponent` | P.1814 particle-size exponent for wavelength-dependent suspended-particle attenuation | unitless |
| `L_km` / `L_m` | `fso_path_length` | FSO path length in the units required by a specific formula | km, m |
| `sigma_chi2_dB2` | `scintillation_log_amplitude_variance` | log-amplitude scintillation variance | dB^2 |
| `El_sun` | `solar_elevation_angle` | sun elevation angle in the P.1814 ambient-light model | rad |
| `P_radiated_sun` | `solar_radiated_power` | approximate solar radiated power | W/m^2 |
| `F_solar` | `solar_spectral_power_factor` | solar spectral power factor from P.1814 polynomial fit | model-specific |
| `W_receiver` | `receiver_optical_bandwidth_nm` | receiver optical bandwidth in the P.1814 solar-background model | nm |
| `P_solar` | `solar_background_power` | solar ambient power entering the receiver | W |

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
| `epsilon` | `specific_orbital_energy` | two-body specific orbital energy | J/kg |
| `v` | `spacecraft_speed` | spacecraft inertial speed | m/s, km/s |
| `r_vec` | `inertial_position_vector` | spacecraft inertial position vector | m, km |
| `v_vec` | `inertial_velocity_vector` | spacecraft inertial velocity vector | m/s, km/s |
| `h_vec` | `specific_angular_momentum_vector` | specific angular momentum vector | km^2/s, m^2/s |
| `h_orbit` | `specific_angular_momentum` | magnitude of specific angular momentum | km^2/s, m^2/s |
| `e` | `eccentricity` | scalar orbit eccentricity | unitless |
| `e_vec` | `eccentricity_vector` | eccentricity vector | unitless |
| `p` | `semilatus_rectum` | conic semilatus rectum | m, km |
| `nu` | `true_anomaly` | true anomaly | rad, deg |
| `r_orbit` | `orbit_radius_at_true_anomaly` | conic radius at a specified true anomaly | m, km |
| `r_p` | `periapsis_radius` | periapsis/perigee radius | m, km |
| `r_a` | `apoapsis_radius` | apoapsis/apogee radius | m, km |
| `a_E` | `earth_ellipsoid_semi_major_axis` | Earth ellipsoid semi-major axis | m, km |
| `e_E` | `earth_ellipsoid_eccentricity` | Earth ellipsoid eccentricity | unitless |
| `phi` | `station_geodetic_latitude` | station geodetic latitude | rad, deg |
| `lon` | `station_longitude` | station longitude | rad, deg |
| `h_site` | `station_height` | station ellipsoidal height | m, km |
| `N_phi` | `prime_vertical_radius` | prime vertical radius of curvature | m, km |
| `r_site_ecef` | `station_ecef_position` | station Earth-fixed position vector | m, km |
| `r_sat_ecef` | `satellite_ecef_position` | spacecraft Earth-fixed position vector | m, km |
| `rho_ecef` | `ecef_relative_vector` | satellite minus station vector in ECEF | m, km |
| `dx` | `ecef_delta_x` | ECEF relative X component | m, km |
| `dy` | `ecef_delta_y` | ECEF relative Y component | m, km |
| `dz` | `ecef_delta_z` | ECEF relative Z component | m, km |
| `r_eci` | `satellite_eci_position` | spacecraft inertial position vector | m, km |
| `theta_GMST` | `greenwich_sidereal_angle` | Greenwich sidereal rotation angle | rad, deg |
| `E_min` | `minimum_elevation_mask` | minimum elevation for access | rad, deg |
| `psi_Emin` | `minimum_elevation_access_angle` | central angle at the access boundary | rad, deg |
| `rho_Emin` | `minimum_elevation_slant_range` | slant range at the minimum-elevation access boundary | m, km |
| `coverage_radius` | `coverage_radius` | spherical-Earth ground footprint radius | m, km |
| `RangeMax` | `maximum_range_limit` | maximum allowed communications or sensor range | m, km |
| `omega_rel` | `relative_apparent_angular_rate` | apparent angular rate across an access region | rad/s |
| `omega_E` | `earth_rotation_rate` | Earth sidereal rotation rate | rad/s |
| `GroundTrackShiftPerOrbit` | `ground_track_shift_per_orbit` | Earth-rotation longitude shift during one orbit | rad, deg |
| `i` | `inclination` | orbit inclination | rad, deg |
| `u` | `argument_of_latitude` | argument of latitude | rad, deg |
| `lat_ss` | `subsatellite_latitude` | subsatellite latitude | rad, deg |
| `lon_ss` | `subsatellite_longitude` | subsatellite longitude | rad, deg |

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
| `InputSamples` | `compression_input_samples` | number of source samples entering the compressor | sample |
| `J` | `compression_block_size_samples` | CCSDS 121 samples per entropy-coder block; valid standard values are 8, 16, 32, or 64 | sample/block |
| `InputBlocks` | `compression_input_blocks` | number of `J`-sample blocks after padding | block |
| `PaddingSamples` | `compression_padding_samples` | samples appended to complete the final block | sample |
| `r` | `reference_sample_interval_blocks` | CCSDS 121 reference sample interval in blocks | block |
| `ReferenceSampleCount` | `reference_sample_count` | number of uncoded reference samples inserted in the coded stream | sample |
| `ReferenceSampleBits` | `reference_sample_bits` | bits occupied by uncoded reference samples | bit |
| `n` | `sample_resolution_bits` | CCSDS 121 sample resolution | bit/sample |
| `x_i` | `compression_sample_value` | input sample value at index `i` | source-unit |
| `xhat_i` | `compression_predicted_sample` | predicted sample value used by CCSDS 121 preprocessing | source-unit |
| `Delta_i` | `compression_prediction_error` | signed prediction error before mapping | source-unit |
| `delta_i` | `compression_mapped_prediction_error` | nonnegative mapped prediction error entering entropy coding | integer |
| `theta_i` | `compression_mapper_threshold` | prediction-error mapper threshold | source-unit |
| `x_min` | `sample_minimum_value` | minimum representable sample value | source-unit |
| `x_max` | `sample_maximum_value` | maximum representable sample value | source-unit |
| `k` | `split_sample_parameter` | number of LSBs transmitted uncoded in a CCSDS 121 split-sample option | bit |
| `SplitMSB_i` | `split_sample_msb_value` | integer value encoded by FS codeword in a split-sample option | integer |
| `SplitLSB_i` | `split_sample_lsb_value` | low-order `k` bits sent uncoded in a split-sample option | integer |
| `EncodedSamplesInBlock` | `encoded_samples_in_block` | samples encoded in the block, `J` or `J-1` when a reference sample is present | sample |
| `gamma_j` | `second_extension_symbol` | CCSDS 121 second-extension symbol for sample pair `j` | integer |
| `BlocksInReferenceInterval` | `blocks_in_reference_interval` | block count in a reference interval or final partial interval | block |
| `IDBits` | `compression_option_id_bits` | option-identification key length for a coded data set | bit |
| `EncodedBits_option` | `compression_candidate_encoded_bits` | candidate encoded length for one code option | bit |
| `N_x` | `image_cross_track_samples` | image samples in the cross-track/sample dimension | sample |
| `N_y` | `image_frames_or_lines` | image frames or lines in the along-track dimension | frame, line |
| `N_z` | `image_spectral_bands` | spectral bands in a multispectral/hyperspectral cube | band |
| `D` | `image_sample_bit_depth` | image sample dynamic range in bits | bit/sample |
| `s_z(t)` | `spectral_sample_value` | sample value for spectral band `z` at index `t` | DN |
| `s_hat_z(t)` | `spectral_predicted_sample` | predicted sample in CCSDS 123 notation | DN |
| `s_tilde_z(t)` | `spectral_scaled_predicted_sample` | integer scaled predicted sample with one extra bit of resolution | DN |
| `m_z(t)` | `near_lossless_max_error` | per-sample maximum reconstruction error for CCSDS 123 near-lossless mode | DN |
| `a_z` | `absolute_error_limit` | band-specific absolute error limit | DN |
| `u` | `error_limit_update_exponent` | exponent controlling periodic error-limit updates | unit |
| `CompressedImageBits` | `compressed_image_bits` | compressed image size | bit |
| `AcquisitionDuration` | `image_acquisition_duration` | duration over which the image cube is acquired | s |

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
| `SpacePacketPrimaryHeaderBits` | `space_packet_primary_header_bits` | CCSDS Space Packet primary header length | bit |
| `SpacePacketPrimaryHeaderOctets` | `space_packet_primary_header_octets` | CCSDS Space Packet primary header length | octet |
| `PacketDataLength` | `space_packet_data_length_field` | 16-bit field storing one fewer than the Space Packet Data Field octet count | octet-count-minus-one |
| `SpacePacketDataFieldOctets` | `space_packet_data_field_octets` | Space Packet Data Field length | octet |
| `SpacePacketOctets` | `space_packet_octets` | complete Space Packet length | octet |
| `SpacePacketMinOctets` | `space_packet_min_octets` | minimum complete Space Packet length | octet |
| `SpacePacketMaxDataFieldOctets` | `space_packet_max_data_field_octets` | maximum Space Packet Data Field length | octet |
| `SpacePacketMaxOctets` | `space_packet_max_octets` | maximum complete Space Packet length | octet |
| `PacketSecondaryHeaderOctets` | `packet_secondary_header_octets` | optional Space Packet secondary header length | octet |
| `SpacePacketUserDataOctets` | `space_packet_user_data_octets` | user data carried in a Space Packet after secondary-header overhead | octet |
| `SpacePacketEfficiency` | `space_packet_efficiency` | user-data fraction of a Space Packet | ratio |
| `APIDCount` | `space_packet_apid_count` | number of representable APID values | unit |
| `IdleAPID` | `space_packet_idle_apid` | all-ones APID reserved for idle packets | integer |
| `PacketSequenceModulus` | `space_packet_sequence_modulus` | wrap modulus for the Packet Sequence Count | unit |
| `PacketSequenceCount` | `space_packet_sequence_count` | 14-bit packet sequence count for an APID | integer |
| `PacketSegmentsNeeded` | `space_packet_segments_needed` | number of packets needed for a user data unit | packet |
| `MaxUserDataPerPacketOctets` | `max_user_data_per_space_packet_octets` | selected maximum user-data capacity per Space Packet | octet |
| `USLP_MCIDBits` | `uslp_master_channel_id_bits` | USLP MCID field width | bit |
| `USLP_GVCIDBits` | `uslp_global_virtual_channel_id_bits` | USLP GVCID field width | bit |
| `USLP_GMAPIDBits` | `uslp_global_map_id_bits` | USLP GMAP ID field width | bit |
| `USLP_SCIDCount` | `uslp_spacecraft_id_count` | number of SCID values representable in USLP | unit |
| `USLP_VCIDCount` | `uslp_virtual_channel_id_count` | number of VCID values representable in USLP | unit |
| `USLP_UserVCIDCount` | `uslp_user_virtual_channel_id_count` | usable non-OID VCID value count | unit |
| `USLP_MAPIDCount` | `uslp_map_id_count` | number of MAP ID values representable in USLP | unit |
| `USLP_FrameLengthCount` | `uslp_frame_length_count` | 16-bit field storing one fewer than the USLP Transfer Frame octet count | octet-count-minus-one |
| `USLP_FrameOctets` | `uslp_frame_octets` | complete USLP Transfer Frame length | octet |
| `USLP_MaxFrameOctets` | `uslp_max_frame_octets` | maximum USLP Transfer Frame length implied by the Frame Length field | octet |
| `USLP_PrimaryHeaderBaseBits` | `uslp_primary_header_base_bits` | non-truncated primary-header fixed field length before VCF Count | bit |
| `USLP_VCFCountOctets` | `uslp_vcf_count_octets` | selected Virtual Channel Frame Count field length | octet |
| `USLP_VCFCountBits` | `uslp_vcf_count_bits` | selected Virtual Channel Frame Count field length | bit |
| `USLP_PrimaryHeaderOctets` | `uslp_primary_header_octets` | non-truncated USLP Transfer Frame Primary Header length | octet |
| `USLP_VCFCountModulus` | `uslp_vcf_count_modulus` | wrap modulus for the selected VCF Count width | unit |
| `USLP_VCFCount` | `uslp_vcf_count` | Virtual Channel Frame Count value | integer |
| `USLP_TruncatedPrimaryHeaderBits` | `uslp_truncated_primary_header_bits` | truncated USLP primary-header length | bit |
| `USLP_TruncatedPrimaryHeaderOctets` | `uslp_truncated_primary_header_octets` | truncated USLP primary-header length | octet |
| `USLP_OCFOctets` | `uslp_ocf_octets` | USLP Operational Control Field length when present | octet |
| `USLP_FECFOctets` | `uslp_fecf_octets` | USLP Frame Error Control Field length when present | octet |
| `InsertZoneOctets` | `transfer_frame_insert_zone_octets` | Transfer Frame Insert Zone length | octet |
| `USLP_TFDFOctets` | `uslp_tfdf_octets` | USLP Transfer Frame Data Field length | octet |
| `USLP_SDLS_TFDFOctets` | `uslp_sdls_tfdf_octets` | USLP Transfer Frame Data Field length after SDLS overhead | octet |
| `FHP_LVOP_Present` | `uslp_fhp_lvop_present` | whether the optional First Header/Last Valid Octet Pointer is present | boolean |
| `USLP_TFDFHeaderOctets` | `uslp_tfdf_header_octets` | USLP Transfer Frame Data Field Header length | octet |
| `USLP_TFDZOctets` | `uslp_tfdz_octets` | USLP Transfer Frame Data Zone length | octet |
| `USLP_FrameEfficiency` | `uslp_frame_efficiency` | TFDZ fraction of the complete USLP Transfer Frame | ratio |
| `USLP_PointerAllOnes` | `uslp_pointer_all_ones_value` | all-ones 16-bit FHP/LVOP special value | integer |
| `USLP_OID_VCID` | `uslp_oid_vcid` | Only Idle Data Transfer Frame VCID value | integer |
| `USLP_OID_MAPID` | `uslp_oid_mapid` | Only Idle Data Transfer Frame MAP ID value | integer |
| `ValidDataOctets` | `valid_data_octets` | valid data octets within a fixed-length data zone | octet |
| `USLP_FixedTFDZIdleOctets` | `uslp_fixed_tfdz_idle_octets` | idle octets inserted to complete a fixed-length TFDZ | octet |
| `SDUOctets` | `service_data_unit_octets` | service data unit length | octet |
| `USLP_MaxTFDZOctetsForSAP` | `uslp_max_tfdz_octets_for_sap` | selected maximum TFDZ capacity for a SAP/VC/MAP service | octet |
| `USLP_SegmentsNeeded` | `uslp_segments_needed` | number of USLP frames needed for segmented SDU transport | frame |
| `AOS_FrameOctets` | `aos_frame_octets` | total AOS Transfer Frame length | octet |
| `AOS_PrimaryHeaderOctets` | `aos_primary_header_octets` | AOS Transfer Frame Primary Header length | octet |
| `AOS_GVCIDBits` | `aos_gvcid_bits` | AOS Global Virtual Channel Identifier field width | bit |
| `AOS_VCIDCount` | `aos_vcid_count` | number of AOS virtual channel identifiers | count |
| `AOS_VCFrameCountModulus` | `aos_vc_frame_count_modulus` | wrap modulus for the AOS Virtual Channel Frame Count | count |
| `AOS_VCFrameCount` | `aos_vc_frame_count` | current AOS Virtual Channel Frame Count | count |
| `AOS_SignalingBits` | `aos_signaling_bits` | AOS signaling field width in the primary header | bit |
| `AOS_InsertZoneOctets` | `aos_insert_zone_octets` | AOS Transfer Frame Insert Zone length | octet |
| `AOS_OCFOctets` | `aos_ocf_octets` | AOS Operational Control Field length when present | octet |
| `AOS_FECFOctets` | `aos_fecf_octets` | AOS Frame Error Control Field length when present | octet |
| `AOS_DataFieldOctets` | `aos_data_field_octets` | AOS Transfer Frame Data Field capacity | octet |
| `AOS_M_PDU_HeaderOctets` | `aos_mpdu_header_octets` | AOS M_PDU header length containing the First Header Pointer | octet |
| `AOS_M_PDU_PacketZoneOctets` | `aos_mpdu_packet_zone_octets` | AOS packet-zone capacity in M_PDU service | octet |
| `AOS_VCA_SDU_Octets` | `aos_vca_sdu_octets` | AOS Virtual Channel Access service data unit size | octet |
| `AOS_SDLS_DataFieldOctets` | `aos_sdls_data_field_octets` | AOS data-field capacity after SDLS security fields | octet |
| `AOS_FrameEfficiency` | `aos_frame_efficiency` | AOS data-field fraction of the full frame | ratio |
| `AOS_PacketServiceEfficiency` | `aos_packet_service_efficiency` | AOS M_PDU packet-zone fraction of the full frame | ratio |
| `PlaintextBits` | `plaintext_bits` | security payload bits before security overhead | bit |
| `IVBits` | `initialization_vector_bits` | security initialization vector length | bit |
| `AuthTagBits` | `auth_tag_bits` | authentication tag length | bit |
| `PER` | `packet_error_rate` | packet/frame error probability | ratio |
| `AckDelay` | `ack_delay` | acknowledgement delay | s, ms |
| `PFD` | `power_flux_density` | power flux density | W/m^2, dBW/m^2 |
| `PSD` | `power_spectral_density` | power spectral density | W/Hz, dBW/Hz |
| `V_rms` | `rms_voltage` | RMS voltage | V |
| `Z` | `impedance` | RF/load impedance when used in `P=V^2/Z` | ohm |
