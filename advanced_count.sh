#!/bin/bash

TARGET_DIR="${1:-.}"

EXT="$2"

# Перевірка існування директорії
if [ ! -d "$TARGET_DIR" ]; then
    echo "Помилка: директорія $TARGET_DIR не існує"
    exit 1
fi

echo "Аналіз директорії: $TARGET_DIR"

if [ -n "$EXT" ]; then
    echo "Пошук файлів з розширенням: *.$EXT"
    NAME_FILTER=(-name "*.$EXT")
else
    echo "Пошук файлів: усі типи"
    NAME_FILTER=()
fi

file_count=$(find "$TARGET_DIR" -type f "${NAME_FILTER[@]}" 2>/dev/null | wc -l)

if [ "$file_count" -gt 0 ]; then
    # Підсумок розміру у зручному для читання форматі
    total_size=$(find "$TARGET_DIR" -type f "${NAME_FILTER[@]}" -exec du -ch {} + 2>/dev/null | tail -n 1 | cut -f1)
else
    total_size="0B"
fi

echo "Кількість знайдених файлів (рекурсивно): $file_count"
echo "Загальний розмір файлів: $total_size"

exit 0
