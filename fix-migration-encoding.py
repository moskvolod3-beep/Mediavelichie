#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Скрипт для исправления кодировки файла миграции
Конвертирует UTF-16 в UTF-8
"""

import sys
import os
import shutil

def fix_encoding(input_file, output_file=None):
    """Конвертирует файл из UTF-16 в UTF-8"""
    
    if output_file is None:
        output_file = input_file
    
    # Создаем резервную копию
    backup_file = f"{input_file}.backup"
    if not os.path.exists(backup_file):
        shutil.copy2(input_file, backup_file)
        print(f"Created backup: {backup_file}")
    
    # Читаем файл в UTF-16
    try:
        with open(input_file, 'rb') as f:
            raw_content = f.read()
        
        # Определяем кодировку по BOM
        if raw_content.startswith(b'\xff\xfe'):
            # UTF-16 LE
            content = raw_content.decode('utf-16-le')
        elif raw_content.startswith(b'\xfe\xff'):
            # UTF-16 BE
            content = raw_content.decode('utf-16-be')
        else:
            # Пробуем UTF-16 LE по умолчанию
            try:
                content = raw_content.decode('utf-16-le')
            except UnicodeDecodeError:
                try:
                    content = raw_content.decode('utf-16-be')
                except UnicodeDecodeError:
                    print(f"Error: Could not determine encoding of file {input_file}")
                    return False
    except Exception as e:
        print(f"Error reading file: {e}")
        return False
    
    # Удаляем BOM если есть
    if content.startswith('\ufeff'):
        content = content[1:]
    
    # Записываем в UTF-8
    with open(output_file, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)
    
    print(f"OK: File converted to UTF-8: {output_file}")
    return True

if __name__ == '__main__':
    migration_file = sys.argv[1] if len(sys.argv) > 1 else 'backend/supabase/migrations/20260128133013_full_schema_export.sql'
    
    if not os.path.exists(migration_file):
        print(f"Error: File not found: {migration_file}")
        sys.exit(1)
    
    if fix_encoding(migration_file):
        print("Done!")
    else:
        sys.exit(1)
