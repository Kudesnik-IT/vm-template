#!/bin/bash

# Функция для вывода сообщений с отступом
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Предупреждение перед началом
log "\e[31mВНИМАНИЕ\e[0m: Этот скрипт очистит систему и подготовит её к использованию как шаблон."
log "После выполнения скрипта системе будет нужна дополнительная настройка, чтобы вернуться к нормальному состоянию."
read -p "Вы уверены, что хотите продолжить? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log "Операция отменена пользователем."
    exit 1
fi

log "Начинаем подготовку системы к шаблону..."

# --- Шаг 1: Очистка системы ---
log "Шаг 1: Очистка временных файлов и журналов..."
sudo rm -rf /tmp/* /var/tmp/*
sudo truncate -s 0 /var/log/*.log /var/log/syslog /var/log/auth.log
sudo apt clean
sudo apt autoclean
sudo apt autoremove --purge -y
log "Шаг 1 завершен."

# --- Шаг 2: Сброс уникальных идентификаторов ---
log "Шаг 2: Сброс UUID файловых систем..."
for partition in $(lsblk -ln -o NAME | grep -E "^sd"); do
    sudo tune2fs -U random /dev/$partition 2>/dev/null || true
done
log "UUID файловых систем сброшены."

log "Шаг 2: Сброс MAC-адресов сетевых интерфейсов..."
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules
log "MAC-адреса сброшены."

# --- Шаг 3: Настройка имени хоста и сети ---
log "Шаг 3: Сброс имени хоста..."
sudo hostnamectl set-hostname localhost
echo "127.0.0.1   localhost" | sudo tee /etc/hosts > /dev/null
echo "::1         localhost ip6-localhost ip6-loopback" | sudo tee -a /etc/hosts > /dev/null
log "Имя хоста и файл hosts обновлены."

# --- Шаг 4: Удаление SSH-ключей ---
log "Шаг 4: Удаление SSH-ключей..."
sudo rm -f /etc/ssh/ssh_host_*
log "SSH-ключи удалены."

# --- Шаг 5: Отключение служб и автозапуска ---
log "Шаг 5: Отключение служб..."
sudo systemctl disable --now systemd-resolved 2>/dev/null || true
sudo systemctl disable --now NetworkManager 2>/dev/null || true
log "Службы отключены."

# --- Шаг 6: Очистка истории команд ---
log "Шаг 6: Очистка истории команд..."
history -c
sudo history -c
sudo rm -f ~/.bash_history /root/.bash_history
log "История команд очищена."

# --- Шаг 7: Дефрагментация диска (опционально) ---
#log "Шаг 7: Дефрагментация диска..."
#sudo dd if=/dev/zero of=/zero.fill bs=1M 2>/dev/null || true
#sudo rm -f /zero.fill
#log "Дефрагментация завершена."

# --- Завершение ---
log "Подготовка системы к шаблону завершена."
log "Теперь вы можете выключить систему и преобразовать её в шаблон в Proxmox."