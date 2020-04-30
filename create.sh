#!/bin/bash
#Absolute path to this script
SCRIPT=$(readlink -f $0)
#Absolute path this script is in
SCRIPTPATH=$(dirname $SCRIPT)
STACK=$(basename "$SCRIPTPATH")
export RUN_DIRECTORY="/usr/local/docker-mounted-files/${STACK}"
cd "$SCRIPTPATH"

sudo docker-compose down
sudo rm -rf "${RUN_DIRECTORY}"
sudo mkdir -p "${RUN_DIRECTORY}"
sudo chmod a+rx "${RUN_DIRECTORY}"

cd "${RUN_DIRECTORY}"
test -z $1 || HOST="_$1"
test -z $2 || INSTANCE="_$2"
test -z $KEY && { echo "KEY is not defined."; exit 1; }

if ! test -f ~/secrets.tar.gz.enc
then
    curl -o ~/secrets.tar.gz.enc "https://cloud.scimetis.net/s/${KEY}/download?path=%2F&files=secrets.tar.gz.enc"
    if ! test -f ~/secrets.tar.gz.enc
    then
        echo "ERROR: ~/secrets.tar.gz.enc not found, exiting."
        exit 1
    fi
fi

openssl enc -aes-256-cbc -d -in ~/secrets.tar.gz.enc \
| sudo tar -zxv --strip 2 secrets/docker-boursorama-scraping-stack${HOST}${INSTANCE}/conf.yml \
|| { echo "Could not extract from secrets archive, exiting."; rm -f ~/secrets.tar.gz.enc; exit 1; }
sudo chown root. conf.yml 

cd "$SCRIPTPATH"
for NETWORK in stocknet
do
    sudo docker network inspect ${NETWORK} &> /dev/null && continue
    sudo docker network create ${NETWORK}
    sudo docker network inspect ${NETWORK} &> /dev/null || \
    { echo "ERROR: could not create network ${NETWORK}, exiting."; exit 1; }
done

unset VERSION_BOURSORAMA_SCRAPING
export VERSION_BOURSORAMA_SCRAPING=$(git ls-remote https://git.scimetis.net/yohan/docker-boursorama-scraping.git| head -1 | cut -f 1|cut -c -10)

mkdir -p ~/build
git clone https://git.scimetis.net/yohan/docker-boursorama-scraping.git ~/build/docker-boursorama-scraping
sudo docker build -t boursorama-scraping:$VERSION_BOURSORAMA_SCRAPING ~/build/docker-boursorama-scraping

sudo -E bash -c 'docker-compose up --no-start --force-recreate'

rm -rf ~/build
