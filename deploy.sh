#:/bin/bash

# coutput of this is needed in next line, if it stays as before then example will work
gcloud run deploy server --image europe-west1-docker.pkg.dev/project-55c8f63e-66c7-41ab-998/myrepository/server:latest --platform managed --region europe-west1 --allow-unauthenticated --set-env-vars NGINX_LOG_LEVEL=info
gcloud run deploy client --image europe-west1-docker.pkg.dev/project-55c8f63e-66c7-41ab-998/myrepository/client:latest --platform managed --region europe-west1 --allow-unauthenticated --set-env-vars CLOUDURL=https://server-544873492758.europe-west1.run.app,NGINX_LOG_LEVEL=info