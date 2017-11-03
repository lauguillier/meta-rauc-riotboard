require rauc-hawkbit.inc
inherit setuptools3

#SRC_URI += "git://github.com/rauc/rauc-hawkbit.git;protocol=http;branch=master;rev=664cc2389ecdafca7696e2fb45e72f444cd5db84"

#SRC_URI[md5sum] = "d1d192f38ec8d1bf169cd5b181e531ce"
#SRC_URI[sha256sum] = "5760dec0fbddae2b1add44bf63fb5f20a20a2f637d10032e3be8f725b472491b"

RDEPENDS_${PN} = " \
    ${PYTHON_PN}-netserver \
    ${PYTHON_PN}-json \
    ${PYTHON_PN}-multiprocessing \
    ${PYTHON_PN}-asyncio \
    ${PYTHON_PN}-aiohttp \
    ${PYTHON_PN}-gbulb \
"
