# Portage de Rauc sur Riotboard (Yocto / morty)

Les étapes suivantes sont nécessaires pour implémenter Rauc sur riotboard :

* télécharger le Yocto morty de fsl-community : instructions sur http://freescale.github.io

 _Attention, nécessite python 2 et pas 3_

* Ajouter les meta rauc (morty) et homeassistant (en krogoth car pas de version morty !) :

      cd fsl-community-bsp
      git clone -b morty https://github.com/rauc/meta-rauc.git
      git clone -b krogoth https://github.com/bachp/meta-homeassistant.git

* Configurer Yocto :

      MACHINE=imx6dl-riotboard DISTRO=fslc-framebuffer source ./setup-environment riot-board

* Ajouter meta-rauc-riotboard et meta-test :

      git clone https://github.com/lauguillier/meta-rauc-riotboard.git
      git clone https://github.com/lauguillier/meta-test.git

* Dans le local.conf, il faut ajouter les lignes suivantes :

      IMAGE_FSTYPES_append  = " ext4"
      #Add SD image format
      IMAGE_FSTYPES_append = " rauc-sdimg"

      # Enabling systemd
      DISTRO_FEATURES_append = " systemd"
      VIRTUAL-RUNTIME_init_manager = "systemd"
      DISTRO_FEATURES_BACKFILL_CONSIDERED = "sysvinit"
      VIRTUAL-RUNTIME_initscripts = ""
      IMAGE_INSTALL_append  = " hello nano"
      IMAGE_FEATURES_append = " ssh-server-dropbear"
      IMAGE_INSTALL_append = " u-boot-fw-utils"
      IMAGE_BOOT_FILES_append = " boot.scr u-boot.bin;${SDIMG_KERNELIMAGE}"
      IMAGE_INSTALL_append = " kernel-image kernel-devicetree"


* lancer la génération de l'image avec

      bitbake core-image-minimal

* Il faut également construire des utilitaires, dont wic qui est utilisé pour créer les images :

      bitbake parted-native dosfstools-native mtools-native
