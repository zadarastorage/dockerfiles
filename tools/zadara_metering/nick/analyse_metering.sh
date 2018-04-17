#!/bin/bash 

getinfo()
{
  read -p "Enter the API access key: " api_access_key
  read -p "Enter the VPSA's FQDN (e.g. vsa-00000015-uk-lon-01.zadaravpsa.com): " vpsa_address
  read -p "Enter the VPSA name: " vpsa_name
}

writerunfile()
{
sed -i 's/^access_key=.*$/access_key='${api_access_key}'/g' /home/ubuntu/metering/run.sh
sed -i 's/^vpsa_address=.*$/vpsa_address='${vpsa_address}'/g' /home/ubuntu/metering/run.sh
sed -i 's/^vpsa_name=.*$/vpsa_name='${vpsa_name}'/g' /home/ubuntu/metering/run.sh

  echo ""
  echo "Your informaton was saved in '$1'."
  echo ""
#  exit 0
}

file="/home/ubuntu/metering/run.sh"
if [ ! -f $file ]; then
  echo ""
  echo "The file '$file' doesn't exist!"
  echo ""
  exit 1
fi

clear
echo "Let's pull the metering db and import to Influx/Grafana..."
echo ""

getinfo
echo ""
echo "Settings confirmation:"
echo "API Access Key:	$api_access_key"
echo "VPSA's FQDN:	$vpsa_address"
echo "VPSA name:	$vpsa_name"
echo ""

while true; do
  read -p "Is this correct? [y/n]: " yn
  case $yn in
    [Yy] ) #writerunfile $file
           break;;
    [Nn] ) getinfo;;
        * ) echo "Please enter y or n!";;
  esac
done

cd /home/ubuntu/metering
./run.sh "${api_access_key}" "${vpsa_address}" "${vpsa_name}"
