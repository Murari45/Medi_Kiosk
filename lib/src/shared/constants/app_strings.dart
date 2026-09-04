class AppStrings {
  // Supported language codes
  static const String en = 'en';
  static const String hi = 'hi';
  static const String ta = 'ta';
  static const String te = 'te';
  static const String bn = 'bn';

  static const List<Map<String, String>> supportedLanguages = [
    {'code': en, 'name': 'English', 'native': 'English', 'locale': 'en-IN'},
    {'code': hi, 'name': 'Hindi', 'native': 'हिंदी', 'locale': 'hi-IN'},
    {'code': ta, 'name': 'Tamil', 'native': 'தமிழ்', 'locale': 'ta-IN'},
    {'code': te, 'name': 'Telugu', 'native': 'తెలుగు', 'locale': 'te-IN'},
    {'code': bn, 'name': 'Bengali', 'native': 'বাংলা', 'locale': 'bn-IN'},
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    en: {
      'app_name': 'MediKiosk AI',
      'tagline': 'Voice-Enabled Smart Clinical Pre-Intake Platform',
      'welcome_title': 'Select Your Language',
      'welcome_subtitle': 'Please tap your preferred language to begin. Tap the speaker to hear.',
      'welcome_voice': 'Hello! Welcome to MediKiosk AI. Please choose your preferred language to continue.',
      'btn_listen': 'Listen',
      'btn_continue': 'Continue',
      'btn_speak': 'Tap to Speak',
      'listening': 'Listening to your response...',
      'speak_now': 'Please speak now...',
      'not_understood': 'I didn\'t quite catch that, could you please repeat?',
      'hesitation_detected': 'Response marked as uncertain. Please clarify with your doctor.',
      
      // Roles & Auth
      'role_patient': 'Patient Portal',
      'role_doctor': 'Doctor Portal',
      'role_admin': 'Admin System',
      'sign_in': 'Sign In',
      'sign_out': 'Sign Out',
      'register': 'Register New Patient',
      'abha_id_label': 'ABHA ID / Username',
      'abha_id_hint': 'e.g., patient_1024@abdm or 9876543210',
      'password_label': 'Password',
      'full_name': 'Full Name',
      'phone_number': 'Mobile Number',
      'aadhaar_number': 'Aadhaar / Gov ID',
      'email': 'Email Address',
      'blood_type': 'Blood Group',
      'allergies': 'Known Allergies',
      'save_profile': 'Save Profile',
      'profile_updated': 'Patient Profile updated successfully!',
      
      // Patient Dashboard
      'patient_dashboard': 'Patient Dashboard',
      'allopathy_title': 'Allopathy Intake (Modern Medicine)',
      'allopathy_desc': 'SOCRATES protocol clinical triage for acute & general symptoms.',
      'ayush_title': 'AYUSH Intake (Ayurvedic)',
      'ayush_desc': 'Dashavidha Pariksha 10-fold holistic assessment for wellness & lifestyle.',
      'uploaded_docs': 'Previous Medical Documents & Reports',
      'upload_new_doc': 'Upload / Scan Document',
      'upcoming_appointments': 'Upcoming Appointments',
      'view_summaries': 'View Previous Summaries',
      
      // SOCRATES Allopathy Questions
      'socrates_site': 'Where exactly are you experiencing the pain or discomfort?',
      'socrates_onset': 'When did this problem start, and was it sudden or gradual?',
      'socrates_character': 'How would you describe the feeling? Is it sharp, dull, throbbing, or burning?',
      'socrates_radiation': 'Does the pain spread or radiate to any other parts of your body?',
      'socrates_associated': 'Do you have any other symptoms like fever, nausea, dizziness, or shortness of breath?',
      'socrates_timing': 'Is the pain constant throughout the day, or does it come and go?',
      'socrates_exacerbating': 'Does anything specific make the pain better or worse, like moving or resting?',
      'socrates_severity': 'On a scale from 1 to 10, where 1 is minimal and 10 is unbearable, how severe is it?',
      
      // AYUSH Dashavidha Pariksha Questions
      'ayush_prakriti': 'What is your primary body constitution (Prakriti: Vata, Pitta, Kapha)?',
      'ayush_vikriti': 'What current imbalance or aggravated Dosha are you experiencing?',
      'ayush_sara': 'How is your tissue vitality and overall body strength (Sara)?',
      'ayush_samhanana': 'How is your body build and muscle compactness (Samhanana)?',
      'ayush_pramana': 'How are your physical body proportions and measurements (Pramana)?',
      'ayush_satmya': 'What foods and climate are you naturally accustomed to (Satmya)?',
      'ayush_satva': 'How is your mental resilience, stress tolerance, and clarity (Satva)?',
      'ayush_ahara': 'How is your appetite, digestion power, and food capacity (Ahara Shakti)?',
      'ayush_vyayama': 'How is your physical endurance and capacity for exercise (Vyayama Shakti)?',
      'ayush_vaya': 'What is your age category and developmental stage (Vaya)?',
      
      // Priority & Token
      'token_generated': 'Intake Complete - Token Generated',
      'priority_p1': 'Priority 1 (Urgent Attention)',
      'priority_p2': 'Priority 2 (Moderate Priority)',
      'priority_p3': 'Priority 3 (Routine Queue)',
      'token_message': 'Please take your token slip and proceed to the waiting area. The doctor will call you shortly.',
      
      // Doctor Portal
      'doctor_queue': 'Live Patient Triage Queue',
      'certain_section': '100% CERTAIN (AI Verified)',
      'not_sure_section': 'NOT SURE (Patient Hesitated)',
      'unclear_section': 'UNCLEAR (Requires Doctor Clarification)',
      'read_summary': 'Read Summary Aloud',
      'voice_prescribe': 'Dictate Voice Prescription',
      'generate_pdf': 'Generate & Print PDF Rx',
      'submit_consultation': 'Complete Consultation & Next',
    },
    hi: {
      'app_name': 'मेडीकियोस्क एआई',
      'tagline': 'आवाज़-सक्षम स्मार्ट क्लिनिकल प्री-इंटेक प्लेटफॉर्म',
      'welcome_title': 'अपनी भाषा चुनें',
      'welcome_subtitle': 'आरंभ करने के लिए कृपया अपनी पसंदीदा भाषा स्पर्श करें। सुनने के लिए स्पीकर दबाएं।',
      'welcome_voice': 'नमस्ते! मेडीकियोस्क एआई में आपका स्वागत है। आगे बढ़ने के लिए कृपया अपनी भाषा चुनें।',
      'btn_listen': 'सुनें',
      'btn_continue': 'आगे बढ़ें',
      'btn_speak': 'बोलने के लिए दबाएं',
      'listening': 'आपकी आवाज़ सुनी जा रही है...',
      'speak_now': 'कृपया अब बोलें...',
      'not_understood': 'माफ़ कीजिये, मैं ठीक से समझ नहीं पाया, क्या आप दोबारा बोल सकते हैं?',
      'hesitation_detected': 'प्रतिक्रिया अनिश्चित मानी गई। कृपया अपने डॉक्टर से स्पष्ट करें।',
      
      // Roles & Auth
      'role_patient': 'मरीज पोर्टल',
      'role_doctor': 'डॉक्टर पोर्टल',
      'role_admin': 'व्यवस्थापक प्रणाली',
      'sign_in': 'साइन इन करें',
      'sign_out': 'साइन आउट करें',
      'register': 'नया मरीज पंजीकरण',
      'abha_id_label': 'आभा आईडी / उपयोगकर्ता नाम',
      'abha_id_hint': 'उदा. patient_1024@abdm या 9876543210',
      'password_label': 'पासवर्ड',
      'full_name': 'पूरा नाम',
      'phone_number': 'मोबाइल नंबर',
      'aadhaar_number': 'आधार / पहचान पत्र',
      'email': 'ईमेल पता',
      'blood_type': 'रक्त समूह',
      'allergies': 'ज्ञात एलर्जी',
      'save_profile': 'प्रोफ़ाइल सहेजें',
      'profile_updated': 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई!',
      
      // Patient Dashboard
      'patient_dashboard': 'मरीज डैशबोर्ड',
      'allopathy_title': 'एलोपैथी जांच (आधुनिक चिकित्सा)',
      'allopathy_desc': 'तीव्र और सामान्य लक्षणों के लिए सुकरात (SOCRATES) प्रोटोकॉल।',
      'ayush_title': 'आयुष जांच (आयुर्वेदिक)',
      'ayush_desc': 'दशविध परीक्षा 10-आयामी समग्र स्वास्थ्य मूल्यांकन।',
      'uploaded_docs': 'पिछले मेडिकल दस्तावेज़ और रिपोर्ट',
      'upload_new_doc': 'दस्तावेज़ अपलोड / स्कैन करें',
      'upcoming_appointments': 'आगामी मुलाकातें',
      'view_summaries': 'पिछले सारांश देखें',
      
      // SOCRATES Allopathy Questions
      'socrates_site': 'आपको दर्द या तकलीफ़ शरीर के किस हिस्से में हो रही है?',
      'socrates_onset': 'यह समस्या कब शुरू हुई, और क्या यह अचानक हुई या धीरे-धीरे?',
      'socrates_character': 'दर्द किस तरह का महसूस होता है? क्या यह तेज़, हल्का, चुभने वाला या जलन जैसा है?',
      'socrates_radiation': 'क्या यह दर्द शरीर के किसी अन्य हिस्से में भी फैलता है?',
      'socrates_associated': 'क्या आपको बुखार, उल्टी, चक्कर या सांस फूलने जैसे अन्य लक्षण भी हैं?',
      'socrates_timing': 'क्या दर्द दिनभर लगातार रहता है, या आता-जाता रहता है?',
      'socrates_exacerbating': 'क्या किसी विशेष गतिविधि या आराम करने से दर्द कम या ज़्यादा होता है?',
      'socrates_severity': '1 से 10 के पैमाने पर दर्द कितना गंभीर है (1 बहुत कम, 10 असहनीय)?',
      
      // AYUSH Dashavidha Pariksha Questions
      'ayush_prakriti': 'आपकी शारीरिक प्रकृति क्या है (वात, पित्त, कफ)?',
      'ayush_vikriti': 'वर्तमान में आपको कौन सा दोष असंतुलित महसूस हो रहा है?',
      'ayush_sara': 'आपकी शारीरिक धातु शक्ति और ऊर्जा का स्तर कैसा है (सार)?',
      'ayush_samhanana': 'आपकी शारीरिक बनावट और मांसपेशियों की सुदृढ़ता कैसी है (संहनन)?',
      'ayush_pramana': 'आपका शारीरिक अनुपात और माप कैसा है (प्रमाण)?',
      'ayush_satmya': 'आपको कौन सा खान-पान और वातावरण अनुकूल रहता है (सात्म्य)?',
      'ayush_satva': 'आपका मानसिक संतुलन और तनाव सहने की क्षमता कैसी है (सत्व)?',
      'ayush_ahara': 'आपकी भूख और पाचन शक्ति कैसी है (आहार शक्ति)?',
      'ayush_vyayama': 'आपकी शारीरिक सहनशक्ति और व्यायाम क्षमता कैसी है (व्यायाम शक्ति)?',
      'ayush_vaya': 'आपकी आयु वर्ग और अवस्था क्या है (वय)?',
      
      // Priority & Token
      'token_generated': 'जांच पूर्ण - टोकन प्राप्त हुआ',
      'priority_p1': 'प्राथमिकता 1 (आपातकालीन / तुरंत ध्यान)',
      'priority_p2': 'प्राथमिकता 2 (मध्यम प्राथमिकता)',
      'priority_p3': 'प्राथमिकता 3 (सामान्य कतार)',
      'token_message': 'कृपया अपना टोकन नंबर लें और प्रतीक्षालय में बैठें। डॉक्टर आपको शीघ्र बुलाएंगे।',
      
      // Doctor Portal
      'doctor_queue': 'लाइव मरीज प्राथमिकता कतार',
      'certain_section': '100% निश्चित (एआई द्वारा सत्यापित)',
      'not_sure_section': 'अनिश्चित (मरीज ने झिझक दिखाई)',
      'unclear_section': 'अस्पष्ट (डॉक्टर द्वारा स्पष्टीकरण आवश्यक)',
      'read_summary': 'सारांश बोलकर सुनाएं',
      'voice_prescribe': 'आवाज़ से पर्चा लिखें',
      'generate_pdf': 'पीडीएफ पर्चा बनाएं और प्रिंट करें',
      'submit_consultation': 'परामर्श पूरा करें और अगला मरीज देखें',
    },
    ta: {
      'app_name': 'மெடிகியோஸ்க் AI',
      'tagline': 'குரல்வழி இயங்கும் ஸ்மார்ட் மருத்துவ பரிசோதனை தளம்',
      'welcome_title': 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்',
      'welcome_subtitle': 'தொடங்க உங்கள் விருப்பமான மொழியைத் தொடவும். கேட்க ஸ்பீக்கரை அழுத்தவும்.',
      'welcome_voice': 'வணக்கம்! மெடிகியோஸ்க் AI-க்கு உங்களை வரவேற்கிறோம். தொடர உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்.',
      'btn_listen': 'கேளுங்கள்',
      'btn_continue': 'தொடரவும்',
      'btn_speak': 'பேச தொடவும்',
      'listening': 'உங்கள் குரலைக் கேட்கிறது...',
      'speak_now': 'இப்போது பேசுங்கள்...',
      'not_understood': 'மன்னிக்கவும், என்னால் சரியாகப் புரிந்து கொள்ள முடியவில்லை, மீண்டும் கூற முடியுமா?',
      'hesitation_detected': 'பதில் உறுதியற்றதாகக் குறிக்கப்பட்டது. மருத்துவரிடம் தெளிவுபடுத்தவும்.',
      'role_patient': 'நோயாளி போர்ட்டல்',
      'role_doctor': 'மருத்துவர் போர்ட்டல்',
      'role_admin': 'நிர்வாக அமைப்பு',
      'sign_in': 'உள்நுழையவும்',
      'sign_out': 'வெளியேறு',
      'register': 'புதிய நோயாளி பதிவு',
      'abha_id_label': 'ஆபா ஐடி / பயனர் பெயர்',
      'patient_dashboard': 'நோயாளி டாஷ்போர்டு',
      'allopathy_title': 'அலோபதி பரிசோதனை (நவீன மருத்துவம்)',
      'ayush_title': 'ஆயுஷ் பரிசோதனை (ஆயுர்வேதம்)',
      'socrates_site': 'வலி அல்லது அசௌகரியம் சரியாக எங்கு உள்ளது?',
      'socrates_onset': 'இந்த பிரச்சனை எப்போது தொடங்கியது?',
      'socrates_character': 'வலி எவ்வாறு உணர்கிறது? கூர்மையானதா அல்லது எரிச்சலா?',
      'socrates_radiation': 'வலி உடலின் பிற பகுதிகளுக்குப் பரவுகிறதா?',
      'socrates_associated': 'காய்ச்சல் அல்லது மயக்கம் போன்ற பிற அறிகுறிகள் உள்ளதா?',
      'socrates_timing': 'வலி நாள் முழுவதும் இருக்கிறதா அல்லது வந்து போகிறதா?',
      'socrates_exacerbating': 'எதாவது செய்யும்போது வலி அதிகமாகிறதா அல்லது குறைகிறதா?',
      'socrates_severity': '1 முதல் 10 வரை, வலி எவ்வளவு தீவிரமாக உள்ளது?',
      'token_generated': 'பரிசோதனை முடிந்தது - டோக்கன் உருவானது',
      'priority_p1': 'முன்னுரிமை 1 (அவசரம்)',
      'priority_p2': 'முன்னுரிமை 2 (மிதமான)',
      'priority_p3': 'முன்னுரிமை 3 (வழக்கமான)',
    },
    te: {
      'app_name': 'మెడికియోస్క్ AI',
      'tagline': 'వాయిస్ ఆధారిత స్మార్ట్ క్లినికల్ ప్రి-ఇన్‌టేక్ ప్లాట్‌ఫామ్',
      'welcome_title': 'మీ భాషను ఎంచుకోండి',
      'welcome_subtitle': 'ప్రారంభించడానికి దయచేసి మీ భాషను ఎంచుకోండి. వినడానికి స్పీకర్‌ను నొక్కండి.',
      'welcome_voice': 'నమస్కారం! మెడికియోస్క్ AI కి స్వాగతం. కొనసాగడానికి దయచేసి మీ భాషను ఎంచుకోండి.',
      'btn_listen': 'వినండి',
      'btn_continue': 'కొనసాగించండి',
      'btn_speak': 'మాట్లాడటానికి నొక్కండి',
      'listening': 'మీ వాయిస్ వినబడుతోంది...',
      'speak_now': 'దయచేసి ఇప్పుడు మాట్లాడండి...',
      'not_understood': 'క్షమించండి, సరిగ్గా అర్థం కాలేదు, దయచేసి మళ్ళీ చెప్పగలరా?',
      'hesitation_detected': 'సమాధానం అనిశ్చితంగా గుర్తించబడింది. వైద్యుడితో స్పష్టం చేయండి.',
      'role_patient': 'రోగి పోర్టల్',
      'role_doctor': 'వైద్యుల పోర్టల్',
      'role_admin': 'అడ్మిన్ సిస్టమ్',
      'sign_in': 'సైన్ ఇన్ చేయండి',
      'sign_out': 'లాగ్ అవుట్',
      'register': 'కొత్త రోగి నమోదు',
      'abha_id_label': 'ఆభా ఐడి / యూజర్ నేమ్',
      'patient_dashboard': 'రోగి డ్యాష్‌బోర్డ్',
      'allopathy_title': 'అల్లోపతి ఇన్టేక్ (ఆధునిక వైద్యం)',
      'ayush_title': 'ఆయుష్ ఇన్టేక్ (ఆయుర్వేదం)',
      'socrates_site': 'బాధ లేదా నొప్పి శరీరంలో ఖచ్చితంగా ఎక్కడ ఉంది?',
      'socrates_onset': 'ఈ సమస్య ఎప్పుడు ప్రారంభమైంది?',
      'socrates_character': 'నొప్పి ఎలా అనిపిస్తుంది? తీవ్రంగానా లేక మంటగానా?',
      'socrates_radiation': 'నొప్పి శరీరంలోని ఇతర భాగాలకు వ్యాపిస్తుందా?',
      'socrates_associated': 'జ్వరం లేదా మైకం వంటి ఇతర లక్షణాలు ఉన్నాయా?',
      'socrates_timing': 'నొప్పి రోజంతా స్థిరంగా ఉంటుందా లేదా వచ్చి పోతుందా?',
      'socrates_exacerbating': 'విశ్రాంతి తీసుకుంటే లేదా ఏదైనా చేస్తే నొప్పి తగ్గుతుందా?',
      'socrates_severity': '1 నుండి 10 స్కేలులో, నొప్పి తీవ్రత ఎంత?',
      'token_generated': 'పూర్తయింది - టోకెన్ జారీ చేయబడింది',
      'priority_p1': 'ప్రాధాన్యత 1 (అత్యవసరం)',
      'priority_p2': 'ప్రాధాన్యత 2 (మధ్యస్థం)',
      'priority_p3': 'ప్రాధాన్యత 3 (సాధారణం)',
    },
    bn: {
      'app_name': 'মেডিকিওস্ক এআই',
      'tagline': 'ভয়েস-সক্ষম স্মার্ট ক্লিনিকাল প্রি-ইনটেক প্ল্যাটফর্ম',
      'welcome_title': 'আপনার ভাষা নির্বাচন করুন',
      'welcome_subtitle': 'শুরু করতে আপনার পছন্দের ভাষা স্পর্শ করুন। শুনতে স্পিকার চাপুন।',
      'welcome_voice': 'নমস্কার! মেডিকিওস্ক এআই-তে আপনাকে স্বাগতম। এগিয়ে যেতে অনুগ্রহ করে আপনার ভাষা বেছে নিন।',
      'btn_listen': 'শুনুন',
      'btn_continue': 'এগিয়ে যান',
      'btn_speak': 'কথা বলতে স্পর্শ করুন',
      'listening': 'আপনার কথা শোনা হচ্ছে...',
      'speak_now': 'দয়া করে এখন বলুন...',
      'not_understood': 'দুঃখিত, ঠিক বুঝতে পারিনি, আপনি কি পুনরায় বলতে পারবেন?',
      'hesitation_detected': 'উত্তরটি অনিশ্চিত বলে চিহ্নিত করা হয়েছে। ডাক্তারের সাথে পরামর্শ করুন।',
      'role_patient': 'রোগীর পোর্টাল',
      'role_doctor': 'ডাক্তারের পোর্টাল',
      'role_admin': 'প্রশাসনিক ব্যবস্থা',
      'sign_in': 'সাইন ইন করুন',
      'sign_out': 'সাইন আউট',
      'register': 'নতুন রোগীর নিবন্ধন',
      'abha_id_label': 'আভা আইডি / ব্যবহারকারীর নাম',
      'patient_dashboard': 'রোগীর ড্যাশবোর্ড',
      'allopathy_title': 'অ্যালোপ্যাথি ইনটেক (আধুনিক চিকিৎসা)',
      'ayush_title': 'আয়ুষ ইনটেক (আয়ুর্বেদিক)',
      'socrates_site': 'ব্যথা বা অস্বস্তি শরীরের ঠিক কোন জায়গায় হচ্ছে?',
      'socrates_onset': 'এই সমস্যাটি কখন শুরু হয়েছিল?',
      'socrates_character': 'ব্যথাটি কেমন ধরনের? তীব্র, নাকি জ্বালাপোড়া ভাব?',
      'socrates_radiation': 'ব্যথা কি শরীরের অন্য কোথাও ছড়িয়ে পড়ে?',
      'socrates_associated': 'জ্বর বা বমির মতো অন্য কোনো লক্ষণ আছে কি?',
      'socrates_timing': 'ব্যথা কি সারাদিন থাকে নাকি আসে যায়?',
      'socrates_exacerbating': 'বিশ্রাম নিলে বা কিছু করলে ব্যথা কি কমে বা বাড়ে?',
      'socrates_severity': '১ থেকে ১০ এর স্কেলে, ব্যথার মাত্রা কত?',
      'token_generated': 'সম্পন্ন - টোকেন তৈরি হয়েছে',
      'priority_p1': 'অগ্রাধিকার ১ (জরুরী)',
      'priority_p2': 'অগ্রাধিকার ২ (মাঝারি)',
      'priority_p3': 'অগ্রাধিকার ৩ (সাধারণ)',
    },
  };

  static String tr(String key, {String lang = 'en'}) {
    final langMap = _localizedValues[lang] ?? _localizedValues[en]!;
    return langMap[key] ?? _localizedValues[en]?[key] ?? key;
  }

  static String getSpeechDescription(String buttonId, {String lang = 'en'}) {
    switch (buttonId) {
      case 'btn_allopathy':
        return lang == 'hi'
            ? 'यह बटन आधुनिक एलोपैथी जांच के लिए है। अपने लक्षणों के बारे में बताने के लिए दबाएं।'
            : 'This button starts the Allopathy intake for modern medical evaluation.';
      case 'btn_ayush':
        return lang == 'hi'
            ? 'यह बटन पारंपरिक आयुष और आयुर्वेदिक स्वास्थ्य मूल्यांकन के लिए है।'
            : 'This button starts the AYUSH Dashavidha Pariksha holistic assessment.';
      case 'btn_signin':
        return lang == 'hi'
            ? 'अपने खाते में साइन इन करने के लिए यहां दबाएं।'
            : 'Press here to sign in with your ABHA ID or phone number.';
      case 'btn_register':
        return lang == 'hi'
            ? 'नया मरीज खाता बनाने के लिए यहां दबाएं।'
            : 'Press here to register as a new patient.';
      case 'btn_upload':
        return lang == 'hi'
            ? 'अपनी पर्ची या लैब रिपोर्ट स्कैन करने के लिए यहां दबाएं।'
            : 'Press here to upload or scan medical reports and prescriptions.';
      default:
        return 'Interactive button.';
    }
  }
}
