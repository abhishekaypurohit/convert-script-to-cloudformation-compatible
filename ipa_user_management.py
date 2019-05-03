#!/usr/bin/env python2

import httplib

import requests
from python_freeipa import Client

"""
This file consists of methods related to User Management related to IPA. This script utilizes the APIs exposed from FreeIPA
"""

IPA_SERVER_HOST = "server.cldr.site"
IPA_SERVER_IPADDR = ""
IPA_ADMIN_USER = "admin"
IPA_ADMIN_PASSWORD = "asdQWE123"
IPA_REST_API_URL = "https://server.cldr.site/ipa"
IPA_API_VERSION = "2.215"
IPA_CA_CERT_FILE = ""

OBTAIN_SESSION_REQ_DATA = """

 
"""
USER_ADD_REQ_DATA = """
{}
"""

cookies = {
}


def get_ipa_cert():
    """
    Gets the cert file from IPA Server.
    :return:
    """
    global IPA_CA_CERT_FILE
    conn = httplib.HTTPConnection(IPA_SERVER_HOST)
    conn.putrequest('GET', '/ipa/config/ca.crt')
    conn.endheaders()
    res = conn.getresponse()
    cert = res.read()

    print("cert Response={}".format(cert))

    # store cert
    IPA_CA_CERT_FILE = '/tmp/{}_ca.crt'.format(IPA_SERVER_HOST)

    with open(IPA_CA_CERT_FILE, 'a') as ca_cert_file:
        ca_cert_file.write(cert)

    return cert


def obtain_session(user_name, password):
    """

    :param user_name:
    :param password:
    :return:
    """
    headers = {
        'Referer': 'https://{}/ipa'.format(IPA_SERVER_HOST),
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'text/plain',
    }

    data = {
        'user': '{}'.format(IPA_ADMIN_USER),
        'password': '{}'.format(IPA_ADMIN_PASSWORD)
    }

    res = requests.request("POST", IPA_REST_API_URL, headers=headers, data=data, cert=(IPA_CA_CERT_FILE))
    print("Response={}".format(res))


def add_user(user_name, first_name, last_name):
    print("Adding User into IPA")

    client = Client(IPA_SERVER_HOST, version='2.215')
    client.login(IPA_ADMIN_USER, IPA_ADMIN_PASSWORD)
    user = client.user_add(user_name, first_name, last_name, "{} {}".format(first_name, last_name))
    print user


get_ipa_cert()
obtain_session("admin", "asdQWE123")
# add_user("mpandey", "Manish", "Pandey")
