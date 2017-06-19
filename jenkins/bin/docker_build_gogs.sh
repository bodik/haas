docker pull gogs/gogs
mkdir -p /var/gogs
docker run --name=gogs -p 10022:22 -p 10080:3000 -v /var/gogs:/data gogs/gogs
docker start gogs
