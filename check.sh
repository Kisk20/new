bash
#!/bin/bash

echo "=== Проверка конфигурации системы ==="

echo -e "\n1. Лимиты дескрипторов:"
echo "Soft limit: $(ulimit -Sn)"
echo "Hard limit: $(ulimit -Hn)"
echo "System limit: $(cat /proc/sys/fs/file-max)"

echo -e "\n2. Привязка к CPU для сервисов:"
sudo systemctl list-units --type=service | grep -E "(tarantool|ваш_сервис)" | while read service; do
    svc=$(echo $service | awk '{print $1}')
    echo "Сервис: $svc"
    sudo systemctl cat $svc 2>/dev/null | grep -i cpuaffinity || echo "  CPUAffinity не настроен"
done

echo -e "\n3. Сетевые интерфейсы:"
for iface in $(ip link show | grep -E "^[0-9]+:" | awk -F: '{print $2}' | tr -d ' '); do
    mtu=$(cat /sys/class/net/$iface/mtu 2>/dev/null)
    echo "$iface: MTU=$mtu"
done

echo -e "\n4. Проверка multiqueue:"
for iface in $(ip link show | grep -E "^[0-9]+:" | awk -F: '{print $2}' | tr -d ' '); do
    echo -n "$iface: "
    sudo ethtool -l $iface 2>/dev/null | grep "Combined:" | head -1 || echo "не поддерживает"
done

echo -e "\n5. Диски:"
lsblk -o NAME,TYPE,SIZE,ROTA,MODEL,MOUNTPOINT

echo -e "\n6. Переменные окружения Go процессов:"
ps aux | grep -E "\.go|go_binary" | grep -v grep | while read line; do
    pid=$(echo $line | awk '{print $2}')
    echo "PID $pid:"
    cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep -E "^GOMAXPROCS|^GOMEMLIMIT|^GOGC" || echo "  Не найдены"
done