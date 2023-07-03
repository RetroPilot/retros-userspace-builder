# RetrOS Userspace Builder
This tool builds a sparse userspace for Android that can run RetroPilot. This userspace is included in builds of RetrOS for various devices.

## Build process for generic Android devices
```
git clone https://github.com/RetroPilot/retros-userspace-builder
cd  retros-userspace-builder
./install.py
./finish.sh
```
## Testing
### **ONLY TESTED WITH LINEAGE 18.1**

Use either a rooted Android 11 device or a RetrOS device. For Android devices not running Retros, install termux but don't open it.

Push the userland to the phone with adb and extract it
```
adb push userspace.tar.gz /sdcard/Download/
adb shell
su
cd /data/data/com.termux
tar xvf /sdcard/Download/userspace.tar.gz
```

For non-RetrOS devices, also run:

```
mount -o remount,rw /dev/root /
```
or
```
mount -o remount,rw /
```
then
```
ln -s /data/data/com.termux/files/usr /usr
mkdir -p /tmp && mount -t tmpfs -o size=2048M tmpfs /tmp
```
Enter the userspace
```
export HOME=/data/data/com.termux/files/home && export PATH=/data/data/com.termux/files/usr/bin:/bin && export LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib:/data/data/com.termux/files/usr/local/lib64 && bash
```
Finish up installation on-device
```
cd ~
tmux
./install.sh
```
From here, you can git clone RetroPilot into /data or develop your own applications to run inside the userspace.