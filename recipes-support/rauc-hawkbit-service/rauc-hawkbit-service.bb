DESCRIPTION = "Rauc-hawkbit-client daemon"
SECTION = "base"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS_prepend := "${THISDIR}/rauc-hawkbit-service/:"

SRC_URI += "file://rauc-hawkbit.service"
SRC_URI += "file://rauc-hawkbit"

SYSTEMD_SERVICE_${PN} = "rauc-hawkbit.service"

RDEPENDS_${PN} = "systemd rauc-hawkbit"
DEPENDS = "systemd"

inherit systemd

S = "${WORKDIR}"

do_install() {
	# install service file
	install -d ${D}${systemd_unitdir}/system
	install -c -m 0644 ${WORKDIR}/rauc-hawkbit.service ${D}${systemd_unitdir}/system

	# install rauc-hawkbit daemon script
	install -d ${D}${bindir}
	install -c -m 0755 ${WORKDIR}/rauc-hawkbit ${D}${bindir}
}

FILES_${PN} = "${base_libdir}/systemd/system/rauc-hawkbit.service"
FILES_${PN} += "${bindir}/rauc-hawkbit"

# As this package is tied to systemd, only build it when we're also building systemd.
python () {
    if not bb.utils.contains ('DISTRO_FEATURES', 'systemd', True, False, d):
        raise bb.parse.SkipPackage("'systemd' not in DISTRO_FEATURES")
}
