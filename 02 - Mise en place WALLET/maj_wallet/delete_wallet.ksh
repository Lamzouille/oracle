#!/bin/ksh
# Les lignes du fichier contenant les donnees à supprimer dans le wallet
# doivent avoir le format suivant :
# SERVER_NAME;ORACLE_SID;PORT;USER_NAME;PSW
# si le caractere separateur des champs du fichier est
CARSEP="\;"
if [ $# -eq 0 ]
then
        echo "Usage: $0 credential_file"
        return 1
fi
if [[ $(whoami) != "oracle" ]]
then
        echo "ERREUR : l'utilisateur autorise a lancer ce script est oracle !"
        return 1
fi
echo "\n------------ VERSION 7.0.2 DE SGE ------------"
echo "------------ suppression credential wallet ------------"
credential_file="$1"
if [ ! -f "${credential_file}" ]
then
        echo "Le fichier credential_file ${credential_file} n'existe pas"
        return 1
fi


read wallet_name?"-- Nom du wallet (default wallet_OSEP): "
if [ ${#wallet_name} -eq 0 ]
then
        wallet_name="wallet_OSEP"
fi
#read refbase?"-- Nom(SID) de la base de donnees affaires: "
echo "-- Mot de passe du wallet ${wallet_name} (default wallet_OSEP): \c"
stty -echo
read wallet_psw
if [ ${#wallet_psw} -eq 0 ]
then
        wallet_psw="wallet_OSEP"
fi
echo ${wallet_psw} >/tmp/mdp
stty echo
echo "\nSuppression du ${wallet_name} des credentials definis dans le fichier ${credential_file}"
# boucle de lecture du fichier ${credential_file}
while IFS="${CARSEP}" read SERVER_NAME ORACLE_SID PORT USER_NAME PSW
do
        echo "Suppression du ${wallet_name} du credential pour l'alias ${ORACLE_SID}_${USER_NAME}"
        ${ORACLE_HOME}/bin/mkstore -wrl /home/oracle/network/${wallet_name} -deleteCredential "${ORACLE_SID}_${USER_NAME}" </tmp/mdp
        cr=$?
        if [ $cr != 0 ]
        then
                echo "ERREUR : Suppression du wallet ${wallet_name} du credential ${ORACLE_SID}_${USER_NAME} KO"
                echo "Rends le fichier cwallet.sso lisisble aux membres du groupe dba(sgedev)"
                chmod g+r /home/oracle/network/${wallet_name}/cwallet.sso
#               rm /tmp/mdp
                return 1
        fi
done< "${credential_file}"
#rm /tmp/mdp
echo " Suppression du ${wallet_name} des credentials du fichier ${credential_file} OK"

echo "Rends le fichier cwallet.sso lisisble aux membres du groupe dba(sgedev)"
chmod g+r /home/oracle/network/${wallet_name}/cwallet.sso

echo "\nSuppression des lignes du tnsnames.ora a partir des informations du fichier ${credential_file}"
unset SERVER_NAME
unset ORACLE_SID
unset PORT
unset USER_NAME
unset PSW
#sauvegarde du fichier tnsnames.ora avant modification
cp ${TNS_ADMIN}/tnsnames.ora ${TNS_ADMIN}/tnsnames.ora.`date +%Y%m%d%H%M%S`
cr=$?
if [ $cr != 0 ]
then
        echo "Sauvegarde du fichier tnsnames.ora KO"$
        echo "\nMise a jour du tnsnames.ora avec les informations du fichier ${credential_file} non effectuee"
        return 1
fi

# boucle de lecture du fichier ${credential_file}
while IFS="${CARSEP}" read SERVER_NAME ORACLE_SID PORT USER_NAME PSW
do
        cp ${TNS_ADMIN}/tnsnames.ora /tmp/tnsnames.ora.tmp
        sed "/^${ORACLE_SID}_${USER_NAME}/d" /tmp/tnsnames.ora.tmp >${TNS_ADMIN}/tnsnames.ora
done< "${credential_file}"
#rm /tmp/tnsnames.ora.tmp
echo "\nSuppression des lignes du tnsnames.ora a partir des informations du fichier ${credential_file} OK"

				