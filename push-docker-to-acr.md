# Push images to Azure container Registry (ACR)

#### Install docker using : https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe

#### Check docker is successfully installed
```
docker network ls
```

#### Install az cli if not present using : 
```
https://aka.ms/installazurecliwindows
```

#### Pull Docker image
```
docker pull princepereira/tcp-client-server:latest
```

#### Login to azure container registry (ACR)
```
az acr login --name <registry-name>
```
 
#### Tag the image with ACR repo
```
docker tag princepereira/tcp-client-server:latest <login-server>/tcp-client-server:latest
```

#### Push the image to ACR
```
docker push <login-server>/tcp-client-server:latest
```
