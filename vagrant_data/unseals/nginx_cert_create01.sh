#!/usr/bin/env bash
echo "$(date +%Y-%m-%d_%H:%M:%S%Z%z) [INFO] Запущен скрипт генерации сертификата" | sudo tee -a /var/log/vault.log

# Указываем полный путь к сертификату и параметр Срок до окончания действия сертификата = 5 дней  (120часов или 432000сек)
CERT_NAME="test.example.com.crt"
DAYS="30"
#Переходим в рабочий каталог `/vagrant_data`
cd /vagrant_data 

# Проверяем оставшийся срок жизни сертификата
echo "Текущий статус сертификата ${CERT_NAME}.pem:"
echo $(sudo openssl x509 -enddate -noout -in "/etc/nginx/conf.d/${CERT_NAME}.pem" -checkend $((DAYS*24*60*60)))
echo "==========="
echo "Останавливаем службу nginx"
sudo systemctl stop nginx
echo "Дата окончания действия сертификата ${CERT_NAME}.pem истекает - $(sudo openssl x509 -enddate -noout -in /etc/nginx/conf.d/${CERT_NAME}.pem)"
echo "==========="
echo "Создаем сертификат для nginx"
vault write -format=json pki_int/issue/example-dot-com common_name="localhost" alt_names="localhost" ttl="1d" > $CERT_NAME

# Готовим для сервера NGINX Открытый(test.example.com.crt.pem) и Закрытый(test.example.com.crt.key) ключи
cat $CERT_NAME | jq -r .data.certificate > "$CERT_NAME.pem"
cat $CERT_NAME | jq -r .data.issuing_ca >> "$CERT_NAME.pem"
cat $CERT_NAME | jq -r .data.private_key > "$CERT_NAME.key"

echo "Выпущен новый сертификат ${CERT_NAME}.pem  $(sudo openssl x509 -startdate -enddate -noout -in ${CERT_NAME}.pem)"
sudo cp "./$CERT_NAME.pem" /etc/nginx/conf.d/"$CERT_NAME.pem"
sudo cp "./$CERT_NAME.key" /etc/nginx/conf.d/"$CERT_NAME.key"
if (($?==0))
then
  echo "Новый сертификат скопирован в папку сертификатов nginx. Дата окончания действия сертификата ${CERT_NAME}.pem истекает - $(sudo openssl x509 -enddate -noout -in /etc/nginx/conf.d/${CERT_NAME}.pem)"
  echo "$(date +%Y-%m-%d_%H:%M:%S%Z%z) [INFO] Установлен новый сертификат ${CERT_NAME}.pem  $(sudo openssl x509 -serial -enddate -noout -in /etc/nginx/conf.d/${CERT_NAME}.pem)"  | tr '\n' ',' | sudo tee -a /var/log/vault.log
  echo "" | sudo tee -a /var/log/vault.log

else
  echo "Ошибка копирования нового сертификата"
  echo $(sudo openssl x509 -enddate -noout -in "${CERT_NAME}.pem" -checkend $((DAYS*24*60*60)))
  echo "$(date +%Y-%m-%d_%H:%M:%S%Z%z) [ERROR] Ошибка копирования нового сертификата ${CERT_NAME}.pem" | sudo tee -a /var/log/vault.log
fi
echo "==========="

sudo openssl x509 -enddate -noout -in "/etc/nginx/conf.d/${CERT_NAME}.pem"  -checkend "$((DAYS*24*60*60))" | grep "Certificate will expire"
if(($?==0))
then
  echo "ВНИМАНИЕ Дата окончания действия сертификата ${CERT_NAME}.pem менее чем через ${DAYS} дней "
  echo "$(date +%Y-%m-%d_%H:%M:%S%Z%z) [WARN] ВНИМАНИЕ Дата окончания действия сертификата ${CERT_NAME}.pem менее чем через ${DAYS} дней $(sudo openssl x509 -serial -enddate -noout -in /etc/nginx/conf.d/${CERT_NAME}.pem)"  | tr '\n' ',' | sudo tee -a /var/log/vault.log
  echo "" | sudo tee -a /var/log/vault.log
else
  echo "Дата окончания действия сертификата ${CERT_NAME}.pem более чем через ${DAYS} дней "
fi
# Перезапускаем сервера `nginx`
echo "Перезапускаем службу nginx"
sudo systemctl restart nginx

