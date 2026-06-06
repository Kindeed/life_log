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
| `L_total` | `total_loss` | total path and implementation loss | dB |
| `A_rain` | `rain_attenuation` | rain attenuation | dB |
| `A_gas` | `gas_attenuation` | atmospheric gas attenuation | dB |
| `A_cloud` | `cloud_attenuation` | cloud/fog attenuation | dB |
| `A_scint` | `scintillation_loss` | scintillation fade allowance | dB |
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

## Telemetry and Frames

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `word_length` | `word_length` | PCM word length | bit |
| `words_per_minor` | `words_per_minor` | PCM words per minor frame | unit |
| `minor_frame_rate` | `minor_rate` | minor frames per second | Hz |
| `minor_frames_per_major` | `minor_per_major` | minor frames in major frame | unit |
| `sync_bits` | `sync_bits` | synchronization marker length | bit |
| `TransferFrameBits` | `transfer_frame_bits` | complete transfer frame length | bit |
| `DataFieldBits` | `data_field_bits` | payload data field length | bit |
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

## Tracking, Ranging, and Doppler

| Symbol | Field ID suggestion | Meaning | Unit |
| --- | --- | --- | --- |
| `R_chip` | `chip_rate` | PN ranging chip rate | chips/s |
| `N_code` | `code_length` | PN code length | chip |
| `sigma_t` | `timing_error` | timing uncertainty | s, ns |
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
