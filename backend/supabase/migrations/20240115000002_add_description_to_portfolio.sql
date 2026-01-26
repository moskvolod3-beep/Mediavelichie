-- ============================================
-- МИГРАЦИЯ: Добавление поля description в таблицу portfolio
-- ============================================
-- Добавляет поле description для хранения описания видео роликов

-- Добавляем поле description в таблицу portfolio
ALTER TABLE portfolio 
ADD COLUMN IF NOT EXISTS description TEXT;

-- Комментарий к полю
COMMENT ON COLUMN portfolio.description IS 'Описание видео ролика';
