<!-- Restoran Sipariş Otomasyon README.md -->

<div align="center">

# 🍽️ Restaurant Order & Receipt System  

*Flutter & .NET tabanlı restoran sipariş ve fiş otomasyonu*  

</div>

---

## 🚀 Proje Hakkında  

**Restaurant Order & Receipt System**, restoranlarda sipariş alımını kolaylaştıran ve manuel masaüstü otomasyon yazılımlarına olan ihtiyacı ortadan kaldırmayı hedefleyen bir uygulamadır.  

- 📝 Garson / kullanıcı **siparişi mobil cihaz üzerinden alır**.  
- 📄 Sipariş **ilgili bölüme fiş olarak otomatik gönderilir** (ör. mutfak, bar, tatlı bölümü).  
- 🖨️ **Fiş yazdırma desteği** ile manuel işlem ortadan kalkar.  
- 📊 İlerleyen sürümlerde **stok takibi** ve **detaylı raporlama** desteği eklenecektir.  

> Sonuç: Restoranlar, **ekstra bilgisayar tabanlı otomasyon yazılımına gerek kalmadan** mobil cihazlar üzerinden tüm süreci yönetebilir.  

---

## 🖼️ Demo & Görseller  

![Order Taking UI](https://via.placeholder.com/600x400.png?text=Restaurant+Order+App+UI+Placeholder)  
*(Mobil arayüz: sipariş alma ekranı)*  

![Receipt Printing](https://via.placeholder.com/600x400.png?text=Receipt+Printing+Placeholder)  
*(Fiş yazdırma süreci placeholder)*  

---

## 🛠️ Kullanılan Teknolojiler  

| Katman | Teknoloji |
|---|---|
| Mobil Uygulama | **Flutter** |
| Local Storage | **Hive** |
| API & Backend | **.NET 8 (REST API + WebSocket)** |
| Veritabanı | **MSSQL** |
| İletişim | **WebSocket** ile gerçek zamanlı sipariş aktarımı |
| Diğer | Fiş yazdırma entegrasyonu (POS yazıcılar) |

---

## 🔑 Özellikler  

- 📱 **Mobil Sipariş Alma**: Garsonlar masadan kalkmadan siparişleri anında cihaza işler.  
- 🖨️ **Fiş Yazdırma**: Sipariş ilgili bölüme otomatik fiş olarak gönderilir (örn. mutfak yazıcısı).  
- ⚡ **Gerçek Zamanlı İletişim**: WebSocket ile siparişler anında iletilir.  
- 🗂️ **Hive Local Storage**: Çevrimdışı senaryolarda bile siparişler kaydedilir.  
- 🔄 **MSSQL & .NET Entegrasyonu**: Restoran verileri güvenli ve ölçeklenebilir şekilde tutulur.  
- 📊 **Stok Takip (Yakında)**: Malzemelerin anlık takibi ve otomatik raporlama.  

---
🚀 Özellikler

✅ Authentication & Authorization – Güvenli kullanıcı girişleri, rol tabanlı yetkilendirme
✅ Kategori Bazlı Menü – Yemekleri kategorilere göre ayırma ve kolay erişim
✅ Fiyatlandırma Sistemi – Menüye bağlı fiyatlandırma
✅ Anlık Sipariş Takibi – REST API + WebSocket ile tüm cihazlarda senkronize siparişler
✅ Fiş Yazdırma – Müşteri siparişi alındığında otomatik fiş çıktısı
✅ Kullanıcı Doğrulama – Hesap bazlı oturum yönetimi
✅ Yemek Takibi – Mutfak tarafında yemek hazırlık & teslim kontrolü
✅ Gelecek Özellik: 📦 Stok Takibi

🛠️ Kullanılan Teknolojiler

Frontend (Mobil): Flutter

Backend API: .NET 8 (REST API + WebSocket)

Database: MSSQL

Local Storage: Hive

Gerçek Zamanlı İletişim: WebSocket

Authentication & Authorization: JWT + .NET Identity

🍽️ Restaurant Order & Receipt System

📌 Flutter + .NET + MSSQL + Hive + REST API + WebSocket
Gerçek zamanlı sipariş takibi, fiş yazdırma ve restoran otomasyonu.

🎥 Demo Video

[📺 Uygulama Tanıtım Videosu](https://studio.youtube.com/video/sd72daiaKoE/edit)

## 🧩 Kurulum & Çalıştırma  

### 1️⃣ Backend (.NET 8 API)  

```bash
# API repo'yu klonla
git clone https://github.com/kullaniciAdin/restaurant-api.git
cd restaurant-api

# Bağımlılıkları yükle
dotnet restore

# Veritabanı migrate et
dotnet ef database update

# API’yi başlat
dotnet run
```

2️⃣ Mobil Uygulama (Flutter)
```bash
# Mobil repo'yu klonla
git clone https://github.com/yusufdegerli/restaurant_app.git
cd restaurant_app

# Paketleri yükle
flutter pub get

# Çalıştır
flutter run
```
📦 Mimarinin Genel Yapısı
```bash
Flutter App (Garson Uygulaması)
        |
        |--> WebSocket (Gerçek Zamanlı Sipariş)
        |
        V
. NET API  <--> MSSQL (Sipariş, Menü, Kullanıcı, Stok)
        |
        |--> Hive (Çevrimdışı Depolama)
        |
        |--> Fiş Yazıcı (POS Printer)
```

📊 Gelecek Planları

🔍 Detaylı stok takibi (malzeme giriş/çıkış raporları)

📈 Analitik raporlama (en çok satan ürünler, gelir-gider raporu)

🌐 Çoklu dil desteği

🏪 Bulut entegrasyonu (çok şubeli restoran yönetimi)

💳 Ödeme entegrasyonu (kredi kartı / QR kod)

📬 İletişim: yusufdgrl72@gmail.com

🌐 Web: yusufdegerli.github.io

<div align="center">

“Gerçek zamanlı, hızlı ve hatasız sipariş akışı = mutlu müşteri + verimli restoran.”

Restaurant Order & Receipt System 📲🍴

</div> ```
