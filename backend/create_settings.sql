CREATE TABLE settings (
    id SERIAL PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    key_name VARCHAR(100) NOT NULL,
    value JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(category, key_name)
);

-- 插入基本設置
INSERT INTO settings (category, key_name, value) VALUES
('general', 'atHome', 'false'),
('general', 'rooms', '["Standard"]'),
('general', 'automation', '{"active": false, "atHome": false, "exclude": [], "startTime": "08:00", "endTime": "17:00"}'),
('notifications', 'active', 'false'),
('notifications', 'removeAfter', '3'),
('recordings', 'active', 'false'),
('recordings', 'type', '"Snapshot"'),
('recordings', 'timer', '10'),
('recordings', 'removeAfter', '7'); 