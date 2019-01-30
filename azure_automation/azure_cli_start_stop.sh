#!/bin/bash

if [ "$1" != "" ]; then
    echo "Positional parameter 1 contains something"
    echo $1
else
    echo "Positional parameter 1 is empty"
    exit 0
fi

az login --username estapar@azureopsdelphix.onmicrosoft.com --password Estapar

if [ "$1" == "stop" ]; then
echo "**** Going to stop Target Delphix Engine ****"

az vm deallocate --resource-group services-rg --name AZ-VDELPHIX

echo "**** stopped Target Delphix Engine ****"

elif [ "$1" == "start" ]; then

echo "**** Going to start Target Delphix Engine ****"

az vm start --resource-group services-rg --name AZ-VDELPHIX

echo "**** started Target Delphix Engine ****"

fi

echo "**** Logging out ****"

az logout --username estapar@azureopsdelphix.onmicrosoft.com

exit

