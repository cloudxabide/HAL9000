#!/bin/bash

# Purpose:  To update my base install to run AI/ML workloads on my Dell XPS15 or Asus PC
#  Status:  In-progress - trying to convert this to run as a non-root user

# * * * * * * * * * * * *
# System Stuff
# * * * * * * * * * * * *
PWD=`pwd`
DATE=`date +%Y%m%d`
ARCH=`uname -p`
PKG_MGR=$(which apt || which apt-get)

# Make sure the host is named correctly
case $(dmidecode  -s baseboard-product-name) in
  21CD000QUS)
    MYHOSTNAME="blackmesa"
  ;;
  0F6K9V)
    MYHOSTNAME="slippy" 
  ;;
  'ROG STRIX Z490-E GAMING')
    MYHOSTNAME="hal9000" 
  ;;
esac
echo "$MYHOSTNAME" | sudo tee /etc/hostname

# Customize environment for Morpheus
# Add TMPFS mount for user:morpheus
grep morpheus /etc/fstab
if [ $? -ne 0 ]
then
  sudo cp /etc/fstab /etc/fstab.`date +%F`
  echo "# TMPFS Mount" | sudo tee -a /etc/fstab
  echo "tmpfs   /home/morpheus tmpfs  rw,size=1G,nr_inodes=5k,noexec,nodev,nosuid,uid=2026,gid=2026,mode=1700   0  0" | sudo tee -a /etc/fstab
  sudo mkdir /home/morpheus
fi

sudo systemctl daemon-reload
sudo mount -a

# Install "Standard OS Packages"
SYSTEM_PACKAGES="wget gpg curl git npm"
sudo apt-get -y install $SYSTEM_PACKAGES

# Manage Users 
id -u jradtke &>/dev/null || sudo useradd -m -u2025 -G10 -c "James Radtke" -p '$6$MIxbq9WNh2oCmaqT$10PxCiJVStBELFM.AKTV3RqRUmqGryrpIStH5wl6YNpAtaQw.Nc/lkk0FT9RdnKlEJEuB81af6GWoBnPFKqIh.' -s /bin/bash jradtke
id -u morpheus &>/dev/null || sudo useradd -m -u2026 -c "Morpheus" -p '$6$MIxbq9WNh2oCmaqT$10PxCiJVStBELFM.AKTV3RqRUmqGryrpIStH5wl6YNpAtaQw.Nc/lkk0FT9RdnKlEJEuB81af6GWoBnPFKqIh.' morpheus

# SUDO
SUDOERS="jradtke mansible"
for USER in $SUDOERS
do
  [ ! -f /etc/sudoers.d/$USER-nopasswd-all ] && echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER-nopasswd-all
done

# Install Chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
echo "deb https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google.list
sudo apt-get update -y
sudo apt-get install -y google-chrome-stable

# Install VSCode (this mess of code is from Microsoft - I will leave it as-is)
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg

sudo apt update
sudo apt install -y apt-transport-https code # or code-insiders

# Prevent screen hang - for Dell (need to add a case statement here)
case $(dmidecode  -s baseboard-product-name) in
  21CD000QUS)
cat << EOF | sudo tee /etc/modprobe.d/i915.conf
options i915 enable_psr=0
EOF
;;
esac

# Update User Shell Environment
mkdir ${HOME}/.bashrc.d/
cd
for FILE in .bash_profile .bashrc .gitconfig .gitignore .gitignore_global
do
  echo "curl -o ${FILE} https://raw.githubusercontent.com/cloudxabide/devops/main/Files/${FILE}"
  curl -o ${FILE} https://raw.githubusercontent.com/cloudxabide/devops/main/Files/${FILE}
done

curl -o ${HOME}/.bashrc.d/common https://raw.githubusercontent.com/cloudxabide/devops/main/Files/.bashrc.d_common
curl -o ${HOME}/.bashrc.d/ubuntu https://raw.githubusercontent.com/cloudxabide/devops/main/Files/.bashrc.d_ubuntu

# Manage Login Screen (remove some users)
USERS="mansible morpheus sharriradtke sophos techies"
for USER in $USERS
do
echo "[User]
Language=en_US.UTF-8
XSession=gnome
SystemAccount=true" | sudo tee /var/lib/AccountsService/users/$USER
done

# Update GRUB menu
wget -O - https://github.com/shvchk/fallout-grub-theme/raw/master/install.sh | sudo bash -

##################
## NVIDIA STUFF
##################
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/1.14.3/install-guide.html
# CUDA / Docker stuff
## First - remove existing NVIDIA bits
sudo apt autoremove -y nvidia* --purge
sudo /usr/bin/nvidia-uninstall

ubuntu-drivers devices
apt install -y nvidia-driver-535 && shutdown now -r

lspci | egrep -i 'vga|3d|display'
lsmod | grep nvidia
nvidia-smi
# glxgears

# Install Docker CE
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y 
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update -y && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Note:  you have to logout/login for the usermod to take effect
sudo usermod -aG docker $(whoami)

# Run a test to see
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

#  Update the system (and reboot)
sudo apt -y update
sudo apt -y upgrade
sudo reboot
