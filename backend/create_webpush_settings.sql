CREATE TABLE webpush_settings (
    id SERIAL PRIMARY KEY,
    public_key VARCHAR(255),
    private_key VARCHAR(255),
    subscription BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
); 