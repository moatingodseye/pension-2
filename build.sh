#:/bin/bash
git reset --hard origin/main
git pull
cd client
docker build -t flutter_dev -f flutterfile .
docker build -t client -f dockerfile .
cd ..
cd server
docker build -t server -f dockerfile .
cd ..
