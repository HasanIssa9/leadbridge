# LeadBridge — خطوات الرفع على GitHub

## الخطوة 1: إنشاء GitHub Token

1. اذهب إلى: https://github.com/settings/tokens/new
2. ادخل بـ hissa3548@gmail.com
3. اختر:
   - Note: leadbridge-deploy
   - Expiration: 90 days
   - Scopes: ✅ repo (كاملة) ✅ workflow
4. انسخ الـ Token (يبدأ بـ ghp_)

---

## الخطوة 2: إنشاء Repository

1. اذهب إلى: https://github.com/new
2. Repository name: `leadbridge`
3. Private ✅
4. لا تضف README
5. اضغط **Create repository**

---

## الخطوة 3: رفع الكود (افتح CMD كـ Admin)

```cmd
cd "C:\Users\Hasan Issa\Documents\leadbridge"
git remote add origin https://YOUR_TOKEN@github.com/hissa3548/leadbridge.git
git branch -M main
git push -u origin main
```

استبدل YOUR_TOKEN بالتوكن الذي حصلت عليه في الخطوة 1

---

## الخطوة 4: تفعيل GitHub Pages (للويب)

1. Repository → Settings → Pages
2. Source: GitHub Actions
3. انتظر 3-5 دقائق
4. رابط الويب: https://hissa3548.github.io/leadbridge

---

## الخطوة 5: تحميل الـ APK

بعد push، GitHub Actions سيبني الـ APK تلقائياً:

1. اذهب إلى: https://github.com/hissa3548/leadbridge/actions
2. انتظر 5-10 دقائق حتى يكتمل البناء
3. اضغط على الـ workflow → Artifacts → leadbridge-apk
4. حمّل الـ APK

---

## الخطوة 6: بناء APK محلياً (كـ Admin)

إذا أردت بناء الـ APK على جهازك مباشرة:

1. ابحث عن ملف: `build_apk_as_admin.bat` في مجلد leadbridge
2. اضغط عليه بالزر الأيمن
3. اختر "Run as administrator"
4. انتظر 5-10 دقائق
5. ستجد الـ APK في:
   `flutter_app\build\app\outputs\flutter-apk\app-release.apk`

---

## ملفات المشروع المحفوظة

```
C:\Users\Hasan Issa\Documents\leadbridge\
├── backend/          ← Node.js API
├── flutter_app/      ← Mobile + Web App
├── .github/          ← GitHub Actions CI/CD
└── build_apk_as_admin.bat  ← بناء APK محلياً
```

## رابط الويب بعد Deploy
https://hissa3548.github.io/leadbridge
