# Source Registry

This registry records the standards, handbooks, and published books that should govern formula expansion. URLs point to official or publisher pages when possible. Formula extraction should use the latest active issue unless a mission specifically requires an older issue.

## Public Standards and Handbooks

| Source ID | Source | Authority | Current relevance | Use in knowledge base |
| --- | --- | --- | --- | --- |
| CCSDS-SLS | CCSDS Space Link Services area | CCSDS | SLS covers layers 1 and 2: RF/modulation, channel coding, data link, data compression, and ranging. | Top-level domain map for telemetry, telecommand, ranging, and space link formulas. |
| CCSDS-401 | CCSDS 401.0-B, Radio Frequency and Modulation Systems | CCSDS SLS-RFM | RF, modulation, frequency assignment, spectral constraints. | RF/modulation formulas, bandwidth checks, Doppler and spectrum allocation context. |
| CCSDS-131 | CCSDS 131.0-B, TM Synchronization and Channel Coding | CCSDS SLS-C&S | Active TM coding standard; CCSDS lists Issue 6 in April 2026. Current public extraction uses Issue 5 from September 2023 until the Issue 6 PDF is retrievable and checked. | TM sync markers, randomization, convolutional/turbo/LDPC/Reed-Solomon families, coded stream overhead. |
| CCSDS-131.2 | CCSDS 131.2-B, Flexible Advanced Coding and Modulation Scheme for High Rate Telemetry Applications | CCSDS SLS-C&S | High-rate telemetry coding and modulation. | ACM/SCCC-oriented high-rate telemetry calculators. |
| CCSDS-131.3 | CCSDS 131.3-B, CCSDS Space Link Protocols over ETSI DVB-S2 Standard | CCSDS SLS-C&S | High data rate telemetry, DVB-S2 MODCOD applicability, USLP support. | MODCOD table extraction, spectral efficiency, frame overhead. |
| CCSDS-231 | CCSDS 231.0-B-4, TC Synchronization and Channel Coding | CCSDS SLS-C&S | Active TC synchronization/channel coding standard, July 2021; BCH/LDPC and CLTU extracts started in `standard_extracts.md`. | CLTU, BCH/LDPC coding, repeated transmission, uplink coding overhead. |
| CCSDS-232 | CCSDS 232.0-B-4, TC Space Data Link Protocol | CCSDS SLS-SLP | TC asynchronous transfer frame protocol; current version includes Corrigendum 1 dated October 2023. | TC frame overhead, command throughput, COP-related sizing. |
| CCSDS-132 | CCSDS 132.0-B-3, TM Space Data Link Protocol | CCSDS SLS-SLP | TM transfer frame protocol, October 2021; TM frame field extracts started in `standard_extracts.md`. | TM frame/packet overhead and virtual-channel throughput. |
| CCSDS-732 | CCSDS 732.0-B-5, AOS Space Data Link Protocol | CCSDS SLS-SLP | AOS data link, October 2025. | AOS frame overhead, insert zone, virtual channels, packet service throughput. |
| CCSDS-732.1 | CCSDS 732.1-B-3, Unified Space Data Link Protocol | CCSDS SLS-SLP | USLP, June 2024. | Unified frame overhead and service-mode sizing. |
| CCSDS-414.1 | CCSDS 414.1-B-3, Pseudo-Noise Ranging Systems | CCSDS SLS-RFM | PN ranging, transparent/regenerative systems, January 2022; chip-rate and acquisition extracts started in `standard_extracts.md`. | PN ranging chip-rate, ambiguity, modulation and processing architecture. |
| CCSDS-415 | CCSDS 415.0-G, Data Transmission and PN Ranging for 2 GHz CDMA Link via Data Relay Satellite | CCSDS SLS-RFM | Spread-spectrum and CDMA support material. | Spread-spectrum ranging and link-budget extensions. |
| CCSDS-121 | CCSDS 121.0-B-3, Lossless Data Compression | CCSDS SLS-DC | Source-coding data-compression algorithm and source-packet insertion. | Lossless compression ratio, packetization overhead, data-volume reduction. |
| CCSDS-122 | CCSDS 122.0-B-2, Image Data Compression | CCSDS SLS-DC | Image compression for payload instrument data and compression-rate control. | Payload image compression sizing and storage/downlink budget reduction. |
| CCSDS-123 | CCSDS 123.0-B-2, Multispectral and Hyperspectral Image Compression | CCSDS SLS-DC | Low-complexity lossless and near-lossless compression for 3-D image data. | Multispectral/hyperspectral data-rate and volume calculators. |
| CCSDS-211.0 | CCSDS 211.0-B-6, Proximity-1 Space Link Protocol--Data Link Layer | CCSDS SLS-SLP | Proximity-1 data link layer and transfer frames. | Relay/orbiter-lander transfer frame and throughput calculators. |
| CCSDS-211.1 | CCSDS 211.1-B-4, Proximity-1 Physical Layer | CCSDS SLS-RFM | Proximity-1 physical layer procedures, reconfirmed through June 2024. | Proximity link RF, rate, modulation, and physical-layer parameter extraction. |
| CCSDS-211.2 | CCSDS 211.2-B-3, Proximity-1 Coding and Synchronization Sublayer | CCSDS SLS-C&S | Proximity-1 coding and synchronization. | Proximity coding/sync overhead and coded rate formulas. |
| ITU-P525 | ITU-R P.525-5, Calculation of free-space attenuation | ITU-R | Current Recommendation dated 11/2024; equations 1-11 extracted into `standard_extracts.md`. | FSPL, field strength, PFD, isotropic received power, and radar free-space loss formulas. |
| ITU-P618 | ITU-R P.618-14, Earth-space propagation prediction | ITU-R | In force, approved 2023-08-23; rain and total attenuation extracts started in `standard_extracts.md`. | Earth-space attenuation, rain fade, scintillation, availability. |
| ITU-P676 | ITU-R P.676, Attenuation by atmospheric gases | ITU-R | Gas attenuation model. | Oxygen/water vapor attenuation and path integration. |
| ITU-P838 | ITU-R P.838-3, Specific attenuation model for rain | ITU-R | Rain specific attenuation model; P.838-3 remains listed on ITU official pages. | `gamma_R = k R^alpha` and polarization-dependent coefficients. |
| ITU-P839 | ITU-R P.839-4, Rain height model | ITU-R | Needed by P.618 rain path geometry; P.839-4 remains listed on ITU official pages. | Rain height and slant-path length support. |
| DSN-810-005 | DSN Telecommunications Link Design Handbook | NASA/JPL DSN | Current public DSN handbook download page lists modules and recent release clearances; module 105E atmospheric/noise extracts are started. | Deep-space link, DSN station capability, command/telemetry/ranging modules. |
| DESCANSO-DSTSE | Deep Space Telecommunications Systems Engineering | NASA/JPL DESCANSO | Public deep-space communications reference; antenna/link extracts are started in `standard_extracts.md`. | Link equation derivations, antenna gain/effective aperture, system noise temperature, modulation/coding context. |
| NASA-SST-COMM | NASA SmallSat State of the Art, Communications | NASA | Small satellite RF/optical communication overview. | System-level trade examples and calculator scenario framing. |

## Published Books

| Source ID | Book | Publisher page evidence | Use in knowledge base |
| --- | --- | --- | --- |
| BOOK-MARAL | Maral, Bousquet, Sun, *Satellite Communications Systems*, 6th ed. | Wiley page lists link-performance chapter coverage. | Satellite uplink/downlink/overall link performance, transponder and intersatellite link formulas. |
| BOOK-SMAD | Wertz et al., *Space Mission Engineering: The New SMAD* | Google Books description lists communications and engineering reference coverage. | Mission-level communications budget, contact time, coverage, design trade calculators. |
| BOOK-BALANIS | Balanis, *Antenna Theory: Analysis and Design*, 4th ed. | Wiley page lists antenna parameters, effective areas, Friis, radar equation, antenna temperature. | Antenna gain, effective aperture, beamwidth, polarization, reflector/dish sizing, array fundamentals. |
| BOOK-SKLAR | Sklar and Harris, *Digital Communications*, 3rd ed. | Pearson page lists modulation, coding, synchronization, OFDM, MIMO, link budgets. | Eb/N0, BER/PER, modulation, baseband, channel coding, synchronization formulas. |
| BOOK-PROAKIS | Proakis and Salehi, *Digital Communications* | Published textbook; add publisher URL during next pass. | BER curves, matched filtering, AWGN, coding, synchronization. |
| BOOK-HAYKIN | Haykin, *Communication Systems* | Published textbook; add publisher URL during next pass. | Baseband/passband signals, noise, modulation, filtering. |
| BOOK-VALLADO | Vallado, *Fundamentals of Astrodynamics and Applications* | Published textbook; add publisher URL during next pass. | Orbit geometry, ground-station look angles, visibility, range/range-rate support. |
| BOOK-BATE | Bate, Mueller, White, *Fundamentals of Astrodynamics* | Published textbook; add publisher URL during next pass. | Classical orbit mechanics and contact geometry sanity checks. |

## Next Source Extraction Tasks

1. Continue active CCSDS PDF extraction for 131.0-B-6, 732.0-B, 732.1-B, COP-1, compression, and Proximity-1; first-pass extracts already exist for 131.0-B-5, 231.0-B-4, 414.1-B-3, 132.0-B-3, and 232.0-B-4.
2. Extract only implementation-relevant tables: code rates, frame lengths, sync marker sizes, transfer frame fields, MODCOD identifiers, PN chip-rate values, and mode/managed-parameter options.
3. Cross-check ITU-R P.618 dependencies: P.618 calls into P.837, P.838, P.839, P.840, P.676 depending on fade mechanism.
4. Extract CCSDS compression and Proximity-1 sizing fields where public Blue/Green Books define selectable parameters.
5. Add ECSS and Chinese/GJB public index references only where public bibliographic details are available. Do not encode restricted standards text.

## Reference Links

| Source ID | Link |
| --- | --- |
| CCSDS-SLS | https://ccsds.org/publications/sls/ |
| CCSDS active publications | https://ccsds.org/publications/allpubs/ |
| CCSDS search | https://ccsds.org/searchpubs/ |
| CCSDS-131 | https://ccsds.org/publications/allpubs/entry/3449/ |
| CCSDS-131 B-5 PDF | https://public.ccsds.org/Pubs/131x0b5.pdf |
| CCSDS-231 | https://ccsds.org/publications/allpubs/entry/3203/ |
| CCSDS-231 PDF | https://public.ccsds.org/Pubs/231x0b4e1.pdf |
| CCSDS-132 PDF | https://public.ccsds.org/Pubs/132x0b3.pdf |
| CCSDS-232 PDF | https://public.ccsds.org/Pubs/232x0b4e1c1.pdf |
| CCSDS-414.1 | https://ccsds.org/publications/allpubs/entry/3249/ |
| CCSDS-414.1 PDF | https://public.ccsds.org/Pubs/414x1b3e1.pdf |
| CCSDS-121/122/123 search | https://ccsds.org/searchpubs/ |
| CCSDS Proximity-1 search | https://ccsds.org/searchpubs/ |
| ITU-P525 | https://www.itu.int/rec/R-REC-P.525/en |
| ITU-P525-5 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.525-5-202411-I!!PDF-E.pdf |
| ITU-P618 | https://www.itu.int/rec/R-REC-P.618-14-202308-I/en |
| ITU-P618-14 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.618-14-202308-I!!PDF-E.pdf |
| ITU-P676 | https://www.itu.int/rec/R-REC-P.676/en |
| ITU-P838 | https://www.itu.int/rec/R-REC-P.838/en |
| ITU-P838-3 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/p/r-rec-p.838-3-200503-i!!pdf-e.pdf |
| ITU-P839 | https://www.itu.int/rec/R-REC-P.839/en |
| ITU-P839-4 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/p/r-rec-p.839-4-201309-i!!pdf-e.pdf |
| DSN-810-005 | https://deepspace.jpl.nasa.gov/dsndocs/810-005/ |
| DSN-810-005 downloads | https://deepspace.jpl.nasa.gov/dsndocs/810-005/downloads/ |
| DSN-810-005 front matter | https://deepspace.jpl.nasa.gov/dsndocs/810-005/fm.pdf |
| DSN-810-005 105E | https://deepspace.jpl.nasa.gov/dsndocs/810-005/105/105E.pdf |
| DESCANSO-DSTSE | https://descanso.jpl.nasa.gov/dstse/DSTSE.pdf |
| JPL DESCANSO monographs | https://descanso.jpl.nasa.gov/monograph/mono.html |
| NASA-SST-COMM | https://www.nasa.gov/smallsat-institute/sst-soa/soa-communications/ |
| BOOK-MARAL | https://onlinelibrary.wiley.com/doi/book/10.1002/9781119673811 |
| BOOK-BALANIS | https://www.wiley-vch.de/de/fachgebiete/ingenieurwesen/antenna-theory-978-1-118-64206-1 |
| BOOK-SKLAR | https://www.pearson.com/en-ca/subject-catalog/p/digital-communications-fundamentals-and-applications/P200000000614/9780134588568 |
| BOOK-SMAD | https://books.google.com/books/about/Space_Mission_Engineering.html?id=4JM7tAEACAAJ |
