# Ourchat
OurChat adalah aplikasi chat modern yang dibangun menggunakan Flutter. Aplikasi ini bertujuan untuk menghubungkan pengguna di seluruh dunia melalui pesan instan yang sederhana dan cepat. Dengan antarmuka yang intuitif dan fitur-fitur real-time, OurChat memudahkan pengguna untuk berkomunikasi, berbagi gambar, dan tetap terhubung dengan teman maupun keluarga di mana pun mereka berada.

## Fitur Utama
- Autentikasi Pengguna – Pengguna dapat mendaftar akun baru dan masuk (login) menggunakan email dan password melalui Firebase Authentication. Juga mendukung fitur lupa password untuk reset kata sandi via email.
- Profil dengan Foto – Saat mendaftar, pengguna bisa mengunggah foto profil. Foto disimpan di storage Supabase, dan URL foto tersebut disimpan di Cloud Firestore untuk ditampilkan dalam aplikasi.
- Update user dan profil
- Chat Personal & Grup – OurChat mendukung obrolan satu-satu dan obrolan grup (beberapa pengguna dalam satu percakapan). Setiap chat menampilkan nama obrolan (atau daftar anggota untuk grup) beserta status online/terakhir aktif.
- Pesan Teks Real-time – Kirim dan terima pesan teks secara real-time. Percakapan terupdate seketika menggunakan Cloud Firestore sehingga pengguna dapat berbincang tanpa hambatan.
- Berbagi Gambar – Unggah dan kirim gambar/foto di dalam chat. Gambar akan diunggah ke Supabase storage, dan tautan gambarnya dibagikan di chat sehingga pengguna lain dapat melihatnya langsung di percakapan.
- Daftar Pengguna & Pencarian – Temukan pengguna lain yang terdaftar untuk memulai chat baru. OurChat menyediakan halaman daftar pengguna lengkap dengan fungsi pencarian, sehingga Anda dapat mencari teman dengan mudah dan memulai obrolan.
- Voice Note - Kirim Pesan suara dan mendengarkan
- Status Online – Lihat status online atau kapan terakhir kali pengguna aktif (last seen). Hal ini memudahkan Anda mengetahui ketersediaan teman chat sebelum mengirim pesan.
Antarmuka Modern – Desain UI yang bersih dan modern menggunakan Flutter, memberikan pengalaman pengguna yang ramah di perangkat mobile maupun web.
- Enkripsi end-to-end

## Teknologi yang digunakan
OurChat dibangun sepenuhnya dengan teknologi cross-platform sehingga dapat dijalankan di Android, iOS, maupun Web. Stack utama yang digunakan antara lain:
- Flutter & Dart – Framework dan bahasa pemrograman utama untuk membangun antarmuka aplikasi yang responsif di berbagai platform.
- Firebase Authentication – Mengelola fitur login dan pendaftaran akun menggunakan email/password secara aman.
- Cloud Firestore – Basis data NoSQL realtime untuk menyimpan data aplikasi, termasuk profil pengguna, daftar chat, dan pesan. Firestore memungkinkan sinkronisasi pesan secara real-time ke semua pengguna.
- Supabase Storage – Layanan penyimpanan objek digunakan untuk menyimpan file gambar (contoh: foto profil pengguna dan gambar yang dikirim dalam chat). URL file yang disimpan di Supabase dicatat di Firestore agar dapat ditampilkan di aplikasi.
- Pustaka Pendukung – Paket Flutter tambahan yang digunakan meliputi: firebase_core, firebase_auth, cloud_firestore, supabase_flutter, dan lain-lain untuk mendukung fungsionalitas di atas.

## Roadmap
Ke depannya, beberapa fitur baru direncanakan untuk meningkatkan OurChat:
- Peningkatan Lain – Perbaikan antarmuka pengguna, optimalisasi performa, dan dukungan fitur-fitur tambahan berdasarkan masukan (misalnya notifikasi push untuk pesan baru, indikator "sedang mengetik", dll).

## Kontribusi
- Kontribusi dari komunitas sangat kami apresiasi. Jika Anda ingin berkontribusi pada OurChat, silakan fork repositori ini dan ajukan pull request untuk perbaikan bug atau penambahan fitur. Anda juga dapat membuka Issue untuk melaporkan bug atau mengusulkan fitur baru.
