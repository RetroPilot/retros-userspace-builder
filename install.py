#!/usr/bin/env python3

import subprocess
import requests
import os
import tempfile
import shutil

#BASE_URL = 'http://termux.net/'
BASE_URL = 'https://packages.termux.dev/apt/'

# Create mirror using
# lftp -c "mirror --use-pget-n=10 --verbose http://termux.net"
# azcopy --source dists/ --destination https://termuxdist.blob.core.windows.net/dists --recursive --dest-key $(az storage account keys list --account-name termuxdist --output tsv --query "[0].value")


DEFAULT_PKG = ['apt', 'bash', 'busybox', 'ca-certificates', 'command-not-found', 'dash', 'dash', 'dpkg', 'gdbm', 'gpgv', 'libandroid-support', 'libbz2', 'libc++', 'libcrypt', 'libcurl', 'libffi', 'libgcrypt', 'libgpg-error', 'liblzma', 'libnghttp2', 'libsqlite', 'ndk-sysroot', 'ncurses', 'ncurses-ui-libs', 'openssl', 'python', 'python-pip', 'readline', 'termux-am', 'termux-exec', 'termux-tools', 'qt5-base', 'qt5-declarative', 'libicu', 'swig', 'gettext', 'ripgrep']

# The checked-in debs are built using the neos branch on:
# https://github.com/commaai/termux-packages/tree/neos/
#
# Quick Start:
#  * start docker: scripts/run-docker.sh
#  * build inside container: ./build-package.sh -a aarch64 python
#  * copy the deb from termux-packages/debs/

LOCAL_OVERRIDE_PKG = {
  #'rust': 'rust_1.38.0-4_aarch64.deb',
  #'python': 'python_3.8.5_aarch64.deb',
  #'swig': 'swig_4.0.1-1_aarch64.deb',
  'libicu': 'libicu_65.1-1_aarch64.deb',
  #'gettext': 'gettext_0.20.1-3_aarch64.deb',
  #'ripgrep': 'ripgrep_11.0.2-1_aarch64.deb',
  'qt5-base': 'qt5-base_5.12.8-28_aarch64.deb',
  'qt5-declarative': 'qt5-declarative_5.12.8-28_aarch64.deb',
  'apt': 'apt_2.7.1-1_aarch64.deb' # patched to remove stupid ass "can't run as root" bullshit only an asshole would add fuck those guys i mean it's my FUCKING OS let me do WHAT I WANT assholes. you know what? this ramble is getting me all sweaty. i'm spiraling. anyway, i fixed that bullshit. at least this isn't the longest single line in the file.
}

def load_packages():
    pkg_deps = {}
    pkg_filenames = {}

    r = requests.get(BASE_URL + 'termux-root/dists/stable/main/binary-aarch64/Packages').text
    r2 = requests.get(BASE_URL + 'termux-main/dists/stable/main/binary-aarch64/Packages').text
    print(BASE_URL + 'dists/stable/main/binary-aarch64/Packages')

    for l in r.split('\n'):
        if l.startswith("Package:"):
            pkg_name = l.split(': ')[1]
            pkg_depends = []
        elif l.startswith('Depends: '):
            pkg_depends = l.split(': ')[1].split(',')
            pkg_depends = [p.replace(' ', '') for p in pkg_depends]

            # strip version (eg. gnupg (>= 2.2.9-1))
            pkg_depends = [p.split('(')[0] for p in pkg_depends]
        elif l.startswith('Filename: '):
            pkg_filename = l.split(': ')[1]
            pkg_deps[pkg_name] = pkg_depends
            pkg_filenames[pkg_name] = "termux-root/"+pkg_filename

    for l in r2.split('\n'):
        if l.startswith("Package:"):
            pkg_name = l.split(': ')[1]
            pkg_depends = []
        elif l.startswith('Depends: '):
            pkg_depends = l.split(': ')[1].split(',')
            pkg_depends = [p.replace(' ', '') for p in pkg_depends]
            pkg_depends = [p.replace('|dropbear','') for p in pkg_depends]

            # strip version (eg. gnupg (>= 2.2.9-1))
            pkg_depends = [p.split('(')[0] for p in pkg_depends]
        elif l.startswith('Filename: '):
            pkg_filename = l.split(': ')[1]
            pkg_deps[pkg_name] = pkg_depends
            pkg_filenames[pkg_name] = "termux-main/"+pkg_filename
    return pkg_deps, pkg_filenames


def get_dependencies(pkg_deps, pkg_name):
    r = [pkg_name]
    try:
        new_deps = pkg_deps[pkg_name]
        for dep in new_deps:
            r += get_dependencies(pkg_deps, dep)
    except KeyError:
        pass

    return r


def install_package(pkg_deps, pkg_filenames, pkg):
    if not os.path.exists('out'):
        os.mkdir('out')

    build_usr_dir = os.getcwd()
    tmp_dir = tempfile.mkdtemp()

    if pkg in LOCAL_OVERRIDE_PKG:
        deb_name = LOCAL_OVERRIDE_PKG[pkg]
        deb_path = os.path.join(os.path.join(build_usr_dir, "debs"), deb_name)
        print("Using local copy of package %s - %s - %s" % (pkg, tmp_dir, deb_name))
    elif pkg in pkg_filenames:
        url = BASE_URL + pkg_filenames[pkg]
        print("Downloading %s - %s - %s" % (pkg, tmp_dir, url))
        r = requests.get(url)
        deb_name = 'out.deb'
        deb_path = os.path.join(tmp_dir, deb_name)
        open(deb_path, 'wb').write(r.content)
    else:
        print("%s not found" % pkg)
        return ""

    subprocess.check_call(['ar', 'x', deb_path], cwd=tmp_dir)
    subprocess.check_call(['tar', '-C', './out', '-p', '-xf', os.path.join(tmp_dir, 'data.tar.xz')])
    if os.path.exists(os.path.join(tmp_dir, 'control.tar.gz')):
        subprocess.check_call(['tar', '-xf', os.path.join(tmp_dir, 'control.tar.gz')], cwd=tmp_dir)
    else:
        subprocess.check_call(['tar', '-xf', os.path.join(tmp_dir, 'control.tar.xz')], cwd=tmp_dir)

    control = open(os.path.join(tmp_dir, 'control')).read()
    control += 'Status: install ok installed\n'

    files = subprocess.check_output(['dpkg', '-c', deb_path], cwd=tmp_dir, encoding='utf-8')

    file_list = ""
    for f in files.split('\n'):
        try:
            filename = f.split()[5][1:]
            if filename == '/':
                filename = '/.'  # this is what apt does
            file_list += filename + "\n"

        except IndexError:
            pass

    info_path = 'out/data/data/com.termux/files/usr/var/lib/dpkg/info'
    if not os.path.exists(info_path):
        os.makedirs(info_path)

    open(os.path.join(info_path, pkg + '.list'), 'w').write(file_list)

    copies = ['conffiles', 'postinst', 'prerm']

    for copy in copies:
        f = os.path.join(tmp_dir, copy)
        if os.path.exists(f):
            target = os.path.join(info_path, pkg + '.' + copy)
            shutil.copyfile(f, target)

    return control


if __name__ == "__main__":
    to_install = DEFAULT_PKG
    to_install += [
        'autoconf',
        'automake',
        'bison',
        'clang',
        'cmake',
        'coreutils',
        'curl',
        'ffmpeg',
        'flex',
        'gdb',
        'git',
        'git-lfs',
        'htop',
        'jq',
        'libcurl',
        # 'libcurl-dev',
        'libffi',
        # 'libffi-dev',
        'libjpeg-turbo',
        # 'libjpeg-turbo-dev',
        'liblz4',
        # 'liblz4-dev',
        'liblzo',
        # 'liblzo-dev',
        'libmpc',
        'libtool',
        'libuuid',
        # 'libuuid-dev',
        #'libzmq',
        'libpcap',
        # 'libpcap-dev',
        'make',
        'man',
        'nano',
        'ncurses',
        # 'ncurses-dev',
        'openssh',
        'openssl',
        # 'openssl-dev',
        'openssl-tool',
        'patchelf',
        'pkg-config',
        'rsync',
        'strace',
        'tar',
        'tmux',
        'vim',
        'wget',
        'xz-utils',
        'zlib',
        # 'zlib-dev',
        'binutils',
        'binutils-libs',
        'binutils-bin',
    ]

    pkg_deps, pkg_filenames = load_packages()
    deps = []
    for pkg in to_install:
        deps += get_dependencies(pkg_deps, pkg)
    deps = set(deps)

    status = ""

    for pkg in deps:
        s = install_package(pkg_deps, pkg_filenames, pkg)
        status += s + "\n"
    print(deps)

    try:
        os.makedirs('out/data/data/com.termux/files/usr/var/lib/dpkg/')
    except OSError:
        pass

    status_file = 'out/data/data/com.termux/files/usr/var/lib/dpkg/status'
    open(status_file, 'w').write(status)
