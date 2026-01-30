# Shared package
cd shared 
dart test
cd ..

# Server package  
cd server
dart test
cd ..

# Client package
cd client
flutter test
cd ..