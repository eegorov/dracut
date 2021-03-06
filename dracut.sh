#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Generator script for a dracut initramfs
# Tries to retain some degree of compatibility with the command line
# of the various mkinitrd implementations out there
#

# Copyright 2005-2013 Red Hat, Inc.  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# store for logging
dracut_args=( "$@" )

set -o pipefail

usage() {
    [[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut
    if [[ -f $dracutbasedir/dracut-version.sh ]]; then
        . $dracutbasedir/dracut-version.sh
    fi

#                                                       80x25 linebreak here ^
    cat << EOF
Usage: $0 [OPTION]... [<initramfs> [<kernel-version>]]

Version: $DRACUT_VERSION

Creates initial ramdisk images for preloading modules

  -h, --help  Display all options

If a [LIST] has multiple arguments, then you have to put these in quotes.

For example:

    # dracut --add-drivers "module1 module2"  ...

EOF
}

long_usage() {
    [[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut
    if [[ -f $dracutbasedir/dracut-version.sh ]]; then
        . $dracutbasedir/dracut-version.sh
    fi

#                                                       80x25 linebreak here ^
    cat << EOF
Usage: $0 [OPTION]... [<initramfs> [<kernel-version>]]

Version: $DRACUT_VERSION

Creates initial ramdisk images for preloading modules

  --kver [VERSION]      Set kernel version to [VERSION].
  -f, --force           Overwrite existing initramfs file.
  -a, --add [LIST]      Add a space-separated list of dracut modules.
  -m, --modules [LIST]  Specify a space-separated list of dracut modules to
                         call when building the initramfs. Modules are located
                         in /usr/lib/dracut/modules.d.
  -o, --omit [LIST]     Omit a space-separated list of dracut modules.
  --force-add [LIST]    Force to add a space-separated list of dracut modules
                         to the default set of modules, when -H is specified.
  -d, --drivers [LIST]  Specify a space-separated list of kernel modules to
                         exclusively include in the initramfs.
  --add-drivers [LIST]  Specify a space-separated list of kernel
                         modules to add to the initramfs.
  --omit-drivers [LIST] Specify a space-separated list of kernel
                         modules not to add to the initramfs.
  --filesystems [LIST]  Specify a space-separated list of kernel filesystem
                         modules to exclusively include in the generic
                         initramfs.
  -k, --kmoddir [DIR]   Specify the directory, where to look for kernel
                         modules
  --fwdir [DIR]         Specify additional directories, where to look for
                         firmwares, separated by :
  --kernel-only         Only install kernel drivers and firmware files
  --no-kernel           Do not install kernel drivers and firmware files
  --kernel-cmdline [PARAMETERS] Specify default kernel command line parameters
  --strip               Strip binaries in the initramfs
  --nostrip             Do not strip binaries in the initramfs
  --hardlink            Hardlink files in the initramfs
  --nohardlink          Do not hardlink files in the initramfs
  --prefix [DIR]        Prefix initramfs files with [DIR]
  --noprefix            Do not prefix initramfs files
  --mdadmconf           Include local /etc/mdadm.conf
  --nomdadmconf         Do not include local /etc/mdadm.conf
  --lvmconf             Include local /etc/lvm/lvm.conf
  --nolvmconf           Do not include local /etc/lvm/lvm.conf
  --fscks [LIST]        Add a space-separated list of fsck helpers.
  --nofscks             Inhibit installation of any fsck helpers.
  --ro-mnt              Mount / and /usr read-only by default.
  -h, --help            This message
  --debug               Output debug information of the build process
  --profile             Output profile information of the build process
  -L, --stdlog [0-6]    Specify logging level (to standard error)
                         0 - suppress any messages
                         1 - only fatal errors
                         2 - all errors
                         3 - warnings
                         4 - info
                         5 - debug info (here starts lots of output)
                         6 - trace info (and even more)
  -v, --verbose         Increase verbosity level
  -q, --quiet           Decrease verbosity level
  -c, --conf [FILE]     Specify configuration file to use.
                         Default: /etc/dracut.conf
  --confdir [DIR]       Specify configuration directory to use *.conf files
                         from. Default: /etc/dracut.conf.d
  --tmpdir [DIR]        Temporary directory to be used instead of default
                         /var/tmp.
  -l, --local           Local mode. Use modules from the current working
                         directory instead of the system-wide installed in
                         /usr/lib/dracut/modules.d.
                         Useful when running dracut from a git checkout.
  -H, --hostonly        Host-Only mode: Install only what is needed for
                         booting the local host instead of a generic host.
  -N, --no-hostonly     Disables Host-Only mode
  --fstab               Use /etc/fstab to determine the root device.
  --add-fstab [FILE]    Add file to the initramfs fstab
  --mount "[DEV] [MP] [FSTYPE] [FSOPTS]"
                        Mount device [DEV] on mountpoint [MP] with filesystem
                        [FSTYPE] and options [FSOPTS] in the initramfs
  --add-device "[DEV]"  Bring up [DEV] in initramfs
  -i, --include [SOURCE] [TARGET]
                        Include the files in the SOURCE directory into the
                         Target directory in the final initramfs.
                        If SOURCE is a file, it will be installed to TARGET
                         in the final initramfs.
  -I, --install [LIST]  Install the space separated list of files into the
                         initramfs.
  --gzip                Compress the generated initramfs using gzip.
                         This will be done by default, unless another
                         compression option or --no-compress is passed.
  --bzip2               Compress the generated initramfs using bzip2.
                         Make sure your kernel has bzip2 decompression support
                         compiled in, otherwise you will not be able to boot.
  --lzma                Compress the generated initramfs using lzma.
                         Make sure your kernel has lzma support compiled in,
                         otherwise you will not be able to boot.
  --xz                  Compress the generated initramfs using xz.
                         Make sure that your kernel has xz support compiled
                         in, otherwise you will not be able to boot.
  --compress [COMPRESSION] Compress the generated initramfs with the
                         passed compression program.  Make sure your kernel
                         knows how to decompress the generated initramfs,
                         otherwise you will not be able to boot.
  --no-compress         Do not compress the generated initramfs.  This will
                         override any other compression options.
  --list-modules        List all available dracut modules.
  -M, --show-modules    Print included module's name to standard output during
                         build.
  --keep                Keep the temporary initramfs for debugging purposes
  --printsize           Print out the module install size
  --sshkey [SSHKEY]     Add ssh key to initramfs (use with ssh-client module)

If [LIST] has multiple arguments, then you have to put these in quotes.

For example:

    # dracut --add-drivers "module1 module2"  ...

EOF
}

# function push()
# push values to a stack
# $1 = stack variable
# $2.. values
# example:
# push stack 1 2 "3 4"
push() {
    local _i
    local __stack=$1; shift
    for _i in "$@"; do
        eval ${__stack}'[${#'${__stack}'[@]}]="$_i"'
    done
}

# function pop()
# pops the last value from a stack
# assigns value to second argument variable
# or echo to stdout, if no second argument
# $1 = stack variable
# $2 = optional variable to store the value
# example:
# pop stack val
# val=$(pop stack)
pop() {
    local __stack=$1; shift
    local __resultvar=$1
    local _value;
    # check for empty stack
    eval '[[ ${#'${__stack}'[@]} -eq 0 ]] && return 1'

    eval _value='${'${__stack}'[${#'${__stack}'[@]}-1]}'

    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$_value'"
    else
        echo "$_value"
    fi
    eval unset ${__stack}'[${#'${__stack}'[@]}-1]'
    return 0
}

# Little helper function for reading args from the commandline.
# it automatically handles -a b and -a=b variants, and returns 1 if
# we need to shift $3.
read_arg() {
    # $1 = arg name
    # $2 = arg value
    # $3 = arg parameter
    local rematch='^[^=]*=(.*)$'
    if [[ $2 =~ $rematch ]]; then
        read "$1" <<< "${BASH_REMATCH[1]}"
    else
        read "$1" <<< "$3"
        # There is no way to shift our callers args, so
        # return 1 to indicate they should do it instead.
        return 1
    fi
}


dropindirs_sort()
{
    suffix=$1; shift
    args=("$@")
    files=$(
        while (( $# > 0 )); do
            for i in ${1}/*${suffix}; do
                [[ -f $i ]] && echo ${i##*/}
            done
            shift
        done | sort -Vu
    )

    for f in $files; do
        for d in "${args[@]}"; do
            if [[ -f "$d/$f" ]]; then
                echo "$d/$f"
                continue 2
            fi
        done
    done
}

verbosity_mod_l=0
unset kernel
unset outfile

# Workaround -i, --include taking 2 arguments
set -- "${@/--include/++include}"

# This prevents any long argument ending with "-i"
# -i, like --opt-i but I think we can just prevent that
set -- "${@/%-i/++include}"

TEMP=$(unset POSIXLY_CORRECT; getopt \
    -o "a:m:o:d:I:k:c:L:fvqlHhMN" \
    --long kver: \
    --long add: \
    --long force-add: \
    --long add-drivers: \
    --long omit-drivers: \
    --long modules: \
    --long omit: \
    --long drivers: \
    --long filesystems: \
    --long install: \
    --long fwdir: \
    --long libdirs: \
    --long fscks: \
    --long add-fstab: \
    --long mount: \
    --long device: \
    --long nofscks: \
    --long ro-mnt \
    --long kmoddir: \
    --long conf: \
    --long confdir: \
    --long tmpdir: \
    --long stdlog: \
    --long compress: \
    --long prefix: \
    --long force \
    --long kernel-only \
    --long no-kernel \
    --long kernel-cmdline: \
    --long strip \
    --long nostrip \
    --long hardlink \
    --long nohardlink \
    --long noprefix \
    --long mdadmconf \
    --long nomdadmconf \
    --long lvmconf \
    --long nolvmconf \
    --long debug \
    --long profile \
    --long sshkey: \
    --long verbose \
    --long quiet \
    --long local \
    --long hostonly \
    --long host-only \
    --long no-hostonly \
    --long no-host-only \
    --long fstab \
    --long help \
    --long bzip2 \
    --long lzma \
    --long xz \
    --long no-compress \
    --long gzip \
    --long list-modules \
    --long show-modules \
    --long keep \
    --long printsize \
    --long regenerate-all \
    --long noimageifnotneeded \
    -- "$@")

if (( $? != 0 )); then
    usage
    exit 1
fi

eval set -- "$TEMP"

while :; do
    case $1 in
        --kver)        kernel="$2"; shift;;
        -a|--add)      push add_dracutmodules_l  "$2"; shift;;
        --force-add)   push force_add_dracutmodules_l  "$2"; shift;;
        --add-drivers) push add_drivers_l        "$2"; shift;;
        --omit-drivers) push omit_drivers_l      "$2"; shift;;
        -m|--modules)  push dracutmodules_l      "$2"; shift;;
        -o|--omit)     push omit_dracutmodules_l "$2"; shift;;
        -d|--drivers)  push drivers_l            "$2"; shift;;
        --filesystems) push filesystems_l        "$2"; shift;;
        -I|--install)  push install_items_l      "$2"; shift;;
        --fwdir)       push fw_dir_l             "$2"; shift;;
        --libdirs)     push libdirs_l            "$2"; shift;;
        --fscks)       push fscks_l              "$2"; shift;;
        --add-fstab)   push add_fstab_l          "$2"; shift;;
        --mount)       push fstab_lines          "$2"; shift;;
        --add-device|--device)
                       push add_device_l         "$2"; shift;;
        --kernel-cmdline) push kernel_cmdline_l  "$2"; shift;;
        --nofscks)     nofscks_l="yes";;
        --ro-mnt)      ro_mnt_l="yes";;
        -k|--kmoddir)  drivers_dir_l="$2"; shift;;
        -c|--conf)     conffile="$2"; shift;;
        --confdir)     confdir="$2"; shift;;
        --tmpdir)      tmpdir_l="$2"; shift;;
        -L|--stdlog)   stdloglvl_l="$2"; shift;;
        --compress)    compress_l="$2"; shift;;
        --prefix)      prefix_l="$2"; shift;;
        -f|--force)    force=yes;;
        --kernel-only) kernel_only="yes"; no_kernel="no";;
        --no-kernel)   kernel_only="no"; no_kernel="yes";;
        --strip)       do_strip_l="yes";;
        --nostrip)     do_strip_l="no";;
        --hardlink)    do_hardlink_l="yes";;
        --nohardlink)  do_hardlink_l="no";;
        --noprefix)    prefix_l="/";;
        --mdadmconf)   mdadmconf_l="yes";;
        --nomdadmconf) mdadmconf_l="no";;
        --lvmconf)     lvmconf_l="yes";;
        --nolvmconf)   lvmconf_l="no";;
        --debug)       debug="yes";;
        --profile)     profile="yes";;
        --sshkey)      sshkey="$2"; shift;;
        -v|--verbose)  ((verbosity_mod_l++));;
        -q|--quiet)    ((verbosity_mod_l--));;
        -l|--local)
                       allowlocal="yes"
                       [[ -f "$(readlink -f ${0%/*})/dracut-functions.sh" ]] \
                           && dracutbasedir="$(readlink -f ${0%/*})"
                       ;;
        -H|--hostonly|--host-only)
                       hostonly_l="yes" ;;
        -N|--no-hostonly|--no-host-only)
                       hostonly_l="no" ;;
        --fstab)       use_fstab_l="yes" ;;
        -h|--help)     long_usage; exit 1 ;;
        -i|--include)  push include_src "$2"
                       shift;;
        --bzip2)       compress_l="bzip2";;
        --lzma)        compress_l="lzma";;
        --xz)          compress_l="xz";;
        --no-compress) _no_compress_l="cat";;
        --gzip)        compress_l="gzip";;
        --list-modules) do_list="yes";;
        -M|--show-modules)
                       show_modules_l="yes"
                       ;;
        --keep)        keep="yes";;
        --printsize)   printsize="yes";;
        --regenerate-all) regenerate_all="yes";;
        --noimageifnotneeded) noimageifnotneeded="yes";;

        --) shift; break;;

        *)  # should not even reach this point
            printf "\n!Unknown option: '%s'\n\n" "$1" >&2; usage; exit 1;;
    esac
    shift
done

# getopt cannot handle multiple arguments, so just handle "-I,--include"
# the old fashioned way

while (($# > 0)); do
    case ${1%%=*} in
        ++include) push include_src "$2"
                       push include_target "$3"
                       shift 2;;
        *)
            if ! [[ ${outfile+x} ]]; then
                outfile=$1
            elif ! [[ ${kernel+x} ]]; then
                kernel=$1
            else
                printf "\nUnknown arguments: %s\n\n" "$*" >&2
                usage; exit 1;
            fi
            ;;
    esac
    shift
done

if [[ $regenerate_all == "yes" ]]; then
    ret=0
    if [[ $kernel ]]; then
        echo "--regenerate-all cannot be called with a kernel version" >&2
        exit 1
    fi

    if [[ $outfile ]]; then
        echo "--regenerate-all cannot be called with a image file" >&2
        exit 1
    fi

    ((len=${#dracut_args[@]}))
    for ((i=0; i < len; i++)); do
        [[ ${dracut_args[$i]} == "--regenerate-all" ]] && \
            unset dracut_args[$i]
    done

    cd /lib/modules
    for i in *; do
        [[ -f $i/modules.builtin ]] || continue
        dracut --kver=$i "${dracut_args[@]}"
        ((ret+=$?))
    done
    exit $ret
fi

if ! [[ $kernel ]]; then
    kernel=$(uname -r)
fi

if ! [[ $outfile ]]; then
    [[ -f /etc/machine-id ]] && read MACHINE_ID < /etc/machine-id

    if [[ $MACHINE_ID ]] && ( [[ -d /boot/${MACHINE_ID} ]] || [[ -L /boot/${MACHINE_ID} ]] ); then
        outfile="/boot/${MACHINE_ID}/$kernel/initrd"
    else
        outfile="/boot/initramfs-$kernel.img"
    fi
fi

for i in /usr/sbin /sbin /usr/bin /bin; do
    rl=$i
    if [ -L "$i" ]; then
        rl=$(readlink -f $i)
    fi
    if [[ "$NPATH" != "*:$rl*" ]] ; then
        NPATH+=":$rl"
    fi
done
export PATH="${NPATH#:}"
unset NPATH
unset LD_LIBRARY_PATH
unset GREP_OPTIONS

export DRACUT_LOG_LEVEL=warning
[[ $debug ]] && {
    export DRACUT_LOG_LEVEL=debug
    export PS4='${BASH_SOURCE}@${LINENO}(${FUNCNAME[0]}): ';
    set -x
}

[[ $profile ]] && {
    export PS4='+ $(date "+%s.%N") ${BASH_SOURCE}@${LINENO}: ';
    set -x
    debug=yes
}

[[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut

# if we were not passed a config file, try the default one
if [[ ! -f $conffile ]]; then
    [[ $allowlocal ]] && conffile="$dracutbasedir/dracut.conf" || \
        conffile="/etc/dracut.conf"
fi

if [[ ! -d $confdir ]]; then
    [[ $allowlocal ]] && confdir="$dracutbasedir/dracut.conf.d" || \
        confdir="/etc/dracut.conf.d"
fi

# source our config file
[[ -f $conffile ]] && . "$conffile"

# source our config dir
for f in $(dropindirs_sort ".conf" "$confdir" "$dracutbasedir/dracut.conf.d"); do
    [[ -e $f ]] && . "$f"
done

# these optins add to the stuff in the config file
if (( ${#add_dracutmodules_l[@]} )); then
    while pop add_dracutmodules_l val; do
        add_dracutmodules+=" $val "
    done
fi

if (( ${#force_add_dracutmodules_l[@]} )); then
    while pop force_add_dracutmodules_l val; do
        force_add_dracutmodules+=" $val "
    done
fi

if (( ${#fscks_l[@]} )); then
    while pop fscks_l val; do
        fscks+=" $val "
    done
fi

if (( ${#add_fstab_l[@]} )); then
    while pop add_fstab_l val; do
        add_fstab+=" $val "
    done
fi

if (( ${#fstab_lines_l[@]} )); then
    while pop fstab_lines_l val; do
        push fstab_lines $val
    done
fi

if (( ${#install_items_l[@]} )); then
    while pop install_items_l val; do
        install_items+=" $val "
    done
fi

# these options override the stuff in the config file
if (( ${#dracutmodules_l[@]} )); then
    dracutmodules=''
    while pop dracutmodules_l val; do
        dracutmodules+="$val "
    done
fi

if (( ${#omit_dracutmodules_l[@]} )); then
    omit_dracutmodules=''
    while pop omit_dracutmodules_l val; do
        omit_dracutmodules+="$val "
    done
fi

if (( ${#filesystems_l[@]} )); then
    filesystems=''
    while pop filesystems_l val; do
        filesystems+="$val "
    done
fi

if (( ${#fw_dir_l[@]} )); then
    fw_dir=''
    while pop fw_dir_l val; do
        fw_dir+="$val "
    done
fi

if (( ${#libdirs_l[@]} )); then
    libdirs=''
    while pop libdirs_l val; do
        libdirs+="$val "
    done
fi

[[ $stdloglvl_l ]] && stdloglvl=$stdloglvl_l
[[ ! $stdloglvl ]] && stdloglvl=4
stdloglvl=$((stdloglvl + verbosity_mod_l))
((stdloglvl > 6)) && stdloglvl=6
((stdloglvl < 0)) && stdloglvl=0

[[ $drivers_dir_l ]] && drivers_dir=$drivers_dir_l
[[ $do_strip_l ]] && do_strip=$do_strip_l
[[ $do_strip ]] || do_strip=yes
[[ $do_hardlink_l ]] && do_hardlink=$do_hardlink_l
[[ $do_hardlink ]] || do_hardlink=yes
[[ $prefix_l ]] && prefix=$prefix_l
[[ $prefix = "/" ]] && unset prefix
[[ $hostonly_l ]] && hostonly=$hostonly_l
[[ $use_fstab_l ]] && use_fstab=$use_fstab_l
[[ $mdadmconf_l ]] && mdadmconf=$mdadmconf_l
[[ $lvmconf_l ]] && lvmconf=$lvmconf_l
[[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut
[[ $fw_dir ]] || fw_dir="/lib/firmware/updates /lib/firmware"
[[ $tmpdir_l ]] && tmpdir="$tmpdir_l"
[[ $tmpdir ]] || tmpdir=/var/tmp
[[ $compress_l ]] && compress=$compress_l
[[ $show_modules_l ]] && show_modules=$show_modules_l
[[ $nofscks_l ]] && nofscks="yes"
[[ $ro_mnt_l ]] && ro_mnt="yes"
# eliminate IFS hackery when messing with fw_dir
fw_dir=${fw_dir//:/ }

# handle compression options.
[[ $compress ]] || compress="gzip"
case $compress in
    bzip2) compress="bzip2 -9";;
    lzma)  compress="lzma -9";;
    xz)    compress="xz --check=crc32 --lzma2=dict=1MiB";;
    gzip)  command -v pigz > /dev/null 2>&1 && compress="pigz -9" || \
                                         compress="gzip -9";;
esac
if [[ $_no_compress_l = "cat" ]]; then
    compress="cat"
fi

[[ $hostonly = yes ]] && hostonly="-h"
[[ $hostonly != "-h" ]] && unset hostonly

readonly TMPDIR="$tmpdir"
readonly initdir=$(mktemp --tmpdir="$TMPDIR/" -d -t initramfs.XXXXXX)
[ -d "$initdir" ] || {
    echo "dracut: mktemp --tmpdir=\"$TMPDIR/\" -d -t initramfs.XXXXXX failed." >&2
    exit 1
}

# clean up after ourselves no matter how we die.
trap 'ret=$?;[[ $outfile ]] && [[ -f $outfile.$$ ]] && rm -f "$outfile.$$";[[ $keep ]] && echo "Not removing $initdir." >&2 || { [[ $initdir ]] && rm -rf "$initdir";exit $ret; };' EXIT
# clean up after ourselves no matter how we die.
trap 'exit 1;' SIGINT

export DRACUT_KERNEL_LAZY="1"
export DRACUT_RESOLVE_LAZY="1"

if [[ -f $dracutbasedir/dracut-functions.sh ]]; then
    . $dracutbasedir/dracut-functions.sh
else
    echo "dracut: Cannot find $dracutbasedir/dracut-functions.sh." >&2
    echo "dracut: Are you running from a git checkout?" >&2
    echo "dracut: Try passing -l as an argument to $0" >&2
    exit 1
fi

inst /bin/sh
if ! $DRACUT_INSTALL ${initdir+-D "$initdir"} -R "$initdir/bin/sh" &>/dev/null; then
    unset DRACUT_RESOLVE_LAZY
    export DRACUT_RESOLVE_DEPS=1
fi
rm -fr ${initdir}/*

if [[ -f $dracutbasedir/dracut-version.sh ]]; then
    . $dracutbasedir/dracut-version.sh
fi

# Verify bash version, current minimum is 3.1
if (( ${BASH_VERSINFO[0]} < 3 ||
    ( ${BASH_VERSINFO[0]} == 3 && ${BASH_VERSINFO[1]} < 1 ) )); then
    dfatal 'You need at least Bash 3.1 to use dracut, sorry.'
    exit 1
fi

dracutfunctions=$dracutbasedir/dracut-functions.sh
export dracutfunctions

if (( ${#drivers_l[@]} )); then
    drivers=''
    while pop drivers_l val; do
        drivers+="$val "
    done
fi
drivers=${drivers/-/_}

if (( ${#add_drivers_l[@]} )); then
    while pop add_drivers_l val; do
        add_drivers+=" $val "
    done
fi
add_drivers=${add_drivers/-/_}

if (( ${#omit_drivers_l[@]} )); then
    while pop omit_drivers_l val; do
        omit_drivers+=" $val "
    done
fi
omit_drivers=${omit_drivers/-/_}

if (( ${#kernel_cmdline_l[@]} )); then
    while pop kernel_cmdline_l val; do
        kernel_cmdline+=" $val "
    done
fi

omit_drivers_corrected=""
for d in $omit_drivers; do
    strstr " $drivers $add_drivers " " $d " && continue
    omit_drivers_corrected+="$d|"
done
omit_drivers="${omit_drivers_corrected%|}"
unset omit_drivers_corrected

# prepare args for logging
for ((i=0; i < ${#dracut_args[@]}; i++)); do
    strstr "${dracut_args[$i]}" " " && \
        dracut_args[$i]="\"${dracut_args[$i]}\""
        #" keep vim happy
done
ddebug "Executing: $0 ${dracut_args[@]}"

[[ $do_list = yes ]] && {
    for mod in $dracutbasedir/modules.d/*; do
        [[ -d $mod ]] || continue;
        [[ -e $mod/install || -e $mod/installkernel || \
            -e $mod/module-setup.sh ]] || continue
        echo ${mod##*/??}
    done
    exit 0
}

# This is kinda legacy -- eventually it should go away.
case $dracutmodules in
    ""|auto) dracutmodules="all" ;;
esac

abs_outfile=$(readlink -f "$outfile") && outfile="$abs_outfile"

if [[ -d $srcmods ]]; then
    [[ -f $srcmods/modules.dep ]] || {
      dwarn "$srcmods/modules.dep is missing. Did you run depmod?"
    }
fi

if [[ -f $outfile && ! $force ]]; then
    dfatal "Will not override existing initramfs ($outfile) without --force"
    exit 1
fi

outdir=${outfile%/*}
[[ $outdir ]] || outdir="/"

if [[ ! -d "$outdir" ]]; then
    dfatal "Can't write to $outdir: Directory $outdir does not exist or is not accessible."
    exit 1
elif [[ ! -w "$outdir" ]]; then
    dfatal "No permission to write to $outdir."
    exit 1
elif [[ -f "$outfile" && ! -w "$outfile" ]]; then
    dfatal "No permission to write $outfile."
    exit 1
fi

# Need to be able to have non-root users read stuff (rpcbind etc)
chmod 755 "$initdir"

if [[ $hostonly ]]; then
    for i in /sys /proc /run /dev; do
        if ! findmnt "$i" &>/dev/null; then
            dwarning "Turning off host-only mode: '$i' is not mounted!"
            unset hostonly
        fi
    done
    if ! [[ -d /run/udev/data ]]; then
        dwarning "Turning off host-only mode: udev database not found!"
        unset hostonly
    fi
fi

declare -A host_fs_types

for line in "${fstab_lines[@]}"; do
    set -- $line
    #dev mp fs fsopts
    push host_devs "$1"
    host_fs_types["$1"]="$3"
done

for f in $add_fstab; do
    [ -e $f ] || continue
    while read dev rest; do
        push host_devs $dev
    done < $f
done

if (( ${#add_device_l[@]} )); then
    while pop add_device_l val; do
        add_device+=" $val "
    done
fi

for dev in $add_device; do
    push host_devs $dev
done

if [[ $hostonly ]]; then
    # in hostonly mode, determine all devices, which have to be accessed
    # and examine them for filesystem types

    push host_mp \
        "/" \
        "/etc" \
        "/usr" \
        "/usr/bin" \
        "/usr/sbin" \
        "/usr/lib" \
        "/usr/lib64" \
        "/boot"

    for mp in "${host_mp[@]}"; do
        mountpoint "$mp" >/dev/null 2>&1 || continue
        push host_devs $(readlink -f "/dev/block/$(find_block_device "$mp")")
    done

    while read dev type rest; do
        [[ -b $dev ]] || continue
        [[ "$type" == "partition" ]] || continue
        while read _d _m _t _o _r; do
            [[ "$_d" == \#* ]] && continue
            [[ $_d ]] || continue
            [[ $_t != "swap" ]] || [[ $_m != "swap" ]] && continue
            [[ "$_o" == *noauto* ]] && continue
            [[ "$_d" == UUID\=* ]] && _d="/dev/disk/by-uuid/${_d#UUID=}"
            [[ "$_d" == LABEL\=* ]] && _d="/dev/disk/by-label/$_d#LABEL=}"
            [[ "$_d" -ef "$dev" ]] || continue
            push host_devs $(readlink -f $dev)
            break
        done < /etc/fstab
    done < /proc/swaps

fi

_get_fs_type() (
    [[ $1 ]] || return
    if [[ -b $1 ]] && get_fs_env $1; then
        echo "$(readlink -f $1) $ID_FS_TYPE"
        return 1
    fi
    if [[ -b /dev/block/$1 ]] && get_fs_env /dev/block/$1; then
        echo "$(readlink -f /dev/block/$1) $ID_FS_TYPE"
        return 1
    fi
    if fstype=$(find_dev_fstype $1); then
        echo "$1 $fstype"
        return 1
    fi
    return 1
)

for dev in "${host_devs[@]}"; do
    while read key val; do
        host_fs_types["$key"]="$val"
    done < <(
        _get_fs_type $dev
        check_block_and_slaves_all _get_fs_type $(get_maj_min $dev)
    )
done

[[ -d $udevdir ]] \
    || udevdir=$(pkg-config udev --variable=udevdir 2>/dev/null)
if ! [[ -d "$udevdir" ]]; then
    [[ -d /lib/udev ]] && udevdir=/lib/udev
    [[ -d /usr/lib/udev ]] && udevdir=/usr/lib/udev
fi

[[ -d $systemdutildir ]] \
    || systemdutildir=$(pkg-config systemd --variable=systemdutildir 2>/dev/null)

if ! [[ -d "$systemdutildir" ]]; then
    [[ -d /lib/systemd ]] && systemdutildir=/lib/systemd
    [[ -d /usr/lib/systemd ]] && systemdutildir=/usr/lib/systemd
fi

[[ -d $systemdsystemunitdir ]] \
    || systemdsystemunitdir=$(pkg-config systemd --variable=systemdsystemunitdir 2>/dev/null)

[[ -d "$systemdsystemunitdir" ]] || systemdsystemunitdir=${systemdutildir}/system

[[ -d $systemdsystemconfdir ]] \
    || systemdsystemconfdir=$(pkg-config systemd --variable=systemdsystemconfdir 2>/dev/null)

[[ -d "$systemdsystemconfdir" ]] || systemdsystemconfdir=/etc/systemd/system

export initdir dracutbasedir dracutmodules \
    fw_dir drivers_dir debug no_kernel kernel_only \
    omit_drivers mdadmconf lvmconf \
    use_fstab fstab_lines libdirs fscks nofscks ro_mnt \
    stdloglvl sysloglvl fileloglvl kmsgloglvl logfile \
    debug host_fs_types host_devs sshkey add_fstab \
    DRACUT_VERSION udevdir prefix filesystems drivers \
    systemdutildir systemdsystemunitdir systemdsystemconfdir

# Create some directory structure first
[[ $prefix ]] && mkdir -m 0755 -p "${initdir}${prefix}"

[[ -h /lib ]] || mkdir -m 0755 -p "${initdir}${prefix}/lib"
[[ $prefix ]] && ln -sfn "${prefix#/}/lib" "$initdir/lib"

if [[ $prefix ]]; then
    for d in bin etc lib sbin tmp usr var $libdirs; do
        strstr "$d" "/" && continue
        ln -sfn "${prefix#/}/${d#/}" "$initdir/$d"
    done
fi

if [[ $kernel_only != yes ]]; then
    for d in usr/bin usr/sbin bin etc lib sbin tmp usr var $libdirs; do
        [[ -e "${initdir}${prefix}/$d" ]] && continue
        if [ -L "/$d" ]; then
            inst_symlink "/$d" "${prefix}/$d"
        else
            mkdir -m 0755 -p "${initdir}${prefix}/$d"
        fi
    done

    for d in dev proc sys sysroot root run run/lock run/initramfs; do
        if [ -L "/$d" ]; then
            inst_symlink "/$d"
        else
            mkdir -m 0755 -p "$initdir/$d"
        fi
    done

    ln -sfn ../run "$initdir/var/run"
    ln -sfn ../run/lock "$initdir/var/lock"
    ln -sfn ../run/log "$initdir/var/log"
else
    for d in lib "$libdir"; do
        [[ -e "${initdir}${prefix}/$d" ]] && continue
        if [ -h "/$d" ]; then
            inst "/$d" "${prefix}/$d"
        else
            mkdir -m 0755 -p "${initdir}${prefix}/$d"
        fi
    done
fi

if [[ $kernel_only != yes ]]; then
    mkdir -p "${initdir}/etc/cmdline.d"
    for _d in $hookdirs; do
        mkdir -m 0755 -p ${initdir}/lib/dracut/hooks/$_d
    done
    if [[ "$UID" = "0" ]]; then
        [ -c ${initdir}/dev/null ] || mknod ${initdir}/dev/null c 1 3
        [ -c ${initdir}/dev/kmsg ] || mknod ${initdir}/dev/kmsg c 1 11
        [ -c ${initdir}/dev/console ] || mknod ${initdir}/dev/console c 5 1
    fi
fi

mods_to_load=""
# check all our modules to see if they should be sourced.
# This builds a list of modules that we will install next.
for_each_module_dir check_module
for_each_module_dir check_mount

strstr "$mods_to_load" "fips" && export DRACUT_FIPS_MODE=1

_isize=0 #initramfs size
modules_loaded=" "
# source our modules.
for moddir in "$dracutbasedir/modules.d"/[0-9][0-9]*; do
    _d_mod=${moddir##*/}; _d_mod=${_d_mod#[0-9][0-9]}
    if strstr "$mods_to_load" " $_d_mod "; then
        [[ $show_modules = yes ]] && echo "$_d_mod" || \
            dinfo "*** Including module: $_d_mod ***"
        if [[ $kernel_only = yes ]]; then
            module_installkernel $_d_mod || {
                dfatal "installkernel failed in module $_d_mod"
                exit 1
            }
        else
            module_install $_d_mod
            if [[ $no_kernel != yes ]]; then
                module_installkernel $_d_mod || {
                    dfatal "installkernel failed in module $_d_mod"
                    exit 1
                }
            fi
        fi
        mods_to_load=${mods_to_load// $_d_mod /}
        modules_loaded+="$_d_mod "

        #print the module install size
        if [ -n "$printsize" ]; then
            _isize_new=$(du -sk ${initdir}|cut -f1)
            _isize_delta=$(($_isize_new - $_isize))
            echo "$_d_mod install size: ${_isize_delta}k"
            _isize=$_isize_new
        fi
    fi
done
unset moddir

for i in $modules_loaded; do
    mkdir -p $initdir/lib/dracut
    echo "$i" >> $initdir/lib/dracut/modules.txt
done

dinfo "*** Including modules done ***"

## final stuff that has to happen
if [[ $no_kernel != yes ]]; then

    if [[ $drivers ]]; then
        hostonly='' instmods $drivers
    fi

    if [[ $add_drivers ]]; then
        hostonly='' instmods -c $add_drivers
    fi
    if [[ $filesystems ]]; then
        hostonly='' instmods -c $filesystems
    fi

    dinfo "*** Installing kernel module dependencies and firmware ***"
    dracut_kernel_post
    dinfo "*** Installing kernel module dependencies and firmware done ***"

    if [[ $noimageifnotneeded == yes ]] && [[ $hostonly ]]; then
        if [[ ! -f "$initdir/lib/dracut/need-initqueue" ]] && \
            [[ -f ${initdir}/lib/modules/$kernel/modules.dep && ! -s ${initdir}/lib/modules/$kernel/modules.dep ]]; then
            for i in ${initdir}/etc/cmdline.d/*.conf; do
                # We need no initramfs image and do not generate one.
                [[ $i == "${initdir}/etc/cmdline.d/*.conf" ]] && exit 0
            done
        fi
    fi
fi

if [[ $kernel_only != yes ]]; then
    (( ${#install_items[@]} > 0 )) && dracut_install  ${install_items[@]}

    [[ $kernel_cmdline ]] && echo "$kernel_cmdline" >> "${initdir}/etc/cmdline.d/01-default.conf"

    while pop fstab_lines line; do
        echo "$line 0 0" >> "${initdir}/etc/fstab"
    done

    for f in $add_fstab; do
        cat $f >> "${initdir}/etc/fstab"
    done

    if [ -d ${initdir}/$systemdutildir ]; then
        mkdir -p ${initdir}/etc/conf.d
        {
            echo "systemdutildir=\"$systemdutildir\""
            echo "systemdsystemunitdir=\"$systemdsystemunitdir\""
            echo "systemdsystemconfdir=\"$systemdsystemconfdir\""
        } > ${initdir}/etc/conf.d/systemd.conf
    fi

    if [[ $DRACUT_RESOLVE_LAZY ]] && [[ $DRACUT_INSTALL ]]; then
        dinfo "*** Resolving executable dependencies ***"
        find "$initdir" -type f \
            '(' -perm -0100 -or -perm -0010 -or -perm -0001 ')' \
            -not -path '*.ko' -print0 \
        | xargs -r -0 $DRACUT_INSTALL ${initdir+-D "$initdir"} -R ${DRACUT_FIPS_MODE+-H}
        dinfo "*** Resolving executable dependencies done***"
    fi
fi

while pop include_src src && pop include_target tgt; do
    if [[ $src && $tgt ]]; then
        if [[ -f $src ]]; then
            inst $src $tgt
        else
            ddebug "Including directory: $src"
            mkdir -p "${initdir}/${tgt}"
            # check for preexisting symlinks, so we can cope with the
            # symlinks to $prefix
            for i in "$src"/*; do
                [[ -e "$i" || -h "$i" ]] || continue
                s=${initdir}/${tgt}/${i#$src/}
                if [[ -d "$i" ]]; then
                    if ! [[ -e "$s" ]]; then
                        mkdir -m 0755 -p "$s"
                        chmod --reference="$i" "$s"
                    fi
                    cp --reflink=auto --sparse=auto -fa -t "$s" "$i"/*
                else
                    cp --reflink=auto --sparse=auto -fa -t "$s" "$i"
                fi
            done
        fi
    fi
done

if [[ $kernel_only != yes ]]; then
    # make sure that library links are correct and up to date
    for f in /etc/ld.so.conf /etc/ld.so.conf.d/*; do
        [[ -f $f ]] && inst_simple "$f"
    done
    if ! ldconfig -r "$initdir"; then
        if [[ $UID = 0 ]]; then
            derror "ldconfig exited ungracefully"
        else
            derror "ldconfig might need uid=0 (root) for chroot()"
        fi
    fi
fi

if (($maxloglvl >= 5)); then
    ddebug "Listing sizes of included files:"
    du -c "$initdir" | sort -n | ddebug
fi

PRELINK_BIN=$(command -v prelink)
if [[ $UID = 0 ]] && [[ $PRELINK_BIN ]]; then
    if [[ $DRACUT_FIPS_MODE ]]; then
        dinfo "*** Pre-unlinking files ***"
        dracut_install -o prelink /etc/prelink.conf /etc/prelink.conf.d/*.conf /etc/prelink.cache
        chroot "$initdir" $PRELINK_BIN -u -a
        rm -f "$initdir"/$PRELINK_BIN
        rm -fr "$initdir"/etc/prelink.*
        dinfo "*** Pre-unlinking files done ***"
    else
        dinfo "*** Pre-linking files ***"
        dracut_install -o prelink /etc/prelink.conf /etc/prelink.conf.d/*.conf
        chroot "$initdir" $PRELINK_BIN -a
        rm -f "$initdir"/$PRELINK_BIN
        rm -fr "$initdir"/etc/prelink.*
        dinfo "*** Pre-linking files done ***"
    fi
fi

if [[ $do_hardlink = yes ]] && command -v hardlink >/dev/null; then
    dinfo "*** Hardlinking files ***"
    hardlink "$initdir" 2>&1
    dinfo "*** Hardlinking files done ***"
fi

# strip binaries
if [[ $do_strip = yes ]] ; then
    for p in strip xargs find; do
        if ! type -P $p >/dev/null; then
            dwarn "Could not find '$p'. Not stripping the initramfs."
            do_strip=no
        fi
    done
fi

if [[ $do_strip = yes ]] ; then
    dinfo "*** Stripping files ***"
    if [[ $DRACUT_FIPS_MODE ]]; then
        find "$initdir" -type f \
            -executable -not -path '*/lib/modules/*.ko' -print0 \
            | while read -r -d $'\0' f; do
            if ! [[ -e "${f%/*}/.${f##*/}.hmac" ]] \
                && ! [[ -e "/lib/fipscheck/${f##*/}.hmac" ]] \
                && ! [[ -e "/lib64/fipscheck/${f##*/}.hmac" ]]; then
                echo -n "$f"; echo -n -e "\000"
            fi
        done | xargs -r -0 strip -g 2>/dev/null
    else
        find "$initdir" -type f \
            -executable -not -path '*/lib/modules/*.ko' -print0 \
            | xargs -r -0 strip -g 2>/dev/null
    fi

    # strip kernel modules, but do not touch signed modules
    find "$initdir" -type f -path '*/lib/modules/*.ko' -print0 \
        | while read -r -d $'\0' f; do
        SIG=$(tail -c 28 "$f")
        [[ $SIG == '~Module signature appended~' ]] || { echo -n "$f"; echo -n -e "\000"; }
    done | xargs -r -0 strip -g

    dinfo "*** Stripping files done ***"
fi

rm -f "$outfile"
dinfo "*** Creating image file ***"
if ! ( umask 077; cd "$initdir"; find . |cpio -R 0:0 -H newc -o --quiet| \
    $compress > "$outfile.$$"; ); then
    dfatal "dracut: creation of $outfile.$$ failed"
    exit 1
fi
mv $outfile.$$ $outfile
dinfo "*** Creating image file done ***"

dinfo "Wrote $outfile:"
dinfo "$(ls -l "$outfile")"

exit 0
