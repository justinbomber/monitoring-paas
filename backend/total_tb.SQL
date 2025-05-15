-- ENUM Types
CREATE TYPE status_enum AS ENUM('REQUESTING','NOT_ALLOWED','CONNECTED','DISCONNECTED');
CREATE TYPE stream_type_enum AS ENUM('hls','webrtc');
CREATE TYPE movement_type_enum AS ENUM(
    'ContinuousMove',
    'AbsoluteMove',
    'RelativeMove',
    'Stop',
    'GotoHomePosition',
    'SetHomePosition',
    'GotoPreset',
    'SetPreset',
    'RemovePreset',
    'GetPresets',
    'GetStatus',
    'GetProfiles',
    'GetStreamUri',
    'GetSnapshotUri',
    'GetVideoSources',
    'GetVideoEncoderConfigurationOptions',
    'GetImagingSettings',
    'SetImagingSettings',
    'Move',
    'GetDeviceInformation',
    'GetSystemDateAndTime',
    'SetSystemDateAndTime',
    'GetNetworkInterfaces',
    'Reboot'
);
-- CREATE TYPE action_type_enum AS ENUM('ADD_STREAM','REMOVE_STREAM','RELOAD');

-- Locations (monitored sites)
CREATE TABLE locations (
    location_id     VARCHAR(50) PRIMARY KEY,
    location_name   VARCHAR(32) NOT NULL,
    location_city   VARCHAR(100) NOT NULL,
    frps_port_begin INT NOT NULL,
    frps_port_end   INT NOT NULL,
    status          status_enum NOT NULL DEFAULT 'REQUESTING',
    subnet          INET NOT NULL,
    subnet_mask     INET NOT NULL,
    create_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    update_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Location Center (FRP node)
CREATE TABLE location_center (
    location_center_id VARCHAR(50) NOT NULL PRIMARY KEY,
    frps_ip       INET NOT NULL UNIQUE,
    create_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    update_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Map each Location to a Location Center (FRPS node)
CREATE TABLE location_center_map (
    location_center_id VARCHAR(50) NOT NULL REFERENCES location_center(location_center_id),
    location_id        VARCHAR(50) NOT NULL REFERENCES locations(location_id),
    PRIMARY KEY(location_center_id, location_id)
);

-- Users and Credentials
CREATE TABLE users (
    username   VARCHAR(50) PRIMARY KEY,
    password   VARCHAR(255) NOT NULL,
    email      VARCHAR(255) UNIQUE NOT NULL,
    create_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    update_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Roles (admin, watcher, etc.)
CREATE TABLE roles (
    role_id    VARCHAR(50) PRIMARY KEY,
    role_name  VARCHAR(32) NOT NULL UNIQUE
);

-- User ↔ Role mapping (many-to-many)
CREATE TABLE user_role_map (
    username VARCHAR(50) NOT NULL REFERENCES users(username),
    role_id  VARCHAR(50)   NOT NULL REFERENCES roles(role_id),
    PRIMARY KEY(username, role_id)
);

-- User ↔ Location mapping (access control)
CREATE TABLE user_location_map (
    username    VARCHAR(50) NOT NULL REFERENCES users(username),
    location_id VARCHAR(50)   NOT NULL REFERENCES locations(location_id),
    PRIMARY KEY(username, location_id)
);

-- Camera Metadata
CREATE TABLE camera_metadata (
    camera_id    VARCHAR(50)   NOT NULL,
    camera_name  VARCHAR(32) NOT NULL,
    internal_ip  INET   NOT NULL,
    soap_user     VARCHAR(100),
    soap_password VARCHAR(255),
    status       status_enum  NOT NULL DEFAULT 'REQUESTING',
    create_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    update_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY(camera_id),
    UNIQUE(camera_name)
);

CREATE TABLE camera_location_map (
    camera_name  VARCHAR(32) NOT NULL REFERENCES camera_metadata(camera_name),
    camera_id    VARCHAR(50)   NOT NULL REFERENCES camera_metadata(camera_id),
    location_id  VARCHAR(50)   NOT NULL REFERENCES locations(location_id),
    PRIMARY KEY(camera_name, location_id)
);

-- Movement Types Catalog
CREATE TABLE movement_type (
    movement_type_id VARCHAR(50) PRIMARY KEY,
    name              movement_type_enum NOT NULL UNIQUE
);

-- Camera ↔ Movement mapping
CREATE TABLE camera_movement (
    camera_id         VARCHAR(50) NOT NULL REFERENCES camera_metadata(camera_id),
    movement_type_id  VARCHAR(50) NOT NULL REFERENCES movement_type(movement_type_id),
    PRIMARY KEY(camera_id, movement_type_id)
);

-- Stream Endpoints (MediaMTX config)
CREATE TABLE stream_endpoint (
    camera_id    VARCHAR(50) NOT NULL REFERENCES camera_metadata(camera_id),
    profile_name  VARCHAR(32) NOT NULL,
    source_url   VARCHAR(256)    NOT NULL,
    mtx_outer_url VARCHAR(256)   NOT NULL,
    frps_remote_port INT NOT NULL,
    update_at    TIMESTAMPTZ      NOT NULL DEFAULT now(),
    stream_type   stream_type_enum NOT NULL,
    PRIMARY KEY(camera_id, profile_name)
);
CREATE INDEX idx_stream_location ON stream_endpoint(location_id);
CREATE INDEX idx_stream_updated ON stream_endpoint(update_at DESC);

-- Camera Status Log (state transitions)
CREATE TABLE camera_status_log (
    id         BIGSERIAL PRIMARY KEY,
    camera_id  VARCHAR(50) NOT NULL REFERENCES camera_metadata(camera_id),
    old_status status_enum NOT NULL,
    new_status status_enum NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Location Status Log
CREATE TABLE location_status_log (
    id          BIGSERIAL PRIMARY KEY,
    location_id VARCHAR(50)   NOT NULL REFERENCES locations(location_id),
    old_status  status_enum NOT NULL,
    new_status  status_enum NOT NULL,
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Historical Camera Metadata (partitioned by time)
CREATE TABLE camera_his_metadata (
    location_id   VARCHAR(50)           NOT NULL REFERENCES locations(location_id),
    camera_id     VARCHAR(50)           NOT NULL REFERENCES camera_metadata(camera_id),
    start_time    TIMESTAMPTZ      NOT NULL,
    end_time      TIMESTAMPTZ      NOT NULL,
    file_location TEXT             NOT NULL,
    file_name     TEXT             NOT NULL,
    PRIMARY KEY(location_id, camera_id, start_time)
) PARTITION BY RANGE (start_time);


-- Action Queue (for agent tasks)
-- CREATE TABLE action_queue (
--     camera_id   VARCHAR(50)           NOT NULL REFERENCES camera_metadata(camera_id),
--     action_type action_type_enum NOT NULL,
--     payload     JSONB,
--     created_at  TIMESTAMPTZ      NOT NULL DEFAULT now(),
--     processed_at TIMESTAMPTZ,
--     finished_at TIMESTAMPTZ,
--     error_msg   TEXT,
--     PRIMARY KEY(camera_id, action_type, created_at)
-- );

-- 為可能進行大量讀寫的表添加索引
CREATE INDEX idx_locations_status ON locations(status);
CREATE INDEX idx_locations_create_at ON locations(create_at);
CREATE INDEX idx_locations_update_at ON locations(update_at);

CREATE INDEX idx_camera_metadata_status ON camera_metadata(status);
CREATE INDEX idx_camera_metadata_create_at ON camera_metadata(create_at);
CREATE INDEX idx_camera_metadata_update_at ON camera_metadata(update_at);

CREATE INDEX idx_stream_endpoint_update_at ON stream_endpoint(update_at);

CREATE INDEX idx_camera_status_log_camera_id ON camera_status_log(camera_id);
CREATE INDEX idx_camera_status_log_changed_at ON camera_status_log(changed_at);

CREATE INDEX idx_location_status_log_location_id ON location_status_log(location_id);
CREATE INDEX idx_location_status_log_changed_at ON location_status_log(changed_at);

CREATE INDEX idx_camera_his_metadata_start_time ON camera_his_metadata(start_time);
CREATE INDEX idx_camera_his_metadata_end_time ON camera_his_metadata(end_time);
CREATE INDEX idx_camera_his_metadata_camera_id ON camera_his_metadata(camera_id);
CREATE INDEX idx_camera_his_metadata_location_id ON camera_his_metadata(location_id);
INSERT INTO movement_type(movement_type_id, name) VALUES('CONTINUOUS_MOVE','ContinuousMove');
INSERT INTO movement_type(movement_type_id, name) VALUES('ABSOLUTE_MOVE','AbsoluteMove');
INSERT INTO movement_type(movement_type_id, name) VALUES('RELATIVE_MOVE','RelativeMove');
INSERT INTO movement_type(movement_type_id, name) VALUES('STOP','Stop');
INSERT INTO movement_type(movement_type_id, name) VALUES('GOTO_HOME_POSITION','GotoHomePosition');
INSERT INTO movement_type(movement_type_id, name) VALUES('SET_HOME_POSITION','SetHomePosition');
INSERT INTO movement_type(movement_type_id, name) VALUES('GOTO_PRESET','GotoPreset');
INSERT INTO movement_type(movement_type_id, name) VALUES('SET_PRESET','SetPreset');
INSERT INTO movement_type(movement_type_id, name) VALUES('REMOVE_PRESET','RemovePreset');
INSERT INTO movement_type(movement_type_id, name) VALUES('GET_PRESETS','GetPresets');
INSERT INTO movement_type(movement_type_id, name) VALUES('GET_STATUS','GetStatus');
INSERT INTO movement_type(movement_type_id, name) VALUES('GET_PROFILES','GetProfiles');
INSERT INTO movement_type(movement_type_id, name) VALUES('GET_STREAM_URI','GetStreamUri');
INSERT INTO movement_type(movement_type_id, name) VALUES('GET_SNAPSHOT_URI','GetSnapshotUri');
INSERT INTO movement_type(movement_type_id, name) VALUES('GET_VIDEO_SOURCES','GetVideoSources');
INSERT INTO movement_type(movement_type_id, name) VALUES('GET_VIDEO_ENCODER_CONFIGURATION_OPTIONS','GetVideoEncoderConfigurationOptions');
INSERT INTO movement_type(movement_type_id, name) VALUES('GET_IMAGING_SETTINGS','GetImagingSettings');
INSERT INTO movement_type(movement_type_id, name) VALUES('SET_IMAGING_SETTINGS','SetImagingSettings');
INSERT INTO movement_type(movement_type_id, name) VALUES('MOVE','Move');
INSERT INTO movement_type(movement_type_id, name) VALUES('GET_DEVICE_INFORMATION','GetDeviceInformation');
INSERT INTO movement_type(movement_type_id, name) VALUES('GET_SYSTEM_DATE_AND_TIME','GetSystemDateAndTime');
INSERT INTO movement_type(movement_type_id, name) VALUES('SET_SYSTEM_DATE_AND_TIME','SetSystemDateAndTime');
INSERT INTO movement_type(movement_type_id, name) VALUES('GET_NETWORK_INTERFACES','GetNetworkInterfaces');
INSERT INTO movement_type(movement_type_id, name) VALUES('REBOOT','Reboot');

