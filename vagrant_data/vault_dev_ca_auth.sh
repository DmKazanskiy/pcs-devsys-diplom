#!/usr/bin/env bash
cd /vagrant_data
sudo rm *.crt *.csr *.pem *.key

VAULT_ADDR=http://127.0.0.1:8200
VAULT_TOKEN=root
PREFIX='CA_cert'
PKI_INT='pki_intermediate'
echo export $VAULT_ADDR
export $VAULT_ADDR
echo export $VAULT_TOKEN
export $VAULT_TOKEN
echo 'sleep 3s....'
vault login root 
sleep 1
# Активируем PKI тип секрета для корневого центра сертификации
vault secrets enable pki
#Создаем корневой центр сертификации (CA). 10 лет и сохраняем корневой сертификат.
vault write -field=certificate pki/root/generate/internal \
     common_name="localnginx" \
     alt_names="localnginx" \
     ttl=87600h > ${PREFIX}.crt

#Публикуем URL’ы для корневого центра сертификации
vault write pki/config/urls \
  issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
  crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

#Активируем PKI тип секрета для промежуточного центра сертификации
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
#Генерируем запрос на выдачу сертификата для промежуточного центра сертификации
vault write -format=json pki_int/intermediate/generate/internal \
     common_name="localnginx" \
     alt_names="localnginx" \
     | jq -r '.data.csr' > ${PKI_INT}.csr
#Отправляем полученный CSR-файл в корневой центр сертификации, получаем сертификат для промежуточного центра сертификации (5лет)
vault write -format=json pki/root/sign-intermediate csr=@${PKI_INT}.csr \
     format=pem_bundle ttl="43800h" \
     | jq -r '.data.certificate' > ${PKI_INT}.cert.pem

#Публикуем подписанный сертификат промежуточного центра сертификации
vault write pki_int/intermediate/set-signed certificate=@${PKI_INT}.cert.pem

#Создаем роль, с помощью которой будем выдавать сертификаты (макс 30 дней)
vault write pki_int/roles/example-dot-com \
     allow_bare_domains=true \
     allow_glob_domains=true \
     allow_localhost=true \
     allowed_domains="localhost" \
     allow_subdomains=true \
     max_ttl="730h"

#Создаем сертификат
vault write -format=json pki_int/issue/example-dot-com common_name="localhost" alt_names="localhost" ttl="24h" > test.example.com.crt


echo 'Сохраняем сертификат в правильном формате'

# Готовим для сервера NGINX Открытый(test.example.com.crt.pem) и Закрытый(test.example.com.crt.key) ключи
cat test.example.com.crt | jq -r .data.certificate > test.example.com.crt.pem
cat test.example.com.crt | jq -r .data.issuing_ca >> test.example.com.crt.pem
cat test.example.com.crt | jq -r .data.private_key > test.example.com.crt.key
