DESCRIPTION = "Rauc bundle generator"
SECTION = ""
DEPENDS = ""

inherit image_types_rauc
inherit bundle

# RAUC_BUNDLE_COMPATIBLE
#    Sets the compatible string for the bundle. This should match the compatible you specified in your system.conf or, more generally, the compatible of the target platform you intend to install this bundle on
RAUC_BUNDLE_COMPATIBLE = "RioTHello"

# RAUC_BUNDLE_SLOTS
#    Use this to list all slot classes for which the bundle should contain images. A value of "rootfs appfs" for example will create a manifest with images for two slot classes; rootfs and appfs
RAUC_BUNDLE_SLOTS = "rootfs" 

# RAUC_SLOT_<slotclass>
#    For each slot class, set this to the image (recipe) name which builds the artifact you intend to place in the slot class
RAUC_SLOT_rootfs = "core-image-minimal"

# RAUC_SLOT_<slotclass>[type]
#    For each slot class, set this to the type of image you intend to place in this slot. Possible types are: rootfs (default), kernel, bootloader
RAUC_SLOT_rootfs[fstype] = "ext4"


RAUC_KEY_FILE = "${THISDIR}/files/development-1.key.pem"
RAUC_CERT_FILE = "${THISDIR}/files/development-1.cert.pem"
