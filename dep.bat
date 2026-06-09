@echo off
chcp 65001 >nul
title تثبيت المتطلبات وبناء التطبيق + تنزيل Winlator
echo ===================================================================
echo   إعداد بيئة تطوير Tauri وتنزيل Winlator تلقائياً
echo ===================================================================
echo.

:: -------------------------------------------------------------------
:: 1. التحقق من صلاحيات المدير (لتثبيت البرامج)
:: -------------------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [تنبيه] هذا السكريبت يحتاج صلاحيات المدير لتثبيت المتطلبات.
    echo الرجاء إعادة تشغيل الملف كمسؤول (انقر بزر الماوس الأيمن - Run as Administrator).
    pause
    exit /b
)

:: -------------------------------------------------------------------
:: 2. تثبيت المتطلبات عبر winget (إن وجد)
:: -------------------------------------------------------------------
echo [1/5] التحقق من وجود winget...
where winget >nul 2>nul
if %errorlevel% neq 0 (
    echo winget غير موجود. سيتم توجيهك لتحميل المتطلبات يدوياً.
    echo يرجى تثبيت:
    echo - Node.js LTS من https://nodejs.org
    echo - Rust من https://rustup.rs
    echo - Visual Studio Build Tools مع حزمة "Desktop development with C++"
    echo.
    echo اضغط أي مفتاح بعد الانتهاء من التثبيت اليدوي...
    pause >nul
    goto :CHECK_TOOLS
)

echo تثبيت Node.js LTS...
winget install -e --id OpenJS.NodeJS.LTS --silent --accept-package-agreements
if %errorlevel% neq 0 echo [تحذير] فشل تثبيت Node.js تلقائياً، قم بتثبيته يدوياً.

echo تثبيت Rust...
winget install -e --id Rustlang.Rustup --silent --accept-package-agreements
if %errorlevel% neq 0 echo [تحذير] فشل تثبيت Rust تلقائياً.

echo تثبيت Visual Studio Build Tools (قد يستغرق وقتاً)...
winget install -e --id Microsoft.VisualStudio.2022.BuildTools --silent --accept-package-agreements --override "--passive --add Microsoft.VisualStudio.Workload.VCTools"
if %errorlevel% neq 0 echo [تحذير] فشل تثبيت Build Tools تلقائياً، قم بتثبيته يدوياً من https://visualstudio.microsoft.com/visual-cpp-build-tools/

:: -------------------------------------------------------------------
:: 3. التحقق من وجود الأدوات الأساسية بعد التثبيت
:: -------------------------------------------------------------------
:CHECK_TOOLS
echo.
echo [2/5] التحقق من التثبيت...
where node >nul 2>nul || (echo [خطأ] Node.js غير موجود. قم بتثبيته وأعد تشغيل السكريبت. && pause && exit /b)
where cargo >nul 2>nul || (echo [خطأ] Rust غير موجود. قم بتثبيته وأعد التشغيل. && pause && exit /b)
echo [موافق] جميع الأدوات الأساسية موجودة.

:: -------------------------------------------------------------------
:: 4. تثبيت اعتماديات المشروع وبناء التطبيق
:: -------------------------------------------------------------------
echo.
echo [3/5] تثبيت مكتبات المشروع (npm install)...
call npm install
if %errorlevel% neq 0 (
    echo [خطأ] فشل npm install.
    pause
    exit /b
)

echo.
echo [4/5] بناء واجهة الويب (npm run build)...
call npm run build
if %errorlevel% neq 0 (
    echo [خطأ] فشل بناء الواجهة.
    pause
    exit /b
)

echo.
echo [5/5] بناء تطبيق Tauri (cargo tauri build)...
call cargo tauri build
if %errorlevel% neq 0 (
    echo [خطأ] فشل بناء Tauri.
    echo تأكد من تثبيت C++ Build Tools وتوفر MSVC.
    pause
    exit /b
)

:: -------------------------------------------------------------------
:: 5. تنزيل أحدث إصدار من Winlator (APK)
:: -------------------------------------------------------------------
echo.
echo [6/6] تنزيل أحدث نسخة من Winlator (لأجهزة Android)...
set "WINLATOR_URL=https://github.com/brunodev85/winlator/releases/latest/download/winlator.apk"
set "WINLATOR_OUT=winlator_latest.apk"
curl -L -o "%WINLATOR_OUT%" "%WINLATOR_URL%"
if %errorlevel% neq 0 (
    echo [تحذير] فشل تنزيل Winlator عبر curl. يمكنك تنزيله يدوياً من:
    echo https://github.com/brunodev85/winlator/releases
) else (
    echo [موافق] تم تنزيل Winlator إلى %CD%\%WINLATOR_OUT%
)

:: -------------------------------------------------------------------
:: 6. عرض مسار الملفات النهائية
:: -------------------------------------------------------------------
echo.
echo ===================================================================
echo 🎉 انتهى العمل بنجاح!
echo ===================================================================
echo ملفات تطبيقك (EXE/MSI) موجودة في:
echo   - \src-tauri\target\release\             (الملف المباشر)
echo   - \src-tauri\target\release\bundle\msi\  (حزمة التثبيت)
echo.
echo ملف Winlator الذي تم تنزيله: %WINLATOR_OUT%
echo.
pause