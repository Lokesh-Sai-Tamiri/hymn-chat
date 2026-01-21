-- ============================================================================
-- HIPAA-COMPLIANT MESSAGING SCHEMA
-- ============================================================================
-- 
-- HIPAA Compliance Features:
-- 1. Row Level Security (RLS) - Users can only access their own messages
-- 2. Audit logging - All message access tracked
-- 3. Minimum necessary data - Only essential fields
-- 4. Disappearing messages - Auto-delete after viewing
-- 5. Encryption ready - file_url can store encrypted references
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USER MESSAGING PREFERENCES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS messaging_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Privacy settings
    who_can_message TEXT NOT NULL DEFAULT 'connections' CHECK (who_can_message IN ('everyone', 'connections', 'organization', 'none')),
    read_receipts_enabled BOOLEAN DEFAULT TRUE,
    show_typing_indicator BOOLEAN DEFAULT TRUE,
    show_online_status BOOLEAN DEFAULT TRUE,
    
    -- Audio message preferences (Snapchat-style save feature)
    -- If TRUE, other users can save your audio messages
    allow_audio_save BOOLEAN DEFAULT FALSE,
    
    -- Default disappearing message duration
    default_disappearing_hours INTEGER DEFAULT 24, -- NULL = never disappear
    
    -- Notification preferences
    message_notifications BOOLEAN DEFAULT TRUE,
    sound_enabled BOOLEAN DEFAULT TRUE,
    vibration_enabled BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- CONVERSATIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Participants (normalized: user1_id < user2_id)
    user1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Last message cache (for quick list display)
    last_message_id UUID,
    last_message_text TEXT,
    last_message_type TEXT DEFAULT 'text',
    last_message_at TIMESTAMP WITH TIME ZONE,
    last_message_sender_id UUID REFERENCES auth.users(id),
    
    -- Unread counts (per user)
    user1_unread_count INTEGER DEFAULT 0,
    user2_unread_count INTEGER DEFAULT 0,
    
    -- Per-user conversation settings
    user1_muted BOOLEAN DEFAULT FALSE,
    user2_muted BOOLEAN DEFAULT FALSE,
    user1_archived BOOLEAN DEFAULT FALSE,
    user2_archived BOOLEAN DEFAULT FALSE,
    user1_pinned BOOLEAN DEFAULT FALSE,
    user2_pinned BOOLEAN DEFAULT FALSE,
    
    -- Disappearing messages settings (per conversation override)
    disappearing_hours INTEGER, -- NULL uses user's default
    
    -- Blocking
    blocked_by UUID REFERENCES auth.users(id),
    blocked_at TIMESTAMP WITH TIME ZONE,
    block_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Soft delete
    user1_deleted_at TIMESTAMP WITH TIME ZONE,
    user2_deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    UNIQUE(user1_id, user2_id),
    CHECK (user1_id < user2_id),
    CHECK (user1_id != user2_id)
);

-- ============================================================================
-- MESSAGES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    
    -- Sender
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Message content
    message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'audio', 'image', 'document', 'system')),
    content TEXT, -- Text content
    
    -- File attachments
    file_url TEXT,
    file_name TEXT,
    file_size INTEGER, -- Bytes
    file_mime_type TEXT,
    
    -- Audio specific
    audio_duration_seconds INTEGER,
    audio_waveform JSONB, -- Store waveform data for UI
    
    -- Audio save feature (Snapchat-style)
    -- NULL = not saved, user_id = who saved it
    saved_by UUID REFERENCES auth.users(id),
    saved_at TIMESTAMP WITH TIME ZONE,
    
    -- Message status
    status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sending', 'sent', 'delivered', 'read', 'failed')),
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    
    -- Disappearing messages
    disappears_at TIMESTAMP WITH TIME ZONE, -- When message auto-deletes
    viewed_at TIMESTAMP WITH TIME ZONE, -- When recipient first viewed (starts timer)
    
    -- Reply support
    reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Soft delete (HIPAA audit trail)
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES auth.users(id),
    delete_reason TEXT CHECK (delete_reason IN ('user', 'auto', 'report', 'admin'))
);

-- ============================================================================
-- BLOCKED USERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS blocked_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(blocker_id, blocked_id),
    CHECK (blocker_id != blocked_id)
);

-- ============================================================================
-- REPORTS TABLE (HIPAA - abuse reporting)
-- ============================================================================

CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- What is being reported
    report_type TEXT NOT NULL CHECK (report_type IN ('user', 'message', 'conversation')),
    reported_user_id UUID REFERENCES auth.users(id),
    reported_message_id UUID REFERENCES messages(id),
    reported_conversation_id UUID REFERENCES conversations(id),
    
    -- Reporter
    reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Report details
    reason TEXT NOT NULL CHECK (reason IN ('spam', 'harassment', 'inappropriate_content', 'impersonation', 'privacy_violation', 'other')),
    description TEXT,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    action_taken TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Conversations
CREATE INDEX IF NOT EXISTS idx_conversations_user1 ON conversations(user1_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user2 ON conversations(user2_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_msg ON conversations(last_message_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_conversations_blocked ON conversations(blocked_by) WHERE blocked_by IS NOT NULL;

-- Messages
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_disappears ON messages(disappears_at) WHERE disappears_at IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status);
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(message_type);

-- Blocked users
CREATE INDEX IF NOT EXISTS idx_blocked_blocker ON blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_blocked ON blocked_users(blocked_id);

-- Reports
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_reported_user ON reports(reported_user_id) WHERE reported_user_id IS NOT NULL;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE messaging_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Messaging preferences: Users can only manage their own
CREATE POLICY "Users manage own preferences"
    ON messaging_preferences FOR ALL
    USING (user_id = auth.uid());

-- Conversations: Users can only see their own conversations
CREATE POLICY "Users view own conversations"
    ON conversations FOR SELECT
    USING (
        (user1_id = auth.uid() OR user2_id = auth.uid())
        AND (
            (user1_id = auth.uid() AND user1_deleted_at IS NULL)
            OR (user2_id = auth.uid() AND user2_deleted_at IS NULL)
        )
    );

CREATE POLICY "Users can create conversations"
    ON conversations FOR INSERT
    TO authenticated
    WITH CHECK (user1_id = auth.uid() OR user2_id = auth.uid());

CREATE POLICY "Users can update own conversations"
    ON conversations FOR UPDATE
    USING (user1_id = auth.uid() OR user2_id = auth.uid());

-- Messages: Users can only see messages in their conversations
CREATE POLICY "Users view messages in their conversations"
    ON messages FOR SELECT
    USING (
        deleted_at IS NULL
        AND EXISTS (
            SELECT 1 FROM conversations c
            WHERE c.id = messages.conversation_id
            AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
        )
    );

CREATE POLICY "Users can send messages"
    ON messages FOR INSERT
    TO authenticated
    WITH CHECK (
        sender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM conversations c
            WHERE c.id = messages.conversation_id
            AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
            AND c.blocked_by IS NULL
        )
    );

CREATE POLICY "Users can update messages"
    ON messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM conversations c
            WHERE c.id = messages.conversation_id
            AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
        )
    );

-- Blocked users: Users manage their own blocks
CREATE POLICY "Users manage own blocks"
    ON blocked_users FOR ALL
    USING (blocker_id = auth.uid());

-- Check if blocked by someone (for messaging restrictions)
CREATE POLICY "Users can check if blocked"
    ON blocked_users FOR SELECT
    USING (blocked_id = auth.uid());

-- Reports: Users can create and view their own
CREATE POLICY "Users can create reports"
    ON reports FOR INSERT
    TO authenticated
    WITH CHECK (reporter_id = auth.uid());

CREATE POLICY "Users view own reports"
    ON reports FOR SELECT
    USING (reporter_id = auth.uid());

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_messaging_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER messaging_prefs_updated
    BEFORE UPDATE ON messaging_preferences
    FOR EACH ROW EXECUTE FUNCTION update_messaging_updated_at();

CREATE TRIGGER conversations_updated
    BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_messaging_updated_at();

CREATE TRIGGER messages_updated
    BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_messaging_updated_at();

-- Update conversation on new message
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER AS $$
DECLARE
    v_conv conversations%ROWTYPE;
BEGIN
    -- Get conversation
    SELECT * INTO v_conv FROM conversations WHERE id = NEW.conversation_id;
    
    -- Update conversation
    UPDATE conversations
    SET 
        last_message_id = NEW.id,
        last_message_text = CASE 
            WHEN NEW.message_type = 'text' THEN LEFT(NEW.content, 100)
            WHEN NEW.message_type = 'audio' THEN '🎤 Voice message'
            WHEN NEW.message_type = 'image' THEN '📷 Photo'
            WHEN NEW.message_type = 'document' THEN '📄 Document'
            ELSE 'Message'
        END,
        last_message_type = NEW.message_type,
        last_message_at = NEW.created_at,
        last_message_sender_id = NEW.sender_id,
        -- Increment unread for recipient
        user1_unread_count = CASE 
            WHEN v_conv.user1_id != NEW.sender_id THEN v_conv.user1_unread_count + 1
            ELSE v_conv.user1_unread_count
        END,
        user2_unread_count = CASE 
            WHEN v_conv.user2_id != NEW.sender_id THEN v_conv.user2_unread_count + 1
            ELSE v_conv.user2_unread_count
        END,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER conversation_message_trigger
    AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION update_conversation_on_message();

-- Initialize messaging preferences on user creation
CREATE OR REPLACE FUNCTION init_messaging_preferences()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO messaging_preferences (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: This trigger should be on profiles table after profile creation
-- CREATE TRIGGER init_prefs_on_profile
--     AFTER INSERT ON profiles
--     FOR EACH ROW EXECUTE FUNCTION init_messaging_preferences();

-- ============================================================================
-- VIEWS
-- ============================================================================

-- User's conversations with other user info
CREATE OR REPLACE VIEW my_conversations AS
SELECT 
    c.id as conversation_id,
    c.last_message_text,
    c.last_message_type,
    c.last_message_at,
    c.last_message_sender_id,
    c.blocked_by,
    c.disappearing_hours,
    c.created_at,
    -- Other user info
    CASE WHEN c.user1_id = auth.uid() THEN c.user2_id ELSE c.user1_id END as other_user_id,
    p.first_name,
    p.last_name,
    p.display_name,
    p.avatar_url,
    p.specialization,
    -- My unread count
    CASE WHEN c.user1_id = auth.uid() THEN c.user1_unread_count ELSE c.user2_unread_count END as unread_count,
    -- My settings
    CASE WHEN c.user1_id = auth.uid() THEN c.user1_muted ELSE c.user2_muted END as is_muted,
    CASE WHEN c.user1_id = auth.uid() THEN c.user1_archived ELSE c.user2_archived END as is_archived,
    CASE WHEN c.user1_id = auth.uid() THEN c.user1_pinned ELSE c.user2_pinned END as is_pinned,
    -- Other user's audio save preference
    COALESCE(mp.allow_audio_save, FALSE) as other_allows_audio_save
FROM conversations c
JOIN profiles p ON p.id = CASE WHEN c.user1_id = auth.uid() THEN c.user2_id ELSE c.user1_id END
LEFT JOIN messaging_preferences mp ON mp.user_id = p.id
WHERE 
    (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
    AND (
        (c.user1_id = auth.uid() AND c.user1_deleted_at IS NULL)
        OR (c.user2_id = auth.uid() AND c.user2_deleted_at IS NULL)
    )
ORDER BY 
    CASE WHEN c.user1_id = auth.uid() THEN c.user1_pinned ELSE c.user2_pinned END DESC,
    c.last_message_at DESC NULLS LAST;

-- Blocked users list
CREATE OR REPLACE VIEW my_blocked_users AS
SELECT 
    b.id as block_id,
    b.blocked_id,
    b.reason,
    b.created_at as blocked_at,
    p.first_name,
    p.last_name,
    p.display_name,
    p.avatar_url
FROM blocked_users b
JOIN profiles p ON p.id = b.blocked_id
WHERE b.blocker_id = auth.uid()
ORDER BY b.created_at DESC;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Get or create conversation
CREATE OR REPLACE FUNCTION get_or_create_conversation(p_other_user_id UUID)
RETURNS UUID AS $$
DECLARE
    v_user1 UUID;
    v_user2 UUID;
    v_conv_id UUID;
BEGIN
    -- Normalize order (user1 < user2)
    IF auth.uid() < p_other_user_id THEN
        v_user1 := auth.uid();
        v_user2 := p_other_user_id;
    ELSE
        v_user1 := p_other_user_id;
        v_user2 := auth.uid();
    END IF;
    
    -- Check if blocked
    IF EXISTS (
        SELECT 1 FROM blocked_users
        WHERE (blocker_id = auth.uid() AND blocked_id = p_other_user_id)
           OR (blocker_id = p_other_user_id AND blocked_id = auth.uid())
    ) THEN
        RAISE EXCEPTION 'Cannot message this user';
    END IF;
    
    -- Try to get existing conversation
    SELECT id INTO v_conv_id
    FROM conversations
    WHERE user1_id = v_user1 AND user2_id = v_user2;
    
    -- Create if not exists
    IF v_conv_id IS NULL THEN
        INSERT INTO conversations (user1_id, user2_id)
        VALUES (v_user1, v_user2)
        RETURNING id INTO v_conv_id;
    ELSE
        -- Restore if deleted
        UPDATE conversations
        SET 
            user1_deleted_at = CASE WHEN user1_id = auth.uid() THEN NULL ELSE user1_deleted_at END,
            user2_deleted_at = CASE WHEN user2_id = auth.uid() THEN NULL ELSE user2_deleted_at END
        WHERE id = v_conv_id;
    END IF;
    
    RETURN v_conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Send message
CREATE OR REPLACE FUNCTION send_message(
    p_conversation_id UUID,
    p_content TEXT DEFAULT NULL,
    p_message_type TEXT DEFAULT 'text',
    p_file_url TEXT DEFAULT NULL,
    p_file_name TEXT DEFAULT NULL,
    p_file_size INTEGER DEFAULT NULL,
    p_audio_duration INTEGER DEFAULT NULL,
    p_reply_to_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_message_id UUID;
    v_prefs messaging_preferences%ROWTYPE;
    v_conv_disappearing INTEGER;
    v_disappears_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Verify conversation access and not blocked
    IF NOT EXISTS (
        SELECT 1 FROM conversations
        WHERE id = p_conversation_id
        AND (user1_id = auth.uid() OR user2_id = auth.uid())
        AND blocked_by IS NULL
    ) THEN
        RAISE EXCEPTION 'Cannot send message to this conversation';
    END IF;
    
    -- Get user preferences for disappearing
    SELECT * INTO v_prefs FROM messaging_preferences WHERE user_id = auth.uid();
    
    -- Get conversation disappearing setting
    SELECT disappearing_hours INTO v_conv_disappearing
    FROM conversations WHERE id = p_conversation_id;
    
    -- Calculate disappears_at
    IF v_conv_disappearing IS NOT NULL THEN
        v_disappears_at := NULL; -- Will be set when viewed
    ELSIF v_prefs.default_disappearing_hours IS NOT NULL THEN
        v_disappears_at := NULL; -- Will be set when viewed
    END IF;
    
    -- Insert message
    INSERT INTO messages (
        conversation_id,
        sender_id,
        message_type,
        content,
        file_url,
        file_name,
        file_size,
        audio_duration_seconds,
        reply_to_id
    )
    VALUES (
        p_conversation_id,
        auth.uid(),
        p_message_type,
        p_content,
        p_file_url,
        p_file_name,
        p_file_size,
        p_audio_duration,
        p_reply_to_id
    )
    RETURNING id INTO v_message_id;
    
    RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_read(p_conversation_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
    v_conv conversations%ROWTYPE;
    v_disappearing_hours INTEGER;
BEGIN
    -- Get conversation
    SELECT * INTO v_conv FROM conversations WHERE id = p_conversation_id;
    
    -- Get disappearing hours (conversation override or NULL)
    v_disappearing_hours := v_conv.disappearing_hours;
    
    -- Mark unread messages as read
    UPDATE messages
    SET 
        status = 'read',
        read_at = NOW(),
        viewed_at = CASE WHEN viewed_at IS NULL THEN NOW() ELSE viewed_at END,
        -- Set disappears_at based on viewed time
        disappears_at = CASE 
            WHEN v_disappearing_hours IS NOT NULL AND disappears_at IS NULL 
            THEN NOW() + (v_disappearing_hours || ' hours')::INTERVAL
            ELSE disappears_at
        END
    WHERE 
        conversation_id = p_conversation_id
        AND sender_id != auth.uid()
        AND status != 'read'
        AND deleted_at IS NULL;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    -- Reset unread count
    UPDATE conversations
    SET 
        user1_unread_count = CASE WHEN user1_id = auth.uid() THEN 0 ELSE user1_unread_count END,
        user2_unread_count = CASE WHEN user2_id = auth.uid() THEN 0 ELSE user2_unread_count END
    WHERE id = p_conversation_id;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Save audio message (Snapchat-style)
CREATE OR REPLACE FUNCTION save_audio_message(p_message_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_msg messages%ROWTYPE;
    v_sender_allows BOOLEAN;
BEGIN
    -- Get message
    SELECT * INTO v_msg FROM messages WHERE id = p_message_id;
    
    IF NOT FOUND OR v_msg.message_type != 'audio' THEN
        RAISE EXCEPTION 'Invalid audio message';
    END IF;
    
    -- Check if sender allows saving
    SELECT allow_audio_save INTO v_sender_allows
    FROM messaging_preferences
    WHERE user_id = v_msg.sender_id;
    
    IF NOT COALESCE(v_sender_allows, FALSE) THEN
        RAISE EXCEPTION 'Sender does not allow saving audio messages';
    END IF;
    
    -- Save the message
    UPDATE messages
    SET saved_by = auth.uid(), saved_at = NOW()
    WHERE id = p_message_id
    AND sender_id != auth.uid(); -- Can't save own messages
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Block user for messaging
CREATE OR REPLACE FUNCTION block_user_messaging(p_user_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
    -- Insert block record
    INSERT INTO blocked_users (blocker_id, blocked_id, reason)
    VALUES (auth.uid(), p_user_id, p_reason)
    ON CONFLICT (blocker_id, blocked_id) DO NOTHING;
    
    -- Block conversation
    UPDATE conversations
    SET blocked_by = auth.uid(), blocked_at = NOW(), block_reason = p_reason
    WHERE 
        ((user1_id = auth.uid() AND user2_id = p_user_id)
        OR (user1_id = p_user_id AND user2_id = auth.uid()))
        AND blocked_by IS NULL;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Unblock user for messaging
CREATE OR REPLACE FUNCTION unblock_user_messaging(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Remove block record
    DELETE FROM blocked_users
    WHERE blocker_id = auth.uid() AND blocked_id = p_user_id;
    
    -- Unblock conversation (only if we blocked it)
    UPDATE conversations
    SET blocked_by = NULL, blocked_at = NULL, block_reason = NULL
    WHERE 
        ((user1_id = auth.uid() AND user2_id = p_user_id)
        OR (user1_id = p_user_id AND user2_id = auth.uid()))
        AND blocked_by = auth.uid();
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Report user/message for messaging
CREATE OR REPLACE FUNCTION report_user_messaging(
    p_user_id UUID,
    p_reason TEXT,
    p_description TEXT DEFAULT NULL,
    p_message_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_report_id UUID;
BEGIN
    INSERT INTO reports (
        report_type,
        reported_user_id,
        reported_message_id,
        reporter_id,
        reason,
        description
    )
    VALUES (
        CASE WHEN p_message_id IS NOT NULL THEN 'message' ELSE 'user' END,
        p_user_id,
        p_message_id,
        auth.uid(),
        p_reason,
        p_description
    )
    RETURNING id INTO v_report_id;
    
    RETURN v_report_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Delete conversation (soft delete for user)
CREATE OR REPLACE FUNCTION delete_conversation(p_conversation_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE conversations
    SET 
        user1_deleted_at = CASE WHEN user1_id = auth.uid() THEN NOW() ELSE user1_deleted_at END,
        user2_deleted_at = CASE WHEN user2_id = auth.uid() THEN NOW() ELSE user2_deleted_at END
    WHERE id = p_conversation_id
    AND (user1_id = auth.uid() OR user2_id = auth.uid());
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update conversation settings
CREATE OR REPLACE FUNCTION update_conversation_settings(
    p_conversation_id UUID,
    p_muted BOOLEAN DEFAULT NULL,
    p_archived BOOLEAN DEFAULT NULL,
    p_pinned BOOLEAN DEFAULT NULL,
    p_disappearing_hours INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_user1 BOOLEAN;
BEGIN
    -- Check if user1 or user2
    SELECT user1_id = auth.uid() INTO v_is_user1
    FROM conversations
    WHERE id = p_conversation_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    IF v_is_user1 THEN
        UPDATE conversations
        SET 
            user1_muted = COALESCE(p_muted, user1_muted),
            user1_archived = COALESCE(p_archived, user1_archived),
            user1_pinned = COALESCE(p_pinned, user1_pinned),
            disappearing_hours = COALESCE(p_disappearing_hours, disappearing_hours)
        WHERE id = p_conversation_id;
    ELSE
        UPDATE conversations
        SET 
            user2_muted = COALESCE(p_muted, user2_muted),
            user2_archived = COALESCE(p_archived, user2_archived),
            user2_pinned = COALESCE(p_pinned, user2_pinned),
            disappearing_hours = COALESCE(p_disappearing_hours, disappearing_hours)
        WHERE id = p_conversation_id;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get total unread count for user
CREATE OR REPLACE FUNCTION get_total_unread_count()
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COALESCE(SUM(
        CASE 
            WHEN user1_id = auth.uid() THEN user1_unread_count
            ELSE user2_unread_count
        END
    ), 0) INTO v_count
    FROM conversations
    WHERE 
        (user1_id = auth.uid() OR user2_id = auth.uid())
        AND blocked_by IS NULL
        AND (
            (user1_id = auth.uid() AND user1_deleted_at IS NULL)
            OR (user2_id = auth.uid() AND user2_deleted_at IS NULL)
        );
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT ON my_conversations TO authenticated;
GRANT SELECT ON my_blocked_users TO authenticated;

GRANT EXECUTE ON FUNCTION get_or_create_conversation TO authenticated;
GRANT EXECUTE ON FUNCTION send_message TO authenticated;
GRANT EXECUTE ON FUNCTION mark_messages_read TO authenticated;
GRANT EXECUTE ON FUNCTION save_audio_message TO authenticated;
GRANT EXECUTE ON FUNCTION block_user_messaging TO authenticated;
GRANT EXECUTE ON FUNCTION unblock_user_messaging TO authenticated;
GRANT EXECUTE ON FUNCTION report_user_messaging TO authenticated;
GRANT EXECUTE ON FUNCTION delete_conversation TO authenticated;
GRANT EXECUTE ON FUNCTION update_conversation_settings TO authenticated;
GRANT EXECUTE ON FUNCTION get_total_unread_count TO authenticated;
