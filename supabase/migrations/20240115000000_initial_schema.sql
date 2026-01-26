-- ============================================
-- МИГРАЦИЯ: Начальная схема базы данных
-- ============================================
-- Выполните этот SQL в SQL Editor вашего Supabase проекта
-- или используйте Supabase CLI: supabase db push

-- ============================================
-- Таблица: Заявки (Orders)
-- ============================================
CREATE TABLE IF NOT EXISTS orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    message TEXT,
    privacy_accepted BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'new' CHECK (status IN ('new', 'in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индекс для быстрого поиска по статусу
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- ============================================
-- Таблица: Проекты (Projects)
-- ============================================
CREATE TABLE IF NOT EXISTS projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    main_video_url TEXT,
    main_image_url TEXT,
    release_date DATE,
    team_members JSONB DEFAULT '[]'::jsonb, -- Массив объектов с именами команды
    is_published BOOLEAN DEFAULT true,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для проектов
CREATE INDEX IF NOT EXISTS idx_projects_slug ON projects(slug);
CREATE INDEX IF NOT EXISTS idx_projects_published ON projects(is_published);
CREATE INDEX IF NOT EXISTS idx_projects_order_index ON projects(order_index);

-- ============================================
-- Таблица: Портфолио (Portfolio)
-- ============================================
CREATE TABLE IF NOT EXISTS portfolio (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT,
    image_url TEXT NOT NULL,
    video_url TEXT,
    category TEXT NOT NULL CHECK (category IN ('ohvatnye', 'ekspertnye', 'reklamnye', 'hr', 'sfery')),
    width INTEGER DEFAULT 238,
    height INTEGER DEFAULT 368,
    format TEXT DEFAULT '9-16' CHECK (format IN ('16-9', '9-16', '1-1')),
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    order_index INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для портфолио
CREATE INDEX IF NOT EXISTS idx_portfolio_category ON portfolio(category);
CREATE INDEX IF NOT EXISTS idx_portfolio_published ON portfolio(is_published);
CREATE INDEX IF NOT EXISTS idx_portfolio_order_index ON portfolio(order_index);

-- ============================================
-- Таблица: Отзывы (Reviews)
-- ============================================
CREATE TABLE IF NOT EXISTS reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    author_name TEXT NOT NULL,
    author_avatar_url TEXT,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    text TEXT NOT NULL,
    is_published BOOLEAN DEFAULT true,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для отзывов
CREATE INDEX IF NOT EXISTS idx_reviews_published ON reviews(is_published);
CREATE INDEX IF NOT EXISTS idx_reviews_order_index ON reviews(order_index);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);

-- ============================================
-- Таблица: Видео проектов (Project Videos)
-- ============================================
CREATE TABLE IF NOT EXISTS project_videos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title TEXT,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    category TEXT CHECK (category IN ('advertising', 'hr', 'reels', 'other')),
    video_type TEXT CHECK (video_type IN ('large', 'small', 'vertical')),
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для видео проектов
CREATE INDEX IF NOT EXISTS idx_project_videos_project_id ON project_videos(project_id);
CREATE INDEX IF NOT EXISTS idx_project_videos_category ON project_videos(category);

-- ============================================
-- Функция для автоматического обновления updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггеры для автоматического обновления updated_at
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_portfolio_updated_at BEFORE UPDATE ON portfolio
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_project_videos_updated_at BEFORE UPDATE ON project_videos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Row Level Security (RLS) Policies
-- ============================================

-- Включаем RLS для всех таблиц
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_videos ENABLE ROW LEVEL SECURITY;

-- Политики для orders: только вставка для анонимных пользователей, чтение только для авторизованных
CREATE POLICY "Anyone can insert orders" ON orders
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Only authenticated users can read orders" ON orders
    FOR SELECT USING (auth.role() = 'authenticated');

-- Политики для portfolio: все могут читать опубликованные, только авторизованные могут изменять
CREATE POLICY "Anyone can read published portfolio" ON portfolio
    FOR SELECT USING (is_published = true);

CREATE POLICY "Only authenticated users can manage portfolio" ON portfolio
    FOR ALL USING (auth.role() = 'authenticated');

-- Политики для reviews: все могут читать опубликованные, только авторизованные могут изменять
CREATE POLICY "Anyone can read published reviews" ON reviews
    FOR SELECT USING (is_published = true);

CREATE POLICY "Only authenticated users can manage reviews" ON reviews
    FOR ALL USING (auth.role() = 'authenticated');

-- Политики для projects: все могут читать опубликованные, только авторизованные могут изменять
CREATE POLICY "Anyone can read published projects" ON projects
    FOR SELECT USING (is_published = true);

CREATE POLICY "Only authenticated users can manage projects" ON projects
    FOR ALL USING (auth.role() = 'authenticated');

-- Политики для project_videos: все могут читать, только авторизованные могут изменять
CREATE POLICY "Anyone can read project videos" ON project_videos
    FOR SELECT USING (true);

CREATE POLICY "Only authenticated users can manage project videos" ON project_videos
    FOR ALL USING (auth.role() = 'authenticated');
