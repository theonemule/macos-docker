FROM ubuntu:22.04

#User Settings for VNC
ENV USER=root
ENV PASSWORD=password1

#Variables for installation
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
ENV XKB_DEFAULT_RULES=base

#Install dependencies
RUN apt-get update && \
        echo "tzdata tzdata/Areas select America" > ~/tx.txt && \
        echo "tzdata tzdata/Zones/America select New York" >> ~/tx.txt && \
        debconf-set-selections ~/tx.txt && \
        apt-get install -y unzip gnupg apt-transport-https wget software-properties-common ratpoison novnc websockify libxv1 libglu1-mesa xauth x11-utils xorg tightvncserver libegl1-mesa xauth x11-xkb-utils software-properties-common bzip2 gstreamer1.0-plugins-good gstreamer1.0-pulseaudio gstreamer1.0-tools libglu1-mesa libgtk2.0-0 libncursesw5 libopenal1 libsdl-image1.2 libsdl-ttf2.0-0 libsdl1.2debian libsndfile1 nginx supervisor ucspi-tcp wget build-essential ccache lxterminal qemu-kvm python-is-python3 dmg2img git

#Copy the files for audio and NGINX
COPY nginx.conf /etc/nginx/

# Configure NoVNC
RUN   mkdir ~/.vnc/ && \
  echo $PASSWORD | vncpasswd -f > ~/.vnc/passwd && \
  chmod 0600 ~/.vnc/passwd && \
  echo "set border 0" > ~/.ratpoisonrc  && \
  echo "exec lxterminal">> ~/.ratpoisonrc && \
  openssl req -x509 -nodes -newkey rsa:2048 -keyout ~/novnc.pem -out ~/novnc.pem -days 3650 -subj "/C=US/ST=NY/L=NY/O=NY/OU=NY/CN=NY emailAddress=email@example.com"

#Copy in supervisor configuration for startup
COPY supervisord.conf /etc/supervisor/supervisord.conf
ENTRYPOINT [ "supervisord", "-c", "/etc/supervisor/supervisord.conf" ]


COPY get-and-start-osx.sh ./

RUN git clone https://github.com/kholia/OSX-KVM.git && \
	mv ./OSX-KVM/OpenCore . && \
	mv ./OSX-KVM/OVMF* . && \
	mv ./OSX-KVM/fetch-macOS-v2.py .

# COPY OpenCore .

