#!/bin/bash

# Vérification des paramètres
if [ "$#" -ne 1 ]; then
 echo "Usage: $0 <nom_de_la_vm>"
 exit 1
fi

#Déclaration des variables
VM_NAME=$1
IMAGE="Alpine321"
FLAVOR="srv"
NETWORK="LAN-LABO"
USER_DATA="/var/snap/microstack/common/var/user-init.yaml"
CONFIG_DRIVE="true"
FLOATING_IP="10.20.20.144"

shopt -s expand_aliases
alias openstack='sudo microstack.openstack'

# Vérifie si la VM existe déjà
if openstack server list | grep -q "$VM_NAME"; then
 echo "La VM existe déjà !"
 exit 0
fi

# Création de la VM
openstack server create  "$VM_NAME" \
 --image "$IMAGE" \
 --flavor "$FLAVOR" \
 --network "$NETWORK" \
 --user-data "$USER_DATA" \
 --config-drive "$CONFIG_DRIVE"


# Attente que la VM soit active et récupération de l'IP
echo "Attente que la VM $VM_NAME passe en statut ACTIVE..."

MAX_RETRIES=12
SLEEP_SECONDS=3

for i in $(seq 1 $MAX_RETRIES);do 
	STATUS=$(openstack server show "$VM_NAME" -f value -c status 2>/dev/null || echo "UNKNOWN")

	echo "Statut actuel : $STATUS (tentative $i/$MAX_RETRIES)"
	if [ "$STATUS" = "ACTIVE" ]; then
		echo "La VM est ACTIVE."
		break
	fi

	if [ "$STATUS" = "ERROR" ]; then
		echo "La VM est en état ERROR, arrêt du script."
		exit 1 
	fi 

	sleep "$SLEEP_SECONDS" 

done

if [ "$STATUS" != "ACTIVE" ]; then
	echo "La VM n'est jamais passée en ACTIVE."
	exit 1
fi


IP=$(openstack server show "$VM_NAME" -f json \ | jq -r '.addresses '| cut -d= -f2)
echo "La VM $VM_NAME est déployée avec IP interne: $IP"

#Rattacher la floating IP d'exploitation
openstack server add floating ip "$VM_NAME" "$FLOATING_IP"

allIP=$(openstack server show "$VM_NAME" -f json \ | jq -r '.addresses '| cut -d= -f2)
echo "La VM $VM_NAME est déployée avec les IP : $allIP"

echo "ip=$FLOATING_IP" >> "$GITHUB_OUTPUT"