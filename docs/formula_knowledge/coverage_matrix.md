# Formula Knowledge Coverage Matrix

This matrix tracks whether the knowledge base is moving toward the requested complete formula library. `Seeded` means formula entries exist. `Extraction needed` means a public standard/book must still be inspected for tables, parameter limits, or exact procedures before app implementation.

| Domain | Scope | Primary sources | Current coverage | Remaining gaps |
| --- | --- | --- | --- | --- |
| RF fundamentals | wavelength, dB conversion, EIRP, PFD, PSD, received power | ITU-R P.525, DSN 810-005, Maral/Bousquet | Seeded in RF, LINK, MEAS | Add spectral masks and occupied-bandwidth regulatory checks from CCSDS 401. |
| Antenna | gain, aperture, G/T, pointing, polarization, mismatch, beamwidth | Balanis, DESCANSO, DSN 810-005 | Seeded in RF and SYS | Add reflector-specific beamwidth constants, array factor, sidelobe estimates, antenna temperature model. |
| Receiver/noise | noise figure, equivalent temperature, cascaded noise, N0 | Sklar, Maral/Bousquet, DSN 810-005 | Seeded in RF and LINK | Add lossy feed before LNA treatment, sky-noise models, measured Y-factor calibration. |
| Link budget | FSPL, C/N0, Eb/N0, Es/N0, margin, inverse sizing | ITU-R P.525, DSN 810-005, Maral/Bousquet | Partly implemented; P.525-5 equations extracted | Add uplink/downlink/relay multi-hop budget and transponder saturation/backoff. |
| Propagation | rain, gas, cloud, scintillation, availability | ITU-R P.618, P.676, P.838, P.839, P.840 | Top-level seeded | Extract P.618 step procedure and dependency inputs; add validity ranges. |
| Modulation/baseband | symbol rate, rolloff bandwidth, BER/PER, EVM, Shannon | Sklar, Proakis, CCSDS 401 | Partly implemented and seeded | Add CCSDS modulation families, OQPSK/SQPN, filtered PSK, OFDM and DVB-S2 MODCOD details. |
| Channel coding | RS, convolutional, turbo, LDPC, BCH, interleaving | CCSDS 131, 131.2, 131.3, 231, Sklar | Generic formulas seeded | Extract exact code tables, block lengths, rates, sync markers, performance thresholds. |
| Telemetry frames | PCM, space packet, TM/AOS/USLP frame overhead, VC throughput | IRIG practice, CCSDS 132, 133, 732, 732.1 | PCM partly implemented; generic frame formulas seeded | Extract exact field lengths, optional fields, insert zones, security interaction. |
| Telecommand | TC frames, CLTU, BCH/LDPC, repeat, COP/ARQ goodput | CCSDS 231, 232, COP-1 | Simple throughput implemented; CLTU seeded | Extract CLTU start/tail/fill/coding tables and COP timing model. |
| Ranging/tracking | PN range, ambiguity, Doppler, guard band, Delta-DOR, radar equation | CCSDS 414.1, 415, DSN 810-005, Balanis | Partly implemented; P.525 radar loss and CCSDS 414.1 chip-rate/acquisition formulas extracted | Extract full transparent/regenerative PN mode matrices, D-DOR error model, sequential ranging if public sources permit. |
| Proximity links | orbiter/lander relay physical, coding, data-link efficiency | CCSDS 211.0, 211.1, 211.2 | Newly seeded as protocol formulas | Extract Proximity-1 rate/mode tables, frame overhead, coding/sync options. |
| Data compression | lossless/image/hyperspectral compression and data-volume reduction | CCSDS 121, 122, 123, Sklar | Newly seeded | Extract packetization overhead, predictor/quantizer parameters, rate-control fields. |
| Orbit/contact geometry | slant range, elevation, pass time, range-rate, antenna tracking rates | SMAD, Vallado, DSN 810-005 | Newly seeded | Add Earth rotation, station coordinates, ECI/ECEF transforms, minimum-elevation contact solver. |
| System operations | data volume, contact time, storage margin, duty cycle, power average | SMAD | Seeded | Integrate with actual scenario calculators and schedule windows. |
| Optical links | diffraction, photon energy, pointing loss | DESCANSO optical references, Balanis | Seeded as extension | Add atmospheric optical loss, detector noise, photon-counting BER/PPM formulas. |

## Current Numeric Coverage

As of this pass, `formula_catalog.md` contains over 175 formula or formula-family entries across RF, link, baseband, telemetry, telecommand, ranging/tracking, system, optical, orbit/contact, compression, protocol, and measurement domains.

## Not Yet Complete

The knowledge base is still incomplete until the extraction matrix has been executed against the standard PDFs and textbook chapters. Most standards-driven items marked `Procedure` require exact tables, field lengths, mode identifiers, and applicability limits before they can become app calculators.
