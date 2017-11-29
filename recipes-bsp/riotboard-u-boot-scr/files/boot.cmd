#saveenv
fdt addr ${fdt_addr} && fdt get value bootargs /chosen bootargs

echo "#### Start RAUC boot script" 

test -n "${BOOT_ORDER}" || setenv BOOT_ORDER "A B"
test -n "${BOOT_A_LEFT}" || setenv BOOT_A_LEFT 3
test -n "${BOOT_B_LEFT}" || setenv BOOT_B_LEFT 3
test -n "${BOOT_DEV}" || setenv BOOT_DEV "mmc 1:1"


setenv custom_bootargs
for BOOT_SLOT in "${BOOT_ORDER}"; do
  if test "x${custom_bootargs}" != "x"; then
    # skip remaining slots
  elif test "x${BOOT_SLOT}" = "xA"; then
    if test ${BOOT_A_LEFT} -gt 0; then
      setexpr BOOT_A_LEFT ${BOOT_A_LEFT} - 1
      echo "Found valid slot A, ${BOOT_A_LEFT} attempts remaining"
      setenv custom_bootargs root=/dev/mmcblk1p2 rauc.slot=A
      setenv BOOT_DEV "mmc 1:2"
    fi
  elif test "x${BOOT_SLOT}" = "xB"; then
    if test ${BOOT_B_LEFT} -gt 0; then
      setexpr BOOT_B_LEFT ${BOOT_B_LEFT} - 1
      echo "Found valid slot B, ${BOOT_B_LEFT} attempts remaining"
      setenv custom_bootargs root=/dev/mmcblk1p3 rauc.slot=B
      setenv BOOT_DEV "mmc 1:3"
    fi
  fi
done

if test -n "${custom_bootargs}"; then
  #setenv bootargs ${bootargs} ${custom_bootargs}
  setenv bootargs console=ttymxc1,115200 ${custom_bootargs}
  saveenv
else
  echo "No valid slot found, resetting tries to 3"
  setenv BOOT_A_LEFT 3
  setenv BOOT_B_LEFT 3
  saveenv
  reset
fi

ext4load ${BOOT_DEV} ${loadaddr} /boot/zImage;
ext4load ${BOOT_DEV} ${fdt_addr_r} /boot/imx6dl-riotboard.dtb
bootz ${loadaddr} - ${fdt_addr_r}
