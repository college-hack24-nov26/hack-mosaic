class AppStrings {
  AppStrings._();

  static String currentLang = 'mr'; // 'mr', 'en', 'hi' - Marathi default

  static void setLanguage(String lang) {
    if (['en', 'mr', 'hi'].contains(lang)) {
      currentLang = lang;
    }
  }

  static String t(String key) {
    return _translations[key]?[currentLang] ?? _translations[key]?['en'] ?? key;
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

    // Mandatory Regulatory Safety String
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

    // Navigation
    'nav_home': {'en': 'Home', 'mr': 'मुख्य', 'hi': 'होम'},
    'nav_animals': {'en': 'My Animals', 'mr': 'माझी जनावरे', 'hi': 'मेरे पशु'},
    'nav_report': {'en': 'Report Illness', 'mr': 'आजार नोंदवा', 'hi': 'रोग रिपोर्ट'},
    'nav_alerts': {'en': 'Outbreak Alerts', 'mr': 'रोग सूचना', 'hi': 'रोग अलर्ट'},
    'nav_profile': {'en': 'Profile', 'mr': 'प्रोफाइल', 'hi': 'प्रोफाइल'},

    // Dashboard
    'greeting': {'en': 'Namaste, Farmer', 'mr': 'नमस्ते शेतकरी बांधव', 'hi': 'नमस्ते किसान भाई'},
    'registered_cattle': {'en': 'Registered Animals', 'mr': 'नोंदणीकृत जनावरे', 'hi': 'पंजीकृत पशु'},
    'pending_reports': {'en': 'Pending Reports', 'mr': 'प्रलंबित तपासणी', 'hi': 'लंबित रिपोर्ट'},
    'active_alerts': {'en': 'Nearby Warnings', 'mr': 'परिसरातील सतर्कता', 'hi': 'क्षेत्रीय चेतावनी'},
    'quick_actions': {'en': 'Quick Actions', 'mr': 'त्वरित सेवा', 'hi': 'त्वरित सेवाएं'},
    'action_scan': {'en': 'AI Image Scan', 'mr': 'एआय तपासणी (फोटो)', 'hi': 'एआई जांच (फोटो)'},
    'action_add_animal': {'en': 'Register Animal', 'mr': 'जनावर नोंदवा', 'hi': 'पशु जोड़ें'},
    'action_report': {'en': 'Report Disease', 'mr': 'रोग तक्रार नोंदवा', 'hi': 'रोग शिकायत दर्ज करें'},
    'action_passport': {'en': 'Digital QR Passport', 'mr': 'डिजिटल क्यूआर पास', 'hi': 'डिजिटल क्यूआर पास'},

    // Animals
    'animal_name': {'en': 'Animal Name / Call Name', 'mr': 'नाव / टोपणनाव', 'hi': 'पशु का नाम'},
    'tag_number': {'en': 'Ear Tag / Bharat Pashudhan ID', 'mr': 'कानाचा टॅग / भारत पशुधन आयडी', 'hi': 'ईयर टैग / भारत पशुधन आईडी'},
    'species': {'en': 'Species', 'mr': 'प्रजाती', 'hi': 'प्रजाति'},
    'species_cattle': {'en': 'Cattle (Cow/Bull)', 'mr': 'गाय / बैल', 'hi': 'गाय / बैल'},
    'species_buffalo': {'en': 'Buffalo', 'mr': 'म्हैस / रेडा', 'hi': 'भैंस'},
    'breed': {'en': 'Breed', 'mr': 'जात / ब्रीड', 'hi': 'नस्ल'},
    'gender': {'en': 'Sex', 'mr': 'लिंग', 'hi': 'लिंग'},
    'gender_female': {'en': 'Female', 'mr': 'मादी', 'hi': 'मादा'},
    'gender_male': {'en': 'Male', 'mr': 'नर', 'hi': 'नर'},
    'birth_date': {'en': 'Approx. Birth Date / Age', 'mr': 'जन्मतारीख / वय', 'hi': 'जन्म तिथि / उम्र'},
    'add_animal_btn': {'en': 'Save Animal Record', 'mr': 'जनावर जतन करा', 'hi': 'पशु सुरक्षित करें'},
    'empty_animals': {'en': 'No animals registered yet. Add your cattle to track health & vaccinations.', 'mr': 'अद्याप जनावरांची नोंद नाही. आरोग्य तपासणीसाठी जनावर जोडा.', 'hi': 'अभी कोई पशु पंजीकृत नहीं है। स्वास्थ्य जांच के लिए पशु जोड़ें।'},

    // Reporting
    'select_animal': {'en': '1. Select Affected Animal', 'mr': '१. आजारी जनावर निवडा', 'hi': '१. बीमार पशु चुनें'},
    'select_symptoms': {'en': '2. Select Observed Symptoms', 'mr': '२. दिसणारी लक्षणे निवडा', 'hi': '२. दिखाई देने वाले लक्षण चुनें'},
    'symptom_skin_nodules': {'en': 'Skin Nodules / Lumps', 'mr': 'त्वचेवर गाठी / फोड', 'hi': 'त्वचा पर गांठें / छाले'},
    'symptom_fever': {'en': 'High Fever', 'mr': 'तीव्र ताप', 'hi': 'तेज़ बुखार'},
    'symptom_reduced_milk': {'en': 'Reduced Milk Yield', 'mr': 'दुधात अचानक घट', 'hi': 'दूध में अचानक गिरावट'},
    'symptom_lameness': {'en': 'Limping / Lameness', 'mr': 'लंगडणे / चालण्यास त्रास', 'hi': 'लंगड़ापन / चलने में कष्ट'},
    'symptom_salivation': {'en': 'Excessive Salivation', 'mr': 'तोंडातून लाळ गळणे', 'hi': 'मुंह से लार टपकना'},
    'symptom_nasal_discharge': {'en': 'Nasal Discharge / Cough', 'mr': 'नाकातून स्राव / खोकला', 'hi': 'नाक से स्राव / खांसी'},
    'symptom_appetite_loss': {'en': 'Loss of Appetite / Off Feed', 'mr': 'चारा न खाणे / भूक मंदावणे', 'hi': 'चारा न खाना / भूख न लगना'},
    'report_description': {'en': '3. Additional Notes / Voice (Optional)', 'mr': '३. इतर माहिती किंवा लक्षणे', 'hi': '३. अतिरिक्त लक्षण या विवरण'},
    'capture_photo': {'en': 'Take / Attach Photo', 'mr': 'जनावराचा फोटो काढा', 'hi': 'पशु का फोटो लें'},
    'gps_location': {'en': 'Location Captured', 'mr': 'स्थान (GPS) नोंदवले', 'hi': 'स्थान (GPS) दर्ज हुआ'},
    'submit_report': {'en': 'Submit Report to Vet', 'mr': 'पशुवैद्यकीय अधिकाऱ्यास पाठवा', 'hi': 'पशु चिकित्सक को भेजें'},

    // Statuses
    'status_submitted': {'en': 'Submitted', 'mr': 'नोंदवले', 'hi': 'दर्ज हुआ'},
    'status_under_review': {'en': 'Under Vet Review', 'mr': 'तपासणी सुरू', 'hi': 'समीक्षा जारी'},
    'status_confirmed': {'en': 'Vet Confirmed Case', 'mr': 'तज्ज्ञांनी पुष्टी केली', 'hi': 'पुष्ट रोग'},
    'status_rejected': {'en': 'Rejected / Not Infectious', 'mr': 'फेटाळले (संसर्ग नाही)', 'hi': 'अस्वीकृत (संक्रमण नहीं)'},
    'status_flagged': {'en': 'Visit Required', 'mr': 'प्रत्यक्ष भेट आवश्यक', 'hi': 'प्रत्यक्ष जांच आवश्यक'},

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
