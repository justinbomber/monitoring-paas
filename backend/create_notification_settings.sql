CREATE TABLE notification_settings (
    id SERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    active BOOLEAN DEFAULT false,
    settings JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入預設通知設置
INSERT INTO notification_settings (type, active, settings) VALUES
('alexa', false, '{"domain": "", "serialNr": "", "message": "", "startTime": "00:00", "endTime": "23:59", "proxy": {"port": 9494}}'),
('telegram', false, '{"token": "", "chatID": "", "message": ""}'),
('webhook', false, '{}'); 