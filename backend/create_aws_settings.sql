CREATE TABLE aws_settings (
    id SERIAL PRIMARY KEY,
    access_key_id VARCHAR(255),
    secret_access_key VARCHAR(255),
    region VARCHAR(50),
    contingent_total INTEGER DEFAULT 5000,
    contingent_left INTEGER DEFAULT 5000,
    last_rekognition TIMESTAMP,
    active BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
); 