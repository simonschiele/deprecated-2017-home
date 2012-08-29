#!/bin/sh

git_url="http://simon.psaux.de/git/home.git"

if ! ( git clone ${git_url} installer-home.git/ )
then
    echo "git clone failed"
    exit 1
fi

mv installer-home.git/.bin/bootstrap*.sh .
mv installer-home.git/.hooks/ hooks/
mv installer-home.git/.packages/ packages/
chmod +x bootstrap*sh

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
echo "time ./bootstrap1.sh"
echo ""

