#!/bin/bash

APOCTL=/tmp/apoctl

usage () {
cat << EOF
USAGE:
$0
	-a <API Gateway>
	-n <Prisma Cloud Namespace>
	-u <API Key>
	-p <API Secret>
EOF
}

while getopts a:n:u:p:h FLAG
do
	case "${FLAG}" in
		a) API=${OPTARG};;
		n) NAMESPACE=${OPTARG};;
		u) USER=${OPTARG};;
		p) PASSWORD=${OPTARG};;
		h) usage; exit;;
		\?) echo "Unknown option: -$OPTARG" >&2; exit 1;;
		:) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
		*) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
	esac
done

shift "$(( OPTIND - 1 ))"

if [ -z "$API" ] || [ -z "$NAMESPACE" ] || [ -z "$USER" ] || [ -z "$PASSWORD" ]; then
	usage; exit;
fi

if ! command -v jq &> /dev/null
then
	echo "The command \"jq\" could not be found"
	exit
fi

DATA={\"username\":\"${USER}\",\"password\":\"${PASSWORD}\"}
RESPONSE=`echo $DATA | curl -s --request POST   --url https://api.prismacloud.io/login   --header 'content-type: application/json; charset=UTF-8' --data-binary @-`
STATUS=`echo ${RESPONSE} | jq -r .message`
if [ ${STATUS} != 'login_successful' ]
then
	echo "Invalid credentials"
	exit
fi

PCTOKEN=`echo ${RESPONSE} | jq -r .token`
curl -s -o $APOCTL "https://download.aporeto.com/prismacloud/app2/apoctl/$(uname | tr '[:upper:]' '[:lower:]')/apoctl"
chmod 755 $APOCTL

MTOKEN=`${APOCTL} -A ${API} auth pc-token --token ${PCTOKEN}`
if [ $? -ne 0 ]
then
	echo "Error accessing microsegmentation API"
	exit
fi

RESULT=`${APOCTL} -A ${API} -n ${NAMESPACE} -t ${MTOKEN} api ls namespaces`
if [ $? -ne 0 ]
then
	echo "Error accessing namespace: ${NAMESPACE}"
	exit
fi

echo ${APOCTL} enforcer install linux --auth-mode appcred -A ${API} -n ${NAMESPACE} -t ${MTOKEN} --confirm
