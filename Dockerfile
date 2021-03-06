FROM ubuntu:16.04

ARG steam_user=anonymous
ARG steam_password=
ARG metamod_version=1.20
ARG amxmod_version=1.8.2

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    rm -rf /var/lib/apt/lists/*

RUN add-apt-repository multiverse && \
    dpkg --add-architecture i386 && \
    apt update && \
    apt install -y curl

# Install SteamCMD
RUN mkdir -p /opt/steam && cd /opt/steam && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Install HLDS
RUN mkdir -p /opt/hlds
# Workaround for "app_update 90" bug, see https://forums.alliedmods.net/showthread.php?p=2518786
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password +force_install_dir /opt/hlds +app_update 90 validate +quit
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password +force_install_dir /opt/hlds +app_update 70 validate +quit || :
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password +force_install_dir /opt/hlds +app_update 10 validate +quit || :
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password +force_install_dir /opt/hlds +app_update 90 validate +quit
RUN mkdir -p ~/.steam && ln -s /opt/hlds ~/.steam/sdk32
RUN ln -s /opt/steam/ /opt/hlds/steamcmd
ADD files/steam_appid.txt /opt/hlds/steam_appid.txt
ADD hlds_run.sh /bin/hlds_run.sh
RUN chmod +x /bin/hlds_run.sh

# Add default config
ADD files/server.cfg /opt/hlds/cstrike/server.cfg

# Add maps
ADD maps/* /opt/hlds/cstrike/maps/
ADD files/mapcycle.txt /opt/hlds/cstrike/mapcycle.txt

# Install metamod
RUN mkdir -p /opt/hlds/cstrike/addons/metamod/dlls
RUN curl -sqL "http://prdownloads.sourceforge.net/metamod/metamod-$metamod_version-linux.tar.gz?download" | tar -C /opt/hlds/cstrike/addons/metamod/dlls -zxvf -
ADD files/liblist.gam /opt/hlds/cstrike/liblist.gam
ADD files/plugins.ini /opt/hlds/cstrike/addons/metamod/plugins.ini

# Install dproto
RUN mkdir -p /opt/hlds/cstrike/addons/dproto
ADD files/dproto_i386.so /opt/hlds/cstrike/addons/dproto/dproto_i386.so
ADD files/dproto.cfg /opt/hlds/cstrike/dproto.cfg

# Install AMX mod X
RUN curl -sqL "http://www.amxmodx.org/release/amxmodx-$amxmod_version-base-linux.tar.gz" | tar -C /opt/hlds/cstrike/ -zxvf -
RUN curl -sqL "http://www.amxmodx.org/release/amxmodx-$amxmod_version-cstrike-linux.tar.gz" | tar -C /opt/hlds/cstrike/ -zxvf -
ADD files/maps.ini /opt/hlds/cstrike/addons/amxmodx/configs/maps.ini
ADD files/amx_plugins.ini /opt/hlds/cstrike/addons/amxmodx/configs/plugins.ini

# Add Advanced Quake Sounds v5.0 https://forums.alliedmods.net/showthread.php?t=152034
ADD files/quake_sounds/quakesounds.ini /opt/hlds/cstrike/addons/amxmodx/configs/quakesounds.ini
ADD files/quake_sounds/QuakeSounds.amxx /opt/hlds/cstrike/addons/amxmodx/plugins/QuakeSounds.amxx
RUN mkdir -p /opt/hlds/cstrike/sound/QuakeSounds
ADD files/quake_sounds/QuakeSounds /opt/hlds/cstrike/sound/QuakeSounds

# Add Team Swap
ADD files/team_swap/Auto_Swap_Teams.amxx /opt/hlds/cstrike/addons/amxmodx/plugins/Auto_Swap_Teams.amxx
ADD files/team_swap/Auto_Swap_Teams.txt /opt/hlds/cstrike/addons/amxmodx/data/lang/Auto_Swap_Teams.txt

# Cleanup
RUN apt remove -y curl

WORKDIR /opt/hlds

ENTRYPOINT ["/bin/hlds_run.sh"]