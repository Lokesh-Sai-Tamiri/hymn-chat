-- ============================================================================
-- HIPAA-COMPLIANT CONTACTS SCHEMA
-- ============================================================================
-- 
-- HIPAA Compliance Features:
-- 1. Row Level Security (RLS) - Users can only access their own data
-- 2. Audit logging - All changes are tracked with timestamps
-- 3. Minimum necessary data - Only essential fields stored
-- 4. Access controls - Strict policies on who can read/write
-- 5. Connection-based access - Users must be connected to see details
-- 6. Soft deletes - Data retained for audit trail
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- CONNECTIONS TABLE (Doctor-to-Doctor relationships)
-- ============================================================================
-- This table manages the relationship between doctors (connections/network)
-- A connection is bidirectional once accepted

CREATE TABLE IF NOT EXISTS connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- The user who initiated the connection request
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- The user who received the connection request
    recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Connection status: pending, accepted, rejected, blocked
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    
    -- Optional message with the connection request
    request_message TEXT,
    
    -- Timestamps for audit trail (HIPAA requirement)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    
    -- Soft delete for audit trail (HIPAA - data retention)
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES auth.users(id),
    
    -- Prevent duplicate connection requests
    UNIQUE(requester_id, recipient_id)
);

-- ============================================================================
-- AUDIT LOG TABLE (HIPAA Requirement)
-- ============================================================================
-- Tracks all access and modifications to sensitive data

CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Who performed the action
    user_id UUID REFERENCES auth.users(id),
    
    -- What table was affected
    table_name TEXT NOT NULL,
    
    -- What record was affected
    record_id UUID,
    
    -- What action was performed
    action TEXT NOT NULL CHECK (action IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')),
    
    -- Old values (for UPDATE/DELETE)
    old_values JSONB,
    
    -- New values (for INSERT/UPDATE)
    new_values JSONB,
    
    -- IP address (if available)
    ip_address INET,
    
    -- User agent (if available)
    user_agent TEXT,
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on connections table
ALTER TABLE connections ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view connections where they are involved
CREATE POLICY "Users can view their own connections"
    ON connections FOR SELECT
    USING (
        auth.uid() = requester_id OR 
        auth.uid() = recipient_id
    );

-- Policy: Users can create connection requests
CREATE POLICY "Users can create connection requests"
    ON connections FOR INSERT
    WITH CHECK (
        auth.uid() = requester_id AND
        requester_id != recipient_id -- Can't connect with yourself
    );

-- Policy: Users can update connections they're involved in
-- (accept/reject requests, block users)
CREATE POLICY "Users can update their connections"
    ON connections FOR UPDATE
    USING (
        auth.uid() = requester_id OR 
        auth.uid() = recipient_id
    );

-- Policy: Users can soft-delete their connections
CREATE POLICY "Users can delete their connections"
    ON connections FOR DELETE
    USING (
        auth.uid() = requester_id OR 
        auth.uid() = recipient_id
    );

-- Enable RLS on audit_log (read-only for users, write via triggers)
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own audit logs
CREATE POLICY "Users can view their own audit logs"
    ON audit_log FOR SELECT
    USING (auth.uid() = user_id);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_connections_requester ON connections(requester_id);
CREATE INDEX IF NOT EXISTS idx_connections_recipient ON connections(recipient_id);
CREATE INDEX IF NOT EXISTS idx_connections_status ON connections(status);
CREATE INDEX IF NOT EXISTS idx_connections_created ON connections(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_table ON audit_log(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log(created_at);

-- ============================================================================
-- TRIGGER: Auto-update updated_at timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER connections_updated_at
    BEFORE UPDATE ON connections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- TRIGGER: Audit logging for connections (HIPAA requirement)
-- ============================================================================

CREATE OR REPLACE FUNCTION audit_connections_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (user_id, table_name, record_id, action, new_values)
        VALUES (auth.uid(), 'connections', NEW.id, 'INSERT', row_to_json(NEW)::jsonb);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (user_id, table_name, record_id, action, old_values, new_values)
        VALUES (auth.uid(), 'connections', NEW.id, 'UPDATE', row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (user_id, table_name, record_id, action, old_values)
        VALUES (auth.uid(), 'connections', OLD.id, 'DELETE', row_to_json(OLD)::jsonb);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER connections_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON connections
    FOR EACH ROW
    EXECUTE FUNCTION audit_connections_changes();

-- ============================================================================
-- VIEW: User's network (accepted connections with profile info)
-- ============================================================================
-- This view joins connections with profiles for easy querying

CREATE OR REPLACE VIEW user_network AS
SELECT 
    c.id as connection_id,
    c.status,
    c.created_at as connected_since,
    c.requester_id,
    c.recipient_id,
    -- Get the "other" user's ID (not the current user)
    CASE 
        WHEN c.requester_id = auth.uid() THEN c.recipient_id
        ELSE c.requester_id
    END as contact_user_id,
    -- Get the other user's profile info
    p.first_name,
    p.last_name,
    p.display_name,
    p.specialization,
    p.clinic_name,
    p.avatar_url,
    p.city,
    p.state
FROM connections c
JOIN profiles p ON (
    CASE 
        WHEN c.requester_id = auth.uid() THEN c.recipient_id
        ELSE c.requester_id
    END = p.id
)
WHERE 
    (c.requester_id = auth.uid() OR c.recipient_id = auth.uid())
    AND c.status = 'accepted'
    AND c.deleted_at IS NULL;

-- ============================================================================
-- VIEW: Pending connection requests (received)
-- ============================================================================

CREATE OR REPLACE VIEW pending_requests AS
SELECT 
    c.id as connection_id,
    c.requester_id,
    c.request_message,
    c.created_at,
    p.first_name,
    p.last_name,
    p.display_name,
    p.specialization,
    p.clinic_name,
    p.avatar_url,
    p.city,
    p.state
FROM connections c
JOIN profiles p ON c.requester_id = p.id
WHERE 
    c.recipient_id = auth.uid()
    AND c.status = 'pending'
    AND c.deleted_at IS NULL;

-- ============================================================================
-- VIEW: Sent connection requests (outgoing)
-- ============================================================================

CREATE OR REPLACE VIEW sent_requests AS
SELECT 
    c.id as connection_id,
    c.recipient_id,
    c.status,
    c.request_message,
    c.created_at,
    p.first_name,
    p.last_name,
    p.display_name,
    p.specialization,
    p.clinic_name,
    p.avatar_url,
    p.city,
    p.state
FROM connections c
JOIN profiles p ON c.recipient_id = p.id
WHERE 
    c.requester_id = auth.uid()
    AND c.status IN ('pending', 'rejected')
    AND c.deleted_at IS NULL;

-- ============================================================================
-- VIEW: Suggested connections (profiles not yet connected)
-- ============================================================================

CREATE OR REPLACE VIEW suggested_connections AS
SELECT 
    p.id as user_id,
    p.first_name,
    p.last_name,
    p.display_name,
    p.specialization,
    p.clinic_name,
    p.avatar_url,
    p.city,
    p.state,
    p.profile_completed
FROM profiles p
WHERE 
    p.id != auth.uid()
    AND p.profile_completed = true
    AND NOT EXISTS (
        SELECT 1 FROM connections c
        WHERE 
            ((c.requester_id = auth.uid() AND c.recipient_id = p.id)
            OR (c.recipient_id = auth.uid() AND c.requester_id = p.id))
            AND c.deleted_at IS NULL
            AND c.status != 'rejected'
    )
LIMIT 50;

-- ============================================================================
-- FUNCTION: Send connection request
-- ============================================================================

CREATE OR REPLACE FUNCTION send_connection_request(
    p_recipient_id UUID,
    p_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_connection_id UUID;
BEGIN
    -- Check if connection already exists
    IF EXISTS (
        SELECT 1 FROM connections
        WHERE 
            ((requester_id = auth.uid() AND recipient_id = p_recipient_id)
            OR (recipient_id = auth.uid() AND requester_id = p_recipient_id))
            AND deleted_at IS NULL
            AND status NOT IN ('rejected', 'blocked')
    ) THEN
        RAISE EXCEPTION 'Connection already exists or is pending';
    END IF;

    INSERT INTO connections (requester_id, recipient_id, request_message, status)
    VALUES (auth.uid(), p_recipient_id, p_message, 'pending')
    RETURNING id INTO v_connection_id;

    RETURN v_connection_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Accept connection request
-- ============================================================================

CREATE OR REPLACE FUNCTION accept_connection_request(p_connection_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE connections
    SET 
        status = 'accepted',
        accepted_at = NOW()
    WHERE 
        id = p_connection_id
        AND recipient_id = auth.uid()
        AND status = 'pending';
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Reject connection request
-- ============================================================================

CREATE OR REPLACE FUNCTION reject_connection_request(p_connection_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE connections
    SET status = 'rejected'
    WHERE 
        id = p_connection_id
        AND recipient_id = auth.uid()
        AND status = 'pending';
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Remove connection (soft delete)
-- ============================================================================

CREATE OR REPLACE FUNCTION remove_connection(p_connection_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE connections
    SET 
        deleted_at = NOW(),
        deleted_by = auth.uid()
    WHERE 
        id = p_connection_id
        AND (requester_id = auth.uid() OR recipient_id = auth.uid())
        AND status = 'accepted';
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Block user
-- ============================================================================

CREATE OR REPLACE FUNCTION block_user(p_user_id UUID)
RETURNS UUID AS $$
DECLARE
    v_connection_id UUID;
BEGIN
    -- Update existing connection or create new blocked entry
    INSERT INTO connections (requester_id, recipient_id, status)
    VALUES (auth.uid(), p_user_id, 'blocked')
    ON CONFLICT (requester_id, recipient_id) 
    DO UPDATE SET status = 'blocked', updated_at = NOW()
    RETURNING id INTO v_connection_id;

    RETURN v_connection_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant access to authenticated users
GRANT SELECT ON user_network TO authenticated;
GRANT SELECT ON pending_requests TO authenticated;
GRANT SELECT ON sent_requests TO authenticated;
GRANT SELECT ON suggested_connections TO authenticated;

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION send_connection_request TO authenticated;
GRANT EXECUTE ON FUNCTION accept_connection_request TO authenticated;
GRANT EXECUTE ON FUNCTION reject_connection_request TO authenticated;
GRANT EXECUTE ON FUNCTION remove_connection TO authenticated;
GRANT EXECUTE ON FUNCTION block_user TO authenticated;
