# Patch-SMART-BSM-2019_06_25
Patch Aplikasi SMART WEB BSM per tanggal 25 Juni 2019

Material Patch ini terdiri dari 4 Folder
a. Database Script
   berisi file :
   - Patch2019_06_25.sql :
   Script database yang harus dieksekusi menggunakan Microsoft SQL Server Studio
b. Dokumen
   berisi file :
   - ALUR PROSES PENDAFTARAN_2019_06_25.docx :
   Dokumen panduan untuk menjalankan testing aplikasi 
c. SMART_PPG_WEBAPI
   berisi folder (dan file didalamnya) :
   - Models
   = bin
   Kedua folder ini disalin (overwrite) ke lokasi source aplikasi web SMART_PPG_WEBAPI yang ada di server qa2
   (di D:\SMART_PPG\SmartAPI_BSM)
d. SMART_PPG_WEBCLIENT
   berisi folder (dan file didalamnya) :
   - Views
   - bin 
   Kedua folder ini disalin (overwrite) ke lokasi source aplikasi web SMART_PPG_WEBCLIENT yang ada di server qa2
   (di D:\SMART_PPG\Smart_BSM)

Urutan menjalankan update patch :
1. Buka Microsoft SQL Server Studio di server qa2 (atau server database SMART BSM)
   Buka menu : File > Open > File ...
   Pilih file yang ada di folder Database Script (poin a diatas)
   Eksekusi script dengan memilih menu : Query > Execute 
   (atau dengan menekan tombol F5)
2. Buka IIS Manager di server qa2
   Buka semua node yang ada di bawah Sites
   Non Aktifkan lebih dahulu website SMART BSM dengan cara :
   Klik kanan di node SMART_PPG_WEBAPI, lalu pilih Manage Website > Stop
   Klik kanan di node SMART_PPG_WEBCLIENT, lalu pilih Manage Website > Stop
3. Salin folder beserta isinya ke folder, yang merupakan lokasi source aplikasi web SMART BSM
   Sesuai dengan poin c dan d diatas. Salin dengan pilihan overwrite.
4. Buka kembali IIS Manager di server qa2
   Buka semua node yang ada di bawah Sites
   Aktifkan kembali website SMART BSM dengan cara :
   Klik kanan di node SMART_PPG_WEBAPI, lalu pilih Manage Website > Start
   Klik kanan di node SMART_PPG_WEBCLIENT, lalu pilih Manage Website > Start
5. Proses update patch sudah selesai.
