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
| `A_e` | `effective_aperture` | effective receiving aperture | m^2 |
| `G` | `antenna_gain_linear` | antenna gain linear | ratio |
| `G_dBi` | `antenna_gain` | antenna gain relative to isotropic | dBi |
| `G/T` | `g_over_t` | gain-to-noise-temperature ratio | dB/K |
| `P_tx` | `tx_power` | transmitter RF output power | W, dBW, dBm |
| `L_tx` | `tx_loss` | transmitter-side feed/network loss | dB |
| `EIRP` | `eirp` | effective isotropic radiated power | dBW, dBm |
| `ERP` | `erp` | effective radiated power relative to dipole | dBW, dBm |
| `VSWR` | `vswr` | voltage standing wave ratio | ratio |
| `Gamma` | `reflection_coefficient` | reflection coefficient magnitude | ratio |
| `theta_3dB` | `beamwidth_3db` | half-power beamwidth | deg, rad |
| `theta_error` | `pointing_error` | pointing offset from boresight | deg, rad |

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

## Modulation and Coding

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `M` | `modulation_order` | modulation constellation size | unit |
| `m` | `bits_per_symbol` | bits per symbol, `log2(M)` | bit/symbol |
| `R_c` | `coding_rate` | channel coding rate | ratio |
| `alpha` | `rolloff` | raised-cosine rolloff factor | ratio |
| `BER` | `bit_error_rate` | bit error probability | ratio |
| `SER` | `symbol_error_rate` | symbol error probability | ratio |
| `PER` | `packet_error_rate` | packet or frame error probability | ratio |
| `EVM` | `evm` | error vector magnitude | ratio, percent |
| `depth` | `interleaver_depth` | interleaver depth | unit |
| `block_bits` | `codeblock_bits` | code block length | bit |
| `InfoBits` | `information_bits` | uncoded information length entering a channel encoder | bit |
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
| `PlaintextBits` | `plaintext_bits` | security payload bits before security overhead | bit |
| `IVBits` | `initialization_vector_bits` | security initialization vector length | bit |
| `AuthTagBits` | `auth_tag_bits` | authentication tag length | bit |
| `PER` | `packet_error_rate` | packet/frame error probability | ratio |
| `AckDelay` | `ack_delay` | acknowledgement delay | s, ms |
| `PFD` | `power_flux_density` | power flux density | W/m^2, dBW/m^2 |
| `PSD` | `power_spectral_density` | power spectral density | W/Hz, dBW/Hz |
| `V_rms` | `rms_voltage` | RMS voltage | V |
| `Z` | `impedance` | RF/load impedance when used in `P=V^2/Z` | ohm |
