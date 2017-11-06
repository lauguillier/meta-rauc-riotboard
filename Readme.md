**Portage de Rauc sur Riotboard (Yocto / morty)**

Les étapes suivantes sont nécessaires pour implémenter Rauc sur Riotbord :

* télécharger le Yocto morty de fsl-community : instructions sur http://freescale.github.io

* cd fsl-community-bsp

* Ajouter les meta rauc (morty) et homeassistant (krogoth !) :

    riot-board git clone -b morty https://github.com/rauc/meta-rauc.git
    
    riot-board git clone -b krogoth https://github.com/bachp/meta-homeassistant.git

* MACHINE=imx6dl-riotboard DISTRO=fslc-framebuffer source ./setup-environment riot-board

* bitbake core-image-minimal


Il faut également construire des utilitaires, dont wic qui est utilisé pour créer les images :

    bitbake parted-native dosfstools-native mtools-native
