# FHLight
echo -e "process attach -p `ps ax|grep Warcraft|grep -v grep|awk '{print $1}'`\nmemory write 0x100a1931a 0xeb\nprocess detach\nquit" > /tmp/luaunlock && lldb -s /tmp/luaunlock
