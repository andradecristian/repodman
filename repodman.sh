#!/bin/bash

function initia_lization () {
mkdir -p /var/rhelrepo
mkdir -p /root/repodman/updt
cat > /root/repodman/updt/update_rhel6.sh << 'EOF'
#!/bin/bash
yum install -y yum-utils createrepo

###UPDATES
yum-config-manager --enable rhel-6-server-rpms
reposync --gpgcheck -l --repoid=rhel-6-server-rpms --download_path=/repodata --downloadcomps --download-metadata
cd /repodata/rhel-6-server-rpms
createrepo -v  /repodata/rhel-6-server-rpms -g comps.xml

###SUPPLEMENTARY
yum-config-manager --enable rhel-6-server-supplementary-rpms
reposync --gpgcheck -l --repoid=rhel-6-server-supplementary-rpms --download_path=/repodata --downloadcomps --download-metadata
cd /repodata/rhel-6-server-supplementary-rpms
createrepo -v  /repodata/rhel-6-server-supplementary-rpms -g comps.xml

###EXTRAS
yum-config-manager --enable rhel-6-server-extras-rpms
reposync --gpgcheck -l --repoid=rhel-6-server-extras-rpms --download_path=/repodata --downloadcomps --download-metadata
cd /repodata/rhel-6-server-extras-rpms
createrepo -v  /repodata/rhel-6-server-extras-rpms -g comps.xml
EOF
chmod 700 /root/repodman/updt/update_rhel6.sh

cat > /root/repodman/updt/update_rhel7.sh << 'EOF'
#!/bin/bash
yum install -y yum-utils createrepo
###UPDATES
yum-config-manager --enable rhel-7-server-rpms
reposync --gpgcheck -l --repoid=rhel-7-server-rpms --download_path=/repodata --downloadcomps --download-metadata
cd /repodata/rhel-7-server-rpms
createrepo -v  /repodata/rhel-7-server-rpms -g comps.xml

###SUPPLEMENTARY
yum-config-manager --enable rhel-7-server-supplementary-rpms
reposync --gpgcheck -l --repoid=rhel-7-server-supplementary-rpms --download_path=/repodata --downloadcomps --download-metadata
cd /repodata/rhel-7-server-supplementary-rpms
createrepo -v  /repodata/rhel-7-server-supplementary-rpms -g comps.xml

###EXTRAS
yum-config-manager --enable rhel-7-server-extras-rpms
reposync --gpgcheck -l --repoid=rhel-7-server-extras-rpms --download_path=/repodata --downloadcomps --download-metadata
cd /repodata/rhel-7-server-extras-rpms
createrepo -v  /repodata/rhel-7-server-extras-rpms -g comps.xml
EOF
chmod 700 /root/repodman/updt/update_rhel7.sh

cat > /root/repodman/updt/update_rhel8.sh << 'EOF'
#!/bin/bash
yum install -y yum-utils createrepo
###UPDATES
yum-config-manager --enable rhel-8-for-x86_64-baseos-rpms
reposync -p /repodata --download-metadata --repo=rhel-8-for-x86_64-baseos-rpms

###APPSTREAM
yum-config-manager --enable rhel-8-for-x86_64-appstream-rpms
reposync -p /repodata --download-metadata --repo=rhel-8-for-x86_64-appstream-rpms


###SUPPLEMENTARY
yum-config-manager --enable rhel-8-for-x86_64-supplementary-rpms
reposync -p /repodata --download-metadata --repo=rhel-8-for-x86_64-supplementary-rpms
EOF
chmod 700 /root/repodman/updt/update_rhel8.sh

podman pull registry.access.redhat.com/ubi8:latest
podman pull registry.access.redhat.com/ubi7:latest
podman pull registry.access.redhat.com/rhel6/rhel:latest

podman tag registry.access.redhat.com/rhel6/rhel:latest rhel6:rhel6v1
podman tag registry.access.redhat.com/ubi7:latest rhel7:rhel7v1
podman tag registry.access.redhat.com/ubi8:latest rhel8:rhel8v1


mkdir -p /var/rhelrepo/rhel6/logs
mkdir -p /var/rhelrepo/rhel7/logs
mkdir -p /var/rhelrepo/rhel8/logs
touch /var/rhelrepo/rhel6/logs/rhel6.log
touch /var/rhelrepo/rhel6/logs/rhel6_error.log

touch /var/rhelrepo/rhel7/logs/rhel7.log
touch /var/rhelrepo/rhel7/logs/rhel7_error.log

touch /var/rhelrepo/rhel8/logs/rhel8.log
touch /var/rhelrepo/rhel8/logs/rhel8_error.log


}




function update () {
find /var/rhelrepo/rhel6/ -type f -empty | xargs rm -f "{}"
podman run -dt --rm --name=rhel6shell -v ./updt:/updt -v /var/rhelrepo/rhel6:/repodata localhost/rhel6:rhel6v1
podman exec -it rhel6shell bash -c "/updt/update_rhel6.sh | tee /repodata/logs/rhel6.log 2> /repodata/logs/rhel6_error.log"
podman stop rhel6shell

find /var/rhelrepo/rhel7/ -type f -empty | xargs rm -f "{}"
podman run -dt --rm --name=rhel7shell -v ./updt:/updt -v /var/rhelrepo/rhel7:/repodata localhost/rhel7:rhel7v1
podman exec -it rhel7shell bash -c "/updt/update_rhel7.sh | tee /repodata/logs/rhel7.log 2> /repodata/logs/rhel7_error.log"
podman stop rhel7shell

find /var/rhelrepo/rhel8/ -type f -empty | xargs rm -f "{}"
podman run -dt --rm --name=rhel8shell -v ./updt:/updt -v /var/rhelrepo/rhel8:/repodata localhost/rhel8:rhel8v1
podman exec -it rhel8shell bash -c "/updt/update_rhel8.sh | tee /repodata/logs/rhel8.log 2> /repodata/logs/rhel8_error.log"
podman stop rhel8shell
}


function register () {
clear
subscription-manager register --auto-attach --force
podman login registry.redhat.io
yum install -y podman
}



function menu_ayuda () {
echo " "
      echo "repodman.sh [options]"
      echo " "
      echo "options:"
      echo "-h, --help                Show brief help"
      echo "-i, --initialization      Initialize enviroment"
      echo "-u, --update              Update Rhel 6,7,8 repos"
      echo "-r, --register            Register system in RHN podmans"
      exit 0
}



while [ "$1" != "" ]; do
    case $1 in

   -h|--help)
       menu_ayuda
      exit
       ;;

    -i|--initialization)
     initia_lization
     exit
      ;;

    -u|--update)
      update
      exit
      ;;

    -r|--register)
    register
    exit
      ;;

    * )
     menu_ayuda
     exit
    esac

done


menu_ayuda
