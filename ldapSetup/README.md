# Prerequisites:

1. Docker installed
2. OpenLDAP tools installed

# Description:

This script spin up an OpenLDAP Docker container by running the [“larrycai/openldap”](https://hub.docker.com/r/larrycai/openldap/) image.
Once the container is running, three default OUs will be created, the first named “**Organization**” and under this OU also “**Users**” and “**Groups**” will be created.

The script will ask how many users and groups you would like to create and will create them accordingly.
The users and groups  by the following will create as the following “**userN**” and “**groupN**” while **N** represents the number. 
- For example if you choose to create 3 users they will be created under “Users” OU as the following:
```
user1
user2
user3
```
- Similar to the above, groups will be created under “Groups” OU as the following (in case creating 3 groups):
```
group1
group2
group3
```
**Each group created will include “user1”, “user2” and “user3” as members.**

###### Default credentials:
The credentials for all users created by the script is the username and the password “password”.

## integration to Artifactory
At the end of the script you will get a snippet that can be added to Artifactory’s config descriptor for quick integration.
