# Source Registry

This registry records the standards, handbooks, and published books that should govern formula expansion. URLs point to official or publisher pages when possible. Formula extraction should use the latest active issue unless a mission specifically requires an older issue.

## Public Standards and Handbooks

| Source ID | Source | Authority | Current relevance | Use in knowledge base |
| --- | --- | --- | --- | --- |
| CCSDS-SLS | CCSDS Space Link Services area | CCSDS | SLS covers layers 1 and 2: RF/modulation, channel coding, data link, data compression, and ranging. | Top-level domain map for telemetry, telecommand, ranging, and space link formulas. |
| CCSDS-401 | CCSDS 401.0-B-32, Radio Frequency and Modulation Systems, Part 1: Earth Stations and Spacecraft | CCSDS SLS-RFM | Public Issue 32, October 2021 PDF extracted for first-pass RF/modulation constraints. | QPSK mapping, coded-symbol-rate stability, subcarrier-ratio checks, GMSK/filter bandwidth parameters, modulator imbalance margins, and spectrum/modulation applicability context. |
| CCSDS-131 | CCSDS 131.0-B, TM Synchronization and Channel Coding | CCSDS SLS-C&S | Active TM coding standard; CCSDS lists Issue 6 in April 2026. Current public extraction uses Issue 5 from September 2023 until the Issue 6 PDF is retrievable and checked. | TM sync markers, randomization, convolutional/turbo/LDPC/Reed-Solomon families, coded stream overhead. |
| CCSDS-131.2 | CCSDS 131.2-B, Flexible Advanced Coding and Modulation Scheme for High Rate Telemetry Applications | CCSDS SLS-C&S | High-rate telemetry coding and modulation. | ACM/SCCC-oriented high-rate telemetry calculators. |
| CCSDS-131.3 | CCSDS 131.3-B, CCSDS Space Link Protocols over ETSI DVB-S2 Standard | CCSDS SLS-C&S | High data rate telemetry, DVB-S2 MODCOD applicability, USLP support. | MODCOD table extraction, spectral efficiency, frame overhead. |
| CCSDS-231 | CCSDS 231.0-B-4, TC Synchronization and Channel Coding | CCSDS SLS-C&S | Active TC synchronization/channel coding standard, July 2021; BCH/LDPC and CLTU extracts started in `standard_extracts.md`. | CLTU, BCH/LDPC coding, repeated transmission, uplink coding overhead. |
| CCSDS-232 | CCSDS 232.0-B-4, TC Space Data Link Protocol | CCSDS SLS-SLP | TC asynchronous transfer frame protocol; current version includes Corrigendum 1 dated October 2023. | TC frame overhead, command throughput, COP-related sizing. |
| CCSDS-232.1 | CCSDS 232.1-B-2, Communications Operation Procedure-1 | CCSDS SLS-SLP | Active Blue Book, September 2010 with Technical Corrigendum 1 dated April 2019; public PDF extracted for FOP/FARM, sliding-window, timeout, retransmission, and CLCW managed-parameter formulas. | Telecommand closed-loop ARQ sizing, COP-1 timer budget, frame sequence modulus, FOP/FARM window checks, retransmission limits, and CLCW reporting cadence. |
| CCSDS-132 | CCSDS 132.0-B-3, TM Space Data Link Protocol | CCSDS SLS-SLP | TM transfer frame protocol, October 2021; TM frame field extracts started in `standard_extracts.md`. | TM frame/packet overhead and virtual-channel throughput. |
| CCSDS-133 | CCSDS 133.0-B-2, Space Packet Protocol | CCSDS SLS-SLP | Active Blue Book, June 2020 with Corrigendum 2; public PDF extracted for primary-header, APID, sequence-count, and packet-length formulas. | Space Packet overhead, user-data capacity, APID/idle packet constants, packet sequence wrap, and packet efficiency. |
| CCSDS-732 | CCSDS 732.0-B-5, AOS Space Data Link Protocol | CCSDS SLS-SLP | AOS data link, October 2025; the current public PDF direct URL was not retrievable in this pass, so exact AOS field extraction remains pending. | AOS frame overhead, insert zone, virtual channels, packet service throughput. |
| CCSDS-732.1 | CCSDS 732.1-B-3, Unified Space Data Link Protocol | CCSDS SLS-SLP | USLP, June 2024; public PDF extracted for identifier widths, primary-header fields, frame length, VCF Count options, TFDF/TFDZ capacity, OCF/FECF, OID, and SDLS capacity. | Unified frame overhead, service-mode sizing, packet/SDU segmentation, and frame-efficiency calculators. |
| CCSDS-414.1 | CCSDS 414.1-B-3, Pseudo-Noise Ranging Systems | CCSDS SLS-RFM | PN ranging, transparent/regenerative systems, January 2022; chip-rate and acquisition extracts started in `standard_extracts.md`. | PN ranging chip-rate, ambiguity, modulation and processing architecture. |
| CCSDS-415 | CCSDS 415.0-G, Data Transmission and PN Ranging for 2 GHz CDMA Link via Data Relay Satellite | CCSDS SLS-RFM | Spread-spectrum and CDMA support material. | Spread-spectrum ranging and link-budget extensions. |
| CCSDS-121 | CCSDS 121.0-B-3, Lossless Data Compression | CCSDS SLS-DC | Active Blue Book, August 2020; public PDF extracted for block, predictor, mapper, Rice-option, and CDS first pass. | Lossless compression block sizing, reference-sample overhead, Rice option selection, packetization overhead, data-volume reduction. |
| CCSDS-122 | CCSDS 122.0-B-2, Image Data Compression | CCSDS SLS-DC | Active Blue Book, September 2017; direct guessed PDF URL returned 404 in this pass, but CCSDS active registry confirms the current issue and reconfirmation through July 2028. | Payload image compression sizing and storage/downlink budget reduction; exact wavelet/segment/rate-control tables remain pending. |
| CCSDS-120.2 | CCSDS 120.2-G-2, Low-Complexity Lossless and Near-Lossless Multispectral and Hyperspectral Image Compression | CCSDS SLS-DC | Active Green Book, December 2022; public PDF extracted for tutorial formulas underlying CCSDS 123.0-B-2. | Multispectral/hyperspectral image volume, predictor explanation, near-lossless quantizer and error-limit controls. |
| CCSDS-123 | CCSDS 123.0-B-2, Multispectral and Hyperspectral Image Compression | CCSDS SLS-DC | Active Blue Book, February 2019; CCSDS registry states current version includes corrigenda through February 2021. Corrigendum 3 PDF extracted; full direct Blue Book PDF remains to retrieve. | Multispectral/hyperspectral data-rate and volume calculators, near-lossless fidelity bounds, predictor and entropy-coder table extraction. |
| CCSDS-211.0 | CCSDS 211.0-B-6, Proximity-1 Space Link Protocol--Data Link Layer | CCSDS SLS-SLP | CCSDS active registry lists Issue 6, July 2020; exact public PDF direct URL returned 404 in this pass. ISO 22663/CCSDS 211.0-B-5 public preview is used for stable Version-3 frame field extracts until B-6 PDF is retrieved. | Relay/orbiter-lander Version-3 frame overhead, data-field capacity, header field widths, and frame-plus-PLTU efficiency calculators; Version-4/USLP deltas remain pending. |
| CCSDS-211.1 | CCSDS 211.1-B-4, Proximity-1 Physical Layer | CCSDS SLS-RFM | CCSDS active registry lists Issue 4, December 2013; ISO 21460/CCSDS 211.1-B-4 public preview used for rate reference points and physical-layer scope. | Proximity link `R_d/R_cs/R_chs` reference points, coded/channel symbol-rate validation, modulation relationship, and physical-layer offset/stability margins. |
| CCSDS-211.2 | CCSDS 211.2-B-3, Proximity-1 Coding and Synchronization Sublayer | CCSDS SLS-C&S | Public Issue 3, October 2019 PDF extracted for first-pass PLTU, idle, coding, LDPC/CSM, and randomizer formulas. | Proximity coding/sync overhead, allowed `Rd` validation, coded-rate expansion, LDPC/CSM efficiency, and PLTU efficiency formulas. |
| ITU-P525 | ITU-R P.525-5, Calculation of free-space attenuation | ITU-R | Current Recommendation dated 11/2024; equations 1-11 extracted into `standard_extracts.md`. | FSPL, field strength, PFD, isotropic received power, and radar free-space loss formulas. |
| ITU-P618 | ITU-R P.618-14, Earth-space propagation prediction | ITU-R | In force, approved 2023-08-23; rain, total attenuation, scintillation, and sky-noise extracts started in `standard_extracts.md`. | Earth-space attenuation, rain fade, scintillation, availability, sky noise temperature. |
| ITU-P676 | ITU-R P.676-13, Attenuation by atmospheric gases and related effects | ITU-R | In force, approved 2022-08-24; official page updated 2024-06-21; first-pass gas attenuation extracts started. | Oxygen/water vapor attenuation, path integration, line-by-line and approximate slant-path gas attenuation. |
| ITU-P838 | ITU-R P.838-3, Specific attenuation model for rain | ITU-R | Rain specific attenuation model; P.838-3 remains listed on ITU official pages. | `gamma_R = k R^alpha` and polarization-dependent coefficients. |
| ITU-P839 | ITU-R P.839-4, Rain height model | ITU-R | Needed by P.618 rain path geometry; P.839-4 remains listed on ITU official pages. | Rain height and slant-path length support. |
| ITU-P840 | ITU-R P.840-9, Attenuation due to clouds and fog | ITU-R | In force, approved 2023-08; first-pass cloud/fog attenuation extracts started. | Cloud/fog liquid water attenuation, integrated cloud liquid water maps, log-normal cloud attenuation approximation. |
| ITU-S465 | ITU-R S.465-6, Reference radiation pattern of earth station antennas in the fixed-satellite service | ITU-R | In force, approved 2010-01; provides reference patterns for coordination and interference assessment from 2 to 31 GHz. | Earth-station off-axis gain envelope, minimum angle rules, and legacy small-antenna branches. |
| ITU-S580 | ITU-R S.580-6, Radiation diagrams for earth-station antenna design objectives | ITU-R | In force, approved 2004-01; provides GSO side-lobe design objective for earth-station antennas. | Side-lobe objective, GSO affected-zone checks, transition branch, and equivalent circular aperture diameter. |
| DSN-810-005 | DSN Telecommunications Link Design Handbook | NASA/JPL DSN | Current public DSN handbook download page lists modules and recent release clearances; modules 101I, 103F, 104P, 105E, 202E, 203E, 210E, 211G, and 214C have first-pass extracts. | Deep-space link, DSN station capability, antenna gain/noise-temperature station models, Doppler tracking, sequential/PN ranging, Delta-DOR, VLBI, command/telemetry/ranging modules. |
| DESCANSO-DSTSE | Deep Space Telecommunications Systems Engineering | NASA/JPL DESCANSO | Public deep-space communications reference; antenna/link, baseband, Doppler, ranging, VLBI/DOR, and radiometric-error extracts are started in `standard_extracts.md`. | Link equation derivations, antenna gain/effective aperture, system noise temperature, modulation/coding context, tracking/ranging observables, and external-measurement formulas. |
| DESCANSO-OPTICAL | Hemmati, *Deep Space Optical Communications* | NASA/JPL DESCANSO | Public DESCANSO series monograph, October 2005; first-pass extracts added for optical link, photon counting, PPM, Poisson detection, and acquisition beacon sizing. | Optical link budget, photon-counting receivers, PPM timing/efficiency, Poisson BER/SER, detector background/dark-count terms, and beacon pointing/acquisition support formulas. |
| NASA-SST-COMM | NASA SmallSat State of the Art, Communications | NASA | Small satellite RF/optical communication overview. | System-level trade examples and calculator scenario framing. |
| NASA-BSF | NASA/JPL Basics of Space Flight | NASA/JPL | Public educational reference for orbital motion, spacecraft tracking, and light-time concepts. | Cross-check two-body orbit, range/light-time, and operations explanations. |
| CELESTRAK | CelesTrak astrodynamics and coordinate-system references | CelesTrak | Public astrodynamics reference material maintained by T.S. Kelso; useful for ECI/ECEF/topocentric coordinate cross-checks. | Coordinate-frame, ground-track, sidereal-time, and access-calculation sanity checks. |
| NAVIPEDIA-COORD | Navipedia coordinate transformations | ESA Navipedia | Public coordinate-transformation reference with ECEF, ENU, and geodetic relations. | Ground-station ECEF/ENU transform formulas for antenna pointing and contact geometry. |
| IERS-CONV | IERS Conventions | IERS | Authoritative Earth-orientation and terrestrial/celestial reference-system conventions. | High-precision ECI/ECEF transformation scope and warnings; simple workbench formulas must flag missing EOP corrections. |

## Published Books

| Source ID | Book | Publisher page evidence | Use in knowledge base |
| --- | --- | --- | --- |
| BOOK-MARAL | Maral, Bousquet, Sun, *Satellite Communications Systems*, 6th ed. | Wiley page lists link-performance chapter coverage. | Satellite uplink/downlink/overall link performance, transponder and intersatellite link formulas. |
| BOOK-SMAD | Wertz et al., *Space Mission Engineering: The New SMAD* | Google Books description lists communications and engineering reference coverage. | Mission-level communications budget, contact time, coverage, design trade calculators. |
| BOOK-BALANIS | Balanis, *Antenna Theory: Analysis and Design*, 4th ed. | Wiley page and companion site identify the 4th edition and antenna-theory chapter/resource structure. | Antenna gain, effective aperture, beamwidth, polarization, reflector/dish sizing, directivity, beam solid angle, far-field distance, and array fundamentals. |
| BOOK-SKLAR | Sklar and Harris, *Digital Communications*, 3rd ed. | Pearson/InformIT pages list modulation, coding, synchronization, OFDM, MIMO, link budgets, and baseband transmission coverage. | Eb/N0, BER/PER, modulation, baseband, channel coding, synchronization, OFDM, MIMO formulas. |
| BOOK-PROAKIS | Proakis and Salehi, *Digital Communications*, 5th ed. | Bibliographic/publisher evidence lists digital modulation schemes, AWGN optimum receivers, carrier/symbol synchronization, information theory, and coding topics. | BER curves, matched filtering, AWGN, coding, synchronization. |
| BOOK-HAYKIN | Haykin and Moher, *Communication Systems*, 5th ed. | Wiley/bibliographic pages list analog and digital communications, signal processing, filtering, and systems coverage. | Baseband/passband signals, noise, modulation, filtering. |
| BOOK-GOLDSMITH | Goldsmith, *Wireless Communications* | Cambridge University Press page identifies wireless channel characteristics, capacity limits, modulation, coding, multicarrier, spread spectrum, and multiple-antenna coverage. | Fading-channel models, outage, coherence bandwidth/time, adaptive modulation context, and wireless capacity formulas. |
| BOOK-RAPPAPORT | Rappaport, *Wireless Communications: Principles and Practice*, 2nd ed. | InformIT/Pearson page lists radio propagation, path-loss models, wireless system design, and chapter supplements. | Log-distance path loss, shadowing, Rayleigh/Rician fading, Doppler, delay spread, and practical wireless channel formulas. |
| BOOK-SAYOOD | Sayood, *Introduction to Data Compression*, 4th ed. | Elsevier/O'Reilly pages list information theory, coding, quantization, subband coding, bit allocation, and image-compression coverage. | Cross-check entropy, average code length, quantization, and compression-ratio formulas without copying standard-specific algorithm tables. |
| BOOK-SALOMON | Salomon, *Data Compression: The Complete Reference* | Springer and Google Books pages identify broad lossless/lossy compression, Huffman, arithmetic, dictionary, image, wavelet, and quantization coverage. | General compression terminology and sanity checks for textbook formulas. |
| BOOK-VALLADO | Vallado, *Fundamentals of Astrodynamics and Applications* | Microcosm/AIAA/CelesTrak publisher and support pages identify the astrodynamics reference and source-code material. | Orbit geometry, ground-station look angles, visibility, range/range-rate support. |
| BOOK-BATE | Bate, Mueller, White, *Fundamentals of Astrodynamics* | Dover/Google Books bibliographic pages identify the published astrodynamics textbook. | Classical orbit mechanics and contact geometry sanity checks. |

## Next Source Extraction Tasks

1. Continue active CCSDS PDF extraction for 131.0-B-6, 732.0-B, compression, and Proximity-1; first-pass extracts already exist for 401.0-B-32, 211.2-B-3, 131.0-B-5, 231.0-B-4, 414.1-B-3, 132.0-B-3, 133.0-B-2, 232.0-B-4, 232.1-B-2, and 732.1-B-3.
2. Extract only implementation-relevant tables: code rates, frame lengths, sync marker sizes, transfer frame fields, MODCOD identifiers, PN chip-rate values, and mode/managed-parameter options.
3. Cross-check ITU-R P.618 dependencies: P.618 calls into P.837, P.838, P.839, P.840, P.676 depending on fade mechanism.
4. Continue CCSDS compression and remaining Proximity-1 table fields where public Blue/Green Books define selectable parameters, especially CCSDS 122 exact image-compression tables, CCSDS 123 Blue Book predictor/entropy/header tables, 211.0-B-6 Version-4/USLP deltas, and 211.1-B-4 UHF channel/hailing/polarization tables.
5. Continue orbit/contact/system extraction from Vallado/SMAD/Bate and public coordinate references: exact time-scale handling, EOP corrections, J2 nodal regression, repeat-ground-track checks, and contact-window validation examples.
6. Add ECSS and Chinese/GJB public index references only where public bibliographic details are available. Do not encode restricted standards text.

## Reference Links

| Source ID | Link |
| --- | --- |
| CCSDS-SLS | https://ccsds.org/publications/sls/ |
| CCSDS active publications | https://ccsds.org/publications/allpubs/ |
| CCSDS search | https://ccsds.org/searchpubs/ |
| CCSDS-131 | https://ccsds.org/publications/allpubs/entry/3449/ |
| CCSDS-131 B-5 PDF | https://public.ccsds.org/Pubs/131x0b5.pdf |
| CCSDS-401 PDF | https://public.ccsds.org/Pubs/401x0b32.pdf |
| CCSDS-231 | https://ccsds.org/publications/allpubs/entry/3203/ |
| CCSDS-231 PDF | https://public.ccsds.org/Pubs/231x0b4e1.pdf |
| CCSDS-132 PDF | https://public.ccsds.org/Pubs/132x0b3.pdf |
| CCSDS-133 PDF | https://public.ccsds.org/Pubs/133x0b2e2.pdf |
| CCSDS-232 PDF | https://public.ccsds.org/Pubs/232x0b4e1c1.pdf |
| CCSDS-232.1 PDF | https://public.ccsds.org/Pubs/232x1b2e2c1.pdf |
| CCSDS-732.1 PDF | https://public.ccsds.org/Pubs/732x1b3e1.pdf |
| CCSDS-414.1 | https://ccsds.org/publications/allpubs/entry/3249/ |
| CCSDS-414.1 PDF | https://public.ccsds.org/Pubs/414x1b3e1.pdf |
| CCSDS-121 PDF | https://public.ccsds.org/Pubs/121x0b3.pdf |
| CCSDS-120.2 | https://ccsds.org/publications/allpubs/entry/3211/ |
| CCSDS-120.2 PDF | https://public.ccsds.org/Pubs/120x2g2.pdf |
| CCSDS-123 Corrigendum 3 PDF | https://ccsds.org/Pubs/123x0b2e1c3_tc2101.pdf |
| CCSDS-121/122/123 registry search | https://ccsds.org/searchpubs/ |
| CCSDS Proximity-1 search | https://ccsds.org/searchpubs/ |
| CCSDS-211.2 PDF | https://public.ccsds.org/Pubs/211x2b3.pdf |
| ISO-22663 / CCSDS-211.0 public preview | https://standards.iteh.ai/catalog/standards/iso/6dd0e130-18a3-42a4-8d70-3cfd4a695935/iso-22663-2015 |
| ISO-21460 / CCSDS-211.1 public preview | https://standards.iteh.ai/catalog/standards/iso/aad24abf-50fa-4488-80c9-be32972f9db9/iso-21460-2015 |
| ITU-P525 | https://www.itu.int/rec/R-REC-P.525/en |
| ITU-P525-5 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.525-5-202411-I!!PDF-E.pdf |
| ITU-P618 | https://www.itu.int/rec/R-REC-P.618-14-202308-I/en |
| ITU-P618-14 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.618-14-202308-I!!PDF-E.pdf |
| ITU-P676 | https://www.itu.int/rec/R-REC-P.676/en |
| ITU-P676-13 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.676-13-202208-I!!PDF-E.pdf |
| ITU-P838 | https://www.itu.int/rec/R-REC-P.838/en |
| ITU-P838-3 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/p/r-rec-p.838-3-200503-i!!pdf-e.pdf |
| ITU-P839 | https://www.itu.int/rec/R-REC-P.839/en |
| ITU-P839-4 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/p/r-rec-p.839-4-201309-i!!pdf-e.pdf |
| ITU-P840 | https://www.itu.int/rec/R-REC-P.840/en |
| ITU-P840-9 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.840-9-202308-I!!PDF-E.pdf |
| ITU-S465-6 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/s/R-REC-S.465-6-201001-I!!PDF-E.pdf |
| ITU-S580 | https://www.itu.int/rec/R-REC-S.580-6-200401-I |
| ITU-S580-6 PDF | https://www.itu.int/dms_pubrec/itu-r/rec/s/R-REC-S.580-6-200401-I!!PDF-E.pdf |
| DSN-810-005 | https://deepspace.jpl.nasa.gov/dsndocs/810-005/ |
| DSN-810-005 downloads | https://deepspace.jpl.nasa.gov/dsndocs/810-005/downloads/ |
| DSN-810-005 front matter | https://deepspace.jpl.nasa.gov/dsndocs/810-005/fm.pdf |
| DSN-810-005 101I | https://deepspace.jpl.nasa.gov/dsndocs/810-005/101/101I.pdf |
| DSN-810-005 103F | https://deepspace.jpl.nasa.gov/dsndocs/810-005/103/103F.pdf |
| DSN-810-005 104P | https://deepspace.jpl.nasa.gov/dsndocs/810-005/104/104P.pdf |
| DSN-810-005 105E | https://deepspace.jpl.nasa.gov/dsndocs/810-005/105/105E.pdf |
| DESCANSO-DSTSE | https://descanso.jpl.nasa.gov/dstse/DSTSE.pdf |
| JPL DESCANSO monographs | https://descanso.jpl.nasa.gov/monograph/mono.html |
| DESCANSO-OPTICAL PDF | https://descanso.jpl.nasa.gov/monograph/series7/Descanso_7_Full_Version.pdf |
| NASA-SST-COMM | https://www.nasa.gov/smallsat-institute/sst-soa/soa-communications/ |
| NASA-BSF | https://science.nasa.gov/learn/basics-of-space-flight/ |
| CELESTRAK | https://celestrak.org/columns/ |
| NAVIPEDIA-ENU | https://gssc.esa.int/navipedia/index.php/Transformations_between_ECEF_and_ENU_coordinates |
| NAVIPEDIA-GEODETIC | https://gssc.esa.int/navipedia/index.php/Ellipsoidal_and_Cartesian_Coordinates_Conversion |
| IERS-CONV | https://iers-conventions.obspm.fr/conventions_versions.php |
| BOOK-MARAL | https://onlinelibrary.wiley.com/doi/book/10.1002/9781119673811 |
| BOOK-BALANIS | https://www.wiley-vch.de/de/fachgebiete/ingenieurwesen/antenna-theory-978-1-118-64206-1 |
| BOOK-SKLAR | https://www.pearson.com/en-ca/subject-catalog/p/digital-communications-fundamentals-and-applications/P200000000614/9780134588568 |
| BOOK-SKLAR InformIT | https://www.informit.com/store/digital-communications-fundamentals-and-applications-9780134588568 |
| BOOK-SKLAR O'Reilly TOC | https://www.oreilly.com/library/view/digital-communications-fundamentals/9780134588636/bk01-toc.xhtml |
| BOOK-PROAKIS bibliographic | https://www.campusbooks.com/books/9780072957167-digital-communications |
| BOOK-HAYKIN bibliographic | https://ndlsearch.ndl.go.jp/books/R100000002-I000010817499 |
| BOOK-GOLDSMITH Cambridge | https://www.cambridge.org/core/books/wireless-communications/800BA8A8211FBECB133A7BB77CD2E2BD |
| BOOK-RAPPAPORT InformIT | https://www.informit.com/store/wireless-communications-principles-and-practice-9780130422323 |
| BOOK-SMAD | https://books.google.com/books/about/Space_Mission_Engineering.html?id=4JM7tAEACAAJ |
| BOOK-SAYOOD | https://www.oreilly.com/library/view/introduction-to-data/9780124157965/ |
| BOOK-SALOMON | https://link.springer.com/book/10.1007/978-3-642-86092-8 |
| BOOK-VALLADO | https://celestrak.org/publications/AIAA/2006-6753/ |
| BOOK-BATE | https://books.google.com/books/about/Fundamentals_of_Astrodynamics.html?id=UtJK8cetqGkC |
