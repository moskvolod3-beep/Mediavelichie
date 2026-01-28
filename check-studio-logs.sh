#!/bin/bash

# Быстрая проверка логов Supabase Studio
# Использование: ./check-studio-logs.sh

STUDIO_CONTAINER="mediavelichie-supabase-studio"

echo "=========================================="
echo "Supabase Studio Logs (last 100 lines)"
echo "=========================================="
echo ""

docker logs --tail 100 "$STUDIO_CONTAINER" 2>&1 | tail -50

echo ""
echo "=========================================="
echo "Looking for connection errors..."
echo "=========================================="
echo ""

docker logs "$STUDIO_CONTAINER" 2>&1 | grep -i "error\|fail\|connection\|postgres" | tail -20 || echo "No obvious errors found"

echo ""
echo "=========================================="
echo "Studio Status"
echo "=========================================="
docker ps --filter "name=$STUDIO_CONTAINER" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
