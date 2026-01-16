# Заполнение таблицы Portfolio из бакета Storage

## Автоматическое заполнение

Функция `fillPortfolioFromStorage()` автоматически:
1. Получает список папок (категорий) из бакета `portfolio`
2. Для каждой категории получает список видео файлов
3. Создает или обновляет записи в таблице `portfolio`

## Способ 1: Через HTML страницу (рекомендуется)

1. Откройте файл `fill-portfolio.html` в браузере
2. Нажмите кнопку "Заполнить таблицу"
3. Дождитесь завершения операции
4. Проверьте результаты

## Способ 2: Через консоль браузера

1. Откройте страницу `portfolio.html` в браузере
2. Откройте консоль разработчика (F12)
3. Выполните команду:
   ```javascript
   fillPortfolioFromStorage().then(result => {
       console.log('Результат:', result);
       if (result.success) {
           console.log(`Создано: ${result.created}, Обновлено: ${result.updated}, Ошибок: ${result.errors}`);
       }
   });
   ```

## Способ 3: Через импорт модуля

```javascript
import { fillPortfolioFromStorage } from './js/supabase-client.js';

const result = await fillPortfolioFromStorage('portfolio');
console.log(result);
```

## Структура бакета

Бакет `portfolio` должен содержать папки с категориями:
```
portfolio/
  ├── ohvatnye/
  │   ├── video1.mp4
  │   └── video2.mp4
  ├── ekspertnye/
  │   └── video3.mp4
  ├── reklamnye/
  │   └── video4.mp4
  ├── hr/
  │   └── video5.mp4
  └── sfery/
      └── video6.mp4
```

## Что делает функция

- **Создает записи** для новых видео файлов
- **Обновляет записи** для существующих видео (по `video_url`)
- **Автоматически определяет категорию** из названия папки
- **Формирует название** из имени файла
- **Устанавливает порядок** (`order_index`) на основе позиции файла в списке

## Поддерживаемые форматы видео

- MP4
- MOV
- AVI
- MKV
- WebM
- FLV
- WMV

## Примечания

- Убедитесь, что бакет `portfolio` настроен как публичный
- Функция использует заглушку для `image_url` (можно обновить вручную)
- Размеры по умолчанию: 238x368, формат 9-16
