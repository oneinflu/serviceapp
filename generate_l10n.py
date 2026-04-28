import json

data = {
  'en': {
    'home': 'Home', 'change_language': 'Change Language', 'refer_earn': 'Refer & Earn', 'company_info': 'Company Information',
    'my_subscriptions': 'My Subscriptions', 'my_job_posts': 'My Job Posts', 'my_service_posts': 'My Service Posts',
    'delete_account': 'Delete Account', 'terms_conditions': 'Terms & Conditions', 'about_app': 'About App',
    'logout': 'Logout', 'login': 'Login', 'register': 'Register', 'wallet_dashboard': 'Wallet & Dashboard', 'select_language': 'Select Your Language',
    'wallet_referrals': 'Wallet & Referrals', 'overview': 'Overview', 'network': 'Network', 'commissions': 'Commissions', 'transactions': 'Transactions',
    'wallet_balance': 'Wallet Balance', 'total_earned': 'Total Earned', 'pending': 'Pending', 'withdraw_balance': 'Withdraw Balance',
    'min_withdrawal_is': 'Min. withdrawal is ₹', 'referral_overview': 'Referral Overview', 'total_referrals': 'Total Referrals', 'your_code': 'Your Code',
    'earnings_by_level': 'Earnings by Level', 'no_level_earnings': 'No level earnings yet.', 'your_referral_network': 'Your Referral Network',
    'level': 'Level', 'no_referrals_found': 'No referrals found in your network yet.', 'commission_history': 'Commission History',
    'no_commissions_earned': 'No commissions earned yet.', 'transaction_history': 'Transaction History', 'no_transactions_found': 'No transactions found.',
    'refer_earn_title': 'Refer & Earn', 'refer_friends_earn': 'Refer Friends & Earn!', 'share_code_get_rewarded': 'Share your code and get rewarded for every successful referral.',
    'your_referral_code': 'Your Referral Code', 'tap_to_copy': 'Tap to copy', 'copied_to_clipboard': 'Referral code copied to clipboard!',
    'share_with_friends': 'Share with Friends', 'how_it_works': 'How It Works', 'share_code': 'Share Code', 'share_code_desc': 'Share your unique referral code with your friends.',
    'friends_join': 'Friends Join', 'friends_join_desc': 'Your friends sign up using your referral code.', 'earn_rewards': 'Earn Rewards',
    'earn_rewards_desc': 'You earn a commission for every successful referral.', 'go_to_wallet_dashboard': 'Go to Wallet & Dashboard', 'view_earnings_network': 'View your earnings and network'
  },
  'hi': {
    'home': 'होम', 'change_language': 'भाषा बदलें', 'refer_earn': 'रेफर करें और कमाएं', 'company_info': 'कंपनी की जानकारी',
    'my_subscriptions': 'मेरी सदस्यता', 'my_job_posts': 'मेरी जॉब पोस्ट', 'my_service_posts': 'मेरी सेवा पोस्ट',
    'delete_account': 'खाता हटाएं', 'terms_conditions': 'नियम और शर्तें', 'about_app': 'ऐप के बारे में',
    'logout': 'लॉग आउट', 'login': 'लॉग इन', 'register': 'रजिस्टर', 'wallet_dashboard': 'वॉलेट और डैशबोर्ड', 'select_language': 'अपनी भाषा चुनें',
    'wallet_referrals': 'वॉलेट और रेफरल', 'overview': 'अवलोकन', 'network': 'नेटवर्क', 'commissions': 'कमीशन', 'transactions': 'लेन-देन',
    'wallet_balance': 'वॉलेट बैलेंस', 'total_earned': 'कुल कमाई', 'pending': 'लंबित', 'withdraw_balance': 'बैलेंस निकालें',
    'min_withdrawal_is': 'न्यूनतम निकासी ₹', 'referral_overview': 'रेफरल अवलोकन', 'total_referrals': 'कुल रेफरल', 'your_code': 'आपका कोड',
    'earnings_by_level': 'स्तर के अनुसार कमाई', 'no_level_earnings': 'अभी तक कोई कमाई नहीं।', 'your_referral_network': 'आपका रेफरल नेटवर्क',
    'level': 'स्तर', 'no_referrals_found': 'आपके नेटवर्क में अभी तक कोई रेफरल नहीं है।', 'commission_history': 'कमीशन इतिहास',
    'no_commissions_earned': 'अभी तक कोई कमीशन नहीं।', 'transaction_history': 'लेनदेन इतिहास', 'no_transactions_found': 'कोई लेनदेन नहीं मिला।',
    'refer_earn_title': 'रेफर करें और कमाएं', 'refer_friends_earn': 'दोस्तों को रेफर करें और कमाएं!', 'share_code_get_rewarded': 'अपना कोड साझा करें और हर सफल रेफरल पर इनाम पाएं।',
    'your_referral_code': 'आपका रेफरल कोड', 'tap_to_copy': 'कॉपी करने के लिए टैप करें', 'copied_to_clipboard': 'रेफरल कोड कॉपी हो गया!',
    'share_with_friends': 'दोस्तों के साथ साझा करें', 'how_it_works': 'यह कैसे काम करता है', 'share_code': 'कोड साझा करें', 'share_code_desc': 'अपने दोस्तों के साथ अपना रेफरल कोड साझा करें।',
    'friends_join': 'दोस्त जुड़ेंगे', 'friends_join_desc': 'आपके दोस्त आपके रेफरल कोड का उपयोग करके साइन अप करेंगे।', 'earn_rewards': 'इनाम कमाएं',
    'earn_rewards_desc': 'आप हर सफल रेफरल के लिए कमीशन कमाते हैं।', 'go_to_wallet_dashboard': 'वॉलेट और डैशबोर्ड पर जाएं', 'view_earnings_network': 'अपनी कमाई और नेटवर्क देखें'
  },
  'kn': {
    'home': 'ಮುಖಪುಟ', 'change_language': 'ಭಾಷೆ ಬದಲಾಯಿಸಿ', 'refer_earn': 'ಉಲ್ಲೇಖಿಸಿ ಮತ್ತು ಗಳಿಸಿ', 'company_info': 'ಕಂಪನಿ ಮಾಹಿತಿ',
    'my_subscriptions': 'ನನ್ನ ಚಂದಾದಾರಿಕೆಗಳು', 'my_job_posts': 'ನನ್ನ ಉದ್ಯೋಗ ಪೋಸ್ಟ್‌ಗಳು', 'my_service_posts': 'ನನ್ನ ಸೇವಾ ಪೋಸ್ಟ್‌ಗಳು',
    'delete_account': 'ಖಾತೆ ಅಳಿಸಿ', 'terms_conditions': 'ನಿಯಮಗಳು ಮತ್ತು ನಿಬಂಧನೆಗಳು', 'about_app': 'ಅಪ್ಲಿಕೇಶನ್ ಬಗ್ಗೆ',
    'logout': 'ಲಾಗ್ ಔಟ್', 'login': 'ಲಾಗ್ ಇನ್', 'register': 'ನೋಂದಣಿ', 'wallet_dashboard': 'ವಾಲೆಟ್ ಮತ್ತು ಡ್ಯಾಶ್ಬೋರ್ಡ್', 'select_language': 'ನಿಮ್ಮ ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
    'wallet_referrals': 'ವಾಲೆಟ್ ಮತ್ತು ರೆಫರಲ್ಸ್', 'overview': 'ಅವಲೋಕನ', 'network': 'ನೆಟ್ವರ್ಕ್', 'commissions': 'ಕಮಿಷನ್ಗಳು', 'transactions': 'ವಹಿವಾಟುಗಳು',
    'wallet_balance': 'ವಾಲೆಟ್ ಬ್ಯಾಲೆನ್ಸ್', 'total_earned': 'ಒಟ್ಟು ಗಳಿಕೆ', 'pending': 'ಬಾಕಿ ಇದೆ', 'withdraw_balance': 'ಹಣ ಹಿಂಪಡೆಯಿರಿ',
    'min_withdrawal_is': 'ಕನಿಷ್ಠ ಹಿಂಪಡೆಯುವಿಕೆ ₹', 'referral_overview': 'ರೆಫರಲ್ ಅವಲೋಕನ', 'total_referrals': 'ಒಟ್ಟು ರೆಫರಲ್ಸ್', 'your_code': 'ನಿಮ್ಮ ಕೋಡ್',
    'earnings_by_level': 'ಹಂತದ ಪ್ರಕಾರ ಗಳಿಕೆ', 'no_level_earnings': 'ಇನ್ನೂ ಯಾವುದೇ ಗಳಿಕೆಗಳಿಲ್ಲ.', 'your_referral_network': 'ನಿಮ್ಮ ರೆಫರಲ್ ನೆಟ್ವರ್ಕ್',
    'level': 'ಹಂತ', 'no_referrals_found': 'ನಿಮ್ಮ ನೆಟ್‌ವರ್ಕ್‌ನಲ್ಲಿ ಯಾವುದೇ ರೆಫರಲ್‌ಗಳು ಕಂಡುಬಂದಿಲ್ಲ.', 'commission_history': 'ಕಮಿಷನ್ ಇತಿಹಾಸ',
    'no_commissions_earned': 'ಇನ್ನೂ ಯಾವುದೇ ಕಮಿಷನ್ ಗಳಿಸಿಲ್ಲ.', 'transaction_history': 'ವಹಿವಾಟು ಇತಿಹಾಸ', 'no_transactions_found': 'ಯಾವುದೇ ವಹಿವಾಟುಗಳಿಲ್ಲ.',
    'refer_earn_title': 'ಉಲ್ಲೇಖಿಸಿ ಮತ್ತು ಗಳಿಸಿ', 'refer_friends_earn': 'ಸ್ನೇಹಿತರನ್ನು ಉಲ್ಲೇಖಿಸಿ ಮತ್ತು ಗಳಿಸಿ!', 'share_code_get_rewarded': 'ನಿಮ್ಮ ಕೋಡ್ ಹಂಚಿಕೊಳ್ಳಿ ಮತ್ತು ಪ್ರತಿ ಯಶಸ್ವಿ ಉಲ್ಲೇಖಕ್ಕೆ ಬಹುಮಾನ ಪಡೆಯಿರಿ.',
    'your_referral_code': 'ನಿಮ್ಮ ರೆಫರಲ್ ಕೋಡ್', 'tap_to_copy': 'ನಕಲಿಸಲು ಟ್ಯಾಪ್ ಮಾಡಿ', 'copied_to_clipboard': 'ಕೋಡ್ ನಕಲಿಸಲಾಗಿದೆ!',
    'share_with_friends': 'ಸ್ನೇಹಿತರೊಂದಿಗೆ ಹಂಚಿಕೊಳ್ಳಿ', 'how_it_works': 'ಇದು ಹೇಗೆ ಕೆಲಸ ಮಾಡುತ್ತದೆ', 'share_code': 'ಕೋಡ್ ಹಂಚಿಕೊಳ್ಳಿ', 'share_code_desc': 'ನಿಮ್ಮ ಸ್ನೇಹಿತರೊಂದಿಗೆ ನಿಮ್ಮ ವಿಶಿಷ್ಟ ರೆಫರಲ್ ಕೋಡ್ ಹಂಚಿಕೊಳ್ಳಿ.',
    'friends_join': 'ಸ್ನೇಹಿತರು ಸೇರುತ್ತಾರೆ', 'friends_join_desc': 'ನಿಮ್ಮ ಸ್ನೇಹಿತರು ನಿಮ್ಮ ಕೋಡ್ ಬಳಸಿ ಸೈನ್ ಅಪ್ ಮಾಡುತ್ತಾರೆ.', 'earn_rewards': 'ಬಹುಮಾನ ಗಳಿಸಿ',
    'earn_rewards_desc': 'ಪ್ರತಿ ಯಶಸ್ವಿ ಉಲ್ಲೇಖಕ್ಕಾಗಿ ನೀವು ಕಮಿಷನ್ ಗಳಿಸುತ್ತೀರಿ.', 'go_to_wallet_dashboard': 'ವಾಲೆಟ್ ಮತ್ತು ಡ್ಯಾಶ್‌ಬೋರ್ಡ್‌ಗೆ ಹೋಗಿ', 'view_earnings_network': 'ನಿಮ್ಮ ಗಳಿಕೆ ಮತ್ತು ನೆಟ್‌ವರ್ಕ್ ವೀಕ್ಷಿಸಿ'
  },
  'ta': {
    'home': 'முகப்பு', 'change_language': 'மொழியை மாற்றவும்', 'refer_earn': 'பரிந்துரைத்து சம்பாதிக்க', 'company_info': 'நிறுவனத்தின் தகவல்',
    'my_subscriptions': 'என் சந்தாக்கள்', 'my_job_posts': 'என் வேலைகள்', 'my_service_posts': 'என் சேவைகள்',
    'delete_account': 'கணக்கை நீக்கு', 'terms_conditions': 'விதிமுறைகள்', 'about_app': 'பயன்பாட்டைப் பற்றி',
    'logout': 'வெளியேறு', 'login': 'உள்நுழைய', 'register': 'பதிவு செய்', 'wallet_dashboard': 'வாலட் & டாஷ்போர்டு', 'select_language': 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்',
    'wallet_referrals': 'வாலட் & பரிந்துரைகள்', 'overview': 'மேலோட்டம்', 'network': 'நெட்வொர்க்', 'commissions': 'கமிஷன்கள்', 'transactions': 'பரிவர்த்தனைகள்',
    'wallet_balance': 'வாலட் இருப்பு', 'total_earned': 'மொத்தம் சம்பாதித்தது', 'pending': 'நிலுவையில்', 'withdraw_balance': 'பணத்தை எடு',
    'min_withdrawal_is': 'குறைந்தபட்சம் ₹', 'referral_overview': 'பரிந்துரை மேலோட்டம்', 'total_referrals': 'மொத்த பரிந்துரைகள்', 'your_code': 'உங்கள் குறியீடு',
    'earnings_by_level': 'நிலை வாரியாக வருவாய்', 'no_level_earnings': 'வருவாய் இல்லை.', 'your_referral_network': 'உங்கள் நெட்வொர்க்',
    'level': 'நிலை', 'no_referrals_found': 'பரிந்துரைகள் எதுவும் இல்லை.', 'commission_history': 'கமிஷன் வரலாறு',
    'no_commissions_earned': 'கமிஷன் இல்லை.', 'transaction_history': 'பரிவர்த்தனை வரலாறு', 'no_transactions_found': 'பரிவர்த்தனைகள் இல்லை.',
    'refer_earn_title': 'பரிந்துரைத்து சம்பாதிக்க', 'refer_friends_earn': 'நண்பர்களைப் பரிந்துரைத்து சம்பாதிக்க!', 'share_code_get_rewarded': 'உங்கள் குறியீட்டைப் பகிர்ந்து வெகுமதி பெறுங்கள்.',
    'your_referral_code': 'பரிந்துரை குறியீடு', 'tap_to_copy': 'நகலெடுக்க தட்டவும்', 'copied_to_clipboard': 'குறியீடு நகலெடுக்கப்பட்டது!',
    'share_with_friends': 'நண்பர்களுடன் பகிரவும்', 'how_it_works': 'இது எப்படி வேலை செய்கிறது', 'share_code': 'குறியீட்டைப் பகிரவும்', 'share_code_desc': 'உங்கள் குறியீட்டை நண்பர்களுடன் பகிரவும்.',
    'friends_join': 'நண்பர்கள் சேர்கிறார்கள்', 'friends_join_desc': 'உங்கள் நண்பர்கள் உங்கள் குறியீட்டைப் பயன்படுத்துகிறார்கள்.', 'earn_rewards': 'வெகுமதிகளைப் பெறுங்கள்',
    'earn_rewards_desc': 'ஒவ்வொரு பரிந்துரைக்கும் கமிஷன் பெறுவீர்கள்.', 'go_to_wallet_dashboard': 'வாலட்டிற்குச் செல்லவும்', 'view_earnings_network': 'வருவாயைக் காண்க'
  },
  'te': {
    'home': 'హోమ్', 'change_language': 'భాష మార్చండి', 'refer_earn': 'రిఫర్ చేయండి & సంపాదించండి', 'company_info': 'కంపెనీ సమాచారం',
    'my_subscriptions': 'నా సభ్యత్వాలు', 'my_job_posts': 'నా ఉద్యోగ పోస్ట్‌లు', 'my_service_posts': 'నా సేవా పోస్ట్‌లు',
    'delete_account': 'ఖాతాను తొలగించండి', 'terms_conditions': 'నిబంధనలు', 'about_app': 'యాప్ గురించి',
    'logout': 'లాగ్ అవుట్', 'login': 'లాగిన్', 'register': 'నమోదు చేయండి', 'wallet_dashboard': 'వాలెట్ & డాష్‌బోర్డ్', 'select_language': 'మీ భాషను ఎంచుకోండి',
    'wallet_referrals': 'వాలెట్ & రిఫరల్స్', 'overview': 'అవలోకనం', 'network': 'నెట్‌వర్క్', 'commissions': 'కమిషన్లు', 'transactions': 'లావాదేవీలు',
    'wallet_balance': 'వాలెట్ బ్యాలెన్స్', 'total_earned': 'మొత్తం సంపాదన', 'pending': 'పెండింగ్', 'withdraw_balance': 'ఉపసంహరించుకోండి',
    'min_withdrawal_is': 'కనిష్ట ఉపసంహరణ ₹', 'referral_overview': 'రిఫరల్ అవలోకనం', 'total_referrals': 'మొత్తం రిఫరల్స్', 'your_code': 'మీ కోడ్',
    'earnings_by_level': 'స్థాయి ద్వారా సంపాదన', 'no_level_earnings': 'ఇంకా సంపాదన లేదు.', 'your_referral_network': 'మీ నెట్‌వర్క్',
    'level': 'స్థాయి', 'no_referrals_found': 'రిఫరల్స్ లేవు.', 'commission_history': 'కమిషన్ చరిత్ర',
    'no_commissions_earned': 'కమిషన్లు లేవు.', 'transaction_history': 'లావాదేవీల చరిత్ర', 'no_transactions_found': 'లావాదేవీలు లేవు.',
    'refer_earn_title': 'రిఫర్ చేయండి & సంపాదించండి', 'refer_friends_earn': 'స్నేహితులను రిఫర్ చేయండి!', 'share_code_get_rewarded': 'మీ కోడ్‌ను పంచుకోండి మరియు బహుమతులు పొందండి.',
    'your_referral_code': 'మీ రిఫరల్ కోడ్', 'tap_to_copy': 'కాపీ చేయడానికి నొక్కండి', 'copied_to_clipboard': 'కోడ్ కాపీ చేయబడింది!',
    'share_with_friends': 'స్నేహితులతో పంచుకోండి', 'how_it_works': 'ఇది ఎలా పనిచేస్తుంది', 'share_code': 'కోడ్‌ను పంచుకోండి', 'share_code_desc': 'మీ కోడ్‌ను స్నేహితులతో పంచుకోండి.',
    'friends_join': 'స్నేహితులు చేరుతారు', 'friends_join_desc': 'మీ స్నేహితులు మీ కోడ్‌ను ఉపయోగిస్తారు.', 'earn_rewards': 'బహుమతులు పొందండి',
    'earn_rewards_desc': 'మీకు ప్రతి రిఫరల్‌కు కమిషన్ వస్తుంది.', 'go_to_wallet_dashboard': 'వాలెట్‌కి వెళ్లండి', 'view_earnings_network': 'మీ సంపాదనను చూడండి'
  },
  'ml': {
    'home': 'ഹോം', 'change_language': 'ഭാഷ മാറ്റുക', 'refer_earn': 'റഫർ ചെയ്ത് സമ്പാദിക്കുക', 'company_info': 'കമ്പനി വിവരങ്ങൾ',
    'my_subscriptions': 'എൻ്റെ സബ്സ്ക്രിപ്ഷനുകൾ', 'my_job_posts': 'എൻ്റെ ജോലി പോസ്റ്റുകൾ', 'my_service_posts': 'എൻ്റെ സേവന പോസ്റ്റുകൾ',
    'delete_account': 'അക്കൗണ്ട് ഇല്ലാതാക്കുക', 'terms_conditions': 'നിബന്ധനകൾ', 'about_app': 'ആപ്പിനെക്കുറിച്ച്',
    'logout': 'ലോഗൗട്ട്', 'login': 'ലോഗിൻ', 'register': 'രജിസ്റ്റർ', 'wallet_dashboard': 'വാലറ്റ് & ഡാഷ്‌ബോർഡ്', 'select_language': 'ഭാഷ തിരഞ്ഞെടുക്കുക',
    'wallet_referrals': 'വാലറ്റും റഫറലുകളും', 'overview': 'അവലോകനം', 'network': 'നെറ്റ്‌വർക്ക്', 'commissions': 'കമ്മീഷനുകൾ', 'transactions': 'ഇടപാടുകൾ',
    'wallet_balance': 'വാലറ്റ് ബാലൻസ്', 'total_earned': 'മൊത്തം സമ്പാദിച്ചു', 'pending': 'തീർപ്പുകൽപ്പിച്ചിട്ടില്ല', 'withdraw_balance': 'പിൻവലിക്കുക',
    'min_withdrawal_is': 'കുറഞ്ഞ പിൻവലിക്കൽ ₹', 'referral_overview': 'റഫറൽ അവലോകനം', 'total_referrals': 'മൊത്തം റഫറലുകൾ', 'your_code': 'നിങ്ങളുടെ കോഡ്',
    'earnings_by_level': 'നിലവാരം അനുസരിച്ച് സമ്പാദ്യം', 'no_level_earnings': 'സമ്പാദ്യമില്ല.', 'your_referral_network': 'നിങ്ങളുടെ നെറ്റ്‌വർക്ക്',
    'level': 'നില', 'no_referrals_found': 'റഫറലുകളൊന്നുമില്ല.', 'commission_history': 'കമ്മീഷൻ ചരിത്രം',
    'no_commissions_earned': 'കമ്മീഷനുകളില്ല.', 'transaction_history': 'ഇടപാട് ചരിത്രം', 'no_transactions_found': 'ഇടപാടുകളില്ല.',
    'refer_earn_title': 'റഫർ ചെയ്ത് സമ്പാദിക്കുക', 'refer_friends_earn': 'സുഹൃത്തുക്കളെ റഫർ ചെയ്യുക!', 'share_code_get_rewarded': 'നിങ്ങളുടെ കോഡ് പങ്കിട്ട് പ്രതിഫലം നേടുക.',
    'your_referral_code': 'റഫറൽ കോഡ്', 'tap_to_copy': 'പകർത്താൻ ടാപ്പ് ചെയ്യുക', 'copied_to_clipboard': 'കോഡ് പകർത്തി!',
    'share_with_friends': 'സുഹൃത്തുക്കളുമായി പങ്കിടുക', 'how_it_works': 'ഇതെങ്ങനെ പ്രവർത്തിക്കുന്നു', 'share_code': 'കോഡ് പങ്കിടുക', 'share_code_desc': 'നിങ്ങളുടെ കോഡ് പങ്കിടുക.',
    'friends_join': 'സുഹൃത്തുക്കൾ ചേരുന്നു', 'friends_join_desc': 'സുഹൃത്തുക്കൾ നിങ്ങളുടെ കോഡ് ഉപയോഗിക്കുന്നു.', 'earn_rewards': 'പ്രതിഫലം നേടുക',
    'earn_rewards_desc': 'ഓരോ റഫറലിനും നിങ്ങൾക്ക് കമ്മീഷൻ ലഭിക്കും.', 'go_to_wallet_dashboard': 'വാലറ്റിലേക്ക് പോകുക', 'view_earnings_network': 'സമ്പാദ്യം കാണുക'
  },
  'mr': {
    'home': 'मुख्यपृष्ठ', 'change_language': 'भाषा बदला', 'refer_earn': 'संदर्भ द्या आणि कमवा', 'company_info': 'कंपनीची माहिती',
    'my_subscriptions': 'माझे सदस्यत्व', 'my_job_posts': 'माझ्या जॉब पोस्ट', 'my_service_posts': 'माझ्या सेवा पोस्ट',
    'delete_account': 'खाते हटवा', 'terms_conditions': 'अटी', 'about_app': 'अॅप बद्दल',
    'logout': 'लॉग आउट', 'login': 'लॉग इन', 'register': 'नोंदणी करा', 'wallet_dashboard': 'वॉलेट आणि डॅशबोर्ड', 'select_language': 'तुमची भाषा निवडा',
    'wallet_referrals': 'वॉलेट आणि रेफरल्स', 'overview': 'आढावा', 'network': 'नेटवर्क', 'commissions': 'कमिशन', 'transactions': 'व्यवहार',
    'wallet_balance': 'वॉलेट शिल्लक', 'total_earned': 'एकूण कमाई', 'pending': 'प्रलंबित', 'withdraw_balance': 'पैसे काढा',
    'min_withdrawal_is': 'किमान काढणी ₹', 'referral_overview': 'रेफरल आढावा', 'total_referrals': 'एकूण रेफरल्स', 'your_code': 'तुमचा कोड',
    'earnings_by_level': 'पातळीनुसार कमाई', 'no_level_earnings': 'अद्याप कोणतीही कमाई नाही.', 'your_referral_network': 'तुमचे नेटवर्क',
    'level': 'पातळी', 'no_referrals_found': 'कोणतेही रेफरल्स आढळले नाहीत.', 'commission_history': 'कमिशन इतिहास',
    'no_commissions_earned': 'कोणतेही कमिशन नाही.', 'transaction_history': 'व्यवहार इतिहास', 'no_transactions_found': 'कोणतेही व्यवहार नाहीत.',
    'refer_earn_title': 'संदर्भ द्या आणि कमवा', 'refer_friends_earn': 'मित्रांना संदर्भ द्या!', 'share_code_get_rewarded': 'तुमचा कोड शेअर करा आणि बक्षीस मिळवा.',
    'your_referral_code': 'तुमचा रेफरल कोड', 'tap_to_copy': 'कॉपी करण्यासाठी टॅप करा', 'copied_to_clipboard': 'कोड कॉपी केला!',
    'share_with_friends': 'मित्रांसोबत शेअर करा', 'how_it_works': 'हे कसे काम करते', 'share_code': 'कोड शेअर करा', 'share_code_desc': 'तुमचा कोड शेअर करा.',
    'friends_join': 'मित्र सामील होतील', 'friends_join_desc': 'तुमचे मित्र तुमचा कोड वापरतील.', 'earn_rewards': 'बक्षिसे मिळवा',
    'earn_rewards_desc': 'तुम्हाला प्रत्येक रेफरलसाठी कमिशन मिळेल.', 'go_to_wallet_dashboard': 'वॉलेटवर जा', 'view_earnings_network': 'तुमची कमाई पहा'
  },
  'gu': {
    'home': 'હોમ', 'change_language': 'ભાષા બદલો', 'refer_earn': 'રેફર કરો અને કમાઓ', 'company_info': 'કંપની માહિતી',
    'my_subscriptions': 'મારા સબ્સ્ક્રિપ્શન્સ', 'my_job_posts': 'મારી નોકરીની પોસ્ટ્સ', 'my_service_posts': 'મારી સેવા પોસ્ટ્સ',
    'delete_account': 'ખાતું કાઢી નાખો', 'terms_conditions': 'શરતો', 'about_app': 'એપ્લિકેશન વિશે',
    'logout': 'લોગ આઉટ', 'login': 'લોગ ઇન', 'register': 'રજીસ્ટર', 'wallet_dashboard': 'વૉલેટ અને ડેશબોર્ડ', 'select_language': 'તમારી ભાષા પસંદ કરો',
    'wallet_referrals': 'વૉલેટ અને રેફરલ્સ', 'overview': 'વિહંગાવલોકન', 'network': 'નેટવર્ક', 'commissions': 'કમિશન', 'transactions': 'વ્યવહારો',
    'wallet_balance': 'વૉલેટ બેલેન્સ', 'total_earned': 'કુલ કમાણી', 'pending': 'બાકી', 'withdraw_balance': 'ઉપાડો',
    'min_withdrawal_is': 'લઘુત્તમ ઉપાડ ₹', 'referral_overview': 'રેફરલ વિહંગાવલોકન', 'total_referrals': 'કુલ રેફરલ્સ', 'your_code': 'તમારો કોડ',
    'earnings_by_level': 'સ્તર દ્વારા કમાણી', 'no_level_earnings': 'હજી કોઈ કમાણી નથી.', 'your_referral_network': 'તમારું નેટવર્ક',
    'level': 'સ્તર', 'no_referrals_found': 'કોઈ રેફરલ્સ મળ્યા નથી.', 'commission_history': 'કમિશન ઇતિહાસ',
    'no_commissions_earned': 'કોઈ કમિશન નથી.', 'transaction_history': 'વ્યવહાર ઇતિહાસ', 'no_transactions_found': 'કોઈ વ્યવહારો નથી.',
    'refer_earn_title': 'રેફર કરો અને કમાઓ', 'refer_friends_earn': 'મિત્રોને રેફર કરો!', 'share_code_get_rewarded': 'તમારો કોડ શેર કરો અને ઇનામ મેળવો.',
    'your_referral_code': 'તમારો રેફરલ કોડ', 'tap_to_copy': 'કૉપિ કરવા માટે ટેપ કરો', 'copied_to_clipboard': 'કોડ કૉપિ થયો!',
    'share_with_friends': 'મિત્રો સાથે શેર કરો', 'how_it_works': 'તે કેવી રીતે કામ કરે છે', 'share_code': 'કોડ શેર કરો', 'share_code_desc': 'તમારો કોડ શેર કરો.',
    'friends_join': 'મિત્રો જોડાશે', 'friends_join_desc': 'તમારા મિત્રો તમારો કોડ વાપરશે.', 'earn_rewards': 'ઇનામ મેળવો',
    'earn_rewards_desc': 'તમને દરેક રેફરલ માટે કમિશન મળશે.', 'go_to_wallet_dashboard': 'વૉલેટ પર જાઓ', 'view_earnings_network': 'તમારી કમાણી જુઓ'
  },
  'or': {
    'home': 'ହୋମ୍', 'change_language': 'ଭାଷା ପରିବର୍ତ୍ତନ କରନ୍ତୁ', 'refer_earn': 'ରେଫର୍ ଏବଂ ରୋଜଗାର କରନ୍ତୁ', 'company_info': 'କମ୍ପାନୀ ସୂଚନା',
    'my_subscriptions': 'ମୋର ସବସ୍କ୍ରିପସନ୍', 'my_job_posts': 'ମୋର ଚାକିରି ପୋଷ୍ଟ', 'my_service_posts': 'ମୋର ସେବା ପୋଷ୍ଟ',
    'delete_account': 'ଆକାଉଣ୍ଟ୍ ବିଲୋପ କରନ୍ତୁ', 'terms_conditions': 'ସର୍ତ୍ତାବଳୀ', 'about_app': 'ଆପ୍ ବିଷୟରେ',
    'logout': 'ଲଗ୍ ଆଉଟ୍', 'login': 'ଲଗ୍ ଇନ୍', 'register': 'ରେଜିଷ୍ଟର', 'wallet_dashboard': 'ୱାଲେଟ୍ ଏବଂ ଡ୍ୟାସବୋର୍ଡ', 'select_language': 'ଆପଣଙ୍କର ଭାଷା ବାଛନ୍ତୁ',
    'wallet_referrals': 'ୱାଲେଟ୍ ଏବଂ ରେଫରାଲ୍', 'overview': 'ସମୀକ୍ଷା', 'network': 'ନେଟୱାର୍କ', 'commissions': 'କମିଶନ୍', 'transactions': 'କାରବାର',
    'wallet_balance': 'ୱାଲେଟ୍ ବାଲାନ୍ସ', 'total_earned': 'ମୋଟ ରୋଜଗାର', 'pending': 'ପେଣ୍ଡିଂ', 'withdraw_balance': 'ଟଙ୍କା ଉଠାନ୍ତୁ',
    'min_withdrawal_is': 'ସର୍ବନିମ୍ନ ଉଠାଣ ₹', 'referral_overview': 'ରେଫରାଲ୍ ସମୀକ୍ଷା', 'total_referrals': 'ମୋଟ ରେଫରାଲ୍', 'your_code': 'ଆପଣଙ୍କର କୋଡ୍',
    'earnings_by_level': 'ସ୍ତର ଅନୁଯାୟୀ ରୋଜଗାର', 'no_level_earnings': 'କୌଣସି ରୋଜଗାର ନାହିଁ।', 'your_referral_network': 'ଆପଣଙ୍କର ନେଟୱାର୍କ',
    'level': 'ସ୍ତର', 'no_referrals_found': 'କୌଣସି ରେଫରାଲ୍ ମିଳିଲା ନାହିଁ।', 'commission_history': 'କମିଶନ୍ ଇତିହାସ',
    'no_commissions_earned': 'କୌଣସି କମିଶନ୍ ନାହିଁ।', 'transaction_history': 'କାରବାର ଇତିହାସ', 'no_transactions_found': 'କୌଣସି କାରବାର ନାହିଁ।',
    'refer_earn_title': 'ରେଫର୍ ଏବଂ ରୋଜଗାର କରନ୍ତୁ', 'refer_friends_earn': 'ସାଙ୍ଗମାନଙ୍କୁ ରେଫର୍ କରନ୍ତୁ!', 'share_code_get_rewarded': 'ଆପଣଙ୍କର କୋଡ୍ ସେୟାର୍ କରନ୍ତୁ ଏବଂ ପୁରସ୍କାର ପାଆନ୍ତୁ।',
    'your_referral_code': 'ଆପଣଙ୍କର ରେଫରାଲ୍ କୋଡ୍', 'tap_to_copy': 'କପି କରିବାକୁ ଟ୍ୟାପ୍ କରନ୍ତୁ', 'copied_to_clipboard': 'କୋଡ୍ କପି ହେଲା!',
    'share_with_friends': 'ସାଙ୍ଗମାନଙ୍କ ସହିତ ସେୟାର୍ କରନ୍ତୁ', 'how_it_works': 'ଏହା କିପରି କାମ କରେ', 'share_code': 'କୋଡ୍ ସେୟାର୍ କରନ୍ତୁ', 'share_code_desc': 'ଆପଣଙ୍କର କୋଡ୍ ସେୟାର୍ କରନ୍ତୁ।',
    'friends_join': 'ସାଙ୍ଗମାନେ ଯୋଗଦେବେ', 'friends_join_desc': 'ଆପଣଙ୍କର ସାଙ୍ଗମାନେ ଆପଣଙ୍କର କୋଡ୍ ବ୍ୟବହାର କରିବେ।', 'earn_rewards': 'ପୁରସ୍କାର ପାଆନ୍ତୁ',
    'earn_rewards_desc': 'ପ୍ରତ୍ୟେକ ରେଫରାଲ୍ ପାଇଁ ଆପଣ କମିଶନ୍ ପାଇବେ।', 'go_to_wallet_dashboard': 'ୱାଲେଟ୍କୁ ଯାଆନ୍ତୁ', 'view_earnings_network': 'ଆପଣଙ୍କର ରୋଜଗାର ଦେଖନ୍ତୁ'
  }
}

out = """import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class AppLocalizations {
  static final Map<String, Map<String, String>> _localizedValues = {
"""

for lang, trans in data.items():
    out += f"    '{lang}': {{\n"
    for k, v in trans.items():
        # escape quotes
        v = v.replace("'", "\\'")
        out += f"      '{k}': '{v}',\n"
    out += "    },\n"

out += """  };

  static String of(BuildContext context, String key) {
    final locale = Provider.of<LocaleProvider>(context).locale.languageCode;
    final Map<String, String>? localizedStrings = _localizedValues[locale];
    
    if (localizedStrings != null && localizedStrings.containsKey(key)) {
      return localizedStrings[key]!;
    }
    
    // Fallback to English
    return _localizedValues['en']![key] ?? key;
  }
}
"""

with open('lib/l10n/app_localizations.dart', 'w') as f:
    f.write(out)

print("Generated app_localizations.dart")
