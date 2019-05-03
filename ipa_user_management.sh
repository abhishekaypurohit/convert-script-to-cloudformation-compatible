#!/usr/bin/env bash


function uses() {

    echo "USES:

        $0
        --ipaserver=<fqdn of ipa server host, e.g. server.example.com>
        --adminuser=<ipa admin user name>
        --password=<ipa admin user's password>
        --operation=<operation for IPA> This can be one of the below:

            =user-add

                --user_id=<unique user id of the user getting added>
                --user_firstname=<first name of the user>
                --user_lastname=<last name of the user>

            =user-del
                --user_id=<user to be deleted>

            =user-change-password
                --user_id=<user id for which password is geting changed>
                --new-password=password

            =user-change-add-group
                --user_id=<user id>
                --group_name=<group where this user should be added to>
            =group-add
                --group-name=<name of the group to be added>


        -v|--verbose - Prints all variables input.
        -h|--help - Prints this message
        
        This util adds a user into IPA with username and other details.
        "
}




# Add User
function add_user() {
    out="$(echo $password | kinit $$ADMINUSER )"

    out="$(ipa user-add $USERID --first=$FNAME --last=$LNAME --cn=\"$FNAME $LNAME\" )"

    echo "User Added:" $out

}


# del user
function del_user(){
    out="$(echo $password | kinit $ADMINUSER )"

    out="$(ipa user-del $USERID)"

    out="$(ipa user-del $USERID --first=$FNAME --last=$LNAME --cn=\"$FNAME $LNAME\" )"

    echo "User's Password updated:" $out


}

# change user passoword
function user_change_password(){
    out="$(echo $password | kinit $ADMINUSER )"

    out="$(printf \"$USERPASSWORD\n$USERPASSWORD\" | ipa passwd $USER)"

    echo "User's Password updated:" $out

}

# user group assign
function user_add_group(){
    out="$(echo $password | kinit $ADMINUSER )"

    out="$(ipa group-add-member $GROUPNAME --users=$USER)"

    echo "User's group updated:" $out

}

# group add
function group_add(){
    out="$(echo $password | kinit $ADMINUSER )"

    out="$(ipa group-add $GROUPNAME)"

    echo "Group Added:" $out

}

#
#        --ipaserver=<fqdn of ipa server host, e.g. server.example.com>
#        --adminuser=<ipa admin user name>
#        --password=<ipa admin user's password>
#        --user-add
#
#            Below parameters are for the user getting added into IPA.
#
#            --user_id=<unique user id of the user getting added>
#            --user_firstname=<first name of the user>
#            --user_lastname=<last name of the user>
#
#        --user-del
#            --user_id=<user to be deleted>
#
#        --user-change-password
#            --user_id=<user id for which password is geeting changed>
#            --old-password
#            --new-password
#
#        --user-change-add-group
#            --user_id=<user id for which password is geeting changed>
#            --group_name=<group where this user should be added to>
#        --group-add
#            --group-name
#
#
#        -v|--verbose - Prints all variables input.
#        -h|--help - Prints this message


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
    --user-add=*)
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
USERPASSWORD=$user_password
GROUPNAME=""

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

