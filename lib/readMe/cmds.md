open -a simulator
flutter run
//r to refresh
firebase emulators:start

// git

git add .
git commit -m ""
git push

//rolls back to the previous one(HEAD~1) commiut
git checkout HEAD~1 {directory ie  lib/screens/splash_screen.dart}

git checkout HEAD~1 {/lib/screens/auth_screen.dart}

to sync
git clone https://github.com/dotcael/liminal.git
cd liminal
flutter pub get

to force a push ;
git push origin main -f

//run
flutter run -d chrome