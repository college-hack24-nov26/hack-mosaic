-- 000002_seed_reference_and_demo.up.sql
-- Controlled reference catalogs and clearly labelled synthetic demonstration data (Maharashtra / Satara / Phaltan)

-- 1. Locations (State -> District -> Taluka -> Village)
INSERT INTO locations (id, parent_id, level, code, name_en, name_hi, name_mr, centroid) VALUES
    ('11111111-1111-4111-8111-111111111101', NULL, 'state', 'MH', 'Maharashtra', 'महाराष्ट्र', 'महाराष्ट्र', ST_SetSRID(ST_MakePoint(75.7139, 19.7515), 4326)::geography),
    ('11111111-1111-4111-8111-111111111201', '11111111-1111-4111-8111-111111111101', 'district', 'MH-SAT', 'Satara', 'सातारा', 'सातारा', ST_SetSRID(ST_MakePoint(74.0183, 17.6805), 4326)::geography),
    ('11111111-1111-4111-8111-111111111202', '11111111-1111-4111-8111-111111111101', 'district', 'MH-PUN', 'Pune', 'पुणे', 'पुणे', ST_SetSRID(ST_MakePoint(73.8567, 18.5204), 4326)::geography),
    ('11111111-1111-4111-8111-111111111301', '11111111-1111-4111-8111-111111111201', 'taluka', 'MH-SAT-PHA', 'Phaltan', 'फलटण', 'फलटण', ST_SetSRID(ST_MakePoint(74.4331, 17.9856), 4326)::geography),
    ('11111111-1111-4111-8111-111111111302', '11111111-1111-4111-8111-111111111201', 'taluka', 'MH-SAT-KOR', 'Koregaon', 'कोरेगाव', 'कोरेगाव', ST_SetSRID(ST_MakePoint(74.1625, 17.6992), 4326)::geography),
    ('11111111-1111-4111-8111-111111111303', '11111111-1111-4111-8111-111111111201', 'taluka', 'MH-SAT-SAT', 'Satara', 'सातारा', 'सातारा', ST_SetSRID(ST_MakePoint(74.0183, 17.6805), 4326)::geography),
    ('11111111-1111-4111-8111-111111111304', '11111111-1111-4111-8111-111111111201', 'taluka', 'MH-SAT-KHA', 'Khandala', 'खंडाळा', 'खंडाळा', ST_SetSRID(ST_MakePoint(74.0150, 18.0620), 4326)::geography),
    ('11111111-1111-4111-8111-111111111401', '11111111-1111-4111-8111-111111111301', 'village', 'MH-SAT-PHA-001', 'Phaltan Rural', 'फलटण ग्रामीण', 'फलटण ग्रामीण', ST_SetSRID(ST_MakePoint(74.4331, 17.9856), 4326)::geography),
    ('11111111-1111-4111-8111-111111111402', '11111111-1111-4111-8111-111111111301', 'village', 'MH-SAT-PHA-002', 'Barad', 'बरड', 'बरड', ST_SetSRID(ST_MakePoint(74.4820, 17.9542), 4326)::geography),
    ('11111111-1111-4111-8111-111111111403', '11111111-1111-4111-8111-111111111301', 'village', 'MH-SAT-PHA-003', 'Tadawale', 'ताडवळे', 'ताडवळे', ST_SetSRID(ST_MakePoint(74.3910, 18.0120), 4326)::geography),
    ('11111111-1111-4111-8111-111111111404', '11111111-1111-4111-8111-111111111301', 'village', 'MH-SAT-PHA-004', 'Vidani', 'विडणी', 'विडणी', ST_SetSRID(ST_MakePoint(74.4550, 17.9710), 4326)::geography),
    ('11111111-1111-4111-8111-111111111405', '11111111-1111-4111-8111-111111111301', 'village', 'MH-SAT-PHA-005', 'Sakharwadi', 'साखरवाडी', 'साखरवाडी', ST_SetSRID(ST_MakePoint(74.3620, 18.0340), 4326)::geography)
ON CONFLICT (code) DO NOTHING;

-- 2. Species & Breeds
INSERT INTO species (code, name_en, name_hi, name_mr) VALUES
    ('cattle', 'Cow / Bull', 'गाय / बैल', 'गाय / बैल'),
    ('buffalo', 'Buffalo', 'भैंस', 'म्हैस'),
    ('goat', 'Goat', 'बकरी', 'शेळी')
ON CONFLICT (code) DO NOTHING;

INSERT INTO breeds (species_id, code, name_en, name_hi, name_mr)
SELECT s.id, b.code, b.name_en, b.name_hi, b.name_mr
FROM (VALUES
    ('cattle', 'gir', 'Gir', 'गिर', 'गीर'),
    ('cattle', 'khillar', 'Khillar', 'खिल्लार', 'खिल्लार'),
    ('cattle', 'holstein_friesian', 'Holstein Friesian', 'होल्स्टीन फ्रीजियन', 'होल्स्टिन फ्रिजियन'),
    ('cattle', 'sahiwal', 'Sahiwal', 'साहीवाल', 'साहिवाल'),
    ('cattle', 'jersey', 'Jersey', 'जर्सी', 'जर्सी'),
    ('buffalo', 'murrah', 'Murrah', 'मुर्रा', 'मुऱ्हा'),
    ('buffalo', 'pandharpuri', 'Pandharpuri', 'पंढरपुरी', 'पंढरपुरी'),
    ('buffalo', 'jaffarabadi', 'Jaffarabadi', 'जाफराबादी', 'जाफराबादी'),
    ('goat', 'osmanabadi', 'Osmanabadi', 'उस्मानाबादी', 'उस्मानाबादी'),
    ('goat', 'sangamneri', 'Sangamneri', 'संगमनेरी', 'संगमनेरी')
) AS b(species_code, code, name_en, name_hi, name_mr)
JOIN species s ON s.code = b.species_code
ON CONFLICT (code) DO NOTHING;

-- 3. Diseases
INSERT INTO diseases (code, name_en, name_hi, name_mr, is_notifiable, is_outbreak_tracked, cluster_min_cases, cluster_radius_m, cluster_window_days, precautions_en, precautions_hi, precautions_mr) VALUES
    ('lumpy_skin_disease', 'Lumpy Skin Disease (LSD)', 'लम्पी त्वचा रोग', 'लम्पी त्वचा रोग', TRUE, TRUE, 2, 5000, 14,
     'Isolate affected cattle immediately, control mosquitoes/ticks, disinfect shed, and consult a veterinarian.',
     'प्रभावित पशु को तुरंत अलग करें, मच्छर/मक्खी नियंत्रण करें और पशु चिकित्सक से संपर्क करें।',
     'बाधित जनावरास त्वरित वेगळे ठेवा, गोठ्यात कीटकनाशक फवारणी करा आणि पशुवैद्यकांशी संपर्क साधा.'),
    ('foot_and_mouth_disease', 'Foot and Mouth Disease (FMD)', 'खुरपका-मुंहपका रोग', 'लाळ खुरकत रोग', TRUE, TRUE, 2, 5000, 14,
     'Separate sick animals, wash mouth/hoof lesions with 1% potassium permanganate, and restrict herd movement.',
     'बीमार पशुओं को अलग करें, मुंह और खुर के घावों को पोटैशियम परमैंगनेट से धोएं।',
     'आजारी जनावरांना वेगळे बांधा, तोंड व खुरांच्या जखमा पोटॅशियम परमँगनेटच्या पाण्याने धुवा.'),
    ('brucellosis', 'Brucellosis', 'ब्रुसेलोसिस', 'ब्रुसेलोसिस (संसर्गजन्य गर्भपात)', TRUE, TRUE, 3, 5000, 14,
     'Use gloves when handling placenta/aborted material, disinfect area, and test herd via veterinarian.',
     'गर्भपात सामग्री को छूते समय दस्ताने पहनें और क्षेत्र को कीटाणुरहित करें।',
     'गर्भपात झालेल्या जनावराची वार हाताळताना हातमोजे वापरा व गोठा निर्जंतुक करा.'),
    ('black_quarter', 'Black Quarter (BQ)', 'लंगड़ा बुखार (एकटांगिया)', 'फऱ्या रोग', TRUE, TRUE, 2, 5000, 14,
     'Seek urgent antibiotic treatment from a veterinarian and vaccinate healthy cattle before monsoon.',
     'तुरंत पशु चिकित्सक से एंटीबायोटिक उपचार कराएं और स्वस्थ पशुओं का टीकाकरण करें।',
     'त्वरित पशुवैद्यकांकडून प्रतिजैविक उपचार घ्या आणि निरोगी जनावरांचे लसीकरण करा.'),
    ('haemorrhagic_septicaemia', 'Haemorrhagic Septicaemia (HS)', 'गलघोंटू रोग', 'घटसर्प रोग', TRUE, TRUE, 2, 5000, 14,
     'Keep animals dry and warm, isolate animals with breathing difficulty, and get urgent veterinary care.',
     'पशुओं को सूखे स्थान पर रखें और सांस लेने में कठिनाई होने पर तुरंत डॉक्टर को बुलाएं।',
     'जनावरांना कोरड्या जागी ठेवा आणि श्वास घेण्यास त्रास होत असल्यास त्वरित उपचार करा.'),
    ('mastitis', 'Mastitis', 'थनैला रोग', 'कासदाह (मस्टायटिस)', FALSE, FALSE, 5, 5000, 14,
     'Milk affected cow last, maintain strict udder hygiene, and use post-milking teat dip.',
     'प्रभावित गाय का दूध सबसे अंत में निकालें और थन की स्वच्छता बनाए रखें।',
     'बाधित गाईचे दूध सर्वात शेवटी काढा आणि कासेची स्वच्छता राखा.'),
    ('peste_des_petits_ruminants', 'Peste des Petits Ruminants (PPR)', 'बकरियों की महामारी (PPR)', 'शेळ्यांचा बुळकांडी रोग (PPR)', TRUE, TRUE, 2, 5000, 14,
     'Isolate affected goats, provide clean warm water, and contact a veterinarian immediately.',
     'प्रभावित बकरियों को अलग रखें और तुरंत पशु चिकित्सक से संपर्क करें।',
     'बाधित शेळ्यांना वेगळे ठेवा आणि त्वरित पशुवैद्यकांशी संपर्क साधा.')
ON CONFLICT (code) DO NOTHING;

-- 4. Symptoms
INSERT INTO symptoms (code, name_en, name_hi, name_mr, category) VALUES
    ('skin_nodules', 'Skin nodules / lumps', 'त्वचा पर गांठें', 'अंगावर गाठी येणे', 'skin'),
    ('blisters_mouth_feet', 'Blisters on mouth or hooves', 'मुंह और खुर पर छाले', 'तोंडात व खुरांवर फोड येणे', 'mouth_feet'),
    ('fever', 'High fever', 'तेज बुखार', 'तीव्र ताप येणे', 'general'),
    ('excessive_salivation', 'Excessive salivation / drooling', 'मुंह से अत्यधिक लार गिरना', 'तोंडातून जास्त लाळ गळणे', 'mouth_feet'),
    ('lameness', 'Lameness / difficulty walking', 'लंगड़ापन / चलने में कठिनाई', 'लंगडणे / चालण्यास त्रास', 'musculoskeletal'),
    ('nasal_discharge', 'Nasal or ocular discharge', 'नाक या आंख से पानी आना', 'नाकातून किंवा डोळ्यातून स्राव येणे', 'respiratory'),
    ('loss_of_appetite', 'Loss of appetite', 'चारा न खाना / भूख न लगना', 'चारा न खाणे / भूक मंदावणे', 'general'),
    ('milk_drop', 'Sudden drop in milk yield', 'दूध उत्पादन में अचानक कमी', 'दुधाचे प्रमाण अचानक कमी होणे', 'udder'),
    ('swollen_udder', 'Swollen or hot udder', 'थन में सूजन या गर्मी', 'कास सुजणे किंवा गरम लागणे', 'udder'),
    ('diarrhoea', 'Severe diarrhoea', 'गंभीर दस्त', 'तीव्र जुलाब होणे', 'digestive'),
    ('swelling_limb', 'Painful swelling on thigh / shoulder', 'जांघ या कंधे पर दर्दनाक सूजन', 'मांड्या किंवा खांद्यावर सूज येणे', 'musculoskeletal'),
    ('abortion', 'Late-term abortion', 'गर्भपात होना', 'गर्भपात होणे', 'reproductive'),
    ('enlarged_lymph_nodes', 'Enlarged lymph nodes', 'लसीका ग्रंथियों में सूजन', 'लसीका ग्रंथी सुजणे', 'general')
ON CONFLICT (code) DO NOTHING;

-- 5. Synthetic Demo Accounts (All use password: Pashu@2026)
INSERT INTO users (id, phone, email, password_hash, full_name, role, preferred_language, is_active, account_status) VALUES
    ('22222222-2222-4222-8222-222222222001', '+919876543210', 'ramesh.jadhav@demo.pashuvani.in', crypt('Pashu@2026', gen_salt('bf', 10)), 'Ramesh Jadhav (SYNTHETIC DEMO)', 'farmer', 'mr', TRUE, 'active'),
    ('22222222-2222-4222-8222-222222222002', '+919822334455', 'anil.shinde@demo.pashuvani.in', crypt('Pashu@2026', gen_salt('bf', 10)), 'Anil Shinde (SYNTHETIC DEMO)', 'farmer', 'mr', TRUE, 'active'),
    ('22222222-2222-4222-8222-222222222003', '+919833445566', 'suresh.bhosale@demo.pashuvani.in', crypt('Pashu@2026', gen_salt('bf', 10)), 'Suresh Bhosale (SYNTHETIC DEMO)', 'farmer', 'mr', TRUE, 'active'),
    ('22222222-2222-4222-8222-222222222101', '+919890112233', 'dr.kulkarni@mahavet.gov.in', crypt('Pashu@2026', gen_salt('bf', 10)), 'Dr. Rajesh Kulkarni', 'vet', 'en', TRUE, 'active'),
    ('22222222-2222-4222-8222-222222222102', '+919890223344', 'dr.deshmukh@mahavet.gov.in', crypt('Pashu@2026', gen_salt('bf', 10)), 'Dr. Snehal Deshmukh', 'vet', 'mr', TRUE, 'active'),
    ('22222222-2222-4222-8222-222222222103', '+919890334455', 'dr.pawar@mahavet.gov.in', crypt('Pashu@2026', gen_salt('bf', 10)), 'Dr. Vikram Pawar', 'vet', 'en', TRUE, 'pending_verification'),
    ('22222222-2222-4222-8222-222222222201', '+919890445566', 'dahdo.satara@maharashtra.gov.in', crypt('Pashu@2026', gen_salt('bf', 10)), 'Dr. Mahesh Patil (District Officer)', 'officer', 'en', TRUE, 'active'),
    ('22222222-2222-4222-8222-222222222301', '+919890556677', 'admin@pashuvani.gov.in', crypt('Pashu@2026', gen_salt('bf', 10)), 'State Surveillance Admin', 'admin', 'en', TRUE, 'active')
ON CONFLICT (phone) DO NOTHING;

INSERT INTO farmers (user_id, village_id, taluka_id, district_id, home_location, consent_alerts, consent_given_at) VALUES
    ('22222222-2222-4222-8222-222222222001', '11111111-1111-4111-8111-111111111401', '11111111-1111-4111-8111-111111111301', '11111111-1111-4111-8111-111111111201', ST_SetSRID(ST_MakePoint(74.4331, 17.9856), 4326)::geography, TRUE, NOW()),
    ('22222222-2222-4222-8222-222222222002', '11111111-1111-4111-8111-111111111402', '11111111-1111-4111-8111-111111111301', '11111111-1111-4111-8111-111111111201', ST_SetSRID(ST_MakePoint(74.4820, 17.9542), 4326)::geography, TRUE, NOW()),
    ('22222222-2222-4222-8222-222222222003', '11111111-1111-4111-8111-111111111403', '11111111-1111-4111-8111-111111111301', '11111111-1111-4111-8111-111111111201', ST_SetSRID(ST_MakePoint(74.3910, 18.0120), 4326)::geography, TRUE, NOW())
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO veterinarians (user_id, registration_no, qualification, clinic_name, address, working_hours, is_para_vet, district_id, taluka_id, clinic_location, is_verified, verified_at) VALUES
    ('22222222-2222-4222-8222-222222222101', 'SVC-MH-2019-4482', 'M.V.Sc (Medicine)', 'Taluka Veterinary Polyclinic, Phaltan', 'Near Krishi उत्पन्न Bazar Samiti, Ring Road, Phaltan, Dist. Satara', '9:00 AM – 6:00 PM', FALSE, '11111111-1111-4111-8111-111111111201', '11111111-1111-4111-8111-111111111301', ST_SetSRID(ST_MakePoint(74.4318, 17.9912), 4326)::geography, TRUE, NOW()),
    ('22222222-2222-4222-8222-222222222102', 'SVC-MH-2021-5190', 'B.V.Sc & A.H.', 'Government Veterinary Dispensary Grade-I, Barad', 'Main Bazar Peth, Barad, Tal. Phaltan, Dist. Satara', '9:00 AM – 5:00 PM', FALSE, '11111111-1111-4111-8111-111111111201', '11111111-1111-4111-8111-111111111301', ST_SetSRID(ST_MakePoint(74.4805, 17.9560), 4326)::geography, TRUE, NOW()),
    ('22222222-2222-4222-8222-222222222103', 'SVC-MH-2025-8801', 'B.V.Sc & A.H.', 'Vidani Rural Vet Center', 'Vidani, Tal. Phaltan, Dist. Satara', '10:00 AM – 4:00 PM', FALSE, '11111111-1111-4111-8111-111111111201', '11111111-1111-4111-8111-111111111301', ST_SetSRID(ST_MakePoint(74.4550, 17.9710), 4326)::geography, FALSE, NULL)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO officers (user_id, designation, level, scope_location_id) VALUES
    ('22222222-2222-4222-8222-222222222201', 'District Animal Husbandry Deputy Commissioner, Satara', 'district', '11111111-1111-4111-8111-111111111201')
ON CONFLICT (user_id) DO NOTHING;

-- 6. Synthetic Demo Animals
INSERT INTO animals (id, farmer_user_id, species_id, breed_id, tag_number, name, sex, birth_date, approx_age_months, markings, is_active, client_created_at) VALUES
    ('33333333-3333-4333-8333-333333333001', '22222222-2222-4222-8222-222222222001',
     (SELECT id FROM species WHERE code = 'cattle'),
     (SELECT id FROM breeds WHERE code = 'gir'),
     'MH-SAT-2026-081', 'Gauri', 'female', '2022-03-15', 44, 'Reddish brown coat with white forehead patch', TRUE, NOW() - INTERVAL '30 days'),
    ('33333333-3333-4333-8333-333333333002', '22222222-2222-4222-8222-222222222002',
     (SELECT id FROM species WHERE code = 'buffalo'),
     (SELECT id FROM breeds WHERE code = 'murrah'),
     'MH-SAT-2026-112', 'Krishna', 'female', '2021-07-10', 52, 'Jet black coat with curled horns', TRUE, NOW() - INTERVAL '25 days'),
    ('33333333-3333-4333-8333-333333333003', '22222222-2222-4222-8222-222222222003',
     (SELECT id FROM species WHERE code = 'cattle'),
     (SELECT id FROM breeds WHERE code = 'khillar'),
     'MH-SAT-2026-094', 'Kapila', 'female', '2022-11-05', 36, 'Greyish white compact body', TRUE, NOW() - INTERVAL '20 days'),
    ('33333333-3333-4333-8333-333333333004', '22222222-2222-4222-8222-222222222001',
     (SELECT id FROM species WHERE code = 'cattle'),
     (SELECT id FROM breeds WHERE code = 'holstein_friesian'),
     'MH-SAT-2026-082', 'Nandini', 'female', '2023-01-20', 33, 'Black and white patches on flank', TRUE, NOW() - INTERVAL '18 days')
ON CONFLICT (id) DO NOTHING;

-- 7. Synthetic Demo Disease Reports
INSERT INTO disease_reports (
    id, animal_id, reporter_user_id, reported_at, received_at, description, description_language,
    location, location_source, location_accuracy_m, village_id, taluka_id, district_id,
    screening_model_version, screening_top_label, screening_top_confidence, screening_inconclusive,
    screening_scores, screening_ran_at, status, claimed_by_vet_id, claimed_at, confirmed_disease_id, confirmed_at, expected_image_count
) VALUES
    -- Report 1: Submitted (Pending review)
    ('44444444-4444-4444-8444-444444444001',
     '33333333-3333-4333-8333-333333333001',
     '22222222-2222-4222-8222-222222222001',
     NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours',
     'Multiple round skin nodules noticed on neck, shoulders and back. Animal has 104F fever and reduced feeding.',
     'en',
     ST_SetSRID(ST_MakePoint(74.4331, 17.9856), 4326)::geography, 'gps', 4.5,
     '11111111-1111-4111-8111-111111111401', '11111111-1111-4111-8111-111111111301', '11111111-1111-4111-8111-111111111201',
     'mobilenet_v3_small_v1.0.0', 'lumpy_skin_disease', 0.89, FALSE,
     '[{"label":"lumpy_skin_disease","score":0.89},{"label":"normal","score":0.07},{"label":"foot_and_mouth_disease","score":0.04}]'::jsonb,
     NOW() - INTERVAL '3 hours', 'submitted', NULL, NULL, NULL, NULL, 0),

    -- Report 2: Under Review (Claimed by Dr. Kulkarni)
    ('44444444-4444-4444-8444-444444444002',
     '33333333-3333-4333-8333-333333333002',
     '22222222-2222-4222-8222-222222222002',
     NOW() - INTERVAL '14 hours', NOW() - INTERVAL '14 hours',
     'Excessive salivation stringing from mouth. Reluctant to walk, limping on right hind leg. Small blisters seen on tongue.',
     'en',
     ST_SetSRID(ST_MakePoint(74.4820, 17.9542), 4326)::geography, 'gps', 5.2,
     '11111111-1111-4111-8111-111111111402', '11111111-1111-4111-8111-111111111301', '11111111-1111-4111-8111-111111111201',
     'mobilenet_v3_small_v1.0.0', 'foot_and_mouth_disease', 0.94, FALSE,
     '[{"label":"foot_and_mouth_disease","score":0.94},{"label":"normal","score":0.04},{"label":"lumpy_skin_disease","score":0.02}]'::jsonb,
     NOW() - INTERVAL '14 hours', 'under_review',
     '22222222-2222-4222-8222-222222222101', NOW() - INTERVAL '12 hours', NULL, NULL, 0),

    -- Report 3: Confirmed LSD Case #1 (Tadawale, Phaltan)
    ('44444444-4444-4444-8444-444444444003',
     '33333333-3333-4333-8333-333333333003',
     '22222222-2222-4222-8222-222222222003',
     NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days',
     'Firm circumscribed nodules noticed 4 days ago across brisket and perineum. Mild fever.',
     'en',
     ST_SetSRID(ST_MakePoint(74.4280, 17.9890), 4326)::geography, 'gps', 3.8,
     '11111111-1111-4111-8111-111111111403', '11111111-1111-4111-8111-111111111301', '11111111-1111-4111-8111-111111111201',
     'mobilenet_v3_small_v1.0.0', 'lumpy_skin_disease', 0.92, FALSE,
     '[{"label":"lumpy_skin_disease","score":0.92},{"label":"normal","score":0.05},{"label":"foot_and_mouth_disease","score":0.03}]'::jsonb,
     NOW() - INTERVAL '2 days', 'confirmed',
     '22222222-2222-4222-8222-222222222101', NOW() - INTERVAL '46 hours',
     (SELECT id FROM diseases WHERE code = 'lumpy_skin_disease'), NOW() - INTERVAL '45 hours', 0),

    -- Report 4: Confirmed LSD Case #2 (Phaltan Rural)
    ('44444444-4444-4444-8444-444444444004',
     '33333333-3333-4333-8333-333333333004',
     '22222222-2222-4222-8222-222222222001',
     NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day',
     'Cutaneous nodules and swelling over prescapular lymph nodes with 103.8F fever.',
     'en',
     ST_SetSRID(ST_MakePoint(74.4360, 17.9825), 4326)::geography, 'gps', 4.1,
     '11111111-1111-4111-8111-111111111401', '11111111-1111-4111-8111-111111111301', '11111111-1111-4111-8111-111111111201',
     'mobilenet_v3_small_v1.0.0', 'lumpy_skin_disease', 0.91, FALSE,
     '[{"label":"lumpy_skin_disease","score":0.91},{"label":"normal","score":0.06},{"label":"foot_and_mouth_disease","score":0.03}]'::jsonb,
     NOW() - INTERVAL '1 day', 'confirmed',
     '22222222-2222-4222-8222-222222222101', NOW() - INTERVAL '22 hours',
     (SELECT id FROM diseases WHERE code = 'lumpy_skin_disease'), NOW() - INTERVAL '21 hours', 0)
ON CONFLICT (id) DO NOTHING;

-- Report Symptoms
INSERT INTO report_symptoms (report_id, symptom_id)
SELECT '44444444-4444-4444-8444-444444444001'::uuid, id FROM symptoms WHERE code IN ('skin_nodules', 'fever', 'enlarged_lymph_nodes', 'nasal_discharge')
ON CONFLICT DO NOTHING;

INSERT INTO report_symptoms (report_id, symptom_id)
SELECT '44444444-4444-4444-8444-444444444002'::uuid, id FROM symptoms WHERE code IN ('excessive_salivation', 'blisters_mouth_feet', 'lameness', 'fever')
ON CONFLICT DO NOTHING;

INSERT INTO report_symptoms (report_id, symptom_id)
SELECT '44444444-4444-4444-8444-444444444003'::uuid, id FROM symptoms WHERE code IN ('skin_nodules', 'fever')
ON CONFLICT DO NOTHING;

INSERT INTO report_symptoms (report_id, symptom_id)
SELECT '44444444-4444-4444-8444-444444444004'::uuid, id FROM symptoms WHERE code IN ('skin_nodules', 'fever', 'enlarged_lymph_nodes')
ON CONFLICT DO NOTHING;

-- 8. Vet Verifications for Confirmed Reports 3 & 4
INSERT INTO vet_verifications (id, report_id, vet_user_id, decision, disease_id, notes, visit_required, is_current, verified_at) VALUES
    ('66666666-6666-4666-8666-666666666001',
     '44444444-4444-4444-8444-444444444003',
     '22222222-2222-4222-8222-222222222101',
     'confirmed',
     (SELECT id FROM diseases WHERE code = 'lumpy_skin_disease'),
     'Clinically confirmed Lumpy Skin Disease. Characteristic sit-fast nodules and lymphadenopathy observed. Advised strict vector control and isolation.',
     TRUE, TRUE, NOW() - INTERVAL '45 hours'),
    ('66666666-6666-4666-8666-666666666002',
     '44444444-4444-4444-8444-444444444004',
     '22222222-2222-4222-8222-222222222101',
     'confirmed',
     (SELECT id FROM diseases WHERE code = 'lumpy_skin_disease'),
     'Second confirmed LSD case within Phaltan cluster. Supportive anti-inflammatory therapy initiated.',
     TRUE, TRUE, NOW() - INTERVAL '21 hours')
ON CONFLICT (id) DO NOTHING;

-- 9. Sample Health Records, Vaccinations & Treatments
INSERT INTO health_records (id, animal_id, recorded_by_user_id, source_report_id, record_type, summary, weight_kg, temperature_c, recorded_at) VALUES
    ('77777777-7777-4777-8777-777777777001',
     '33333333-3333-4333-8333-333333333001',
     '22222222-2222-4222-8222-222222222101',
     NULL, 'checkup', 'Routine pre-monsoon health checkup. Good body condition score.', 385.0, 38.6, NOW() - INTERVAL '15 days'),
    ('77777777-7777-4777-8777-777777777002',
     '33333333-3333-4333-8333-333333333003',
     '22222222-2222-4222-8222-222222222101',
     '44444444-4444-4444-8444-444444444003', 'illness', 'Clinical examination confirmed LSD nodules; isolation started.', 360.0, 39.8, NOW() - INTERVAL '45 hours'),
    ('77777777-7777-4777-8777-777777777006',
     '33333333-3333-4333-8333-333333333002',
     '22222222-2222-4222-8222-222222222101',
     '44444444-4444-4444-8444-444444444002', 'illness', 'Oral vesicles on tongue and interdigital cleft lesions observed. Suspected FMD; mouth wash with 1% potassium permanganate initiated.', 440.0, 39.9, NOW() - INTERVAL '12 hours'),
    ('77777777-7777-4777-8777-777777777007',
     '33333333-3333-4333-8333-333333333004',
     '22222222-2222-4222-8222-222222222101',
     '44444444-4444-4444-8444-444444444004', 'illness', 'Confirmed LSD cutaneous nodules over prescapular lymph nodes. Strict shed isolation and vector control started.', 355.0, 39.7, NOW() - INTERVAL '21 hours')
ON CONFLICT (id) DO NOTHING;

INSERT INTO vaccination_records (id, animal_id, disease_id, vaccine_name, batch_number, dose_number, administered_on, next_due_on, administered_by_user_id, notes) VALUES
    ('77777777-7777-4777-8777-777777777101',
     '33333333-3333-4333-8333-333333333001',
     (SELECT id FROM diseases WHERE code = 'foot_and_mouth_disease'),
     'Raksha-Ovac Trivalent FMD', 'FMD-MH-2026-09', 1, CURRENT_DATE - 90, CURRENT_DATE + 90,
     '22222222-2222-4222-8222-222222222101', 'NADCP Round 5 vaccination completed'),
    ('77777777-7777-4777-8777-777777777104',
     '33333333-3333-4333-8333-333333333002',
     (SELECT id FROM diseases WHERE code = 'hemorrhagic_septicemia'),
     'Raksha-HS+BQ Combined Vaccine', 'HSBQ-MH-2026-14', 1, CURRENT_DATE - 75, CURRENT_DATE + 290,
     '22222222-2222-4222-8222-222222222101', 'Pre-monsoon buffalo prophylaxis'),
    ('77777777-7777-4777-8777-777777777105',
     '33333333-3333-4333-8333-333333333003',
     (SELECT id FROM diseases WHERE code = 'foot_and_mouth_disease'),
     'Raksha-Ovac Trivalent FMD', 'FMD-MH-2026-09', 1, CURRENT_DATE - 95, CURRENT_DATE + 85,
     '22222222-2222-4222-8222-222222222101', 'Annual FMD booster'),
    ('77777777-7777-4777-8777-777777777106',
     '33333333-3333-4333-8333-333333333004',
     (SELECT id FROM diseases WHERE code = 'foot_and_mouth_disease'),
     'Raksha-Ovac Trivalent FMD', 'FMD-MH-2026-09', 1, CURRENT_DATE - 90, CURRENT_DATE + 90,
     '22222222-2222-4222-8222-222222222101', 'NADCP Round 5 vaccination completed')
ON CONFLICT (id) DO NOTHING;

INSERT INTO treatments (id, animal_id, report_id, prescribed_by_vet_id, medication_name, dosage, duration_days, instructions, started_on, ended_on, outcome_notes) VALUES
    ('77777777-7777-4777-8777-777777777201',
     '33333333-3333-4333-8333-333333333003',
     '44444444-4444-4444-8444-444444444003',
     '22222222-2222-4222-8222-222222222101',
     'Meloxicam + Enrofloxacin Supportive Protocol',
     '15 ml IM once daily', 5,
     'Keep animal in mosquito-screened shed; apply herbal wound spray on ruptured nodules.',
     CURRENT_DATE - 2, CURRENT_DATE + 3, 'Fever subsiding after 48 hours.'),
    ('77777777-7777-4777-8777-777777777203',
     '33333333-3333-4333-8333-333333333002',
     '44444444-4444-4444-8444-444444444002',
     '22222222-2222-4222-8222-222222222101',
     'Boric Acid + Glycerin Oral Paint & Meloxicam',
     '15 ml IM + Topical oral application TDS', 5,
     'Provide soft green fodder and clean water. Wash hooves with 2% copper sulphate solution.',
     CURRENT_DATE - 1, CURRENT_DATE + 4, 'Salivation reduced; animal able to drink water.'),
    ('77777777-7777-4777-8777-777777777204',
     '33333333-3333-4333-8333-333333333004',
     '44444444-4444-4444-8444-444444444004',
     '22222222-2222-4222-8222-222222222101',
     'Enrofloxacin LA + Chlorpheniramine Maleate',
     '12 ml IM OD × 4 days', 4,
     'Strict isolation from healthy cattle; apply neem-camphor oil around shed.',
     CURRENT_DATE - 1, CURRENT_DATE + 3, 'Under active veterinary supervision.')
ON CONFLICT (id) DO NOTHING;

-- 10. Active Outbreak Cluster (Based solely on veterinarian-confirmed cases 3 & 4)
INSERT INTO outbreaks (id, disease_id, district_id, taluka_id, centroid, radius_m, confirmed_case_count, first_case_at, last_case_at, status) VALUES
    ('55555555-5555-4555-8555-555555555001',
     (SELECT id FROM diseases WHERE code = 'lumpy_skin_disease'),
     '11111111-1111-4111-8111-111111111201',
     '11111111-1111-4111-8111-111111111301',
     ST_SetSRID(ST_MakePoint(74.4320, 17.9858), 4326)::geography,
     5000, 2, NOW() - INTERVAL '45 hours', NOW() - INTERVAL '21 hours', 'active')
ON CONFLICT (id) DO NOTHING;

INSERT INTO outbreak_cases (outbreak_id, report_id) VALUES
    ('55555555-5555-4555-8555-555555555001', '44444444-4444-4444-8444-444444444003'),
    ('55555555-5555-4555-8555-555555555001', '44444444-4444-4444-8444-444444444004')
ON CONFLICT DO NOTHING;

-- 11. Official Officer-Approved Alert for the Outbreak Cluster
INSERT INTO alerts (id, outbreak_id, approved_by_user_id, radius_m, title_en, title_hi, title_mr, body_en, body_hi, body_mr, status, recipient_count, sent_at) VALUES
    ('88888888-8888-4888-8888-888888888001',
     '55555555-5555-4555-8555-555555555001',
     '22222222-2222-4222-8222-222222222201',
     5000,
     'Confirmed Lumpy Skin Disease Alert — Phaltan Taluka',
     'पुष्टि की गई लम्पी त्वचा रोग चेतावनी — फलटण तालुका',
     'रोग चेतावणी: लंपी त्वचा रोग (LSD) — फलटण तालुका',
     'This cluster alert is based on veterinarian-confirmed cases in Phaltan Taluka (within 5 km). Isolate cattle with skin nodules or fever immediately and contact the Taluka Veterinary Polyclinic.',
     'यह चेतावनी फलटण तालुका में पशु चिकित्सक द्वारा पुष्टि किए गए मामलों पर आधारित है। अपने पशुओं की जांच करें।',
     'फलटण तालुक्यात ५ किमी अंतरावर पशुवैद्यकांनी पुष्टी केलेले लंपी त्वचा रोगाचे रुग्ण आढळले आहेत. आपल्या जनावरांची नियमित तपासणी करा व लक्षणे दिसल्यास त्वरित संपर्क साधा.',
     'sent', 3, NOW() - INTERVAL '20 hours')
ON CONFLICT (id) DO NOTHING;

-- 12. Experimental District Risk Estimate (Satara)
INSERT INTO risk_predictions (id, district_id, disease_id, horizon_days, risk_score, risk_band, top_factors, model_version, is_experimental, computed_at) VALUES
    ('99999999-9999-4999-8999-999999999001',
     '11111111-1111-4111-8111-111111111201',
     (SELECT id FROM diseases WHERE code = 'lumpy_skin_disease'),
     14, 0.74, 'high',
     '[{"factor":"confirmed_cases_14d","impact":0.42},{"factor":"post_monsoon_humidity","impact":0.21},{"factor":"vector_density_index","impact":0.11}]'::jsonb,
     'xgb_outbreak_risk_v1.0.0', TRUE, NOW() - INTERVAL '2 hours')
ON CONFLICT (id) DO NOTHING;

