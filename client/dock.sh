#:/bin/bash

docker build -t flutter_dev -f flutterfile .
docker build -t client -f dockerfile .
