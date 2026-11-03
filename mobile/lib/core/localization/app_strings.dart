import 'vet_strings.dart';

class AppStrings {
  AppStrings._();

  static String currentLang = 'mr'; // 'mr', 'en', 'hi' - Marathi default

  static void setLanguage(String lang) {
    if (['en', 'mr', 'hi'].contains(lang)) {
      currentLang = lang;
    }
  }

  static String t(String key) {
    final m = _translations[key] ?? vetStrings[key];
    return m?[currentLang] ?? m?['en'] ?? key;
  }

  /// `t` with `{placeholder}` substitution.
  static String tf(String key, Map<String, String> args) {
    var out = t(key);
    args.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out;
  }

  static String formatSymptom(String code) {
    final key = 'symptom_$code';
    if (_translations.containsKey(key)) {
      return t(key);
    }
    return code.replaceAll('_', ' ');
  }

  static String formatDisease(String code) {
    final key = 'disease_$code';
    if (_translations.containsKey(key)) {
      return t(key);
    }
    return code.replaceAll('_', ' ').toUpperCase();
  }

  static String formatBreed(String code) {
    final key = 'breed_$code';
    if (_translations.containsKey(key)) {
      return t(key);
    }
    return code.replaceAll('_', ' ').toUpperCase();
  }

  static const Map<String, Map<String, String>> _translations = {
    // App & Identity
    'app_name': {
      'en': 'Pashu Wani',
      'mr': 'पशुवाणी',
      'hi': 'पशु वाणी',
    },
    'app_tagline': {
      'en': 'Offline Livestock Healthcare & Surveillance',
      'mr': 'ऑफलाइन पशु आरोग्य व रोग पाळत प्रणाली',
      'hi': 'ऑफलाइन पशु स्वास्थ्य एवं रोग निगरानी',
    },

    // Mandatory Regulatory Safety Strings (PPT S5)
    'clinical_notice': {
      'en': 'Clinical Notice',
      'mr': 'वैद्यकीय अस्वीकरण',
      'hi': 'चिकित्सीय अस्वीकरण',
    },
    'safety_disclaimer': {
      'en': 'This is a preliminary check from your phone, not a diagnosis. A veterinarian will review your report.',
      'mr': 'हा तुमच्या फोनवरील प्राथमिक तपासणी अहवाल आहे, वैद्यकीय निदान नाही. पशुवैद्यकीय अधिकारी तुमच्या अहवालाची तपासणी करतील.',
      'hi': 'यह आपके फोन से की गई प्रारंभिक जांच है, पक्का निदान नहीं। पशु चिकित्सक आपके मामले की जांच करेंगे।',
    },
    'offline_banner': {
      'en': 'Working Offline. Reports & screenings will sync automatically when network returns.',
      'mr': 'ऑफलाइन मोड सुरू आहे. नेटवर्क आल्यावर अहवाल आपोआप सिंक होतील.',
      'hi': 'ऑफलाइन मोड सक्रिय। नेटवर्क आने पर रिपोर्ट अपने आप सिंक हो जाएगी।',
    },

    // Navigation (compact names to prevent tab truncation)
    'nav_home': {'en': 'Home', 'mr': 'मुख्य', 'hi': 'होम'},
    'nav_animals': {'en': 'My Animals', 'mr': 'माझी जनावरे', 'hi': 'मेरे पशु'},
    'nav_report': {'en': 'Report Illness', 'mr': 'रोग नोंदवा', 'hi': 'रोग रिपोर्ट'},
    'nav_nearby': {'en': 'Nearby', 'mr': 'जवळचे', 'hi': 'आसपास'},
    'nav_alerts': {'en': 'Alerts', 'mr': 'रोग सूचना', 'hi': 'रोग अलर्ट'},
    'nav_profile': {'en': 'Profile', 'mr': 'प्रोफाइल', 'hi': 'प्रोफाइल'},

    // Nearby Vets & Outbreak Map
    'nearby_title': {'en': 'Nearby Vets & Outbreaks', 'mr': 'पशुवैद्यक व रोग नकाशे', 'hi': 'पशु चिकित्सक एवं रोग मानचित्र'},
    'tab_nearby_vets': {'en': 'Nearby Veterinarians', 'mr': 'जवळचे पशुवैद्यक', 'hi': 'नज़दीकी पशु चिकित्सक'},
    'tab_outbreak_map': {'en': 'Live Outbreak Map', 'mr': 'रोग प्रसार नकाशा', 'hi': 'रोग प्रसार मानचित्र'},
    'verified_vet': {'en': 'Verified Veterinarian', 'mr': 'प्रमाणित पशुवैद्यकीय अधिकारी', 'hi': 'सत्यापित पशु चिकित्सक'},
    'call_vet': {'en': 'Call Doctor', 'mr': 'कॉल करा', 'hi': 'कॉल करें'},
    'directions': {'en': 'Directions', 'mr': 'मार्ग पहा', 'hi': 'दिशा-निर्देश'},
    'distance_km': {'en': 'km away', 'mr': 'किमी अंतरावर', 'hi': 'किमी दूर'},
    'working_hours': {'en': 'Hours', 'mr': 'वेळ', 'hi': 'समय'},
    'emergency_available': {'en': 'Emergency On-Call', 'mr': 'आपत्कालीन सेवा उपलब्ध', 'hi': 'आपातकालीन सेवा उपलब्ध'},
    'no_vets_available': {'en': 'No verified veterinarians available', 'mr': 'सध्या कोणतेही प्रमाणित पशुवैद्यक उपलब्ध नाहीत', 'hi': 'वर्तमान में कोई सत्यापित पशु चिकित्सक उपलब्ध नहीं है'},
    'check_again_later': {'en': 'Please check again later.', 'mr': 'कृपया काही वेळाने पुन्हा तपासा.', 'hi': 'कृपया कुछ समय बाद पुनः प्रयास करें।'},
    'search_vets': {'en': 'Search doctor or clinic name...', 'mr': 'डॉक्टर किंवा दवाखान्याचे नाव शोधा...', 'hi': 'डॉक्टर या अस्पताल का नाम खोजें...'},
    'map_legend': {'en': 'Map Legend', 'mr': 'नकाशा सूची', 'hi': 'मानचित्र संकेत'},
    'legend_farmer': {'en': 'Your Farm Location', 'mr': 'आपले शेत / स्थान', 'hi': 'आपका खेत / स्थान'},
    'legend_vet': {'en': 'Verified Veterinarian', 'mr': 'प्रमाणित पशुवैद्यक दवाखाना', 'hi': 'सत्यापित पशु चिकित्सालय'},
    'legend_confirmed_outbreak': {'en': 'Confirmed Outbreak Zone', 'mr': 'पुष्टी झालेला रोग संसर्ग क्षेत्र', 'hi': 'पुष्ट रोग प्रकोप क्षेत्र'},
    'legend_suspected_cluster': {'en': 'Suspected Cluster (Under Review)', 'mr': 'संशयित संसर्ग क्षेत्र (तपासणी सुरू)', 'hi': 'संभावित प्रकोप क्षेत्र (समीक्षा जारी)'},
    'legend_case': {'en': 'Confirmed Case Report', 'mr': 'पुष्टी झालेला आजारी रुग्ण', 'hi': 'पुष्ट बीमारी का मामला'},
    'filter_all_layers': {'en': 'All', 'mr': 'सर्व', 'hi': 'सभी'},
    'filter_vets_only': {'en': 'Vets Only', 'mr': 'फक्त डॉक्टर', 'hi': 'केवल डॉक्टर'},
    'filter_outbreaks_only': {'en': 'Outbreaks Only', 'mr': 'फक्त रोग क्षेत्र', 'hi': 'केवल प्रकोप'},
    'center_my_location': {'en': 'Center My Location', 'mr': 'माझे स्थान पहा', 'hi': 'मेरा स्थान देखें'},
    'advisory_guidelines': {'en': 'Surveillance Advisory', 'mr': 'आरोग्य मार्गदर्शक सूचना', 'hi': 'निगरानी दिशा-निर्देश'},
    'cases_in_zone': {'en': 'cases in zone', 'mr': 'या क्षेत्रातील रुग्ण', 'hi': 'क्षेत्र में मामले'},
    'advisory_guidelines_content': {
      'en': '1. Avoid cattle movement outside village boundary.\n2. Spray anti-vector repellent against flies & ticks.\n3. Report any fever or nodule symptoms immediately.',
      'mr': '१. जनावरांना गावाच्या सीमेबाहेर नेणे टाळा.\n२. गोचीड व माश्या प्रतिबंधक औषध फवारणी करा.\n३. ताप किंवा त्वचेवर गाठी दिसल्यास त्वरित कळवा.',
      'hi': '१. पशुओं को गाँव की सीमा से बाहर ले जाने से बचें।\n२. मक्खियों और चीचड़ों से बचाव के लिए दवा छिड़कें।\n३. बुखार या त्वचा पर गांठें दिखने पर तुरंत सूचित करें।',
    },
    'advisory_lsd_cluster': {
      'en': 'Cluster of 4 veterinarian-confirmed cases. Ring vaccination active in Phaltan rural cluster.',
      'mr': '४ पुष्टी झालेले रुग्ण आढळले. फलटण ग्रामीण भागात रिंग लसीकरण मोहीम सुरू.',
      'hi': '४ पुष्ट मामले पाए गए। फलटन ग्रामीण क्षेत्र में रिंग टीकाकरण अभियान जारी।',
    },
    'advisory_fmd_cluster': {
      'en': 'Suspected cluster under veterinarian review near Barad village.',
      'mr': 'बरड गावाजवळ संशयित रुग्णांची पशुवैद्यकीय तपासणी सुरू.',
      'hi': 'बरड गाँव के पास संदिग्ध मामलों की पशु चिकित्सक जांच जारी।',
    },
    'verified_by_dept': {
      'en': 'Verified by Veterinary Department, Satara.',
      'mr': 'पशुसंवर्धन विभाग, सातारा द्वारे अधिकृत तपासणी पूर्ण.',
      'hi': 'पशुपालन विभाग, सतारा द्वारा अधिकृत जांच पूर्ण।',
    },

    // Locations
    'location_phaltan_satara': {
      'en': 'Phaltan, Satara',
      'mr': 'फलटण, सातारा',
      'hi': 'फलटन, सतारा',
    },
    'district_satara': {
      'en': 'Satara District',
      'mr': 'सातारा जिल्हा',
      'hi': 'सतारा ज़िला',
    },
    'phaltan_rural': {
      'en': 'Phaltan Rural',
      'mr': 'फलटण ग्रामीण',
      'hi': 'फलटन ग्रामीण',
    },

    // Dashboard
    'greeting': {'en': 'Namaste, Farmer', 'mr': 'नमस्ते शेतकरी बांधव', 'hi': 'नमस्ते किसान भाई'},
    'registered_cattle': {'en': 'Registered Animals', 'mr': 'नोंदणीकृत जनावरे', 'hi': 'पंजीकृत पशु'},
    'pending_reports': {'en': 'Pending Reports', 'mr': 'प्रलंबित अहवाल', 'hi': 'लंबित रिपोर्ट'},
    'active_alerts': {'en': 'Nearby Warnings', 'mr': 'परिसरातील सतर्कता', 'hi': 'क्षेत्रीय चेतावनी'},
    'quick_actions': {'en': 'Quick Actions', 'mr': 'त्वरित सेवा', 'hi': 'त्वरित सेवाएं'},
    'recent_reports': {'en': 'Recent Reports', 'mr': 'अलीकडील अहवाल', 'hi': 'हाल की रिपोर्ट'},
    'view_all': {'en': 'View All', 'mr': 'सर्व पहा', 'hi': 'सभी देखें'},
    'view_details': {'en': 'View Details', 'mr': 'तपशील पहा', 'hi': 'विवरण देखें'},

    // Quick Actions
    'action_scan': {'en': 'AI Image Scan', 'mr': 'एआय तपासणी', 'hi': 'एआई जांच'},
    'action_scan_sub': {'en': 'MobileNetV3 Vision', 'mr': 'मोबाईलनेट तपासणी', 'hi': 'मोबाइलनेट जांच'},
    'action_add_animal': {'en': 'Register Animal', 'mr': 'जनावर नोंदवा', 'hi': 'पशु जोड़ें'},
    'action_add_animal_sub': {'en': 'New Cattle Registration', 'mr': 'नवीन जनावर नोंदणी', 'hi': 'नया पशु पंजीकरण'},
    'action_report': {'en': 'Report Disease', 'mr': 'रोग तक्रार नोंदवा', 'hi': 'रोग शिकायत दर्ज करें'},
    'action_report_sub': {'en': 'Send Symptoms & Photo', 'mr': 'लक्षणे व फोटो पाठवा', 'hi': 'लक्षण और फोटो भेजें'},
    'action_passport': {'en': 'Digital QR Passport', 'mr': 'डिजिटल क्यूआर पास', 'hi': 'डिजिटल क्यूआर पास'},
    'action_passport_sub': {'en': 'Offline Health Pass', 'mr': 'ऑफलाइन आरोग्य पास', 'hi': 'ऑफलाइन स्वास्थ्य पास'},

    // Surveillance Alerts
    'alert_lsd_title': {
      'en': 'Outbreak Alert: Lumpy Skin Disease (LSD)',
      'mr': 'रोग चेतावणी: लंपी त्वचा रोग (LSD)',
      'hi': 'रोग चेतावनी: लंपी त्वचा रोग (LSD)',
    },
    'alert_lsd_body': {
      'en': 'Veterinarian-confirmed cases detected within 3 km in Phaltan. Check your animals regularly.',
      'mr': 'फलटण तालुक्यात ३ किमी अंतरावर पशुवैद्यकांनी पुष्टी केलेले रुग्ण आढळले आहेत. आपल्या जनावरांची नियमित तपासणी करा.',
      'hi': 'फलटन में ३ किमी के दायरे में पशु चिकित्सकों द्वारा पुष्ट मामले पाए गए हैं। अपने पशुओं की नियमित जांच करें।',
    },

    // Animals Screen
    'animal_name': {'en': 'Animal Name', 'mr': 'जनावराचे नाव', 'hi': 'पशु का नाम'},
    'tag_number': {'en': 'Ear Tag / Bharat Pashudhan ID', 'mr': 'कानाचा टॅग / भारत पशुधन आयडी', 'hi': 'ईयर टैग / भारत पशुधन आईडी'},
    'tag': {'en': 'Tag', 'mr': 'टॅग', 'hi': 'टैग'},
    'no_tag': {'en': 'No Tag', 'mr': 'टॅग नाही', 'hi': 'टैग नहीं'},
    'species': {'en': 'Species', 'mr': 'प्रजाती', 'hi': 'प्रजाति'},
    'species_cattle': {'en': 'Cattle', 'mr': 'गाय / बैल', 'hi': 'गाय / बैल'},
    'species_buffalo': {'en': 'Buffalo', 'mr': 'म्हैस', 'hi': 'भैंस'},
    'breed': {'en': 'Breed', 'mr': 'जात', 'hi': 'नस्ल'},
    'breed_gir': {'en': 'Gir', 'mr': 'गीर', 'hi': 'गीर'},
    'breed_khillar': {'en': 'Khillar', 'mr': 'खिल्लार', 'hi': 'खिल्लार'},
    'breed_deoni': {'en': 'Deoni', 'mr': 'देवणी', 'hi': 'देवणी'},
    'breed_dangi': {'en': 'Dangi', 'mr': 'डांगी', 'hi': 'डांगी'},
    'breed_hf_cross': {'en': 'HF Cross', 'mr': 'एचएफ क्रॉस', 'hi': 'एचएफ क्रॉस'},
    'breed_jersey_cross': {'en': 'Jersey Cross', 'mr': 'जर्सी क्रॉस', 'hi': 'जर्सी क्रॉस'},
    'breed_other': {'en': 'Indigenous / Other', 'mr': 'इतर / देशी', 'hi': 'अन्य देशी'},
    'breed_murrah': {'en': 'Murrah', 'mr': 'मुऱ्हा', 'hi': 'मुर्रा'},
    'breed_jaffarabadi': {'en': 'Jaffarabadi', 'mr': 'जाफराबादी', 'hi': 'जाफराबादी'},
    'breed_pandharpuri': {'en': 'Pandharpuri', 'mr': 'पंढरपुरी', 'hi': 'पंढरपुरी'},
    'breed_mehsana': {'en': 'Mehsana', 'mr': 'मेहसाणा', 'hi': 'मेहसाणा'},
    'gender': {'en': 'Sex', 'mr': 'लिंग', 'hi': 'लिंग'},
    'gender_female': {'en': 'Female', 'mr': 'मादी', 'hi': 'मादा'},
    'gender_male': {'en': 'Male', 'mr': 'नर', 'hi': 'नर'},
    'birth_date': {'en': 'Birth Date or Age', 'mr': 'जन्मतारीख किंवा वय', 'hi': 'जन्म तिथि या उम्र'},
    'add_animal_btn': {'en': 'Save Animal Record', 'mr': 'जनावर जतन करा', 'hi': 'पशु सुरक्षित करें'},
    'add_animal': {'en': 'Add Animal', 'mr': 'जनावर जोडा', 'hi': 'पशु जोड़ें'},
    'empty_animals': {'en': 'No animals registered yet. Add your cattle to track health & vaccinations.', 'mr': 'अद्याप जनावरांची नोंद नाही. आरोग्य तपासणीसाठी जनावर जोडा.', 'hi': 'अभी कोई पशु पंजीकृत नहीं है। स्वास्थ्य जांच के लिए पशु जोड़ें।'},
    'search_animals': {'en': 'Search by name or ear tag...', 'mr': 'नाव किंवा टॅग नंबर शोधा...', 'hi': 'नाम या टैग नंबर खोजें...'},
    'identification_markings': {'en': 'Identification Markings', 'mr': 'ओळख खूण', 'hi': 'पहचान चिह्न'},
    'details': {'en': 'Details', 'mr': 'वैशिष्ट्ये', 'hi': 'विवरण'},
    'vaccination_history': {'en': 'Vaccination History', 'mr': 'लसीकरण इतिहास', 'hi': 'टीकाकरण इतिहास'},
    'report_illness_btn': {'en': 'Report Illness for this Animal', 'mr': 'या जनावराचा आजार नोंदवा', 'hi': 'इस पशु का रोग दर्ज करें'},
    'animal': {'en': 'Animal', 'mr': 'जनावर', 'hi': 'पशु'},

    // Filters
    'filter_all': {'en': 'All', 'mr': 'सर्व', 'hi': 'सभी'},
    'filter_in_review': {'en': 'In Review', 'mr': 'तपासणी सुरू', 'hi': 'समीक्षा जारी'},
    'filter_confirmed': {'en': 'Confirmed', 'mr': 'पुष्टी झालेले', 'hi': 'पुष्ट'},

    // Reporting
    'select_animal': {'en': '1. Select Affected Animal', 'mr': '१. आजारी जनावर निवडा', 'hi': '१. बीमार पशु चुनें'},
    'select_symptoms': {'en': '2. Select Observed Symptoms', 'mr': '२. दिसणारी लक्षणे निवडा', 'hi': '२. दिखाई देने वाले लक्षण चुनें'},
    'report_description': {'en': '3. Additional Notes (Optional)', 'mr': '३. इतर माहिती किंवा लक्षणे', 'hi': '३. अतिरिक्त लक्षण या विवरण'},
    'capture_photo': {'en': 'Take / Attach Photo', 'mr': 'जनावराचा फोटो काढा', 'hi': 'पशु का फोटो लें'},
    'gps_location': {'en': 'Location Captured', 'mr': 'स्थान (GPS) नोंदवले', 'hi': 'स्थान (GPS) दर्ज हुआ'},
    'submit_report': {'en': 'Submit Report to Vet', 'mr': 'पशुवैद्यकीय अधिकाऱ्यास पाठवा', 'hi': 'पशु चिकित्सक को भेजें'},
    'suspected_disease': {'en': 'Suspected Disease Category', 'mr': 'संशयित आजार', 'hi': 'संभावित बीमारी'},
    'photo_attachment': {'en': 'Photo Attachment', 'mr': 'जनावराचा फोटो', 'hi': 'पशु का फोटो'},
    'ai_screening_detected': {'en': 'AI Screening Observation Available', 'mr': 'एआय तपासणी निरीक्षण उपलब्ध', 'hi': 'एआई जांच अवलोकन उपलब्ध'},

    // Disease Catalog
    'disease_lumpy_skin_disease': {
      'en': 'Lumpy Skin Disease (LSD)',
      'mr': 'लंपी त्वचा रोग (LSD)',
      'hi': 'लंपी त्वचा रोग (LSD)',
    },
    'disease_foot_and_mouth': {
      'en': 'Foot & Mouth Disease (FMD)',
      'mr': 'लाळ्या खुरकूत (FMD)',
      'hi': 'खुरपका-मुंहपका (FMD)',
    },
    'disease_hemorrhagic_septicemia': {
      'en': 'Hemorrhagic Septicemia (HS)',
      'mr': 'घटसर्प (HS)',
      'hi': 'गलघोंटू (HS)',
    },
    'disease_black_quarter': {
      'en': 'Black Quarter (BQ)',
      'mr': 'फाशी / एकटांग्या (BQ)',
      'hi': 'लंगड़ा बुखार (BQ)',
    },
    'disease_general_illness': {
      'en': 'General Illness / Other',
      'mr': 'इतर आजार',
      'hi': 'अन्य बीमारी',
    },

    // Symptoms Catalog
    'symptom_skin_nodules': {'en': 'Skin Nodules and Lumps', 'mr': 'त्वचेवर गाठी व फोड', 'hi': 'त्वचा पर गांठें और छाले'},
    'symptom_fever': {'en': 'High Fever', 'mr': 'तीव्र ताप', 'hi': 'तेज़ बुखार'},
    'symptom_reduced_milk': {'en': 'Sudden Drop in Milk', 'mr': 'दुधात अचानक घट', 'hi': 'दूध में अचानक गिरावट'},
    'symptom_lameness': {'en': 'Limping or Lameness', 'mr': 'लंगडणे किंवा चालण्यास त्रास', 'hi': 'लंगड़ापन'},
    'symptom_salivation': {'en': 'Excessive Salivation', 'mr': 'तोंडातून लाळ गळणे', 'hi': 'मुंह से अत्यधिक लार'},
    'symptom_nasal_discharge': {'en': 'Nasal Discharge or Cough', 'mr': 'नाकातून स्राव किंवा खोकला', 'hi': 'नाक से स्राव या खांसी'},
    'symptom_appetite_loss': {'en': 'Loss of Appetite', 'mr': 'चारा न खाणे किंवा भूक मंदावणे', 'hi': 'चारा न खाना या भूख न लगना'},

    // Case Details & History
    'case_history': {'en': 'Case History', 'mr': 'तपासणी अहवाल', 'hi': 'केस इतिहास'},
    'case_status': {'en': 'Case Status', 'mr': 'केस स्थिती', 'hi': 'केस की स्थिति'},
    'observed_symptoms': {'en': 'Observed Symptoms', 'mr': 'नोंदवलेली लक्षणे', 'hi': 'देखे गए लक्षण'},
    'image_evidence': {'en': 'Image Evidence', 'mr': 'फोटो पुरावा', 'hi': 'फोटो साक्ष्य'},
    'farmer_description': {'en': 'Farmer Description', 'mr': 'शेतकऱ्याची नोंद', 'hi': 'किसान का विवरण'},
    'clinical_decision': {'en': 'Clinical Decision', 'mr': 'पशुवैद्यक तपासणी निष्कर्ष', 'hi': 'पशु चिकित्सक निष्कर्ष'},
    'no_reports_found': {'en': 'No disease reports match this filter.', 'mr': 'या निकषासाठी कोणतेही अहवाल आढळले नाहीत.', 'hi': 'इस फ़िल्टर के लिए कोई रिपोर्ट नहीं मिली।'},
    'date': {'en': 'Date', 'mr': 'दिनांक', 'hi': 'दिनांक'},
    'confirmed_disease': {'en': 'Confirmed Disease', 'mr': 'पुष्टी झालेला रोग', 'hi': 'पुष्ट रोग'},
    'vet_verified_notice': {'en': 'Veterinarian has inspected this case.', 'mr': 'पशुवैद्यकांनी केसची तपासणी केली आहे.', 'hi': 'पशु चिकित्सक द्वारा मामले की जांच पूर्ण।'},

    // Statuses
    'status_submitted': {'en': 'Submitted', 'mr': 'नोंदवले', 'hi': 'दर्ज हुआ'},
    'status_under_review': {'en': 'Under Review', 'mr': 'तपासणी सुरू', 'hi': 'समीक्षा जारी'},
    'status_confirmed': {'en': 'Confirmed Case', 'mr': 'पुष्टी झालेला रुग्ण', 'hi': 'पुष्ट केस'},
    'status_rejected': {'en': 'Rejected', 'mr': 'फेटाळले', 'hi': 'अस्वीकृत'},
    'status_flagged': {'en': 'Visit Required', 'mr': 'प्रत्यक्ष भेट आवश्यक', 'hi': 'जांच आवश्यक'},

    // Sync & Connectivity
    'sync_status': {'en': 'Sync Status', 'mr': 'सिंक स्थिती', 'hi': 'सिंक स्थिति'},
    'sync_queue': {'en': 'Offline Sync Queue', 'mr': 'ऑफलाइन सिंक रांग', 'hi': 'ऑफलाइन सिंक कतार'},
    'sync_now': {'en': 'Sync All Records with Server', 'mr': 'सर्व डेटा सर्व्हरवर पाठवा', 'hi': 'सभी डेटा सर्वर पर सिंक करें'},
    'pending_sync': {'en': 'Pending Sync', 'mr': 'सिंक प्रलंबित', 'hi': 'सिंक लंबित'},
    'synced_cloud': {'en': 'Synced with Server', 'mr': 'सर्व्हरवर सुरक्षित', 'hi': 'सर्वर पर सुरक्षित'},
    'queued_device': {'en': 'Queued on Device', 'mr': 'डिव्हाइसवर सुरक्षित', 'hi': 'डिवाइस पर सुरक्षित'},
    'online_connected': {'en': 'Online (Connected)', 'mr': 'ऑनलाइन (इंटरनेट सुरू)', 'hi': 'ऑनलाइन (इंटरनेट सक्रिय)'},
    'offline_simulated': {'en': 'Offline (Simulated)', 'mr': 'ऑफलाइन (स्थानिक मोड)', 'hi': 'ऑफलाइन (स्थानीय मोड)'},

    // Screening / Scanner
    'ai_scanner': {'en': 'AI Vision Scanner', 'mr': 'एआय तपासणी स्कॅनर', 'hi': 'एआई जांच स्कैनर'},
    'select_animal_title': {'en': 'Select Animal', 'mr': 'जनावर निवडा', 'hi': 'पशु चुनें'},
    'run_screening': {'en': 'Run Screening', 'mr': 'तपासणी सुरू करा', 'hi': 'जांच शुरू करें'},
    'screening_result': {'en': 'Screening Result', 'mr': 'तपासणी निकाल', 'hi': 'जांच परिणाम'},
    'statistical_prob': {'en': 'Statistical Confidence', 'mr': 'सांख्यिकीय विश्वासार्हता', 'hi': 'सांख्यिकीय विश्वसनीयता'},
    'visual_observations': {'en': 'Visual Observations', 'mr': 'दृश्य निरीक्षणे', 'hi': 'दृश्य अवलोकन'},
    'file_report': {'en': 'Send to Veterinarian', 'mr': 'पशुवैद्यकास पाठवा', 'hi': 'पशु चिकित्सक को भेजें'},
    'decision_support_banner': {'en': 'AI Preliminary Observation (Decision Support)', 'mr': 'एआय प्राथमिक निरीक्षण (निर्णय साहाय्य)', 'hi': 'एआई प्रारंभिक अवलोकन (निर्णय सहायता)'},
    'model_version_notice': {'en': 'Model: MobileNetV3 • Preliminary screening, not a diagnosis.', 'mr': 'मॉडेल आवृत्ती: मोबाईलनेट • हे वैद्यकीय निदान नाही.', 'hi': 'मॉडल: मोबाइलनेट • यह चिकित्सीय निदान नहीं है।'},

    // Online AI guidance (Gemini) & voice
    'scan_need_photo': {'en': 'Please attach or capture an animal photo first', 'mr': 'कृपया आधी जनावराचा फोटो काढा', 'hi': 'कृपया पहले पशु का फोटो लें'},
    'scan_offline': {
      'en': 'No internet connection. AI guidance needs data. You can still send a report to the veterinarian.',
      'mr': 'इंटरनेट उपलब्ध नाही. एआय मार्गदर्शनासाठी डेटा आवश्यक आहे. तरीही तुम्ही पशुवैद्यकाला अहवाल पाठवू शकता.',
      'hi': 'इंटरनेट उपलब्ध नहीं है। एआई मार्गदर्शन के लिए डेटा चाहिए। फिर भी आप पशु चिकित्सक को रिपोर्ट भेज सकते हैं।',
    },
    'scan_no_key': {'en': 'AI guidance is not set up in this app build.', 'mr': 'या अ‍ॅपमध्ये एआय मार्गदर्शन सुरू केलेले नाही.', 'hi': 'इस ऐप में एआई मार्गदर्शन सक्रिय नहीं है।'},
    'scan_failed': {
      'en': 'AI guidance could not be completed. Please try again or send a report to the veterinarian.',
      'mr': 'एआय मार्गदर्शन पूर्ण होऊ शकले नाही. कृपया पुन्हा प्रयत्न करा किंवा पशुवैद्यकाला अहवाल पाठवा.',
      'hi': 'एआई मार्गदर्शन पूरा नहीं हो सका। कृपया पुनः प्रयास करें या पशु चिकित्सक को रिपोर्ट भेजें।',
    },
    'scan_analyzing': {'en': 'Analysing photo…', 'mr': 'फोटो तपासत आहे…', 'hi': 'फोटो जांच रहे हैं…'},
    'scan_tap_capture': {'en': 'Tap to capture a photo of the problem area', 'mr': 'समस्या असलेल्या भागाचा फोटो काढण्यासाठी टॅप करा', 'hi': 'समस्या वाले हिस्से का फोटो लेने के लिए टैप करें'},
    'scan_tap_hint': {'en': 'Keep nodules, wounds or mouth sores clearly visible', 'mr': 'गाठी, जखम किंवा तोंडातील फोड स्पष्ट दिसू द्या', 'hi': 'गांठें, घाव या मुंह के छाले साफ दिखें'},
    'scan_tips_title': {'en': 'Screening Tips', 'mr': 'तपासणी मार्गदर्शन', 'hi': 'जांच सुझाव'},
    'scan_tips_body': {
      'en': '• Take the photo in good light\n• Hold the camera steady on the affected area\n• Works offline with On-Device TFLite + online Gemini AI',
      'mr': '• चांगल्या प्रकाशात फोटो काढा\n• कॅमेरा बाधित भागावर स्थिर ठेवा\n• इंटरनेट नसतानाही ऑन-डिव्हाइस टीएफलाईट मॉडेलने तपासणी होते',
      'hi': '• अच्छी रोशनी में फोटो लें\n• कैमरा प्रभावित हिस्से पर स्थिर रखें\n• बिना इंटरनेट के भी ऑन-डिवाइस टीएफलाइट मॉडल से जांच होती है',
    },
    'tflite_card_title': {
      'en': 'On-Device TFLite Screening (Offline Model)',
      'mr': 'ऑन-डिव्हाइस टीएफलाईट प्राथमिक तपासणी (ऑफलाइन मॉडेल)',
      'hi': 'ऑन-डिवाइस टीएफलाइट प्रारंभिक जांच (ऑफलाइन मॉडल)',
    },
    'tflite_healthy': {
      'en': 'No Obvious External Lesion Detected (Healthy Pattern)',
      'mr': 'बाह्य जखम किंवा गाठी आढळल्या नाहीत (निरोगी नमुना)',
      'hi': 'बाहरी घाव या गांठ के स्पष्ट संकेत नहीं मिले (स्वस्थ पैटर्न)',
    },
    'tflite_suspected_disease': {
      'en': 'Possible Bovine Lesion / FMD-LSD Signs Detected',
      'mr': 'संभाव्य जनावरांतील जखम / लाळ्या-लंपी सदृश लक्षणे आढळली',
      'hi': 'संभावित पशु घाव / खुरपका-लम्पी जैसे संकेत मिले',
    },
    'tflite_inconclusive': {
      'en': 'Inconclusive (<65% confidence) — Retake in clearer light or consult vet',
      'mr': 'अनिर्णित (<६५% विश्वासार्हता) — स्पष्ट प्रकाशात फोटो घ्या किंवा पशुवैद्यकास दाखवा',
      'hi': 'अनिर्णायक (<६५% विश्वसनीयता) — साफ रोशनी में फोटो लें या पशु चिकित्सक को दिखाएं',
    },
    'tflite_offline_badge': {
      'en': 'Offline TFLite Mode (No Internet Needed)',
      'mr': 'ऑफलाइन टीएफलाईट मोड (इंटरनेट विना कार्यरत)',
      'hi': 'ऑफलाइन टीएफलाइट मोड (बिना इंटरनेट के सक्रिय)',
    },
    'tflite_hybrid_badge': {
      'en': 'Hybrid: On-Device TFLite + Online Gemini AI',
      'mr': 'हायब्रिड: ऑन-डिव्हाइस टीएफलाईट + ऑनलाइन जेमिनी एआय',
      'hi': 'हाइब्रिड: ऑन-डिवाइस टीएफलाइट + ऑनलाइन जेमिनी एआई',
    },
    'camera': {'en': 'Camera', 'mr': 'कॅमेरा', 'hi': 'कैमरा'},
    'gallery': {'en': 'Gallery', 'mr': 'गॅलरी', 'hi': 'गैलरी'},
    'ai_guidance_title': {'en': 'AI First-Aid Guidance (Preliminary)', 'mr': 'एआय प्राथमिक मार्गदर्शन (प्राथमिक)', 'hi': 'एआई प्राथमिक मार्गदर्शन (प्रारंभिक)'},
    'possible_signs': {'en': 'Possible signs (not a diagnosis)', 'mr': 'संभाव्य लक्षणे (निदान नाही)', 'hi': 'संभावित संकेत (निदान नहीं)'},
    'interim_care': {'en': 'What to do until the vet arrives', 'mr': 'पशुवैद्य येईपर्यंत काय करावे', 'hi': 'पशु चिकित्सक के आने तक क्या करें'},
    'warning_signs': {'en': 'Call the vet immediately if', 'mr': 'यापैकी काही दिसल्यास लगेच पशुवैद्यकाला बोलवा', 'hi': 'इनमें से कुछ दिखे तो तुरंत पशु चिकित्सक को बुलाएं'},
    'urgency_low': {'en': 'Urgency: Low', 'mr': 'तातडी: कमी', 'hi': 'तात्कालिकता: कम'},
    'urgency_medium': {'en': 'Urgency: Medium', 'mr': 'तातडी: मध्यम', 'hi': 'तात्कालिकता: मध्यम'},
    'urgency_high': {'en': 'Urgency: High', 'mr': 'तातडी: जास्त', 'hi': 'तात्कालिकता: अधिक'},
    'listen_guidance': {'en': 'Listen in voice', 'mr': 'आवाजात ऐका', 'hi': 'आवाज़ में सुनें'},
    'stop_listening': {'en': 'Stop', 'mr': 'थांबवा', 'hi': 'रोकें'},
    'voice_unavailable': {
      'en': 'Voice for this language is not installed on this phone.',
      'mr': 'या फोनमध्ये या भाषेचा आवाज उपलब्ध नाही.',
      'hi': 'इस फोन में इस भाषा की आवाज़ उपलब्ध नहीं है।',
    },
    'generated_by_ai': {
      'en': 'Generated by Gemini AI. Preliminary guidance only, not a diagnosis.',
      'mr': 'जेमिनी एआयने तयार केले. केवळ प्राथमिक मार्गदर्शन, निदान नव्हे.',
      'hi': 'जेमिनी एआई द्वारा तैयार। केवल प्रारंभिक मार्गदर्शन, निदान नहीं।',
    },

    // Profile & Settings
    'alert_consent': {'en': 'Outbreak Alert Consent', 'mr': 'रोग सूचना संमती', 'hi': 'रोग चेतावनी सहमति'},
    'alert_consent_title': {'en': 'Receive Local Outbreak Alerts', 'mr': 'परिसरातील रोग चेतावणी मिळवा', 'hi': 'क्षेत्रीय रोग चेतावनी प्राप्त करें'},
    'alert_consent_sub': {
      'en': 'Receive immediate warnings when veterinarians confirm infectious cases within 5 km of your farm.',
      'mr': 'आपल्या शेताभोवती ५ किमी अंतरावर पशुवैद्यकांनी पुष्टी केलेले रुग्ण आढळल्यास त्वरित सूचना मिळवा.',
      'hi': 'अपने खेत से ५ किमी के दायरे में पशु चिकित्सकों द्वारा पुष्ट मामलों पर त्वरित चेतावनी प्राप्त करें।',
    },
    'app_language': {'en': 'App Language', 'mr': 'अ‍ॅप भाषा', 'hi': 'ऐप की भाषा'},
    'change_language': {'en': 'Change Language', 'mr': 'भाषा बदला', 'hi': 'भाषा बदलें'},
    'choose_language': {'en': 'Choose Language', 'mr': 'भाषा निवडा', 'hi': 'भाषा चुनें'},

    // Common Buttons
    'save': {'en': 'Save', 'mr': 'जतन करा', 'hi': 'सुरक्षित करें'},
    'cancel': {'en': 'Cancel', 'mr': 'रद्द करा', 'hi': 'रद्द करें'},
    'retry': {'en': 'Retry Sync', 'mr': 'पुन्हा सिंक करा', 'hi': 'पुनः प्रयास करें'},
    'login': {'en': 'Farmer Login', 'mr': 'शेतकरी लॉगिन', 'hi': 'किसान लॉगिन'},
    'register': {'en': 'New Farmer Registration', 'mr': 'नवीन शेतकरी नोंदणी', 'hi': 'नया किसान पंजीकरण'},
    'phone_number': {'en': 'Mobile Phone Number (+91)', 'mr': 'मोबाईल नंबर (+९१)', 'hi': 'मोबाइल नंबर (+९१)'},
    'password': {'en': 'Password', 'mr': 'पासवर्ड', 'hi': 'पासवर्ड'},
    'full_name': {'en': 'Full Name', 'mr': 'पूर्ण नाव', 'hi': 'पूरा नाम'},
    'village': {'en': 'Village Name', 'mr': 'गाव', 'hi': 'गाँव'},
  };
}
