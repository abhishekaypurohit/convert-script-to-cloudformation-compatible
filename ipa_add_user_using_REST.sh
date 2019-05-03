#!/usr/bin/env bash


function uses() {

    echo "USES:

        $0
        --ipaserver=<fqdn of ipa server host, e.g. server.example.com>
        --adminuser=<ipa admin user name>
        --password=<ipa admin user's password>

        Below parameters are for the user getting added into IPA.

        --user_id=<unique user id of the user getting added>
        --user_firstname=<first name of the user>
        --user_lastname=<last name of the user>
        -v|--verbose - Prints all variables input.
        -h|--help - Prints this message
        
        This util adds a user into IPA with username and other details.
        "
}



function download_cert(){

    out="$(curl -k https://$IPASERVER/ipa/config/ca.crt >> $CACRT_LOCATION)"
    echo "Downloaded Cert:" $out

}


# Obtaining session cookie
function obtain_session() {

    out = "$(curl -v -H Referer:https://$IPASERVER/ipa \
                    -H "Content-Type:application/x-www-form-urlencoded"  \
                    -H "Accept:text/plain" \
                    -c $COOKIEJAR -b $COOKIEJAR \
                    --cacert $CACRT_LOCATION  \
                    --data "user=$ADMINUSER&password=$PASSWORD" \
                    -X POST  https://$IPASERVER/ipa/session/login_password)"
    # if running from client machine, above can be executed w/o user password, and with knint
    echo "Got Session Cookie stored:" $out
}

# Add User
function add_user() {
    out="$(curl -v \
             -H referer:https://$IPASERVER/ipa \
             -H "Content-Type:application/json" \
             -H "Accept:applicaton/json" \
             -c $COOKIEJAR -b $COOKIEJAR \
             --cacert $CACRT_LOCATION \
             -d '
             {
                "method":"user_add",
                "params":[
                    ["'$USERID'"],
                    { "givenname": "'$FNAME'", "krbprincipalname": "'$USERID'@'$REALM'", "sn": "'$LNAME'" }]
             }' \
             -X POST https://$IPASERVER/ipa/session/json)"
    echo "User Added:" $out

}


for i in "$@"
do
case $i in
    --ipaserver=*)
    ipa_server="${i#*=}"
    shift # past argument=value
    ;;
    --adminuser=*)
    admin_user="${i#*=}"
    shift # past argument=value
    ;;
    --password=*)
    passwd="${i#*=}"
    shift # past argument=value
    ;;
    --user_id=*)
    user_id="${i#*=}"
    shift # past argument=value
    ;;
    --user_firstname=*)
    user_firstname="${i#*=}"
    shift # past argument=value
    ;;
    --user_lastname=*)
    user_lastname="${i#*=}"
    shift # past argument=value
    ;;
    -v|--verbose)
    verbose="true"
    shift # past argument=value
    ;;
    -h|--help)
    help=true
    shift # past argument=value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done

[[ "$help" == "true" ]] && uses && exit 0;


IPASERVER=$ipa_server
ADMINUSER=$admin_user
PASSWORD=$passwd

USERID=$user_id
FNAME=$user_firstname
LNAME=$user_lastname

CACRT_LOCATION=/tmp/ipa.ca.crt
COOKIEJAR=/tmp/ipasession.cookie

IFS=. read host domain <<< "$IPASERVER"
REALM=$(echo $domain | awk '{print toupper($0)}')
[[ "$verbose" == "true" ]] && echo $REALM;






# If running from IPA client machine,  cacrt is stored at /etc/ipa/ca.crt
download_cert  # After above cert is stored under $CACRT location, now we can use –-cacert $CACRT

# Obtain Session
obtain_session



# Add User
add_user

