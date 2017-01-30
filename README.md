X64 Build 23420

echo -e "process attach -p `ps ax|grep 'MacOS/World of Warcraft'|grep -v grep|awk '{print $1}'`\nmemory write 0x100ad79ba 0xeb\nprocess detach\nquit" > /tmp/luaunlock && lldb -s /tmp/luaunlock
