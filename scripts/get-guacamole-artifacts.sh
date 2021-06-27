#!/bin/sh -e

##
## @fn get-guacamole-artifacts.sh
##
## Downloads the pre-built Guacamole client and extensions of the given version
## from the Apache CDN [https://apache.org/dyn/closer.lua/guacamole/x.y.z/...].
##
## @param GUACAMOLE_VERSION
##     The version of Guacamole to download. This must match a published
##     version directory at https://downloads.apache.org/guacamole/
##
## @param DESTINATION
##     The location on disk in which to build the Guacamole client structure.
##     Typcially this is /opt/guacamole.

GUACAMOLE_VERSION="$1"
DESTINATION="$2"

##
## Prints usage information for this shell script and exits with an error code.
## Calling this function will immediately terminate execution of the script.
##
incorrect_usage() {
    cat <<END
USAGE: get-guacamole-artifacts.sh <version> <destination>
END
    exit 1
}

# Validate parameters
if [ "$#" -ne 2 ]; then
    echo "Wrong number of arguments."
    incorrect_usage
fi

#
# Create destination, if it does not yet exist
#
mkdir -p "$DESTINATION"
mkdir -p "$DESTINATION/downloads"

#
# Using the backup Apache mirror as a master list, download all of the available packages for this version of Guacamole
#
echo "Gathering list of packages to download ..."
for p in $(curl -sL "https://downloads.apache.org/guacamole/${GUACAMOLE_VERSION}/binary/" | grep -oP '(?<=href=")guacamole-.+(\.war|\.tar\.gz)(?=">)'); do
    echo "Downloading ${p}..."
    curl -sL "https://apache.org/dyn/closer.lua/guacamole/$GUACAMOLE_VERSION/binary/$p?action=download" --output "$DESTINATION/downloads/$p"
done

# Also get the source code (for the init scripts)
for p in $(curl -sL "https://downloads.apache.org/guacamole/${GUACAMOLE_VERSION}/source/" | grep -oP '(?<=href=")guacamole-client-.+\.tar\.gz(?=">)'); do
    echo "Downloading ${p}..."
    curl -sL "https://apache.org/dyn/closer.lua/guacamole/$GUACAMOLE_VERSION/source/$p?action=download" --output "$DESTINATION/downloads/$p"
done

#
# Move guacamole.war to destination
#
echo "Moving Guacamole Client ..."
mv "$DESTINATION/downloads/guacamole-$GUACAMOLE_VERSION.war" "$DESTINATION/guacamole.war"

#
# Extract the init scripts
# NOTE: This presumes that the guacamole-client directory structure will remain static (at least as far as the docker init scripts)
#
if [ -f $DESTINATION/downloads/guacamole-client*.tar.gz ]; then
    echo "Moving init scripts ..."
    mkdir -p "$DESTINATION/bin"
    tar -xzf $DESTINATION/downloads/guacamole-client*.tar.gz \
        -C "$DESTINATION/bin/"                               \
        --wildcards                                          \
        --no-anchored                                        \
        --strip-components=3                                 \
        "*.sh"
    rm $DESTINATION/downloads/guacamole-client*.tar.gz
fi

#
# Extract JDBC auth extensions and SQL scripts
#
if [ -f $DESTINATION/downloads/guacamole-auth-jdbc*.tar.gz ]; then
    echo "Extracting JDBC auth extension ..."
    tar -xzf $DESTINATION/downloads/guacamole-auth-jdbc*.tar.gz \
        -C "$DESTINATION"                                       \
        --wildcards                                             \
        --no-anchored                                           \
        --strip-components=1                                    \
        "*.jar"                                                 \
        "*.sql"
    rm $DESTINATION/downloads/guacamole-auth-jdbc*.tar.gz
fi

#
# Download MySQL JDBC driver
#
echo "Downloading MySQL Connector/J ..."
curl -sL "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz" | \
tar -xzf -                     \
    -C "$DESTINATION/mysql/"   \
    --wildcards                \
    --no-anchored              \
    --no-wildcards-match-slash \
    --strip-components=1       \
    "mysql-connector-*.jar"

#
# Download PostgreSQL JDBC driver
#
echo "Downloading PostgreSQL JDBC driver ..."
curl -sL "https://jdbc.postgresql.org/download/postgresql-9.4-1201.jdbc41.jar" > "$DESTINATION/postgresql/postgresql-9.4-1201.jdbc41.jar"

#
# Extract LDAP auth extension and schema modifications
#
if [ -f $DESTINATION/downloads/guacamole-auth-ldap*.tar.gz ]; then
    echo "Extracting LDAP auth extension ..."
    mkdir -p "$DESTINATION/ldap"
    tar -xzf $DESTINATION/downloads/guacamole-auth-ldap*.tar.gz \
        -C "$DESTINATION/ldap"                                  \
        --wildcards                                             \
        --no-anchored                                           \
        --xform="s#.*/##"                                       \
        "*.jar"                                                 \
        "*.ldif"
    rm $DESTINATION/downloads/guacamole-auth-ldap*.tar.gz
fi

#
# Extract OPENID auth extension
#
if [ -f $DESTINATION/downloads/guacamole-auth-openid*.tar.gz ]; then
    echo "Extracting OpenID auth extension ..."
    mkdir -p "$DESTINATION/openid"
    tar -xzf $DESTINATION/downloads/guacamole-auth-openid*.tar.gz \
        -C "$DESTINATION/openid"                                  \
        --wildcards                                               \
        --no-anchored                                             \
        --no-wildcards-match-slash                                \
        --strip-components=1                                      \
        "*.jar"
    rm $DESTINATION/downloads/guacamole-auth-openid*.tar.gz
fi

#
# Extract header auth extension
#
if [ -f $DESTINATION/downloads/guacamole-auth-header*.tar.gz ]; then
    echo "Extracting Header auth extension ..."
    mkdir -p "$DESTINATION/header"
    tar -xzf $DESTINATION/downloads/guacamole-auth-header*.tar.gz \
        -C "$DESTINATION/header/"                                 \
        --wildcards                                               \
        --no-anchored                                             \
        --no-wildcards-match-slash                                \
        --strip-components=1                                      \
        "*.jar"
    rm $DESTINATION/downloads/guacamole-auth-header*.tar.gz
fi

#
# Extract CAS auth extension
#
if [ -f $DESTINATION/downloads/guacamole-auth-cas*.tar.gz ]; then
    echo "Extracting CAS auth extension ..."
    mkdir -p "$DESTINATION/cas"
    tar -xzf $DESTINATION/downloads/guacamole-auth-cas*.tar.gz \
        -C "$DESTINATION/cas/"                                 \
        --wildcards                                            \
        --no-anchored                                          \
        --no-wildcards-match-slash                             \
        --strip-components=1                                   \
        "*.jar"
    rm $DESTINATION/downloads/guacamole-auth-cas*.tar.gz
fi

#
# Extract TOTP auth extension
#
if [ -f $DESTINATION/downloads/guacamole-auth-totp*.tar.gz ]; then
    echo "Extracting TOTP auth extension ..."
    mkdir -p "$DESTINATION/totp"
    tar -xzf $DESTINATION/downloads/guacamole-auth-totp*.tar.gz \
        -C "$DESTINATION/totp/"                                 \
        --wildcards                                             \
        --no-anchored                                           \
        --no-wildcards-match-slash                              \
        --strip-components=1                                    \
        "*.jar"
    rm $DESTINATION/downloads/guacamole-auth-totp*.tar.gz
fi

#
# Extract Duo auth extension
#
if [ -f $DESTINATION/downloads/guacamole-auth-duo*.tar.gz ]; then
    echo "Extracting Duo auth extension ..."
    mkdir -p "$DESTINATION/duo"
    tar -xzf $DESTINATION/downloads/guacamole-auth-duo*.tar.gz \
        -C "$DESTINATION/duo/"                                 \
        --wildcards                                            \
        --no-anchored                                          \
        --no-wildcards-match-slash                             \
        --strip-components=1                                   \
        "*.jar"
    rm $DESTINATION/downloads/guacamole-auth-duo*.tar.gz
fi

#
# Extract Quickconnect auth extension
#
if [ -f $DESTINATION/downloads/guacamole-auth-quickconnect*.tar.gz ]; then
    echo "Extracting QuickConnect auth extension ..."
    mkdir -p "$DESTINATION/quickconnect"
    tar -xzf $DESTINATION/downloads/guacamole-auth-quickconnect*.tar.gz \
        -C "$DESTINATION/quickconnect/"                                 \
        --wildcards                                                     \
        --no-anchored                                                   \
        --no-wildcards-match-slash                                      \
        --strip-components=1                                            \
        "*.jar"
    rm $DESTINATION/downloads/guacamole-auth-quickconnect*.tar.gz
fi

#
# Extract SAML auth extension
#
if [ -f $DESTINATION/downloads/guacamole-auth-saml*.tar.gz ]; then
    echo "Extracting SAML auth extension ..."
    mkdir -p "$DESTINATION/saml"
    tar -xzf $DESTINATION/downloads/guacamole-auth-saml*.tar.gz \
        -C "$DESTINATION/saml/"                                 \
        --wildcards                                             \
        --no-anchored                                           \
        --no-wildcards-match-slash                              \
        --strip-components=1                                    \
        "*.jar"
    rm $DESTINATION/downloads/guacamole-auth-saml*.tar.gz
fi

#
# Make sure there's nothing left in the downloads directory
#
if [ -f $DESTINATION/downloads/* ]; then
    echo "WARNING! Downloads directory still contains packages:"
    ls -1
    echo "You must remove the extra downloads and the directory manually."
else
    rm -rf $DESTINATION/downloads
    echo "Done."
fi
