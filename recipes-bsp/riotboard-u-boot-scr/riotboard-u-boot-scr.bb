SUMMARY = "U-boot boot scripts for Riotboard / rauc"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
COMPATIBLE_MACHINE = "imx6dl-riotboard"

DEPENDS = "u-boot-mkimage-native"

SRC_URI = "file://boot.cmd"
UBOOT_ENV_SUFFIX ?= "scr"
UBOOT_ENV ?= "boot"

do_compile() {
    mkimage -A arm -T script -C none -n "Boot script" -d "${WORKDIR}/boot.cmd" boot.scr
}

inherit deploy

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 boot.scr ${DEPLOYDIR}
}

addtask do_deploy after do_compile before do_build
