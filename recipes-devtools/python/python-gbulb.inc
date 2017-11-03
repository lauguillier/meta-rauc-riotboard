SUMMARY = "Gbulb"
DESCRIPTION = ""
HOMEPAGE = "https://github.com/nathan-hoad/gbulb"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit pypi

SRC_URI[md5sum] = "bf3f2f1de2606f1310111e3479cc52d2"
SRC_URI[sha256sum] = "5e40bf0354f3fc31d1a5e701dae6afc96f1a1bb432ce44de2d2ad3e62ce6e173"

RDEPENDS_${PN} += " \
	${PYTHON_PN}-asyncio \
	${PYTHON_PN}-pygobject \ 
"
