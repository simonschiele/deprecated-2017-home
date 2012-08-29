#!/bin/sh

git_url="http://simon.psaux.de/git/home.git"

if ! ( git clone ${git_url} installer-home.git/ )
then
    echo "git clone failed"
    exit 1
fi

mv installer-home.git/.hooks/install_step*.sh .
mv installer-home.git/.hooks/ hooks/
mv installer-home.git/.packages/ packages/
chmod +x install_step*sh
mkdir -p log/

rm -rf installer-home.git 

echo ""
echo "Settings:"
echo "export BOOTSTRAP_HOSTNAME=\"test.cnet.loc\""
echo "export BOOTSTRAP_SYSTEMTYPE=\"minimal\" \# minimal|server|workstation|laptop"
echo "export BOOTSTRAP_USERNAME=\"simon\""
echo "export BOOTSTRAP_TARGET=\"/dev/sdx\""
echo "export BOOTSTRAP_MOUNT=\"/media/root\""
echo "export BOOTSTRAP_64=false"
echo "export BOOTSTRAP_SWAP=true"
echo "export BOOTSTRAP_SSD=true"
echo "export BOOTSTRAP_PACKAGES=\"vim-nox,git,sudo,etckeeper,locales,kbd,keyboard-configuration,tzdata\""
echo ""
echo "run installer:"
echo "date ./install_step1.sh | tee -a log/step1.log"
echo ""

