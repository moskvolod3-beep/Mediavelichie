#!/bin/bash

# Скрипт для проверки DNS настроек домена
# Использование: ./check-dns.sh [DOMAIN]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAIN="${1:-medvel.ru}"
EXPECTED_IP="194.58.88.127"

echo "=========================================="
echo -e "${CYAN}DNS Configuration Check${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Domain:${NC} $DOMAIN"
echo -e "${BLUE}Expected IP:${NC} $EXPECTED_IP"
echo ""

# Проверка наличия утилит
HAS_DIG=$(command -v dig 2>/dev/null)
HAS_NSLOOKUP=$(command -v nslookup 2>/dev/null)
HAS_HOST=$(command -v host 2>/dev/null)
HAS_CURL=$(command -v curl 2>/dev/null)

if [ -z "$HAS_DIG" ] && [ -z "$HAS_NSLOOKUP" ] && [ -z "$HAS_HOST" ]; then
    echo -e "${RED}Error: No DNS lookup tools found (dig, nslookup, or host)${NC}"
    exit 1
fi

# Функция проверки A-записи
check_a_record() {
    local DOMAIN_NAME=$1
    local RESULT=""
    
    if [ -n "$HAS_DIG" ]; then
        RESULT=$(dig +short "$DOMAIN_NAME" A 2>/dev/null | head -1)
    elif [ -n "$HAS_HOST" ]; then
        RESULT=$(host "$DOMAIN_NAME" 2>/dev/null | grep "has address" | awk '{print $4}' | head -1)
    elif [ -n "$HAS_NSLOOKUP" ]; then
        RESULT=$(nslookup "$DOMAIN_NAME" 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}')
    fi
    
    echo "$RESULT"
}

# Проверка основного домена
echo -e "${BLUE}Checking A record for $DOMAIN...${NC}"
MAIN_IP=$(check_a_record "$DOMAIN")

if [ -z "$MAIN_IP" ]; then
    echo -e "${RED}✗ No A record found for $DOMAIN${NC}"
    MAIN_OK=false
elif [ "$MAIN_IP" = "$EXPECTED_IP" ]; then
    echo -e "${GREEN}✓ A record is correct: $MAIN_IP${NC}"
    MAIN_OK=true
else
    echo -e "${YELLOW}⚠ A record points to different IP: $MAIN_IP (expected: $EXPECTED_IP)${NC}"
    MAIN_OK=false
fi
echo ""

# Проверка www поддомена
WWW_DOMAIN="www.$DOMAIN"
echo -e "${BLUE}Checking A record for $WWW_DOMAIN...${NC}"
WWW_IP=$(check_a_record "$WWW_DOMAIN")

if [ -z "$WWW_IP" ]; then
    echo -e "${RED}✗ No A record found for $WWW_DOMAIN${NC}"
    WWW_OK=false
elif [ "$WWW_IP" = "$EXPECTED_IP" ]; then
    echo -e "${GREEN}✓ A record is correct: $WWW_IP${NC}"
    WWW_OK=true
else
    echo -e "${YELLOW}⚠ A record points to different IP: $WWW_IP (expected: $EXPECTED_IP)${NC}"
    WWW_OK=false
fi
echo ""

# Проверка доступности через HTTP
if [ -n "$HAS_CURL" ]; then
    echo -e "${BLUE}Checking HTTP availability...${NC}"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$DOMAIN" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo -e "${GREEN}✓ HTTP is accessible (status: $HTTP_CODE)${NC}"
        HTTP_OK=true
    else
        echo -e "${YELLOW}⚠ HTTP returned status: $HTTP_CODE${NC}"
        HTTP_OK=false
    fi
    echo ""
fi

# Итоговый отчет
echo "=========================================="
echo -e "${CYAN}Summary${NC}"
echo "=========================================="
echo ""

if [ "$MAIN_OK" = true ]; then
    echo -e "Main domain ($DOMAIN):     ${GREEN}✓ OK${NC}"
else
    echo -e "Main domain ($DOMAIN):     ${RED}✗ FAILED${NC}"
fi

if [ "$WWW_OK" = true ]; then
    echo -e "WWW subdomain ($WWW_DOMAIN): ${GREEN}✓ OK${NC}"
else
    echo -e "WWW subdomain ($WWW_DOMAIN): ${RED}✗ FAILED${NC}"
fi

if [ -n "$HTTP_OK" ]; then
    if [ "$HTTP_OK" = true ]; then
        echo -e "HTTP access:              ${GREEN}✓ OK${NC}"
    else
        echo -e "HTTP access:              ${YELLOW}⚠ CHECK${NC}"
    fi
fi

echo ""

# Рекомендации
if [ "$MAIN_OK" = false ] || [ "$WWW_OK" = false ]; then
    echo -e "${YELLOW}Recommendations:${NC}"
    echo ""
    echo "1. Check DNS records in your domain registrar panel"
    echo "2. Ensure A records point to: $EXPECTED_IP"
    echo "3. Wait for DNS propagation (can take up to 24 hours)"
    echo "4. Check DNS propagation status: https://dnschecker.org/"
    echo ""
fi

# Проверка DNS серверов
if [ -n "$HAS_DIG" ]; then
    echo -e "${BLUE}DNS Servers for $DOMAIN:${NC}"
    dig +short NS "$DOMAIN" 2>/dev/null | head -5 || echo "Could not retrieve DNS servers"
    echo ""
fi

echo "=========================================="
if [ "$MAIN_OK" = true ] && [ "$WWW_OK" = true ]; then
    echo -e "${GREEN}✓ DNS configuration looks good!${NC}"
    exit 0
else
    echo -e "${RED}✗ DNS configuration needs attention${NC}"
    exit 1
fi
