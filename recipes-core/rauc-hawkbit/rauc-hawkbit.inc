DESCRIPTION = "Hawkbit client for RAUC update controller"
HOMEPAGE = "https://github.com/rauc/rauc-hawkbit"
LICENSE = "LGPLv2.1"
LIC_FILES_CHKSUM = "file://COPYING;md5=4fbd65380cdd255951079008b364516c"
DEPENDS = "rauc"

#FILESEXTRAPATHS_prepend := "${THISDIR}/files/:"

SRC_URI = " \
        git://github.com/rauc/rauc-hawkbit.git;protocol=git"
# \
#	file://rauc-hawkbit.cfg \
#	"
S = "${WORKDIR}/git"

SRCREV = "${AUTOREV}"
#"664cc2389ecdafca7696e2fb45e72f444cd5db84"

do_install_append () {
    # Install config file in /etc
    #install -c -m 0644 rauc-hawkbit.cfg ${D}${sysconfdir}/rauc-hawkbit.cfg
    install -d ${D}${sysconfdir}
    install -c -m 0644 ${THISDIR}/files/rauc-hawkbit.cfg ${D}${sysconfdir}/rauc-hawkbit.cfg
}

