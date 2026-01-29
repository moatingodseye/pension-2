#:/bin/bash
# have to run from root as needs the shared folder and docker can only see from where it is down...
cd ..
docker build -t flutter_dev -f client/flutterfile .
docker build -t client -f client/dockerfile .
cd client
