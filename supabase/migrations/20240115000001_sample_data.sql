-- ============================================
-- МИГРАЦИЯ: Примеры данных для тестирования
-- ============================================
-- Выполните этот SQL после создания схемы для добавления тестовых данных

-- ============================================
-- Примеры отзывов
-- ============================================
INSERT INTO reviews (author_name, rating, text, is_published, order_index) VALUES
('Константин', 5, 'Отличная работа! Видео превзошло все ожидания.', true, 1),
('Ольга', 5, 'Профессиональный подход и быстрые сроки.', true, 2),
('Константин Константинович', 5, 'В широком смысле, отзыв — это «ответ» на что-либо, отклик...', true, 3),
('Мария', 5, 'Креативно, ярко и эффективно. Рекомендую!', true, 4),
('Алексей', 5, 'Спасибо за качественный контент для нашего бренда.', true, 5),
('Елена', 5, 'Всё супер! Будем обращаться ещё.', true, 6)
ON CONFLICT DO NOTHING;

-- ============================================
-- Примеры проектов
-- ============================================
INSERT INTO projects (title, slug, description, release_date, team_members, is_published, order_index) VALUES
(
    'Проект для Ярд-империал. Формирование медиа отдела под ключ',
    'yard-imperial-media-department',
    'Мы разработали полный видеокомплекс проекта «Медиа Величия»: от идеи и сценариев — до съёмки, монтажа и финальной подачи.',
    '2026-12-31',
    '["Альберт Исхаков", "Сергей Чубаров", "Владимир Москалев"]'::jsonb,
    true,
    1
)
ON CONFLICT (slug) DO NOTHING;

-- ============================================
-- Примеры портфолио (привязываем к проекту выше)
-- ============================================
-- Сначала получаем ID проекта
DO $$
DECLARE
    project_uuid UUID;
BEGIN
    SELECT id INTO project_uuid FROM projects WHERE slug = 'yard-imperial-media-department' LIMIT 1;
    
    -- Добавляем примеры портфолио
    INSERT INTO portfolio (title, image_url, category, width, height, format, project_id, is_published, order_index) VALUES
    ('Портфолио 1', 'figma-assets/bccc3d4bf07de4fe529b163a853fa1e50300dc33.png', 'ohvatnye', 490, 304, '16-9', project_uuid, true, 1),
    ('Портфолио 2', 'figma-assets/fc52e88aa9f4e759244c3e6e2131f0bf81da24ef.png', 'ohvatnye', 238, 368, '9-16', project_uuid, true, 2),
    ('Портфолио 3', 'figma-assets/89f3e5d0538b01e7b2ab421ab220571d466d7d40.png', 'ekspertnye', 238, 368, '9-16', project_uuid, true, 3),
    ('Портфолио 4', 'figma-assets/c967540e5d810ae3e7dc129273d871bfb781460c.png', 'reklamnye', 490, 304, '16-9', project_uuid, true, 4),
    ('Портфолио 5', 'figma-assets/f2dc1f3f287ad7a71dcf65f0b03a26e8f4f8c3a7.png', 'ohvatnye', 238, 368, '9-16', project_uuid, true, 5),
    ('Портфолио 6', 'figma-assets/64c900ce6ed2535e56db1e50ac88a00de14bf4b3.png', 'hr', 238, 368, '9-16', project_uuid, true, 6),
    ('Портфолио 7', 'figma-assets/90b51286c316c3a7502647f792e8378d9cf9d6d1.png', 'reklamnye', 490, 304, '16-9', project_uuid, true, 7),
    ('Портфолио 8', 'figma-assets/ec45ec5829b77837dbebbfcc28cd31aaa97cb606.png', 'sfery', 490, 304, '16-9', project_uuid, true, 8),
    ('Портфолио 9', 'figma-assets/46fb259cf12d268c5351b03daa40173a38ce635b.png', 'ekspertnye', 490, 304, '16-9', project_uuid, true, 9),
    ('Портфолио 10', 'figma-assets/74723beaddf36faa9a26d08a3607ba6d0a829aa2.png', 'reklamnye', 490, 304, '16-9', project_uuid, true, 10),
    ('Портфолио 11', 'figma-assets/0c5481834d3bb1645ea350917624e6b7ff8e807.png', 'sfery', 490, 304, '16-9', project_uuid, true, 11)
    ON CONFLICT DO NOTHING;
END $$;
