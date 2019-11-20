#!/bin/bash
set -e
echo "***** Installing LDAP Server *****"
echo " "
  docker run -d -p 389:389 --name ldapServer -t larrycai/openldap

echo "***** Checking if the container is running *****"
echo " "
for (( c=1; c<=5; c++ ))
do
  DOCKER_RUN=$(docker inspect -f '{{.State.Status}}' ldapServer)
  if [ "${DOCKER_RUN}" = "running" ]; then
    echo "***** LDAP Server Running *****"
    break
  fi
  sleep 2;
done
sleep 2;

echo "***** Creating defaults organizational Units *****"
echo " "
cat <<EOF > ouOrganization.ldif
dn: ou=Organization,dc=openstack,dc=org
objectClass: top
objectClass: organizationalUnit
ou: Organization
EOF
ldapadd -x -h "127.0.0.1" -p 389 -D "cn=admin,dc=openstack,dc=org" -w "password" -f ouOrganization.ldif
sleep 1;
rm ouOrganization.ldif;

cat <<EOF > ouUsers.ldif
dn: ou=Users,ou=Organization,dc=openstack,dc=org
objectClass: top
objectClass: organizationalUnit
ou: Users
EOF
ldapadd -x -h "127.0.0.1" -p 389 -D "cn=admin,dc=openstack,dc=org" -w "password" -f ouUsers.ldif
sleep 1;
rm ouUsers.ldif;

cat <<EOF > ouGroups.ldif
dn: ou=Groups,ou=Organization,dc=openstack,dc=org
objectClass: top
objectClass: organizationalUnit
ou: Groups
EOF
ldapadd -x -h "127.0.0.1" -p 389 -D "cn=admin,dc=openstack,dc=org" -w "password" -f ouGroups.ldif
sleep 1;
rm ouGroups.ldif;

LDAP_USERS_NUM=0;
while [ "$LDAP_USERS_NUM" -lt 3 ] || [ -z $LDAP_USERS_NUM ]; do
  read -p "How many Users (minimum 4)? : " LDAP_USERS_NUM
done
echo " "
read -p "How many Groups? : " LDAP_GROUPS_NUM

if (("$LDAP_USERS_NUM" > 3)); then
  for i in `seq $LDAP_USERS_NUM $1`;
    do
cat <<EOF > member$i.ldif
version: 1

dn: cn=User$i,ou=Users,ou=Organization,dc=openstack,dc=org
objectClass: inetOrgPerson
cn: user$i
sn: name$i
description: created by script
mail: user$i@org.com
uid: user$i
userPassword:: cGFzc3dvcmQ=
EOF
ldapadd -x -h "127.0.0.1" -p 389 -D "cn=admin,dc=openstack,dc=org" -w "password" -f member$i.ldif
done
rm member*
fi


if [ ! -z $LDAP_GROUPS_NUM ]; then
  for i in `seq $LDAP_GROUPS_NUM $1`;
    do
cat <<EOF > group$i.ldif
dn: cn=group$i,ou=Groups,ou=Organization,dc=openstack,dc=org
objectClass: groupOfNames
objectClass: top
cn: group$i
member: uid=user1,ou=Users,ou=Organization,dc=openstack,dc=org
member: uid=user2,ou=Users,ou=Organization,dc=openstack,dc=org
member: uid=user3,ou=Users,ou=Organization,dc=openstack,dc=org
EOF
ldapadd -x -h "127.0.0.1" -p 389 -D "cn=admin,dc=openstack,dc=org" -w "password" -f group$i.ldif
done
rm group*
fi

echo "***** DONE LDAP Server is ready *****"
echo " "
echo " "

echo "In case would like to integrate LDAP with Artifacctory, you may add the following snippet to Artifactory's Config Desctiptor for quick configuration {change the server name (localhost) accordingly}"
echo " "
echo " "
echo " LDAP Settings:"
echo " "
cat << EOF
<ldapSetting>
<key>openldap</key>
<enabled>true</enabled>
<ldapUrl>ldap://localhost:389/dc=openstack,dc=org</ldapUrl>
<userDnPattern></userDnPattern>
<search>
<searchFilter>uid={0}</searchFilter>
<searchSubTree>true</searchSubTree>
<managerDn>cn=admin,dc=openstack,dc=org</managerDn>
<managerPassword>password</managerPassword>
</search>
<autoCreateUser>false</autoCreateUser>
<emailAttribute>mail</emailAttribute>
<ldapPoisoningProtection>true</ldapPoisoningProtection>
<allowUserToAccessProfile>true</allowUserToAccessProfile>
</ldapSetting>
EOF
echo " "
echo " "
echo " LDAP Group Settings:"
echo " "
cat << EOF
<ldapGroupSetting>
<name>openldap-groups</name>
<groupBaseDn></groupBaseDn>
<groupNameAttribute>cn</groupNameAttribute>
<groupMemberAttribute>member</groupMemberAttribute>
<subTree>true</subTree>
<filter>(objectClass=groupOfNames)</filter>
<descriptionAttribute>description</descriptionAttribute>
<strategy>STATIC</strategy>
<enabledLdap>openldap</enabledLdap>
</ldapGroupSetting>
EOF
