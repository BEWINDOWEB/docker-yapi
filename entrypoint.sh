#!/bin/bash

EMPTY_CONFIG="EMPTY_CONFIG"

replaceFileContent() {
  file="$1"
  str="$2"
  default_val="$3"
  if [ ${default_val} == ${EMPTY_CONFIG} ];then
    default_val=""
  fi
  new_val="$4"
  
  val=${new_val:-${default_val}}
  if [ ${val} == ${default_val} ];then
    echo ${str}=${val}"(default config)"
  else 
    echo ${str}=${val}
  fi
  
  sed -i -e 's/'"${str}"'/'"${val}"'/' ${file}
}

setConfig() {
  replaceFileContent "../config.json" "$1" "$2" "$3"
}

# base config
setConfig YAPI_PORT 9233 ${YAPI_PORT}
setConfig YAPI_ADMIN_ACCOUNT yapiAdmin@example.com ${YAPI_ADMIN_ACCOUNT}
setConfig YAPI_ADMIN_PASSWORD yapiAdminPassword ${YAPI_ADMIN_PASSWORD}
setConfig YAPI_CLOSE_REGISTER true ${YAPI_CLOSE_REGISTER}

# database
setConfig YAPI_DB_CONNECT_STRING ${EMPTY_CONFIG} ${YAPI_DB_CONNECT_STRING}
setConfig YAPI_DB_SERVER_NAME mongo ${YAPI_DB_SERVER_NAME}
setConfig YAPI_DB_DATABASE yapi ${YAPI_DB_DATABASE}
setConfig YAPI_DB_PORT 27017 ${YAPI_DB_PORT}
setConfig YAPI_DB_USER yapiDatabaseAdmin ${YAPI_DB_USER}
setConfig YAPI_DB_PASS 123456 ${YAPI_DB_PASS}
setConfig YAPI_DB_AUTH_SOURCE admin ${YAPI_DB_AUTH_SOURCE}

# opt: email
if [ "${YAPI_MAIL_ENABLE}" == "true" ];then
  setConfig YAPI_MAIL_ENABLE true
  setConfig YAPI_MAIL_HOST smtp.163.com ${YAPI_MAIL_HOST}
  setConfig YAPI_MAIL_PORT 465 ${YAPI_MAIL_PORT}
  setConfig YAPI_MAIL_FROM yapiMailSender@163.com ${YAPI_MAIL_FROM}
  setConfig YAPI_MAIL_AUTH_USER yapiMailAdmin@163.com ${YAPI_MAIL_AUTH_USER}
  setConfig YAPI_MAIL_AUTH_PASS yapiMailPassword ${YAPI_MAIL_AUTH_PASS}
else
  setConfig YAPI_MAIL_ENABLE false
  setConfig YAPI_MAIL_PORT 465
fi

# opt: ldap
if [ "${YAPI_LDAP_LOGIN_ENABLE}" == "true" ];then
  setConfig YAPI_LDAP_LOGIN_ENABLE true
  setConfig YAPI_LDAP_LOGIN_SERVER ldap://ldapServer:389 ${YAPI_LDAP_LOGIN_SERVER}
  setConfig YAPI_LDAP_LOGIN_BASE_DN ${EMPTY_CONFIG} ${YAPI_LDAP_LOGIN_BASE_DN}
  setConfig YAPI_LDAP_LOGIN_BIND_PASSWORD ${EMPTY_CONFIG} ${YAPI_LDAP_LOGIN_BIND_PASSWORD}
  setConfig YAPI_LDAP_LOGIN_SEARCH_DN dc=example,dc=com ${YAPI_LDAP_LOGIN_SEARCH_DN}
  setConfig YAPI_LDAP_LOGIN_SEARCH_STANDARD mail ${YAPI_LDAP_LOGIN_SEARCH_STANDARD}
  setConfig YAPI_LDAP_LOGIN_EMAIL_POSTFIX ${EMPTY_CONFIG} ${YAPI_LDAP_LOGIN_EMAIL_POSTFIX}
  setConfig YAPI_LDAP_LOGIN_EMAIL_KEY ${EMPTY_CONFIG} ${YAPI_LDAP_LOGIN_EMAIL_KEY}
  setConfig YAPI_LDAP_LOGIN_USERNAME_KEY ${EMPTY_CONFIG} ${YAPI_LDAP_LOGIN_USERNAME_KEY}
else
  setConfig YAPI_LDAP_LOGIN_ENABLE false
fi

# install
install() {
  npm install --production --registry https://registry.npm.taobao.org
  npm run install-server

  # opt:plugins
  if [ -n "${YAPI_PLUGINS}" ];then
    # set config
    TRANS_YAPI_PLUGINS=${YAPI_PLUGINS//\"/\\\"}
    TRANS_YAPI_PLUGINS=${TRANS_YAPI_PLUGINS//\./\\\.}
    TRANS_YAPI_PLUGINS=${TRANS_YAPI_PLUGINS//\//\\\/}
    setConfig "\[\]" "BAD_PLUGIN" "\[${TRANS_YAPI_PLUGINS}\]"

    # install plugin
    arr=(${YAPI_PLUGINS//\"/ })
    flag="-1" 
    for str in ${arr[@]}
    do
      if [ ${flag} == "1" ];then
        echo "install plugin ${str}..."
        cd ..
        which yapi
        yapi plugin --name yapi-plugin-${str}
        cd vendors
        pwd
        flag="-1"
      elif [ ${flag} == "0" ];then
        flag="1"
      elif [ ${str} == "name" ];then
        flag="0"
      fi
    done
  fi
}

if [ ! -e "../init.lock" ];then
  echo "[First Install] install server with config file..."
  install
else
  YAPI_MODE=${YAPI_MODE:-DEFAULT}
  if [ ${YAPI_MODE} == "REINSTALL" ];then
    echo "[${YAPI_MODE} MODE] remove lock, clean database, reinstall server with config file..."
    rm -rf ../init.lock
    install
  else
    "[${YAPI_MODE} MODE] restart yapi with no changes."
  fi
fi

# running
echo "try to run yapi..."
node server/app.js
