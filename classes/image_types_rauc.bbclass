inherit image_types

IMAGE_BOOTLOADER ?= "u-boot"

# Handle u-boot suffixes
UBOOT_SUFFIX ?= "bin"
UBOOT_SUFFIX_SDCARD ?= "${UBOOT_SUFFIX}"

#
# Handles i.MX mxs bootstream generation
#
MXSBOOT_NAND_ARGS ?= ""

# IMX Bootlets Linux bootstream
IMAGE_DEPENDS_linux.sb = "elftosb-native:do_populate_sysroot \
                          imx-bootlets:do_deploy \
                          virtual/kernel:do_deploy"
IMAGE_LINK_NAME_linux.sb = ""
IMAGE_CMD_linux.sb () {
	kernel_bin="`readlink ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin`"
	kernel_dtb="`readlink ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.dtb || true`"
	linux_bd_file=imx-bootlets-linux.bd-${MACHINE}
	if [ `basename $kernel_bin .bin` = `basename $kernel_dtb .dtb` ]; then
		# When using device tree we build a zImage with the dtb
		# appended on the end of the image
		linux_bd_file=imx-bootlets-linux.bd-dtb-${MACHINE}
		cat $kernel_bin $kernel_dtb \
		    > $kernel_bin-dtb
		rm -f ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin-dtb
		ln -s $kernel_bin-dtb ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin-dtb
	fi

	# Ensure the file is generated
	rm -f ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.linux.sb
	(cd ${DEPLOY_DIR_IMAGE}; elftosb -z -c $linux_bd_file -o ${IMAGE_NAME}.linux.sb)

	# Remove the appended file as it is only used here
	rm -f ${DEPLOY_DIR_IMAGE}/$kernel_bin-dtb
}


# U-Boot mxsboot generation to SD-Card
UBOOT_SUFFIX_SDCARD_mxs ?= "mxsboot-sdcard"
IMAGE_DEPENDS_uboot-mxsboot-sdcard = "u-boot-mxsboot-native:do_populate_sysroot \
                                      u-boot:do_deploy"
IMAGE_CMD_uboot-mxsboot-sdcard = "mxsboot sd ${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.${UBOOT_SUFFIX} \
                                             ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.uboot-mxsboot-sdcard"

IMAGE_DEPENDS_uboot-mxsboot-nand = "u-boot-mxsboot-native:do_populate_sysroot \
                                      u-boot:do_deploy"
IMAGE_CMD_uboot-mxsboot-nand = "mxsboot ${MXSBOOT_NAND_ARGS} nand \
                                             ${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.${UBOOT_SUFFIX} \
                                             ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.uboot-mxsboot-nand"


# Boot partition volume id
BOOTDD_VOLUME_ID ?= "Boot ${MACHINE}"

# Boot partition size [in KiB]
BOOT_SPACE ?= "8192"

# Barebox environment size [in KiB]
BAREBOX_ENV_SPACE ?= "512"

# Set alignment to 4MB [in KiB]
IMAGE_ROOTFS_ALIGNMENT = "4096"

IMAGE_DEPENDS_sdcard = "parted-native:do_populate_sysroot \
                        dosfstools-native:do_populate_sysroot \
                        mtools-native:do_populate_sysroot \
                        virtual/kernel:do_deploy \
                        ${@d.getVar('IMAGE_BOOTLOADER', True) and d.getVar('IMAGE_BOOTLOADER', True) + ':do_deploy' or ''}"

SDCARD = "${IMGDEPLOYDIR}/${IMAGE_NAME}.rootfs.sdcard"

SDCARD_GENERATION_COMMAND_mx25 = "generate_imx_rauc_sdcard"
SDCARD_GENERATION_COMMAND_mx5 = "generate_imx_rauc_sdcard"
SDCARD_GENERATION_COMMAND_mx6 = "generate_imx_rauc_sdcard"
SDCARD_GENERATION_COMMAND_mx7 = "generate_imx_rauc_sdcard"
SDCARD_GENERATION_COMMAND_vf = "generate_imx_rauc_sdcard"


#
# Generate the boot image with the boot scripts and required Device Tree
# files
_generate_boot_image() {
	echo 'Entering _generate_boot_image'
	local boot_part=$1

	# Create boot partition image
	BOOT_BLOCKS=$(LC_ALL=C parted -s ${SDCARD} unit b print \
	                  | awk "/ $boot_part / { print substr(\$4, 1, length(\$4 -1)) / 1024 }")

	# mkdosfs will sometimes use FAT16 when it is not appropriate,
	# resulting in a boot failure from SYSLINUX. Use FAT32 for
	# images larger than 512MB, otherwise let mkdosfs decide.
	if [ $(expr $BOOT_BLOCKS / 1024) -gt 512 ]; then
		FATSIZE="-F 32"
	fi

	rm -f ${WORKDIR}/boot.img
	mkfs.vfat -n "${BOOTDD_VOLUME_ID}" -S 512 ${FATSIZE} -C ${WORKDIR}/boot.img $BOOT_BLOCKS

	mcopy -i ${WORKDIR}/boot.img -s ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin ::/${KERNEL_IMAGETYPE}

	# Copy boot scripts
	for item in ${BOOT_SCRIPTS}; do
		src=`echo $item | awk -F':' '{ print $1 }'`
		dst=`echo $item | awk -F':' '{ print $2 }'`

		mcopy -i ${WORKDIR}/boot.img -s ${DEPLOY_DIR_IMAGE}/$src ::/$dst
	done

	# Copy device tree file
	if test -n "${KERNEL_DEVICETREE}"; then
		for DTS_FILE in ${KERNEL_DEVICETREE}; do
			DTS_BASE_NAME=`basename ${DTS_FILE} .dtb`
			if [ -e "${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${DTS_BASE_NAME}.dtb" ]; then
				kernel_bin="`readlink ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin`"
				kernel_bin_for_dtb="`readlink ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${DTS_BASE_NAME}.dtb | sed "s,$DTS_BASE_NAME,${MACHINE},g;s,\.dtb$,.bin,g"`"
				if [ $kernel_bin = $kernel_bin_for_dtb ]; then
					mcopy -i ${WORKDIR}/boot.img -s ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${DTS_BASE_NAME}.dtb ::/${DTS_BASE_NAME}.dtb
				fi
			else
				bbfatal "${DTS_FILE} does not exist."
			fi
		done
	fi

	# Copy extlinux.conf to images that have U-Boot Extlinux support.
	if [ "${UBOOT_EXTLINUX}" = "1" ]; then
		mmd -i ${WORKDIR}/boot.img ::/extlinux
		mcopy -i ${WORKDIR}/boot.img -s ${DEPLOY_DIR_IMAGE}/extlinux.conf ::/extlinux/extlinux.conf
	fi
	echo 'Leaving _generate_boot_image'
}

#
# Create an image that can by written onto a SD card using dd for use
# with i.MX SoC family w/ rauc update system in symetric mode
#
# External variables needed:
#   ${SDCARD_ROOTFS}    - the rootfs image to incorporate
#   ${IMAGE_BOOTLOADER} - bootloader to use {u-boot, barebox}
#
# The disk layout used is:
#
#    0                      -> IMAGE_ROOTFS_ALIGNMENT         - reserved to bootloader (not partitioned)
#    IMAGE_ROOTFS_ALIGNMENT -> BOOT_SPACE                     - kernel and other data
#    BOOT_SPACE             -> SDIMG_SIZE                     - rootfs
#
#                                                     Default Free space = 1.3x
#                                                     Use IMAGE_OVERHEAD_FACTOR to add more space
#                                                     <--------->
#            4MiB               8MiB           SDIMG_ROOTFS                    4MiB                              4MiB
# <-----------------------> <----------> <----------------------> <------------------------------> <------------------------------>
#  ------------------------ ------------ ------------------------ ------------------------------- -------------------------------
# | IMAGE_ROOTFS_ALIGNMENT | BOOT_SPACE | ROOTFS_SIZE            |     IMAGE_ROOTFS_ALIGNMENT    |     IMAGE_ROOTFS_ALIGNMENT    |
#  ------------------------ ------------ ------------------------ ------------------------------- -------------------------------
# ^                        ^            ^                        ^                               ^                               ^
# |                        |            |                        |                               |                               |
# 0                      4096     4MiB +  8MiB       4MiB +  8Mib + SDIMG_ROOTFS   4MiB +  8MiB + SDIMG_ROOTFS + 4MiB   4MiB +  8MiB + SDIMG_ROOTFS + 8MiB
generate_imx_rauc_sdcard () {
	echo 'Entering generate_imx_rauc_sdcard'
	echo 'generate_imx_rauc_sdcard: starting parted'
	# Create partition table
	echo parted -s ${SDCARD} mklabel msdos
	parted -s ${SDCARD} mklabel msdos
	echo 'generate_imx_rauc_sdcard: part 1 done'
	echo parted -s ${SDCARD} unit KiB mkpart primary fat32 ${IMAGE_ROOTFS_ALIGNMENT} $(expr ${IMAGE_ROOTFS_ALIGNMENT} \+ ${BOOT_SPACE_ALIGNED})
	parted -s ${SDCARD} unit KiB mkpart primary fat32 ${IMAGE_ROOTFS_ALIGNMENT} $(expr ${IMAGE_ROOTFS_ALIGNMENT} \+ ${BOOT_SPACE_ALIGNED})
	echo 'generate_imx_rauc_sdcard: part 2 done'
	echo parted -s ${SDCARD} unit KiB mkpart primary $(expr  ${IMAGE_ROOTFS_ALIGNMENT} \+ ${BOOT_SPACE_ALIGNED}) $(expr ${IMAGE_ROOTFS_ALIGNMENT} \+ ${BOOT_SPACE_ALIGNED} \+ $ROOTFS_SIZE)
	parted -s ${SDCARD} unit KiB mkpart primary $(expr  ${IMAGE_ROOTFS_ALIGNMENT} \+ ${BOOT_SPACE_ALIGNED}) $(expr ${IMAGE_ROOTFS_ALIGNMENT} \+ ${BOOT_SPACE_ALIGNED} \+ $ROOTFS_SIZE )
	echo 'generate_imx_rauc_sdcard: part 3 done'
	parted ${SDCARD} print
	echo 'generate_imx_rauc_sdcard: finished parted'

	# Burn bootloader
	case "${IMAGE_BOOTLOADER}" in
		imx-bootlets)
		bberror "The imx-bootlets is not supported for i.MX based machines"
		exit 1
		;;
		u-boot)
		echo 'generate_imx_rauc_sdcard: bootloader = u-boot'
		if [ -n "${SPL_BINARY}" ]; then
			echo dd if=${DEPLOY_DIR_IMAGE}/${SPL_BINARY} of=${SDCARD} conv=notrunc seek=2 bs=512
			dd if=${DEPLOY_DIR_IMAGE}/${SPL_BINARY} of=${SDCARD} conv=notrunc seek=2 bs=512
			echo dd if=${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.${UBOOT_SUFFIX_SDCARD} of=${SDCARD} conv=notrunc seek=69 bs=1K
			dd if=${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.${UBOOT_SUFFIX_SDCARD} of=${SDCARD} conv=notrunc seek=69 bs=1K
		else
			dd if=${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.${UBOOT_SUFFIX_SDCARD} of=${SDCARD} conv=notrunc seek=2 bs=512
			echo dd if=${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.${UBOOT_SUFFIX_SDCARD} of=${SDCARD} conv=notrunc seek=2 bs=512
		fi
		;;
		barebox)
		dd if=${DEPLOY_DIR_IMAGE}/barebox-${MACHINE}.bin of=${SDCARD} conv=notrunc seek=1 skip=1 bs=512
		dd if=${DEPLOY_DIR_IMAGE}/bareboxenv-${MACHINE}.bin of=${SDCARD} conv=notrunc seek=1 bs=512k
		;;
		"")
		;;
		*)
		bberror "Unknown IMAGE_BOOTLOADER value"
		exit 1
		;;
	esac

	echo 'generate_imx_rauc_sdcard: calling _generate_boot_image'
	_generate_boot_image 1

	# Burn Partition
	dd if=${WORKDIR}/boot.img of=${SDCARD} conv=notrunc,fsync seek=1 bs=$(expr ${IMAGE_ROOTFS_ALIGNMENT} \* 1024)
	dd if=${SDCARD_ROOTFS} of=${SDCARD} conv=notrunc,fsync seek=1 bs=$(expr ${BOOT_SPACE_ALIGNED} \* 1024 + ${IMAGE_ROOTFS_ALIGNMENT} \* 1024)
	dd if=/dev/null of=${SDCARD} conv=notrunc,fsync seek=1 bs=$(expr ${BOOT_SPACE_ALIGNED} \* 1024 + ${IMAGE_ROOTFS_ALIGNMENT} \* 1024)
	echo 'Leaving generate_imx_rauc_sdcard'
}

IMAGE_CMD_rauc-sdimg () {
	echo 'Entering IMAGE_CMD_rauc-sdimg'
	if [ -z "${SDCARD_ROOTFS}" ]; then
		bberror "SDCARD_ROOTFS is undefined. To use sdcard image from Freescale's BSP it needs to be defined."
		echo 'SDCARD_ROOTFS is undefined. Leaving IMAGE_CMD_rauc-sdimg'
		exit 1
	fi
	echo 'IMAGE_CMD_rauc-sdimg : start calculate SDcard image size'
	# Align boot partition and calculate total SD card image size
	BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE} + ${IMAGE_ROOTFS_ALIGNMENT} - 1)
	BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE_ALIGNED} - ${BOOT_SPACE_ALIGNED} % ${IMAGE_ROOTFS_ALIGNMENT})
	SDCARD_SIZE=$(expr ${IMAGE_ROOTFS_ALIGNMENT} + ${BOOT_SPACE_ALIGNED} + $ROOTFS_SIZE + ${IMAGE_ROOTFS_ALIGNMENT} + $ROOTFS_SIZE + ${IMAGE_ROOTFS_ALIGNMENT})
	echo 'SDCARD Size:' $SDCARD_SIZE

	# Initialize a sparse file
	echo 'IMAGE_CMD_rauc-sdimg : start initializing sparse file'
	dd if=/dev/zero of=${SDCARD} bs=1 count=0 seek=$(expr 1024 \* ${SDCARD_SIZE})

	echo 'IMAGE_CMD_rauc-sdimg : calling generate_imx_rauc_sdcard'
	generate_imx_rauc_sdcard
	#${SDCARD_GENERATION_COMMAND}
	echo 'Leaving IMAGE_CMD_rauc-sdimg'
}


# The sdcard requires the rootfs filesystem to be built before using
# it so we must make this dependency explicit.
IMAGE_TYPEDEP_sdcard += "${@d.getVar('SDCARD_ROOTFS', 1).split('.')[-1]}"

# In case we are building for i.MX23 or i.MX28 we need to have the
# image stream built before the sdcard generation
IMAGE_TYPEDEP_sdcard += " \
    ${@bb.utils.contains('IMAGE_FSTYPES', 'uboot-mxsboot-sdcard', 'uboot-mxsboot-sdcard', '', d)} \
    ${@bb.utils.contains('IMAGE_FSTYPES', 'barebox-mxsboot-sdcard', 'barebox-mxsboot-sdcard', '', d)} \
"
