
# Seçenek 1: En Kısa Versiyon (GitHub "About" bölümü için)

**Türkçe:**
> PowerShell ile dosya sunucusu klasör yetkilerini (NTFS) analiz ve raporlama script'i.

**EN:**
> A PowerShell script to analyze and report NTFS folder permissions on a File Server.


**Türkçe:**
> Bu PowerShell script'i, dosya sunucularındaki karmaşık klasör yetki yapılarını analiz etmek için geliştirilmiştir. Belirtilen bir yol altındaki tüm klasörlerin Erişim Kontrol Listelerini (ACL) tarar, sistem yöneticilerinin güvenlik denetimleri yapmasını ve yetki kirliliğini temizlemesini kolaylaştıracak şekilde anlaşılır bir rapor sunar.

**İngilizce:**
> This PowerShell script is designed to analyze complex folder permission structures on file servers. It scans the Access Control Lists (ACLs) for all folders under a specified path and provides a clear report to help system administrators perform security audits and clean up permission clutter.


**Özellikler:**

Bu araç, sistem yöneticilerinin dosya sunucularındaki NTFS klasör yetkilerini hızlı ve etkili bir şekilde denetlemesini sağlar.

* 📂 Belirtilen klasör ve tüm alt klasörleri derinlemesine tarar.
* 👥 Klasörlere atanmış kullanıcı ve grup yetkilerini listeler.
* 🔒 İzinlerin kalıtım (inheritance) durumunu gösterir.
* 📄 Sonuçları kolay analiz için CSV veya okunabilir metin formatında raporlar.
* 🎯 Güvenlik açıklarını ve gereksiz yetkileri tespit etmeyi kolaylaştırır.

GUI Arayüzü: Kullanıcı dostu Windows Forms tabanlı arayüz
Klasör Seçimi: Gözat butonu ile kolay klasör seçimi
Detaylı Analiz: Klasör yetkileri, kullanıcı/grup bilgileri, yetki türleri
Export Seçenekleri: CSV ve Excel formatlarında export
Progress Tracking: İşlem durumu takibi

Scriptün İşlevleri:

Yetki Analizi: Seçilen klasör ve alt klasörlerdeki tüm yetkileri analiz eder
Domain Kullanıcı Tespiti: Hangi yetkilerin domain kullanıcılarına ait olduğunu belirler
Derinlik Kontrolü: Maksimum 3 seviye derinlikte analiz yapar
Filtreleme: Sadece "Allow" türündeki yetkileri gösterir

Kullanım:

Scripti PowerShell'de çalıştırın
Analiz edilecek klasörü seçin
"Analiz Et" butonuna tıklayın
Sonuçları görüntüleyin
İhtiyaç halinde CSV veya Excel olarak export edin

Güvenlik Notları:

Script, yalnızca okuma yetkisi olan klasörlere erişebilir
Yetki hatalarını yakalar ve gösterir
COM objelerini düzgün şekilde temizler
